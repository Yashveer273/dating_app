// ==========================================
// agent_main_controller.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentProfileModel.dart';

class AgentMainController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;
  RxDouble currentEarnings = 1240.50.obs;
  RxString totalCallTime = '42h 15m'.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
  }

  void changeTab(int index) {
    currentIndex.value = index;
    update();
  }

  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    update();
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

  void loadProfileData() {
    final Map sampleData = {
      '_id': '6a9937f06155a73eb9594662',
      'displayName': 'yash',
      'phoneNumber': '+918218326519',
      'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      'bio': 'jkjj jkjjop\nbnkjno',
      'category': 'General',
      'topics': ['career', 'relationships'],
      'languages': ['hindi', 'english'],
      'agentId': '4F115683',
    };

    // मॉडल के जरिए डेटा इनिशियलाइज किया जा रहा है
    AgentProfileModel.fromJson(sampleData);
    update();
  }
}
