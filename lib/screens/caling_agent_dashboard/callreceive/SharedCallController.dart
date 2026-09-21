// views/caling_agent_dashboard/callreceive/SharedCallController.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  bool isRemoteMuted = false;
  bool isCameraOff = false;
  bool isRemoteCameraOff = false;
  bool isLocalFullScreen = false;
  bool isSpeakerOn = false;

  int secondsElapsed = 0;
  Timer? _callTimer;
  Timer? _maxTimeoutTimer;
  StreamSubscription<DocumentSnapshot>? roomSubscription;
  late final DateTime callStartTime;
  bool isCallEnded = false;
  bool isActionInProgress = false;

  final List<FloatingReactionIcon> floatingReactions = [];
  Timestamp? lastProcessedReactionTime;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  SharedCallController({
    required this.roomId,
    required this.agentId,
    required this.isUserCaller,
    required this.onStateUpdated,
    required this.onExit,
  });

  void init() {
    callStartTime = DateTime.now();
    _startCallTimer();
    _startMaxTimeoutTimer();
    _listenToRoomUpdates();
    _initNotificationsAndShowOngoing();
  }

  Future<void> _initNotificationsAndShowOngoing() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'mute_action') {
          toggleMute();
        } else if (response.actionId == 'speaker_action') {
          toggleSpeaker();
        } else if (response.actionId == 'end_call_action') {
          hangupCall();
        }
      },
    );

    await _showPersistentCallNotification();
  }

  Future<void> _showPersistentCallNotification() async {
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
          actions: <AndroidNotificationAction>[
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

  void _startMaxTimeoutTimer() {
    _maxTimeoutTimer = Timer(const Duration(seconds: 90), () {
      if (!isCallEnded) {
        debugPrint("Call timed out after 90 seconds.");
        forceCleanupOnExit(endedBy: 'timeout');
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsElapsed++;
      if (secondsElapsed % 5 == 0) {
        _showPersistentCallNotification();
      }
      onStateUpdated();
    });
  }

  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    onStateUpdated();
    await _showPersistentCallNotification();
  }

  // views/caling_agent_dashboard/callreceive/SharedCallController.dart

  Future<void> toggleMute() async {
    isMuted = !isMuted;
    onStateUpdated();
    await _showPersistentCallNotification();

    try {
      final updateField = isUserCaller ? 'userMuted' : 'agentMuted';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        updateField: isMuted,
      });
      debugPrint(
        "✅ Mute state successfully updated to Firestore: $updateField = $isMuted",
      );
    } catch (e) {
      debugPrint("❌ Error updating mute state: $e");
    }
  }

  Future<void> toggleCamera() async {
    isCameraOff = !isCameraOff;
    onStateUpdated();

    try {
      final updateField = isUserCaller ? 'userCameraOff' : 'agentCameraOff';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        updateField: isCameraOff,
      });
    } catch (e) {
      debugPrint("Error updating camera state: $e");
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

          final data = snapshot.data() as Map<String, dynamic>?;
          if (data == null) return;

          final status = data['status'];
          if (status == 'ended' ||
              status == 'rejected' ||
              status == 'timeout' ||
              status == 'missed') {
            safeExit();
            return;
          }

          isRemoteMuted = isUserCaller
              ? (data['agentMuted'] ?? false)
              : (data['userMuted'] ?? false);

          isRemoteCameraOff = isUserCaller
              ? (data['agentCameraOff'] ?? false)
              : (data['userCameraOff'] ?? false);

          final reactionData = data['latestReaction'] as Map<String, dynamic>?;
          if (reactionData != null) {
            final timestamp = reactionData['timestamp'] as Timestamp?;
            final sender = reactionData['reactionSender']?.toString();
            final key = reactionData['key']?.toString();

            String currentSenderRole = isUserCaller ? 'user' : 'agent';
            if (timestamp != null &&
                key != null &&
                sender != currentSenderRole) {
              if (lastProcessedReactionTime == null ||
                  timestamp.millisecondsSinceEpoch >
                      lastProcessedReactionTime!.millisecondsSinceEpoch) {
                lastProcessedReactionTime = timestamp;
                _triggerLocalReactionAnimation(key);
              }
            }
          }

          onStateUpdated();
        });
  }

  Future<void> sendReaction(String iconKey) async {
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

    if (key == 'fire') {
      iconData = Icons.local_fire_department;
      iconColor = Colors.orangeAccent;
    } else if (key == 'star') {
      iconData = Icons.star;
      iconColor = Colors.amber;
    } else if (key == 'thumb') {
      iconData = Icons.thumb_up;
      iconColor = Colors.pinkAccent;
    } else if (key == 'sparkle') {
      iconData = Icons.auto_awesome;
      iconColor = Colors.purpleAccent;
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

  Future<void> hangupCall() async {
    if (isCallEnded || isActionInProgress) return;
    isActionInProgress = true;
    onStateUpdated();

    await saveCallSessionAndReset(endedBy: isUserCaller ? 'user' : 'agent');
    safeExit();
  }

  Future<void> forceCleanupOnExit({String endedBy = 'disconnected'}) async {
    if (isCallEnded) return;
    isCallEnded = true;

    try {
      // 1. Mark room as ended
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'status': 'ended',
        'endedBy': endedBy,
        'disconnectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Clear active calls entry for this agent to make them free immediately
      await FirebaseFirestore.instance
          .collection('active_calls')
          .doc(agentId)
          .delete();
    } catch (e) {
      debugPrint("Error in force cleanup: $e");
    }
    safeExit();
  }

  Future<void> saveCallSessionAndReset({required String endedBy}) async {
    if (isCallEnded) return;
    isCallEnded = true;

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': 'ended',
        'endedBy': endedBy,
        'durationSeconds': secondsElapsed,
      });

      // Clear active call doc so agent can receive new calls right away
      await FirebaseFirestore.instance
          .collection('active_calls')
          .doc(agentId)
          .delete();
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  void safeExit() {
    _callTimer?.cancel();
    _maxTimeoutTimer?.cancel();
    roomSubscription?.cancel();

    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);

    onExit();
  }

  void dispose() {
    _callTimer?.cancel();
    _maxTimeoutTimer?.cancel();
    roomSubscription?.cancel();

    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);

    if (!isCallEnded) {
      forceCleanupOnExit(endedBy: isUserCaller ? 'user_crash' : 'agent_crash');
    }
  }
}
