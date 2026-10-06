import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:talk24loves/components/app_colors.dart';

class ThemeController extends GetxController {
  static const String _darkModeKey = 'isDarkMode';
  final GetStorage _storage = GetStorage();
  final RxBool _isDarkMode = true.obs;

  bool get isDarkMode => _isDarkMode.value;

  Future<void> loadTheme() async {
    final savedTheme = _storage.read(_darkModeKey);
    if (savedTheme is! bool) return;

    _isDarkMode.value = savedTheme;
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    await _storage.write(_darkModeKey, _isDarkMode.value);
  }

  Color get primaryText => isDarkMode ? Colors.white : AppColors.darkBgMid;

  Color get secondaryText =>
      isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF666666);
}
