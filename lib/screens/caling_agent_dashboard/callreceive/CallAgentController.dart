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

  // Firebase Stream Subscriptions
  StreamSubscription? _callStreamSubscription;
  StreamSubscription? _roomStatusStreamSubscription;

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

  /// 1️⃣ Firebase से लाइव कॉल्स और रूम स्टेटस सुनना
  /// 1️⃣ Firebase से लाइव कॉल्स और रूम स्टेटस सुनना
  /// 1️⃣ Firebase से लाइव कॉल्स और रूम स्टेटस सुनना (Directly from 'rooms' collection)
  void _startListeningToFirebaseCalls() {
    final String agentId = CallApiService.staticAgentId;

    if (agentId.isEmpty) {
      print('⚠ DEBUG: Static Agent ID खाली है!');
      return;
    }

    try {
      print(
        '🎧 Listening for incoming ringing calls in "rooms" for agent: $agentId',
      );

      // 🟢 Fix: Listen directly to 'rooms' collection where call status is 'ringing'
      _callStreamSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .where('participants.agentId', isEqualTo: agentId)
          .where('status', isEqualTo: 'ringing')
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) {
              print(
                '📥 Rooms snapshot received! Total active ringing calls: ${snapshot.docs.length}',
              );

              for (var docChange in snapshot.docChanges) {
                final data = docChange.doc.data() as Map?;
                if (data == null) continue;

                print(
                  '🔔 Document Change Type: \({docChange.type}, ID:\){docChange.doc.id}, Data: $data',
                );

                if (docChange.type == DocumentChangeType.added ||
                    docChange.type == DocumentChangeType.modified) {
                  final String status = data['status']?.toString() ?? '';

                  if (status == 'ringing') {
                    final formattedData = {
                      'roomId':
                          data['roomId']?.toString() ??
                          data['id'] ??
                          docChange.doc.id,
                      'callerName':
                          data['userName']?.toString() ?? 'Valued Customer',
                      'avatarUrl': data['avatarUrl']?.toString() ?? '',
                      'callType': data['callType']?.toString() ?? 'audio',
                      'createdAt':
                          data['createdAt'] ??
                          DateTime.now().millisecondsSinceEpoch,
                    };

                    print(
                      '✅ New Ringing Call Detected & Formatting Data: $formattedData',
                    );
                    handleApiCallReceived(formattedData);
                  }
                }
              }
            },
            onError: (error) {
              print('❌ Firebase rooms listener error: $error');
            },
          );

      // 2. 🟢 रूम कैंसिलेशन या टाइमआउट (ended / timeout) सुनने के लिए दूसरा लिसनर
      _roomStatusStreamSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .where('participants.agentId', isEqualTo: agentId)
          .where('status', isEqualTo: 'ended')
          .snapshots()
          .listen(
            (snapshot) {
              for (var docChange in snapshot.docChanges) {
                final data = docChange.doc.data() as Map?;
                if (data == null) continue;

                final String roomId = data['id'] ?? docChange.doc.id;
                final bool wasUnanswered = data['endedBy'] == 'agent_no_answer';

                if (incomingQueue.any((call) => call.id == roomId)) {
                  print('🔔 Room ended on server. Moving to history.');

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
            },
            onError: (error) {
              print('❌ Firebase room status listener error: $error');
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
      print('📞 Accepting call ID: $callId');

      final acceptedAt = DateTime.now();
      final roomRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(callId);
      final didAccept = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists ||
            roomSnapshot.data()?['status'] != 'ringing') {
          return false;
        }

        transaction.update(roomRef, {
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'startTimeMs': acceptedAt.millisecondsSinceEpoch,
        });
        return true;
      });

      if (!didAccept) {
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

      incomingCall?.cancelAcceptTimeout();

      final int index = incomingQueue.indexWhere((call) => call.id == callId);
      if (index != -1) {
        incomingQueue.removeAt(index);
      }
      return true;
    } catch (e) {
      incomingCall?.resumeAcceptTimeout();
      print('❌ Error accepting call: $e');
      Get.snackbar('Error', 'Could not connect call. Please try again.');
      return false;
    }
  }

  Future<void> handleCallTimeout(String callId) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(callId);
    try {
      final didTimeout = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists ||
            roomSnapshot.data()?['status'] != 'ringing') {
          return false;
        }

        transaction.update(roomRef, {
          'status': 'ended',
          'endedBy': 'agent_no_answer',
          'disconnectReason': 'agent_timeout',
          'endedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (didTimeout) {
        _resolveLocalCallToHistory(
          callId,
          statusText: 'Missed Call (No answer)',
          statusColor: Colors.orangeAccent,
          badgeIcon: Icons.timer_off_rounded,
          timeDetail: 'No answer • 90s',
        );
      }
    } catch (e) {
      print('Error ending unanswered call: $e');
    }
  }

  Future declineCall(String callId) async {
    final index = incomingQueue.indexWhere((call) => call.id == callId);
    if (index != -1) {
      (incomingQueue[index] as IncomingCallItemModel).cancelAcceptTimeout();
    }

    try {
      print('🚫 Declining/Ending call ID: $callId');

      // 🟢 Backend endCall API कॉल करें ताकि सर्वर-साइड Missed/Declined CallLog सही से सेव हो सके
      // 🟢 Fix: Pass parameters as named parameters with colons (:)
      await CallApiService.endCall(
        roomId: callId,
        agentId: CallApiService.staticAgentId,
        endedBy: 'agent',
        disconnectReason: 'declined_by_agent',
      );

      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
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
      print('❌ Error declining call in Firebase: $e');
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
