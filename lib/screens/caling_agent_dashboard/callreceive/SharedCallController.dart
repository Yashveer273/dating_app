// views/caling_agent_dashboard/callreceive/SharedCallController.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/Api/AppConfig.dart';

class FloatingReactionIcon {
  final int id;
  final IconData icon;
  final Color color;
  final double startX;
  FloatingReactionIcon({
    required this.id,
    required this.icon,
    required this.color,
    required this.startX,
  });
}

class SharedCallController {
  final String roomId;
  final String agentId;
  final String callType; // 'voice' ya 'video'
  final bool isUserCaller;
  final VoidCallback onStateUpdated;
  final VoidCallback onExit;

  bool isMuted = false;
  bool isAgentMuted = false;
  bool isUserMuted = false;
  bool get isRemoteMuted => isUserCaller ? isAgentMuted : isUserMuted;
  bool isCameraOff = false;
  bool isRemoteCameraOff = false;
  bool isLocalFullScreen = false;
  bool isSpeakerOn = false;

  int secondsElapsed = 0;
  int? maxCallDurationSeconds;
  double? walletBalanceAtCall;
  double? callRatePerMinute;
  DateTime? _acceptedAt;
  Timer? _callTimer;
  bool _isBudgetSyncInProgress = false;
  StreamSubscription? roomSubscription;
  late final DateTime callStartTime;
  bool isCallEnded = false;
  bool isActionInProgress = false;
  bool _isExiting = false;

  // WebRTC & Socket State Variables
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? remoteStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  IO.Socket? _socket;

  // ICE Candidates Queue & Guards
  final List<RTCIceCandidate> _iceCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;
  bool _isCreatingOffer = false;
  bool _isInitialized = false;

  final List floatingReactions = [];
  Timestamp? lastProcessedReactionTime;

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
    _updateCalculatedMaxDuration();
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

  Future init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    callStartTime = DateTime.now();

    if (callType == 'video') {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    }

    bool granted = await _requestPermissions();
    if (!granted) {
      debugPrint("❌ Microphone or Camera permission denied!");
    }

    _initSocketAndWebRTC();
    _startCallTimer();
    _listenToRoomUpdates();
    _initNotificationsAndShowOngoing();
  }

  Future<bool> _requestPermissions() async {
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
      debugPrint("⚠️ Permission request error: $e");
      return true;
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
      await _startLocalStreamAndPeerConnection();
      // Sirf caller ek baar offer banaye
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

    // Agar dusra user disconnect ya leave hota hai toh call automatically handle ho
    _socket!.on('user-left', (data) async {
      debugPrint("👤 User left room: $data");
      safeExit();
    });
  }

  Future _startLocalStreamAndPeerConnection() async {
    if (_peerConnection != null) return;

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': (callType == 'voice' || isCameraOff)
          ? false
          : {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            },
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      // 🟢 Local Stream Logs
      debugPrint("🟢 [LOCAL STREAM]getUserMedia सफल रहा।");
      debugPrint(
        "🟢 [LOCAL STREAM] Audio Tracks की संख्या: ${_localStream?.getAudioTracks().length}",
      );
      debugPrint(
        "🟢 [LOCAL STREAM] Video Tracks की संख्या: ${_localStream?.getVideoTracks().length}",
      );

      if (callType == 'video' && _localStream != null) {
        localRenderer.srcObject = _localStream;
        debugPrint(
          "🟢 [LOCAL RENDERER] Local video stream successfully assigned to localRenderer!",
        );
      }

      onStateUpdated();

      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint("🔗 [WebRTC CONNECTION STATE]: $state");
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        debugPrint("❄️ [ICE CONNECTION STATE]: $state");
      };

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
        debugPrint(
          "📤 [PEER CONNECTION] Added local track to peer connection: ${track.kind} (Enabled: ${track.enabled})",
        );
      });

      // 🟢 4. रिमोट ट्रैक हैंडलर (यहाँ सबसे महत्वपूर्ण लॉग्स हैं)
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint("📥 [REMOTE TRACK EVENT FIRED!] ------------------");
        debugPrint(
          "📥 Track Kind: ${event.track.kind} | Track ID: ${event.track.id} | Enabled: ${event.track.enabled}",
        );
        debugPrint("📥 Streams attached in event: ${event.streams.length}");

        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];

          debugPrint(
            "📥 [REMOTE STREAM RECEIVED] Stream ID: ${remoteStream?.id}",
          );
          debugPrint(
            "📥 Remote Audio Tracks count: ${remoteStream?.getAudioTracks().length}",
          );
          debugPrint(
            "📥 Remote Video Tracks count: ${remoteStream?.getVideoTracks().length}",
          );

          if (callType == 'video') {
            remoteRenderer.srcObject = remoteStream;
            debugPrint(
              "✅ [REMOTE RENDERER] Remote video stream successfully bound to remoteRenderer!",
            );
          } else {
            debugPrint(
              "✅ [REMOTE AUDIO] Remote audio stream active for voice call.",
            );
          }
          onStateUpdated();
        } else {
          debugPrint(
            "⚠️ [WARNING] onTrack event received but event.streams is EMPTY!",
          );
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        debugPrint(
          "🧊 [ICE CANDIDATE GENERATED] Sending candidate to socket...",
        );
        _socket?.emit('webrtc-ice-candidate', {
          'roomId': roomId,
          'candidate': candidate.toMap(),
        });
      };
    } catch (e) {
      debugPrint("❌ [ERROR] Error in _startLocalStreamAndPeerConnection: $e");
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
      debugPrint("📤 WebRTC Offer created and sent successfully.");
    } catch (e) {
      debugPrint("❌ Error creating offer: $e");
    } finally {
      _isCreatingOffer = false;
    }
  }

  Future _handleIncomingOffer(Map offerMap) async {
    try {
      if (_peerConnection == null) {
        await _startLocalStreamAndPeerConnection();
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
      debugPrint("📥 Incoming offer handled & answer sent.");
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
      debugPrint("📥 Incoming answer handled successfully.");
    } catch (e) {
      debugPrint("❌ Error handling answer: $e");
    }
  }

  Future toggleMuted() async {
    isMuted = !isMuted;
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
    onStateUpdated();
    await _showPersistentCallNotification();

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
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
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
    isSpeakerOn = !isSpeakerOn;
    Helper.setSpeakerphoneOn(isSpeakerOn);
    onStateUpdated();
    await _showPersistentCallNotification();
  }

  Future _initNotificationsAndShowOngoing() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      await _showPersistentCallNotification();
    } catch (e) {
      debugPrint("⚠️ Notification init warning: $e");
    }
  }

  Future _showPersistentCallNotification() async {
    int notificationId = roomId.hashCode;
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
          'ongoing_call_channel_id',
          'Ongoing Call',
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
      title: 'Ongoing Call (${formatTime(secondsElapsed)})',
      body: 'Tap to manage call controls',
      notificationDetails: platformChannelDetails,
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

  Future sendReaction(String iconKey) async {}

  Future hangupCall() async {
    if (isCallEnded || isActionInProgress) return;
    isActionInProgress = true;
    onStateUpdated();
    try {
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
      await CallApiService.endCall(
        roomId: roomId,
        agentId: agentId,
        endedBy: endedBy,
        disconnectReason: disconnectReason,
        startTime: callStartTime,
        endTime: DateTime.now(),
        durationInSeconds: secondsElapsed,
      );
      debugPrint("🧹 Force cleanup executed successfully.");
    } catch (e) {
      debugPrint("❌ Error in force cleanup: $e");
    }

    safeExit();
  }

  void safeExit() {
    if (_isExiting) return;
    _isExiting = true;
    isCallEnded = true;

    _callTimer?.cancel();
    roomSubscription?.cancel();
    _socket?.disconnect();

    try {
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        _localStream?.dispose();
        _localStream = null;
      }

      remoteStream?.dispose();
      remoteStream = null;

      if (callType == 'video') {
        localRenderer.dispose();
        remoteRenderer.dispose();
      }

      _peerConnection?.dispose();
      _peerConnection = null;
    } catch (e) {
      debugPrint("⚠️ Error during safeExit cleanup: $e");
    }

    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);
    onExit();
  }

  void dispose() {
    safeExit();
  }
}
