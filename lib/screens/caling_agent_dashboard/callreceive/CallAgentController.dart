// ==========================================
// CallAgentController.dart (Updated for RTDB & Safe ForEach)
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart'; // 🟢 RTDB Import
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/Api/call_api_service.dart';

import 'call_item_models.dart';

class CallAgentController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;
  RxDouble currentEarnings = 1240.50.obs;
  RxString totalCallTime = '42h 15m'.obs;

  RxBool autoScrollOnNewCall = true.obs;

  // क्यू लिस्ट जिसमें IncomingCallItemModel स्टोर होंगे
  RxList incomingQueue = [].obs;

  // हिस्ट्री लिस्ट मैनेजमेंट
  RxList historyList = [].obs;
  final UserApiService _apiService = Get.put(UserApiService());

  // RTDB Stream Subscriptions
  StreamSubscription<DatabaseEvent>? _callStreamSubscription;
  StreamSubscription<DatabaseEvent>? _roomStatusStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _startListeningToFirebaseCalls();
    fetchAndLoadCallHistory();
  }

  @override
  void onClose() {
    _callStreamSubscription?.cancel();
    _roomStatusStreamSubscription?.cancel();
    for (final call in incomingQueue) {
      call.dispose();
    }
    super.onClose();
  }

  /// 🟢 API से कॉल हिस्ट्री फेच करके मॉडल में पार्स करके लिस्ट में डालने का फंक्शन
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

  /// 1️⃣ Firebase Realtime Database से लाइव कॉल्स और रूम स्टेटस सुनना (Safe Map Iteration)
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

      // 🟢 1. Ringing calls सुनने के लिए RTDB query
      _callStreamSubscription = roomsRef
          .orderByChild('participants/agentId')
          .equalTo(agentId)
          .onValue
          .listen(
            (DatabaseEvent event) {
              final rawData = event.snapshot.value;
              if (rawData == null) return;

              // 🟢 Type-safe check: RTDB data is returned as a Map
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

      // 🟢 2. रूम कैंसिलेशन या टाइमआउट (ended / rejected) सुनने के लिए लिसनर
      _roomStatusStreamSubscription = roomsRef
          .orderByChild('participants/agentId')
          .equalTo(agentId)
          .onValue
          .listen(
            (DatabaseEvent event) {
              final rawData = event.snapshot.value;
              if (rawData == null) return;

              // 🟢 Type-safe check for Map iteration
              if (rawData is Map) {
                rawData.forEach((key, value) {
                  final String roomId = key?.toString() ?? '';
                  if (value is Map) {
                    final String status = value['status']?.toString() ?? '';
                    final bool wasUnanswered =
                        value['endedBy'] == 'agent_no_answer';

                    if (status == 'ended' || status == 'rejected') {
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

      // 🟢 RTDB Status update to accepted
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

      // 🟢 RTDB Timeout update
      await roomRef.update({
        'status': 'ended',
        'endedBy': 'agent_no_answer',
        'disconnectReason': 'agent_timeout',
        'endedAt': ServerValue.timestamp,
      });

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

      // Backend endCall API कॉल ताकि सर्वर-साइड Missed/Declined CallLog सही से सेव हो सके
      await CallApiService.endCall(
        roomId: callId,
        agentId: CallApiService.staticAgentId,
        endedBy: 'agent',
        disconnectReason: 'declined_by_agent',
      );

      // 🟢 RTDB Status update to ended
      await FirebaseDatabase.instance.ref('rooms/$callId').update({
        'status': 'ended',
        'endedAt': ServerValue.timestamp,
      });

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
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void toggleAutoScroll(bool value) {
    autoScrollOnNewCall.value = value;
  }
}
