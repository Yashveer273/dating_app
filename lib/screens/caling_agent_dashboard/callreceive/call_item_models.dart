import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class IncomingCallItemModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isVideoCall;
  RxBool isBrandNew;

  // Reactive fields
  late final RxInt remainingSeconds;
  late final RxString timeDisplay;
  Timer? _countdownTimer;

  VoidCallback? onTimeout;

  IncomingCallItemModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isVideoCall,
    bool isBrandNew = false,
    int initialDurationSeconds = 90, // यहाँ 90 सेकंड सेट कर दिया गया है
    this.onTimeout,
  }) : isBrandNew = isBrandNew.obs {
    remainingSeconds = initialDurationSeconds.obs;
    timeDisplay = '${initialDurationSeconds}s left to accept'.obs;
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        timeDisplay.value = '${remainingSeconds.value}s left to accept';
      } else {
        _countdownTimer?.cancel();
        if (onTimeout != null) {
          onTimeout!();
        }
      }
    });
  }

  void dispose() {
    _countdownTimer?.cancel();
  }
}

class HistoryCallItemModel {
  final String id; // API का सटीक callId
  final String name;
  final String avatarUrl;
  final String callType;
  final IconData callTypeIcon;
  final String statusText;
  final Color statusColor;
  final Color statusBg;
  final String timeDetail;
  final IconData badgeIcon;
  final DateTime timestamp;

  // 📌 API से मिलने वाले एक्स्ट्रा फील्ड्स (फिलहाल कमेंट किए गए हैं, जरूरत पड़ने पर uncomment करें)
  /*
  final String? customerId;
  final int? durationInSeconds;
  final int? billedMinutes;
  final double? agentRatePerMin;
  final num? totalAgentEarned;
  final num? platformEarnings;
  final num? totalCostDeducted;
  final String? disconnectReason;
  final String? endedBy;
  final DateTime? startTime;
  final DateTime? endTime;
  */

  HistoryCallItemModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.callType,
    required this.callTypeIcon,
    required this.statusText,
    required this.statusColor,
    required this.statusBg,
    required this.timeDetail,
    required this.badgeIcon,
    required this.timestamp,

    /*
    this.customerId,
    this.durationInSeconds,
    this.billedMinutes,
    this.agentRatePerMin,
    this.totalAgentEarned,
    this.platformEarnings,
    this.totalCostDeducted,
    this.disconnectReason,
    this.endedBy,
    this.startTime,
    this.endTime,
    */
  });

  // API JSON से मॉडल बनाने के लिए Factory Constructor
  factory HistoryCallItemModel.fromJson(Map json) {
    final bool isVideo = json['callType']?.toString().toLowerCase() == 'video';
    final String disconnectReason =
        json['disconnectReason']?.toString() ?? 'unknown';

    // स्टेटस टेक्स्ट और रंग तय करना
    String statusText = 'Completed';
    Color statusColor = Colors.green;
    if (disconnectReason == 'user_cancelled') {
      statusText = 'Cancelled by User';
      statusColor = Colors.orangeAccent;
    }

    return HistoryCallItemModel(
      id:
          json['callId']?.toString() ??
          '', // 🟢 बिना किसी मॉडिफिकेशन के डायरेक्ट API callId
      name:
          json['customerName']?.toString() ??
          'Valued Customer', // यदि API में नाम न हो तो डिफ़ॉल्ट
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      callType: isVideo ? 'Video Call' : 'Audio Call',
      callTypeIcon: isVideo
          ? Icons.videocam_rounded
          : Icons.phone_in_talk_rounded,
      statusText: statusText,
      statusColor: statusColor,
      statusBg: statusColor.withOpacity(0.12),
      timeDetail: 'Duration: ${json['durationInSeconds'] ?? 0}s',
      badgeIcon: isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),

      /* --- एक्स्ट्रा फील्ड्स यहाँ मैप किए जा सकते हैं ---
      customerId: json['customerId'],
      durationInSeconds: json['durationInSeconds'],
      billedMinutes: json['billedMinutes'],
      agentRatePerMin: json['rateSnapshot']?['agentRatePerMin']?.toDouble(),
      totalAgentEarned: json['totalAgentEarned'],
      platformEarnings: json['platformEarnings'],
      totalCostDeducted: json['totalCostDeducted'],
      disconnectReason: json['disconnectReason'],
      endedBy: json['endedBy'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      */
    );
  }
}
