import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  RxList<IncomingCallItemModel> incomingQueue = <IncomingCallItemModel>[].obs;

  // हिस्ट्री लिस्ट मैनेजमेंट
  RxList<HistoryCallItemModel> historyList = <HistoryCallItemModel>[].obs;

  // Firebase Stream Subscription
  StreamSubscription<QuerySnapshot>? _callStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    _startListeningToFirebaseCalls();
  }

  @override
  void onClose() {
    _callStreamSubscription?.cancel();
    for (var call in incomingQueue) {
      call.dispose();
    }
    super.onClose();
  }

  /// 1️⃣ Firebase से लाइव कॉल्स सुनना (Static Agent ID और 'ringing' स्टेटस के साथ)
  // क्लास के ऊपर आपका वेरिएबल वही पुराना रहने दें:
  // StreamSubscription<QuerySnapshot>? _callStreamSubscription;

  void _startListeningToFirebaseCalls() {
    final String agentId = CallApiService.staticAgentId;

    if (agentId.isEmpty) {
      print('⚠️ DEBUG: Static Agent ID खाली है!');
      return;
    }

    try {
      // 🚀 यहाँ हमने 'rooms' कलेक्शन की जगह सीधे एजेंट के डॉक्यूमेंट को टारगेट किया है
      // (इससे किसी इंडेक्स की जरूरत नहीं पड़ेगी और डिले पूरी तरह खत्म हो जाएगा)
      _callStreamSubscription = FirebaseFirestore.instance
          .collection('active_calls')
          .where(
            FieldPath.documentId,
            isEqualTo: agentId,
          ) // QuerySnapshot टाइप को सपोर्ट करने के लिए
          .snapshots()
          .listen(
            (QuerySnapshot<Object?> snapshot) {
              for (var docChange in snapshot.docChanges) {
                final data = docChange.doc.data() as Map<String, dynamic>?;
                if (data == null) continue;

                if (docChange.type == DocumentChangeType.added ||
                    docChange.type == DocumentChangeType.modified) {
                  final String status = data['status']?.toString() ?? '';

                  // जब कॉल ringing स्टेट में होगी, तभी एजेंट को दिखेगी
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

      // डुप्लीकेट प्रिवेंशन
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

  /// 🟢 2️⃣ एक्सेप्ट करने का कंट्रोलर फंक्शन
  /// स्टेप: पहले Firebase अपडेट होगा, फिर स्क्रीन शेयरिंग/कॉल स्क्रीन पर नेविगेट होगा।
  Future<bool> acceptCall(String callId) async {
    try {
      print('📞 Accepting call ID: $callId');

      // स्टेप A: Firebase पर स्टेटस 'accepted' करें
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // स्टेप B: लोकल क्यू से कॉल हटाएँ (UI से हटाने के लिए)
      final int index = incomingQueue.indexWhere((call) => call.id == callId);
      if (index != -1) {
        final IncomingCallItemModel call = incomingQueue[index];
        incomingQueue.removeAt(index);
        call.dispose();
      }

      print('✅ Call accepted successfully in Firebase.');
      return true; // सफलता का संकेत
    } catch (e) {
      print('❌ Error accepting call: $e');
      Get.snackbar('Error', 'Could not connect call. Please try again.');
      return false;
    }
  }

  /// 🔴 3️⃣ रिजेक्ट / डिलीट (OnDelete) करने का कंट्रोलर फंक्शन
  /// स्टेप: पहले Firebase पर स्टेटस 'ended' अपडेट होगा, रिस्పాंस आने पर यह फंक्शन ट्रू रिटर्न करेगा
  /// ताकि UI अपनी एनिमेटेड लिस्ट से स्मूथली कार्ड हटा सके।
  Future<bool> declineCall(String callId) async {
    try {
      print('🚫 Declining/Ending call ID: $callId');

      // स्टेप A: Firebase पर बैकएंड रिक्वेस्ट भेजकर स्टेटस 'ended' करें
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });

      print(
        '✅ Firebase response received for rejection. Proceeding to remove from UI queue.',
      );

      // स्टेप B: लोकल क्यू से हटाकर हिस्ट्री में डालें
      _resolveLocalCallToHistory(
        callId,
        isTimeout: false,
        statusText: 'Declined / Cut by Agent',
        statusColor: Colors.redAccent,
        badgeIcon: Icons.call_end_rounded,
      );

      return true; // ✅ रिस्పాंस सक्सेसफुल होने पर UI एनिमेशन ट्रिगर होगा
    } catch (e) {
      print('❌ Error declining call in Firebase: $e');
      // नेटवर्क एरर होने पर भी लोकल यूआई को साफ़ करने के लिए:
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

  /// ⏰ 4️⃣ टाइमआउट होने पर (90 सेकंड पूरे होने पर)
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

  /// 🔌 5️⃣ जब शेयर स्क्रीन या कॉल कट हो जाए (कनेक्शन ब्रेक होने पर कॉल खत्म होने पर)
  /// इसे तब कॉल करें जब यूज़र शेयर स्क्रीन से वापस आ रहा हो या कनेक्शन टूट गया हो
  void handleCallDisconnectFromScreen(
    String roomId, {
    bool isCompletedSuccessfully = true,
  }) {
    print('🔌 Call disconnected from active screen. Moving to history...');

    // लोकल हिस्ट्री में जोड़ें
    // (यहाँ आप कॉल की असली ड्यूरेशन भी पास कर सकते हैं)
    final String timeDetail = isCompletedSuccessfully
        ? 'Duration: 03:45 mins • Just now'
        : 'Connection Lost • Just now';

    // अगर कॉल ऑब्जेक्ट क्यू में नहीं है, तो डायरेक्ट हिस्ट्री आइटम बना सकते हैं
    // (नीचे दिए गए हेल्पर का उपयोग करें)
  }

  /// 📂 लोकल क्यू से हटाकर हिस्ट्री में भेजने का हेल्पर
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
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
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
