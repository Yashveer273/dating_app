import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/components/app_colors.dart';

class ThemeController extends GetxController {
  final RxBool _isDarkMode = true.obs;

  bool get isDarkMode => _isDarkMode.value;

  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
  }

  Color get primaryText => isDarkMode ? Colors.white : AppColors.darkBgMid;

  Color get secondaryText =>
      isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF666666);
}
