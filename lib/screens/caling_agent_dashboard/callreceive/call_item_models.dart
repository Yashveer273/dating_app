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
  final String id;
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
  });
}
