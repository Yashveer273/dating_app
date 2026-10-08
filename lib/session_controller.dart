import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/CallingAgentMainFile.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/agent_model.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';
import 'package:talk24loves/screens/userSection/UserMainFile.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class SessionController extends GetxController {
  final Rx<Widget> currentScreen = Rx<Widget>(const LoginScreen());

  void initializeFromStorage() {
    final UserModel? user = UserStorage.getUser();
    final AgentModel? agent = AgentStorage.getAgent();

    if (agent != null && agent.role == 'agent') {
      currentScreen.value = CallingAgentMainFile();
    } else if (user != null && user.role == 'user') {
      currentScreen.value = UserMainFile();
    } else {
      currentScreen.value = const LoginScreen();
    }
  }
}
