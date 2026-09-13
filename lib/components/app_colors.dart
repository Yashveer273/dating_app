import 'package:flutter/material.dart';

class AppColors {
  // Brand / Accent
  static const Color primaryPink = Color(0xFFF43F5E);
  static const Color pinkDark = Color(0xFFE11D48);
  static const Color pinkLight = Color(0xFFFB7185);
  static const Color pinkDeep = Color(0xFFDB2777);

  // Shared Gradients using AppColors constants
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, pinkDeep, pinkDark],
  );

  // Dark Theme Surfaces & Typography
  static const Color darkBgTop = Color(0xFF090909);
  static const Color darkBgMid = Color(0xFF171717);
  static const Color darkBgBottom = Color(0xFF210C13);
  static const Color darkCard = Color(0xFF1F1F1F);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Color(0xFFA3A3A3);

  // Light Theme Surfaces & Typography
  static const Color lightBgTop = Color(0xFFFFF5F7);
  static const Color lightBgMid = Colors.white;
  static const Color lightBgBottom = Color(0xFFE5E7EB);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFD1D5DB);
  static const Color lightPrimaryText = Color(0xFF171717);
  static const Color lightSecondaryText = Color(0xFF666666);

  // Screen-Specific Colors
  static const Color loginHintText = Color(0xFF737373);
  static const Color loginThemeIconDark = Color(0xFFFBBF24);
  static const Color loginThemeIconLight = Color(0xFF404040);
  static const Color otpSuccessGreen = Color(0xFF10B981);
  static const Color otpFieldBgDark = Color(0xFF1a1a1a);
  static const Color genderDarkUnselectedBorder = Color(0xFF333333);
  static const Color genderDarkRadioBorder = Color(0xFF555555);
  static const Color genderDisabledDarkBtn = Color(0xFF262626);
  static const Color genderDisabledDarkText = Color(0xFF737373);
  static const Color genderDisabledLightText = Color(0xFF9CA3AF);
}
