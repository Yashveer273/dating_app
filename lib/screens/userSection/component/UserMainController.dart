// ==========================================
// UserMainController.dart
// ==========================================
import 'package:get/get.dart';

class UserMainController extends GetxController {
  // Observable index for tracking the current bottom navigation tab
  // 0: Home, 1: Recharge, 2: History
  var currentIndex = 0.obs;

  // Method to handle tab switching
  void changeTab(int index) {
    currentIndex.value = index;
  }
}
