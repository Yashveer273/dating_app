import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/Api/call_api_service.dart';

import 'dart:async';
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

  // Firebase Stream Subscription
  StreamSubscription? _callStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _startListeningToFirebaseCalls();
    fetchAndLoadCallHistory(); // 🟢 API से हिस्ट्री लोड करने का मेथड कॉल किया गया
  }

  @override
  void onClose() {
    _callStreamSubscription?.cancel();
    for (var call in incomingQueue) {
      call.dispose();
    }
    super.onClose();
  }

  /// 🟢 API से कॉल हिस्ट्री फेच करके मॉडल में पार्स करके लिस्ट में डालने का फंक्शन
  void fetchAndLoadCallHistory() async {
    try {
      // मान लेते हैं कि _apiService.fetchAgentCallHistory() लिस्ट या मैप रिटर्न करता है
      // यदि यह डायनामिक डेटा देता है तो उसे नीचे दिए गए तरीके से लूप करें:
      var response = await _apiService.fetchAgentCallHistory();

      // यदि रिस्पॉन्स में 'history' नाम की लिस्ट है (जैसा आपके JSON में दिख रहा है):
      if (response != null && response['history'] != null) {
        List rawList = response['history'];

        List loadedHistory = rawList.map((item) {
          return HistoryCallItemModel.fromJson(item);
        }).toList();

        historyList.assignAll(loadedHistory);
        print(
          '✅ Call history successfully loaded into model: ${historyList.length} items',
        );
      }
    } catch (e) {
      print('❌ Error loading call history from API: $e');
    }
  }

  /// 1️⃣ Firebase से लाइव कॉल्स सुनना
  void _startListeningToFirebaseCalls() {
    final String agentId = CallApiService.staticAgentId;

    if (agentId.isEmpty) {
      print('⚠️️ DEBUG: Static Agent ID खाली है!');
      return;
    }

    try {
      _callStreamSubscription = FirebaseFirestore.instance
          .collection('active_calls')
          .where(FieldPath.documentId, isEqualTo: agentId)
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) {
              for (var docChange in snapshot.docChanges) {
                final data = docChange.doc.data() as Map?;
                if (data == null) continue;

                if (docChange.type == DocumentChangeType.added ||
                    docChange.type == DocumentChangeType.modified) {
                  final String status = data['status']?.toString() ?? '';

                  if (status == 'ringing') {
                    final formattedData = {
                      'roomId': data['roomId']?.toString() ?? '',
                      'callerName':
                          data['userName']?.toString() ?? 'Valued Customer',
                      'avatarUrl': data['avatarUrl']?.toString() ?? '',
                      'callType': data['callType']?.toString() ?? 'video',
                      'createdAt':
                          data['createdAt'] ??
                          DateTime.now().millisecondsSinceEpoch,
                    };
                    handleApiCallReceived(formattedData);
                  }
                }
              }
            },
            onError: (error) {
              print('❌ Firebase listener error: $error');
            },
          );
    } catch (e) {
      print('❌ Error initializing Firebase listener: $e');
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
          onTimeout: () {
            handleCallTimeout(roomId);
          },
        );

        incomingQueue.insert(0, newCallItem);
      }
    } catch (e) {
      print('Error processing call data: $e');
    }
  }

  Future acceptCall(String callId) async {
    try {
      print('📞 Accepting call ID: $callId');
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      final int index = incomingQueue.indexWhere((call) => call.id == callId);
      if (index != -1) {
        final IncomingCallItemModel call = incomingQueue[index];
        incomingQueue.removeAt(index);
        call.dispose();
      }
      return true;
    } catch (e) {
      print('❌ Error accepting call: $e');
      Get.snackbar('Error', 'Could not connect call. Please try again.');
      return false;
    }
  }

  Future declineCall(String callId) async {
    try {
      print('🚫 Declining/Ending call ID: $callId');
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });

      _resolveLocalCallToHistory(
        callId,
        isTimeout: false,
        statusText: 'Declined / Cut by Agent',
        statusColor: Colors.redAccent,
        badgeIcon: Icons.call_end_rounded,
      );
      return true;
    } catch (e) {
      print('❌ Error declining call in Firebase: $e');
      _resolveLocalCallToHistory(
        callId,
        isTimeout: false,
        statusText: 'Declined / Cut by Agent',
        statusColor: Colors.redAccent,
        badgeIcon: Icons.call_end_rounded,
      );
      return true;
    }
  }

  void handleCallTimeout(String callId) {
    print('⌛ Timer (90s) completed for call ID: $callId');
    try {
      FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'timeout',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating timeout status: $e');
    }

    _resolveLocalCallToHistory(
      callId,
      isTimeout: true,
      statusText: 'Missed Call (Timed out)',
      statusColor: Colors.orangeAccent,
      badgeIcon: Icons.timer_off_rounded,
    );
  }

  void _resolveLocalCallToHistory(
    String callId, {
    required bool isTimeout,
    required String statusText,
    required Color statusColor,
    required IconData badgeIcon,
  }) {
    final int index = incomingQueue.indexWhere((call) => call.id == callId);
    if (index == -1) return;

    final IncomingCallItemModel call = incomingQueue[index];
    incomingQueue.removeAt(index);
    call.dispose();

    final String timeDetail = isTimeout
        ? 'Expired automatically (90s limit) • Just now'
        : 'Cut by agent • Just now';

    final newHistoryItem = HistoryCallItemModel(
      id: callId, // 🟢 बिना किसी मॉडिफिकेशन के डायरेक्ट कॉल आईडी का उपयोग
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
