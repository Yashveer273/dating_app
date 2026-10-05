// views/caling_agent_dashboard/callreceive/SharedCallController.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:talk24loves/Api/call_api_service.dart';

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
    if (maxCallDurationSeconds != null && maxCallDurationSeconds! > 0) {
      return;
    }
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

  void init() {
    callStartTime = DateTime.now();
    _startCallTimer();
    _listenToRoomUpdates();
    _initNotificationsAndShowOngoing();
  }

  Future _initNotificationsAndShowOngoing() async {
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
      // 🟢 Fix: Call accept होने के बाद WhatsApp की तरह 0 से duration शुरू होगा
      secondsElapsed = acceptedAt == null
          ? secondsElapsed + 1
          : DateTime.now().difference(acceptedAt).inSeconds.clamp(0, 1 << 31);

      if (isUserCaller && secondsElapsed > 0 && secondsElapsed % 15 == 0) {
        unawaited(_syncBudgetSnapshot());
      }
      final remainingSeconds = remainingCallSeconds;
      if (remainingSeconds != null && remainingSeconds <= 0) {
        onStateUpdated();
        unawaited(
          forceCleanupOnExit(
            endedBy: 'wallet_limit',
            disconnectReason: 'wallet_balance_exhausted',
          ),
        );
        return;
      }
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
    final currentBalance = estimatedWalletBalance;
    final remainingSeconds = remainingCallSeconds;
    if (currentBalance == null || remainingSeconds == null) return;

    _isBudgetSyncInProgress = true;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'currentWalletBalance': currentBalance,
        'remainingDurationSeconds': remainingSeconds,
        'budgetUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing call budget to room: $e');
    } finally {
      _isBudgetSyncInProgress = false;
    }
  }

  Future toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    onStateUpdated();
    await _showPersistentCallNotification();
  }

  Future toggleMute() async {
    isMuted = !isMuted;
    onStateUpdated();
    await _showPersistentCallNotification();

    try {
      // 🟢 Fix: सही फील्ड नेम के साथ Firebase पर म्यूट स्टेटस अपडेट करें ताकि दूसरे यूजर/एजेंट को तुरंत दिखे
      final updateField = isUserCaller ? 'userMuted' : 'agentMuted';
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        updateField: isMuted,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating mute state: $e");
    }
  }

  Future toggleCamera() async {
    isCameraOff = !isCameraOff;
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

  void _listenToRoomUpdates() {
    roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists) {
              safeExit();
              return;
            }

            final data = snapshot.data() as Map?;
            if (data == null) return;

            final startingBalance = data['walletBalanceAtCall'];
            if (startingBalance is num) {
              walletBalanceAtCall = startingBalance.toDouble();
            }
            final rate = data['ratePerMinute'];
            if (rate is num) {
              callRatePerMinute = rate.toDouble();
            }

            final maxDurationDoc = data['maxDurationSeconds'];
            if (maxDurationDoc is num && maxDurationDoc > 0) {
              maxCallDurationSeconds = maxDurationDoc.toInt();
            }

            _updateCalculatedMaxDuration();

            final acceptedAt = data['acceptedAt'];
            if (acceptedAt is Timestamp) {
              _acceptedAt = acceptedAt.toDate();
              secondsElapsed = DateTime.now()
                  .difference(_acceptedAt!)
                  .inSeconds
                  .clamp(0, 1 << 31);
            }

            final status = data['status'];
            if (status == 'ended' ||
                status == 'rejected' ||
                status == 'missed') {
              safeExit();
              return;
            }

            // 🟢 Fix: रियल-टाइम म्यूट स्टेटस डेटा फेच करना (अगर यूजर कॉल कर रहा है तो एजेंट का म्यूट स्टेट पढ़ेगा और vice versa)
            isAgentMuted = data['agentMuted'] == true;
            isUserMuted = data['userMuted'] == true;

            isRemoteCameraOff = isUserCaller
                ? (data['agentCameraOff'] ?? false)
                : (data['userCameraOff'] ?? false);

            try {
              final reactionRaw = data['latestReaction'];
              if (reactionRaw is Map) {
                final reactionData = Map.from(reactionRaw);
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
            } catch (e) {
              debugPrint("Error parsing reaction: $e");
            }

            onStateUpdated();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Call room listener network error: $error');
            unawaited(
              forceCleanupOnExit(
                endedBy: isUserCaller ? 'user' : 'agent',
                disconnectReason: 'network_disconnected',
              ),
            );
          },
        );
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

  Future hangupCall() async {
    if (isCallEnded || isActionInProgress) return;
    isActionInProgress = true;
    onStateUpdated();

    await saveCallSessionAndReset(endedBy: isUserCaller ? 'user' : 'agent');
    safeExit();
  }

  DateTime get _effectiveCallStartTime => _acceptedAt ?? callStartTime;

  int _durationAt(DateTime endTime) {
    final duration = endTime.difference(_effectiveCallStartTime).inSeconds;
    return duration > 0 ? duration : 0;
  }

  Future forceCleanupOnExit({
    String endedBy = 'disconnected',
    String disconnectReason = 'unexpected_disconnect',
  }) async {
    if (isCallEnded) return;
    isCallEnded = true;
    final endTime = DateTime.now();
    final durationInSeconds = _durationAt(endTime);

    try {
      await CallApiService.endCall(
        roomId: roomId,
        agentId: agentId,
        endedBy: endedBy,
        disconnectReason: disconnectReason,
        startTime: _effectiveCallStartTime,
        endTime: endTime,
        durationInSeconds: durationInSeconds,
      );
    } catch (e) {
      debugPrint("Error calling backend endCall API in forceCleanup: $e");
    }

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).set({
        'status': 'ended',
        'endedBy': endedBy,
        'disconnectReason': disconnectReason,
        'disconnectedAt': FieldValue.serverTimestamp(),
        'startTimeMs': _effectiveCallStartTime.millisecondsSinceEpoch,
        'endTimeMs': endTime.millisecondsSinceEpoch,
        'durationInSeconds': durationInSeconds,
        'currentWalletBalance': estimatedWalletBalance,
        'remainingDurationSeconds': remainingCallSeconds,
        'budgetUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('active_calls')
          .doc(agentId)
          .delete();
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
    final endTime = DateTime.now();
    final durationInSeconds = _durationAt(endTime);

    try {
      await CallApiService.endCall(
        roomId: roomId,
        agentId: agentId,
        endedBy: endedBy,
        disconnectReason: disconnectReason,
        startTime: _effectiveCallStartTime,
        endTime: endTime,
        durationInSeconds: durationInSeconds,
      );
    } catch (e) {
      debugPrint("Error calling backend endCall API: $e");
    }

    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': 'ended',
        'endedBy': endedBy,
        'disconnectReason': disconnectReason,
        'startTimeMs': _effectiveCallStartTime.millisecondsSinceEpoch,
        'endTimeMs': endTime.millisecondsSinceEpoch,
        'durationInSeconds': durationInSeconds,
        'durationSeconds': durationInSeconds,
        'currentWalletBalance': estimatedWalletBalance,
        'remainingDurationSeconds': remainingCallSeconds,
        'budgetUpdatedAt': FieldValue.serverTimestamp(),
      });

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
    roomSubscription?.cancel();
    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);
    onExit();
  }

  void dispose() {
    _callTimer?.cancel();
    roomSubscription?.cancel();
    flutterLocalNotificationsPlugin.cancel(id: roomId.hashCode);

    if (!isCallEnded) {
      forceCleanupOnExit(
        endedBy: isUserCaller ? 'user' : 'agent',
        disconnectReason: 'screen_disposed',
      );
    }
  }
}
