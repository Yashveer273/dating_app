import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CallModel {
  final String id;
  final String callerName;
  final String serviceType;
  final String duration;

  CallModel({
    required this.id,
    required this.callerName,
    required this.serviceType,
    required this.duration,
  });

  factory CallModel.fromJson(Map json) {
    return CallModel(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      callerName: json['callerName'] ?? 'Valued Customer',
      serviceType: json['serviceType'] ?? 'General Inquiry',
      duration: json['duration'] ?? '03:00',
    );
  }
}

class CallAgentController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;
  RxDouble currentEarnings = 1240.50.obs;
  RxString totalCallTime = '42h 15m'.obs;

  // Auto-scroll boolean condition and queue list control
  RxBool autoScrollOnNewCall = true.obs;
  RxList incomingQueue = [].obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }

  // Controller method to control the toggle switch effect
  void toggleAutoScroll(bool value) {
    autoScrollOnNewCall.value = value;
  }

  /// -----------------------------------------------------------------
  /// API / Real-time Data Receiver Function
  /// -----------------------------------------------------------------
  /// Call this function when your API fetch completes or a websocket
  /// stream yields new data. It processes the map and injects it into the queue.
  void handleApiCallReceived(Map apiResponseData) {
    try {
      final newCall = CallModel.fromJson(apiResponseData);

      // Check to prevent duplicate injection of the same call ID
      if (!incomingQueue.any((call) => call.id == newCall.id)) {
        // Insert at index 0 so it instantly pops to the top of your calling UI view
        incomingQueue.insert(0, newCall);

        // Optional UX Alert
        Get.snackbar(
          'New Call Alert',
          'Incoming request from ${newCall.callerName}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1F1F1F),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('Error processing incoming call data: $e');
    }
  }

  // Handles user actions (Accept/Decline) to clear from queue
  void resolveCall(String callId, bool isAccepted) {
    incomingQueue.removeWhere((call) => call.id == callId);
    if (isAccepted) {
      // Handle navigation to active calling screen
    }
  }

  void handleCallTimeout(String callId) {
    print(
      'Timer completed for call ID: $callId. Running API call for expired/missed call...',
    );

    // Remove timed-out call from queue automatically
    incomingQueue.removeWhere((call) => call.id == callId);

    // TODO: Put your actual backend API logic here for missed calls
  }

  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    Get.snackbar(
      isOnline.value ? 'You are Online' : 'You are Offline',
      isOnline.value
          ? 'Ready to receive calls from customers.'
          : 'You will no longer receive incoming calls.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isOnline.value
          ? const Color(0xFF10B981)
          : const Color(0xFF1F1F1F),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
    );
  }
}
