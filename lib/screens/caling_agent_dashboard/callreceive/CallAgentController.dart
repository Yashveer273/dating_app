// ==========================================
// CallAgentController.dart (Updated with Packages & Rules)
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/components/AgentStatusManager.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import 'call_item_models.dart';

class CallAgentController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;

  RxString totalCallTime = '0h 0m'.obs;
  RxBool autoScrollOnNewCall = true.obs;

  // क्यू लिस्ट जिसमें IncomingCallItemModel स्टोर होंगे
  RxList incomingQueue = [].obs;

  // हिस्ट्री लिस्ट मैनेजमेंट
  RxList historyList = [].obs;
  final UserApiService _apiService = Get.put(UserApiService());

  // 🟢 रिंगटोन इनेबल/डिसएबल चेक करने का वेरिएबल
  RxBool isRingtoneEnabled = true.obs;

  // 🟢 ऑडियो प्लेयर इंस्टेंस रिंगटोन प्ले करने के लिए
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRingtonePlaying = false;

  // RTDB Stream Subscriptions
  StreamSubscription<DatabaseEvent>? _callStreamSubscription;
  StreamSubscription<DatabaseEvent>? _roomStatusStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadUserPreferences();
    _startListeningToFirebaseCalls();
    fetchAndLoadCallHistory();
  }

  @override
  void onClose() {
    _callStreamSubscription?.cancel();
    _roomStatusStreamSubscription?.cancel();
    _audioPlayer.dispose();
    for (final call in incomingQueue) {
      call.dispose();
    }
    super.onClose();
  }

  void _loadUserPreferences() {
    // यहाँ आप स्टोरेज से रिंगटोन की वैल्यू लोड कर सकते हैं
    isRingtoneEnabled.value = true; // डिफ़ॉल्ट वैल्यू
  }

  /// 🟢 इनकमिंग कॉल आने पर रिंगटोन और वाइब्रेशन को मैनेज करने का लॉजिक
  Future<void> _handleIncomingAlerts() async {
    try {
      // 1. यदि एजेंट पहले से किसी कॉल पर बिजी है
      if (AgentStatusManager.isAgentBusy.value) {
        print(
          '📞 Agent is busy on another call. Playing vibration/busy alert only.',
        );
        // बिजी होने पर सिर्फ नॉर्मल वाइब्रेशन दिखाएंगे
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 500);
        }
        return;
      }

      // 2. चेक करें कि क्या रिंगटोन ट्रूली इनेबल (true) है या नहीं
      if (isRingtoneEnabled.value != true) {
        print(
          '🔕 Ringtone is not enabled. Triggering continuous high vibration.',
        );
        // अगर true नहीं है तो लगातार हाई वाइब्रेशन (जब तक कॉल कट न हो)
        _triggerContinuousHighVibration();
      } else {
        // 3. रिंगटोन इनेबल है (true) -> रिंगटोन साउंड + वाइब्रेशन दोनों प्ले करें
        print('🔔 Ringtone is enabled. Playing ringtone1.mp3 and vibration.');

        if (!_isRingtonePlaying) {
          _playRingtoneSound();
        } else {
          print(
            '🔊 Ringtone is already playing. Skipping duplicate sound playback.',
          );
        }

        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }
      }
    } catch (e) {
      print('❌ Error handling incoming alerts: $e');
    }
  }

  /// 🎵 एसेट से ringtone1.mp3 प्ले करने का फंक्शन
  void _playRingtoneSound() async {
    if (_isRingtonePlaying) return;
    _isRingtonePlaying = true;
    try {
      await _audioPlayer.setReleaseMode(
        ReleaseMode.loop,
      ); // लूप में बजाने के लिए ताकि कॉल आने पर बजती रहे
      await _audioPlayer.play(AssetSource('ringtone1.mp3'));
      print('🎵 Playing ringtone1.mp3 from assets...');
    } catch (e) {
      print('❌ Error playing ringtone: $e');
      _isRingtonePlaying = false;
    }
  }

  /// 📳 लगातार हाई वाइब्रेशन जब तक क्यू खाली न हो या कॉल कट न जाए
  void _triggerContinuousHighVibration() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // पैटर्न के साथ वाइब्रेट करें (लंबी वाइब्रेशन)
        Vibration.vibrate(pattern: [0, 1000, 500, 1000], repeat: 0);
      }
    } catch (e) {
      print('❌ Error in high vibration: $e');
    }
  }

  /// 🔇 क्यू खाली होने पर या कॉल कटने पर रिंगटोन और वाइब्रेशन बंद करने का फंक्शन
  void _stopRingtoneAndVibration() {
    if (incomingQueue.isEmpty) {
      _isRingtonePlaying = false;
      _audioPlayer.stop();
      Vibration.cancel(); // वाइब्रेशन बंद करें
      print('🔇 Queue is empty. Stopping ringtone and vibration.');
    }
  }

  /// 🟢 API से कॉल हिस्ट्री फेच करना
  void fetchAndLoadCallHistory() async {
    try {
      var response = await _apiService.fetchAgentCallHistory();
      if (response != null && response['history'] != null) {
        List rawList = response['history'];
        List loadedHistory = rawList.map((item) {
          return HistoryCallItemModel.fromJson(item);
        }).toList();
        historyList.assignAll(loadedHistory);
      }
    } catch (e) {
      print('❌ Error loading call history from API: $e');
    }
  }

  /// 1️⃣ Firebase Realtime Database से लाइव कॉल्स और रूम स्टेटस सुनना
  void _startListeningToFirebaseCalls() {
    final String agentId = CallApiService.staticAgentId;

    if (agentId.isEmpty) {
      print('⚠ DEBUG: Static Agent ID खाली है!');
      return;
    }

    try {
      print(
        '🎧 Listening for incoming ringing calls in RTDB "rooms" for agent: $agentId',
      );
      final DatabaseReference roomsRef = FirebaseDatabase.instance.ref('rooms');

      _callStreamSubscription = roomsRef
          .orderByChild('participants/agentId')
          .equalTo(agentId)
          .onValue
          .listen(
            (DatabaseEvent event) {
              final rawData = event.snapshot.value;
              if (rawData == null) return;

              if (rawData is Map) {
                rawData.forEach((key, value) {
                  final String roomId = key?.toString() ?? '';
                  if (value is Map) {
                    final String status = value['status']?.toString() ?? '';

                    if (status == 'ringing') {
                      final formattedData = {
                        'roomId':
                            value['roomId']?.toString() ??
                            value['id'] ??
                            roomId,
                        'callerName':
                            value['userName']?.toString() ?? 'Valued Customer',
                        'avatarUrl': value['avatarUrl']?.toString() ?? '',
                        'callType': value['callType']?.toString() ?? 'audio',
                        'createdAt':
                            value['createdAt'] ??
                            DateTime.now().millisecondsSinceEpoch,
                      };

                      print(
                        '✅ Active Ringing Call Detected in RTDB: $formattedData',
                      );
                      handleApiCallReceived(formattedData);
                    }
                  }
                });
              }
            },
            onError: (error) {
              print('❌ RTDB rooms listener error: $error');
            },
          );

      _roomStatusStreamSubscription = roomsRef
          .orderByChild('participants/agentId')
          .equalTo(agentId)
          .onValue
          .listen(
            (DatabaseEvent event) {
              final rawData = event.snapshot.value;
              if (rawData == null) return;

              if (rawData is Map) {
                rawData.forEach((key, value) {
                  final String roomId = key?.toString() ?? '';
                  if (value is Map) {
                    final String status = value['status']?.toString() ?? '';
                    final bool wasUnanswered =
                        value['endedBy'] == 'agent_no_answer';

                    if (status == 'ended' || status == 'rejected') {
                      AgentStatusManager.isAgentBusy.value = false;

                      if (incomingQueue.any((call) => call.id == roomId)) {
                        print(
                          '🔔 Room ended on RTDB server. Moving to history.',
                        );

                        _resolveLocalCallToHistory(
                          roomId,
                          statusText: wasUnanswered
                              ? 'Missed Call (No answer)'
                              : 'Call Ended / Cancelled',
                          statusColor: wasUnanswered
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                          badgeIcon: wasUnanswered
                              ? Icons.timer_off_rounded
                              : Icons.call_end_rounded,
                          timeDetail: wasUnanswered
                              ? 'No answer • 90s'
                              : 'Call ended • Just now',
                        );
                      }
                    }
                  }
                });
              }
            },
            onError: (error) {
              print('❌ RTDB room status listener error: $error');
            },
          );
    } catch (e) {
      print('❌ Error initializing RTDB listener: $e');
    }
  }

  void handleApiCallReceived(Map apiResponseData) {
    try {
      final String roomId =
          apiResponseData['roomId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final String callerName =
          apiResponseData['callerName']?.toString() ?? 'Valued Customer';
      final String avatarUrl = apiResponseData['avatarUrl']?.toString() ?? '';

      bool isVideo = true;
      final rawVideoData = apiResponseData['callType'];
      if (rawVideoData != null && rawVideoData is String) {
        isVideo = rawVideoData.toLowerCase().contains('video');
      }

      if (!incomingQueue.any((call) => call.id == roomId)) {
        for (var call in incomingQueue) {
          call.isBrandNew.value = false;
        }

        // 🟢 इनकमिंग कॉल आने पर अलर्ट ट्रिगर करें
        _handleIncomingAlerts();

        final newCallItem = IncomingCallItemModel(
          id: roomId,
          name: callerName,
          avatarUrl: avatarUrl,
          isVideoCall: isVideo,
          isBrandNew: true,
          initialDurationSeconds: 90,
          onTimeout: () => unawaited(handleCallTimeout(roomId)),
        );

        incomingQueue.insert(0, newCallItem);
      }
    } catch (e) {
      print('Error processing call data: $e');
    }
  }

  Future acceptCall(String callId) async {
    final queueIndex = incomingQueue.indexWhere((call) => call.id == callId);
    final IncomingCallItemModel? incomingCall = queueIndex == -1
        ? null
        : incomingQueue[queueIndex];
    incomingCall?.pauseAcceptTimeout();

    try {
      print('📞 Accepting call ID in RTDB: $callId');

      final roomRef = FirebaseDatabase.instance.ref('rooms/$callId');
      final snapshot = await roomRef.get();

      if (!snapshot.exists || snapshot.child('status').value != 'ringing') {
        incomingCall?.cancelAcceptTimeout();
        _resolveLocalCallToHistory(
          callId,
          statusText: 'Call Ended / Cancelled',
          statusColor: Colors.redAccent,
          badgeIcon: Icons.call_end_rounded,
          timeDetail: 'Call ended • Just now',
        );
        return false;
      }

      // 🟢 कॉल एक्सेप्ट होने पर एजेंट को बिजी मार्क करें
      AgentStatusManager.isAgentBusy.value = true;

      await roomRef.update({
        'status': 'accepted',
        'acceptedAt': ServerValue.timestamp,
        'startTimeMs': ServerValue.timestamp,
      });

      incomingCall?.cancelAcceptTimeout();

      final int index = incomingQueue.indexWhere((call) => call.id == callId);
      if (index != -1) {
        incomingQueue.removeAt(index);
      }

      // 🟢 रिंगटोन और वाइब्रेशन बंद करें क्योंकि कॉल अटेंड हो चुकी है
      _stopRingtoneAndVibration();
      return true;
    } catch (e) {
      incomingCall?.resumeAcceptTimeout();
      print('❌ Error accepting call in RTDB: $e');
      Get.snackbar('Error', 'Could not connect call. Please try again.');
      return false;
    }
  }

  Future<void> handleCallTimeout(String callId) async {
    final roomRef = FirebaseDatabase.instance.ref('rooms/$callId');
    try {
      final snapshot = await roomRef.get();
      if (!snapshot.exists || snapshot.child('status').value != 'ringing') {
        return;
      }

      await roomRef.update({
        'status': 'ended',
        'endedBy': 'agent_no_answer',
        'disconnectReason': 'agent_timeout',
        'endedAt': ServerValue.timestamp,
      });

      AgentStatusManager.isAgentBusy.value = false;

      _resolveLocalCallToHistory(
        callId,
        statusText: 'Missed Call (No answer)',
        statusColor: Colors.orangeAccent,
        badgeIcon: Icons.timer_off_rounded,
        timeDetail: 'No answer • 90s',
      );
    } catch (e) {
      print('Error ending unanswered call in RTDB: $e');
    }
  }

  Future declineCall(String callId) async {
    final index = incomingQueue.indexWhere((call) => call.id == callId);
    if (index != -1) {
      (incomingQueue[index] as IncomingCallItemModel).cancelAcceptTimeout();
    }

    try {
      print('🚫 Declining/Ending call ID: $callId');

      await CallApiService.endCall(
        roomId: callId,
        agentId: CallApiService.staticAgentId,
        endedBy: 'agent',
        disconnectReason: 'declined_by_agent',
      );

      await FirebaseDatabase.instance.ref('rooms/$callId').update({
        'status': 'ended',
        'endedAt': ServerValue.timestamp,
      });

      AgentStatusManager.isAgentBusy.value = false;

      _resolveLocalCallToHistory(
        callId,
        statusText: 'Declined / Cut by Agent',
        statusColor: Colors.redAccent,
        badgeIcon: Icons.call_end_rounded,
        timeDetail: 'Cut by agent • Just now',
      );
      return true;
    } catch (e) {
      print('❌ Error declining call in RTDB: $e');
      AgentStatusManager.isAgentBusy.value = false;
      _resolveLocalCallToHistory(
        callId,
        statusText: 'Declined / Cut by Agent',
        statusColor: Colors.redAccent,
        badgeIcon: Icons.call_end_rounded,
        timeDetail: 'Cut by agent • Just now',
      );
      return true;
    }
  }

  void _resolveLocalCallToHistory(
    String callId, {
    required String statusText,
    required Color statusColor,
    required IconData badgeIcon,
    required String timeDetail,
  }) {
    final int index = incomingQueue.indexWhere((call) => call.id == callId);
    if (index == -1) return;

    final IncomingCallItemModel call = incomingQueue[index];
    incomingQueue.removeAt(index);
    call.dispose();

    final newHistoryItem = HistoryCallItemModel(
      id: callId,
      name: call.name,
      avatarUrl: call.avatarUrl,
      callType: call.isVideoCall ? 'Video Call' : 'Audio Call',
      callTypeIcon: call.isVideoCall
          ? Icons.videocam_rounded
          : Icons.phone_in_talk_rounded,
      statusText: statusText,
      statusColor: statusColor,
      statusBg: statusColor.withOpacity(0.12),
      timeDetail: timeDetail,
      badgeIcon: badgeIcon,
      timestamp: DateTime.now(),
    );

    historyList.insert(0, newHistoryItem);

    // 🟢 क्यू खाली होने पर रिंगटोन/वाइब्रेशन बंद करें
    _stopRingtoneAndVibration();
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void toggleAutoScroll(bool value) {
    autoScrollOnNewCall.value = value;
  }
}
