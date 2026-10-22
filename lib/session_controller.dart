// ==========================================
// SessionController.dart (Updated with Image Cache & Complete Storage Cleanup)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/AgentMainFile.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/agent_model.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';
import 'package:talk24loves/screens/userSection/UserMainFile.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class SessionController extends GetxController {
  final Rx<Widget> currentScreen = Rx<Widget>(const LoginScreen());

  final RxString role = UserStorage.role;

  void initializeFromStorage() {
    final UserModel? user = UserStorage.getUser();
    final AgentModel? agent = AgentStorage.getAgent();

    role.value = UserStorage.role.value;
    printInfo(info: "${role}.....");
    if (role.value == 'agent' && agent != null) {
      currentScreen.value = CallingAgentMainFile();
    } else if (role.value == 'user' && user != null) {
      currentScreen.value = UserMainFile();
    } else {
      role.value = '';
      currentScreen.value = const LoginScreen();
    }
  }

  void updateSession(String newRole) {
    role.value = newRole;
    UserStorage.role.value = newRole;

    if (newRole == 'agent') {
      currentScreen.value = CallingAgentMainFile();
    } else if (newRole == 'user') {
      currentScreen.value = UserMainFile();
    } else {
      role.value = '';
      UserStorage.role.value = '';
      currentScreen.value = const LoginScreen();
    }
  }

  Future<void> logout() async {
    // 1. Reset roles and state variables
    role.value = '';
    UserStorage.role.value = '';

    // 2. Completely wipe local storage (GetStorage) for both User and Agent
    await UserStorage.clearAllAppData();
    await AgentStorage.clearAllAppData();

    // 3. 🔥 Clear Flutter Image Cache & Live Images so old profile/avatar images disappear instantly
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // 4. Redirect to Login Screen
    currentScreen.value = const LoginScreen();
  }
}
