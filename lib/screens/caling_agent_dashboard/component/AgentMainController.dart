// ==========================================
// agent_main_controller.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentJobOnOffModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentProfileModel.dart';

import 'agent_storage.dart';
import 'models/agent_model.dart';

class AgentMainController extends GetxController {
  RxInt currentIndex = 0.obs;
  RxBool isOnline = false.obs;
  RxBool isLoading = false.obs;
  RxDouble currentEarnings = 0.0.obs;
  RxString totalCallTime = ''.obs;
  final AgentModel? agent = AgentStorage.getAgent();
  final UserApiService _apiService = Get.put(UserApiService());

  @override
  void onInit() {
    super.onInit();
    loadJobOnOffStatus();
  }

  Future<void> loadJobOnOffStatus() async {
    isLoading.value = true;
    final status = await _apiService.getJobOnOffStatus();
    isLoading.value = false;

    if (status != null) {
      AgentJobOnOffModel.current = status;
      isOnline.value = status.isOnline;
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
    update();
  }

  Future<void> toggleOnlineStatus() async {
    if (isLoading.value) return;

    final nextStatus = !isOnline.value;
    isLoading.value = true;

    final status = await _apiService.changeJobOnOffStatus(nextStatus);
    isLoading.value = false;

    if (status == null) {
      Get.snackbar(
        'Unable to update status',
        'Please check your connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFC62828),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    AgentJobOnOffModel.current = status;
    isOnline.value = status.isOnline;
    update();
    Get.snackbar(
      status.isOnline ? 'You are Online' : 'You are Offline',
      status.isOnline
          ? 'Ready to receive calls from customers.'
          : 'You will no longer receive incoming calls.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: status.isOnline
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
      '_id': agent?.id,
      'displayName': agent?.displayName,
      'phoneNumber': agent?.phoneNumber,
      'avatar': agent?.avatar,
      'bio': agent?.bio,
      'category': agent?.category,
      'topics': agent?.topics,
      'languages': agent?.languages,
      'agentId': agent?.agentId,
      'location': agent?.location,
    };

    // मॉडल के जरिए डेटा इनिशियलाइज किया जा रहा है
    AgentProfileModel.fromJson(sampleData);
    update();
  }
}
