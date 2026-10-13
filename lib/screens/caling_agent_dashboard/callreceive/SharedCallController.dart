// views/caling_agent_dashboard/callreceive/SharedCallController.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/Api/AppConfig.dart';

// मॉड्यूलर हैंडल्स इम्पोर्ट करें
import 'CallAudioHandler.dart';
import 'CallVideoHandler.dart';
import 'CallReactionHandler.dart';

class SharedCallController
    with
        WidgetsBindingObserver,
        CallAudioHandler,
        CallVideoHandler,
        CallReactionHandler {
  final String roomId;
  final String agentId;
  final String callType; // 'voice' या 'video'
  final bool isUserCaller;
  final VoidCallback onStateUpdated;
  final VoidCallback onExit;

  @override
  bool get isRemoteMuted => isUserCaller ? isAgentMuted : isUserMuted;

  @override
  IO.Socket? get socket => _socket;

  @override
  String get roomIdRef => roomId;

  @override
  VoidCallback get onStateUpdatedRef => onStateUpdated;

  int secondsElapsed = 0;
  int? maxCallDurationSeconds;
  double? walletBalanceAtCall;
  double? callRatePerMinute;
  Timer? _callTimer;
  DateTime? _acceptedAt;
  bool _isBudgetSyncInProgress = false;
  StreamSubscription? roomSubscription;
  late final DateTime callStartTime;
  bool isCallEnded = false;
  bool isActionInProgress = false;
  bool _isExiting = false;
  bool _isInForeground = true;

  RTCPeerConnection? _peerConnection;
  IO.Socket? _socket;

  final List<RTCIceCandidate> _iceCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;
  bool _isCreatingOffer = false;
  bool _isInitialized = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SharedCallController({
    required this.roomId,
    required this.agentId,
    required this.callType,
    required this.isUserCaller,
    required this.onStateUpdated,
    required this.onExit,
    this.maxCallDurationSeconds,
    this.walletBalanceAtCall,
    this.callRatePerMinute,
  }) {
    initRenderers();
    _updateCalculatedMaxDuration();
    WidgetsBinding.instance.addObserver(this);
  }

  void _updateCalculatedMaxDuration() {
    if (maxCallDurationSeconds != null && maxCallDurationSeconds! > 0) return;
    if (walletBalanceAtCall != null &&
        callRatePerMinute != null &&
        callRatePerMinute! > 0) {
      final calculatedSeconds =
          ((walletBalanceAtCall! / callRatePerMinute!) * 60).toInt();
      if (calculatedSeconds > 0) {
        maxCallDurationSeconds = calculatedSeconds;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
      if (!kIsWeb) {
        flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isInForeground = false;
      if (!kIsWeb) {
        _showPersistentCallNotification();
      }
    } else if (state == AppLifecycleState.detached) {
      forceCleanupOnExit(
        endedBy: isUserCaller ? 'user' : 'agent',
        disconnectReason: 'app_terminated',
      );
    }
    super.didChangeAppLifecycleState(state);
  }

  Future init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    callStartTime = DateTime.now();
    _acceptedAt = DateTime.now(); // 🟢 यहाँ इनिशियलाइज कर लें

    bool granted = await _requestPermissions();
    if (!granted) {
      debugPrint("❌ Microphone or Camera permission denied!");
      return;
    }

    await _startLocalStreamAndAudioRouting();
    _initSocketAndWebRTC();
    _startCallTimer();
    _listenToRoomUpdates();
    initReactionListener();

    if (!kIsWeb) {
      await _initNotifications();
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return true;
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        if (callType == 'video') Permission.camera,
      ].request();

      bool micGranted =
          statuses[Permission.microphone] == PermissionStatus.granted;
      bool camGranted = callType == 'video'
          ? statuses[Permission.camera] == PermissionStatus.granted
          : true;

      return micGranted && camGranted;
    } catch (e) {
      debugPrint("⚠️ Permission error: $e");
      return true;
    }
  }

  Future _startLocalStreamAndAudioRouting() async {
    if (localStream != null) return;

    // 🟢 ऑडियो कॉल के लिए बेहतर ऑडियो कॉन्स्टेंट्स ताकि आवाज साफ़ और दोनों तरफ जाए
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': (callType == 'voice' || isCameraOff)
          ? false
          : {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            },
    };

    try {
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // ऑडियो कॉल पर बाय-डिफ़ॉल्ट स्पीकर ऑन या इयरपीस सेट करें
      if (callType == 'voice') {
        Helper.setSpeakerphoneOn(true);
        isSpeakerOn = true;
      }

      if (callType == 'video' && localStream != null) {
        localRenderer.srcObject = localStream;
        debugPrint("🟢 [LOCAL STREAM] Video & Audio loaded successfully.");
      }
      onStateUpdated();
    } catch (e) {
      debugPrint("❌ Error getting user media: $e");
    }
  }

  void _initSocketAndWebRTC() {
    final String currentUserId = isUserCaller
        ? CallApiService.staticUserId
        : agentId;

    _socket = IO.io(AppConfig.rootBaseUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      debugPrint("🔌 Socket Connected: ${_socket!.id}");
      _socket!.emit('register', {'userId': currentUserId});
      _socket!.emit('join-room', {'roomId': roomId, 'callType': callType});
    });

    _socket!.on('room-joined', (data) async {
      debugPrint("🏠 Joined room successfully: $data");
      await _startPeerConnectionOnly();
      if (isUserCaller && _peerConnection != null) {
        await _createAndSendOffer();
      }
    });

    _socket!.on('user-joined', (data) async {
      debugPrint("👤 Another user joined room: $data");
      await _startPeerConnectionOnly();
      if (isUserCaller && _peerConnection != null) {
        await _createAndSendOffer();
      }
    });

    _socket!.on('webrtc-offer', (data) async {
      if (!isUserCaller) {
        await _handleIncomingOffer(data['offer']);
      }
    });

    _socket!.on('webrtc-answer', (data) async {
      if (isUserCaller) {
        await _handleIncomingAnswer(data['answer']);
      }
    });

    _socket!.on('webrtc-ice-candidate', (data) async {
      if (data['candidate'] != null) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        if (_isRemoteDescriptionSet && _peerConnection != null) {
          await _peerConnection!.addCandidate(candidate);
        } else {
          _iceCandidatesQueue.add(candidate);
        }
      }
    });

    _socket!.on('user-left', (data) async {
      debugPrint("👤 User left room: $data");
      safeExit();
    });
  }

  Future _startPeerConnectionOnly() async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    try {
      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint("🔗 [WebRTC CONNECTION STATE]: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          isLoadingRemoteVideo = false;
          onStateUpdated();
        }
        if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          safeExit();
        }
      };

      if (localStream != null) {
        localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, localStream!);
        });
      }

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint(
          "📥 [REMOTE TRACK EVENT] Streams count: ${event.streams.length}",
        );
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          if (callType == 'video') {
            remoteRenderer.srcObject = remoteStream;
            debugPrint("✅ [REMOTE RENDERER] Remote video bound successfully!");
          }
          isLoadingRemoteVideo = false;
          onStateUpdated();
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        _socket?.emit('webrtc-ice-candidate', {
          'roomId': roomId,
          'candidate': candidate.toMap(),
        });
      };
    } catch (e) {
      debugPrint("❌ Error creating peer connection: $e");
    }
  }

  Future _createAndSendOffer() async {
    if (_isCreatingOffer || _peerConnection == null) return;
    _isCreatingOffer = true;

    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == 'video',
      });

      await _peerConnection!.setLocalDescription(offer);
      _socket?.emit('webrtc-offer', {'roomId': roomId, 'offer': offer.toMap()});
    } catch (e) {
      debugPrint("❌ Error creating offer: $e");
    } finally {
      _isCreatingOffer = false;
    }
  }

  Future _handleIncomingOffer(Map offerMap) async {
    try {
      if (_peerConnection == null) {
        await _startPeerConnectionOnly();
      }
      if (_peerConnection == null) return;

      RTCSessionDescription offer = RTCSessionDescription(
        offerMap['sdp'],
        offerMap['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      _isRemoteDescriptionSet = true;

      for (var candidate in _iceCandidatesQueue) {
        await _peerConnection!.addCandidate(candidate);
      }
      _iceCandidatesQueue.clear();

      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': callType == 'video',
      });
      await _peerConnection!.setLocalDescription(answer);

      _socket?.emit('webrtc-answer', {
        'roomId': roomId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      debugPrint("❌ Error handling offer: $e");
    }
  }

  Future _handleIncomingAnswer(Map answerMap) async {
    try {
      if (_peerConnection == null) return;
      RTCSessionDescription answer = RTCSessionDescription(
        answerMap['sdp'],
        answerMap['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
      _isRemoteDescriptionSet = true;

      for (var candidate in _iceCandidatesQueue) {
        await _peerConnection!.addCandidate(candidate);
      }
      _iceCandidatesQueue.clear();
    } catch (e) {
      debugPrint("❌ Error handling answer: $e");
    }
  }

  Future toggleMuted() async {
    toggleMutedLogic(); // AudioHandler mixin से
    onStateUpdated();

    try {
      final updateField = isUserCaller ? 'userMuted' : 'agentMuted';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        updateField: isMuted,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating mute state: $e");
    }
  }

  Future toggleCamera() async {
    if (callType != 'video') return;
    isCameraOff = !isCameraOff;
    if (localStream != null) {
      for (var track in localStream!.getVideoTracks()) {
        track.enabled = !isCameraOff;
      }
    }
    onStateUpdated();

    try {
      final updateField = isUserCaller ? 'userCameraOff' : 'agentCameraOff';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        updateField: isCameraOff,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating camera state: $e");
    }
  }

  Future toggleSpeaker() async {
    toggleSpeakerLogic(); // AudioHandler mixin से
    onStateUpdated();
  }

  Future _initNotifications() async {
    if (kIsWeb) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
    } catch (e) {
      debugPrint("⚠️ Notification init warning: $e");
    }
  }

  Future _showPersistentCallNotification() async {
    if (kIsWeb || _isInForeground) return;

    int notificationId = roomId.hashCode;
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
          'ongoing_call_channel_id',
          'Ongoing Call',
          channelDescription: 'Active call status',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
        );

    NotificationDetails platformChannelDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: notificationId,
      title: callType == 'video' ? 'Ongoing Video Call' : 'Ongoing Audio Call',
      body: 'Tap to return to call',
      notificationDetails: platformChannelDetails,
      payload: 'return_to_call',
    );
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final acceptedAt = _acceptedAt;
      secondsElapsed = acceptedAt == null
          ? secondsElapsed + 1
          : DateTime.now().difference(acceptedAt).inSeconds.clamp(0, 1 << 31);

      if (isUserCaller && secondsElapsed > 0 && secondsElapsed % 15 == 0) {
        unawaited(_syncBudgetSnapshot());
      }
      onStateUpdated();
    });
  }

  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int? get remainingCallSeconds {
    final maxDuration = maxCallDurationSeconds;
    if (maxDuration == null || maxDuration <= 0) return null;
    final remaining = maxDuration - secondsElapsed;
    return remaining > 0 ? remaining : 0;
  }

  double? get estimatedWalletBalance {
    final balance = walletBalanceAtCall;
    final rate = callRatePerMinute;
    if (balance == null || rate == null) return null;
    final remaining = balance - (rate * secondsElapsed / 60);
    return remaining > 0 ? remaining : 0;
  }

  Future _syncBudgetSnapshot() async {
    if (!isUserCaller || _isBudgetSyncInProgress || isCallEnded) return;
    _isBudgetSyncInProgress = true;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'currentWalletBalance': estimatedWalletBalance,
        'remainingDurationSeconds': remainingCallSeconds,
        'budgetUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing budget: $e');
    } finally {
      _isBudgetSyncInProgress = false;
    }
  }

  void _listenToRoomUpdates() {
    roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            safeExit();
            return;
          }
          final data = snapshot.data() as Map?;
          if (data == null) return;

          isAgentMuted = data['agentMuted'] == true;
          isUserMuted = data['userMuted'] == true;
          isRemoteCameraOff = isUserCaller
              ? (data['agentCameraOff'] ?? false)
              : (data['userCameraOff'] ?? false);

          final status = data['status'];
          if (status == 'ended' || status == 'rejected') {
            safeExit();
            return;
          }
          onStateUpdated();
        });
  }

  Future hangupCall() async {
    if (isCallEnded || isActionInProgress) return;
    isActionInProgress = true;
    onStateUpdated();
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await CallApiService.endCall(
        roomId: roomId,
        agentId: agentId,
        endedBy: isUserCaller ? 'user' : 'agent',
        disconnectReason: 'normal_hangup',
        startTime: callStartTime,
        endTime: DateTime.now(),
        durationInSeconds: secondsElapsed,
      );
    } catch (e) {
      debugPrint("Error saving session on hangup: $e");
    }
    safeExit();
  }

  Future forceCleanupOnExit({
    String endedBy = 'disconnected',
    String disconnectReason = 'unexpected_disconnect',
  }) async {
    if (isCallEnded) return;
    isCallEnded = true;

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await CallApiService.endCall(
        roomId: roomId,
        agentId: agentId,
        endedBy: endedBy,
        disconnectReason: disconnectReason,
        startTime: callStartTime,
        endTime: DateTime.now(),
        durationInSeconds: secondsElapsed,
      );
    } catch (e) {
      debugPrint("❌ Error in force cleanup: $e");
    }

    safeExit();
  }

  void safeExit() {
    if (_isExiting) return;
    _isExiting = true;
    isCallEnded = true;

    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    roomSubscription?.cancel();

    try {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;

      if (localStream != null) {
        for (var track in localStream!.getTracks()) {
          track.stop();
        }
        localStream?.dispose();
        localStream = null;
      }

      if (remoteStream != null) {
        for (var track in remoteStream!.getTracks()) {
          track.stop();
        }
        remoteStream?.dispose();
        remoteStream = null;
      }

      disposeRenderers();

      _peerConnection?.close();
      _peerConnection?.dispose();
      _peerConnection = null;

      _iceCandidatesQueue.clear();
      _isRemoteDescriptionSet = false;
      _isCreatingOffer = false;

      Helper.setSpeakerphoneOn(false);
      debugPrint("✅ Call exited cleanly and all modular states reset.");
    } catch (e) {
      debugPrint("⚠️ Error during safeExit cleanup: $e");
    }

    if (!kIsWeb) {
      flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);
    }
    onExit();
  }

  void dispose() {
    safeExit();
  }
}
