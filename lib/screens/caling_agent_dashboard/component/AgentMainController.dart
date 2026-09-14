import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller for managing bottom navigation, online/offline status, and agent metrics
class AgentMainController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;
  RxDouble currentEarnings = 1240.50.obs;
  RxString totalCallTime = '42h 15m'.obs;

  void changeTab(int index) {
    currentIndex.value = index;
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
