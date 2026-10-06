// views/caling_agent_dashboard/callreceive/SharedCallController.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/Api/AppConfig.dart'; // AppConfig se socket URL lene ke liye

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

  // 🟢 WebRTC & Socket State Variables
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? remoteStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  IO.Socket? _socket;

  final List floatingReactions = [];
  Timestamp? lastProcessedReactionTime;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SharedCallController({
    required this.roomId,
    required this.agentId,
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
    callStartTime = DateTime.now();

    // 1. Renderers Initialize Karein
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    // 2. Runtime Permissions Request Karein (Mic & Camera)
    bool granted = await _requestPermissions();
    if (!granted) {
      debugPrint("Microphone or Camera permission denied!");
    }

    // 3. Socket & WebRTC Setup
    _initSocketAndWebRTC();

    _startCallTimer();
    _listenToRoomUpdates();
    _initNotificationsAndShowOngoing();
  }

  // 🟢 Runtime Permissions Handler
  Future _requestPermissions() async {
    Map statuses = await [Permission.microphone, Permission.camera].request();

    bool micGranted =
        statuses[Permission.microphone] == PermissionStatus.granted;
    bool camGranted = statuses[Permission.camera] == PermissionStatus.granted;

    return micGranted && camGranted;
  }

  // 🟢 Socket & WebRTC Initialization
  void _initSocketAndWebRTC() {
    final String currentUserId = isUserCaller
        ? CallApiService.staticUserId
        : agentId;

    // Socket Connection Setup
    _socket = IO.io(AppConfig.rootBaseUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      debugPrint("Socket Connected: ${_socket!.id}");
      // Register user with socket
      _socket!.emit('register', {'userId': currentUserId});
      // Join Room
      _socket!.emit('join-room', {
        'roomId': roomId,
        'callType': (maxCallDurationSeconds != null && isCameraOff)
            ? 'voice'
            : 'video', // ya jo callType ho
      });
    });

    // Socket Listeners for WebRTC Signaling (matchs callSocket.js)
    _socket!.on('room-joined', (data) async {
      debugPrint("Joined room successfully: $data");
      await _startLocalStreamAndPeerConnection();

      // Agar caller hai toh WebRTC Offer banakar bhejein
      if (isUserCaller) {
        await _createAndSendOffer();
      }
    });

    _socket!.on('user-joined', (data) async {
      debugPrint("Another user joined room: $data");
      if (isUserCaller) {
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
        await _peerConnection?.addCandidate(candidate);
      }
    });
  }

  // 🟢 Start Local Stream & WebRTC Peer Connection
  // SharedCallController.dart mein _startLocalStreamAndPeerConnection method ko aise update karein:

  Future _startLocalStreamAndPeerConnection() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isCameraOff
          ? false
          : {
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 30},
            },
    };

    try {
      // 🟢 Web ke liye navigator.mediaDevices.getUserMedia call karna
      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      localRenderer.srcObject = _localStream;

      // Web par render update ensure karne ke liye setState trigger ho
      onStateUpdated();

      final Map<String, dynamic> configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };

      _peerConnection = await createPeerConnection(configuration);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      _peerConnection!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteStream = event.streams[0];
          remoteRenderer.srcObject = remoteStream;
          onStateUpdated(); // 🟢 UI refresh taaki remote video turant dikhe
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        if (candidate != null) {
          _socket?.emit('webrtc-ice-candidate', {
            'roomId': roomId,
            'candidate': candidate.toMap(),
          });
        }
      };
    } catch (e) {
      debugPrint("Error starting local stream on Web: $e");
    }
  }

  Future _createAndSendOffer() async {
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      _socket?.emit('webrtc-offer', {'roomId': roomId, 'offer': offer.toMap()});
    } catch (e) {
      debugPrint("Error creating offer: $e");
    }
  }

  Future _handleIncomingOffer(Map offerMap) async {
    try {
      RTCSessionDescription offer = RTCSessionDescription(
        offerMap['sdp'],
        offerMap['type'],
      );
      await _peerConnection!.setRemoteDescription(offer);
      RTCSessionDescription answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(answer);

      _socket?.emit('webrtc-answer', {
        'roomId': roomId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      debugPrint("Error handling offer: $e");
    }
  }

  Future _handleIncomingAnswer(Map answerMap) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        answerMap['sdp'],
        answerMap['type'],
      );
      await _peerConnection!.setRemoteDescription(answer);
    } catch (e) {
      debugPrint("Error handling answer: $e");
    }
  }

  // 🟢 Toggle Mute Control
  // views/caling_agent_dashboard/callreceive/SharedCallController.dart

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
      // 🟢 YAHAN PAR IS CODE KO ATTACH KARNA HAI:
      final updateField = isUserCaller ? 'userMuted' : 'agentMuted';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        updateField: isMuted,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating mute state: $e");
    }
  }

  // 🟢 Toggle Camera Control (Video Call Support)
  Future toggleCamera() async {
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
    // Helper to toggle speaker mode via WebRTC helper if needed
    Helper.setSpeakerphoneOn(isSpeakerOn);
    onStateUpdated();
    await _showPersistentCallNotification();
  }

  // Notifications setup...
  Future _initNotificationsAndShowOngoing() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'mute_action')
          toggleMuted();
        else if (response.actionId == 'speaker_action')
          toggleSpeaker();
        else if (response.actionId == 'end_call_action')
          hangupCall();
      },
    );
    await _showPersistentCallNotification();
  }

  Future _showPersistentCallNotification() async {
    int notificationId = roomId.hashCode;
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'ongoing_call_channel_id',
          'Ongoing Call',
          channelDescription:
              'Active call persistent notification with controls',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          actions: [
            AndroidNotificationAction(
              'mute_action',
              isMuted ? 'Unmute' : 'Mute',
              showsUserInterface: false,
            ),
            AndroidNotificationAction(
              'speaker_action',
              isSpeakerOn ? 'Earpiece' : 'Speaker',
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'end_call_action',
              'End Call',
              showsUserInterface: false,
            ),
          ],
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

          // 🟢 म्यूट और कैमरा स्टेट्स को अपडेट करना
          isAgentMuted = data['agentMuted'] == true;
          isUserMuted = data['userMuted'] == true;
          isRemoteCameraOff = isUserCaller
              ? (data['agentCameraOff'] ?? false)
              : (data['userCameraOff'] ?? false);

          // 🟢 दूसरे यूजर द्वारा भेजे गए इमोजी/रिएक्शन को सुनना और स्क्रीन पर दिखाना
          final latestReaction = data['latestReaction'] as Map?;
          if (latestReaction != null) {
            final reactionKey = latestReaction['key'] as String?;
            final senderRole = latestReaction['reactionSender'] as String?;
            final timestamp = latestReaction['timestamp'] as Timestamp?;

            // यह जांच करें कि रिएक्शन किसी दूसरे (Remote) यूजर ने भेजा हो और वह नया हो
            if (reactionKey != null &&
                senderRole != (isUserCaller ? 'user' : 'agent')) {
              if (timestamp != null &&
                  (lastProcessedReactionTime == null ||
                      timestamp.compareTo(lastProcessedReactionTime!) > 0)) {
                lastProcessedReactionTime = timestamp;
                _triggerLocalReactionAnimation(
                  reactionKey,
                ); // दूसरी तरफ से आया इमोजी प्ले होगा
              }
            }
          }

          final status = data['status'];
          if (status == 'ended' || status == 'rejected') {
            safeExit();
            return;
          }
          onStateUpdated();
        });
  }

  Future sendReaction(String iconKey) async {
    _triggerLocalReactionAnimation(iconKey);
    try {
      String senderRole = isUserCaller ? 'user' : 'agent';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'latestReaction': {
          'key': iconKey,
          'reactionSender': senderRole,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint("Error sending reaction: $e");
    }
  }

  void _triggerLocalReactionAnimation(String key) {
    IconData iconData = Icons.favorite;
    Color iconColor = Colors.redAccent;

    // 🟢 हर इमोजी की के हिसाब से उसका आइकॉन और रंग सेट करें
    switch (key) {
      case 'heart':
        iconData = Icons.favorite;
        iconColor = Colors.redAccent;
        break;
      case 'fire':
        iconData = Icons.local_fire_department;
        iconColor = Colors.orangeAccent;
        break;
      case 'star':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case 'thumb':
        iconData = Icons.thumb_up;
        iconColor = Colors.pinkAccent;
        break;
      case 'sparkle':
        iconData = Icons.auto_awesome;
        iconColor = Colors.purpleAccent;
        break;
    }

    double randomStartX = 50.0 + (DateTime.now().millisecondsSinceEpoch % 250);
    final reactionItem = FloatingReactionIcon(
      id: DateTime.now().millisecondsSinceEpoch,
      icon: iconData,
      color: iconColor,
      startX: randomStartX,
    );

    floatingReactions.add(reactionItem);
    onStateUpdated();

    Future.delayed(const Duration(milliseconds: 2500), () {
      floatingReactions.removeWhere((item) => item.id == reactionItem.id);
      onStateUpdated();
    });
  }

  Future hangupCall() async {
    if (isCallEnded || isActionInProgress) return;
    isActionInProgress = true;
    onStateUpdated();
    await saveCallSessionAndReset(endedBy: isUserCaller ? 'user' : 'agent');
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
    } catch (e) {
      debugPrint("Error in force cleanup: $e");
    }
    safeExit();
  }

  Future saveCallSessionAndReset({
    required String endedBy,
    String disconnectReason = 'normal_hangup',
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
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  void safeExit() {
    _callTimer?.cancel();
    roomSubscription?.cancel();
    _socket?.disconnect();

    // 🟢 Camera aur Mic ke hardware tracks ko explicitly stop karein taaki light turant band ho jaye
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        track
            .stop(); // Yeh browser ko signal deta hai ki camera/mic band karna hai
      }
      _localStream?.dispose();
      _localStream = null;
    }

    remoteStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _peerConnection?.dispose();

    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);
    onExit();
  }

  void dispose() {
    safeExit();
  }
}
