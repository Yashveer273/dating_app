import 'package:flutter/material.dart';
import 'package:talk24loves/components/AnimatedCustomHeart.dart';
import 'package:talk24loves/components/app_colors.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFE5E7EB);
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFA3A3A3)
        : const Color(0xFF666666);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top border line comes first
          Divider(
            color: borderColor.withOpacity(0.6),
            thickness: 0.8,
            height: 16,
          ),
          const SizedBox(height: 2),

          // 2. Terms and Privacy row with white underlined text and gray dot separator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to Terms of Service
                },
                child: const Text(
                  'Terms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to Privacy Policy
                },
                child: const Text(
                  'Privacy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Below text: copyright and animated custom hearts
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedCustomHeart(
                size: 13,
                isPulsing: true,
                borderColor: AppColors.primaryPink,
                innerColor: AppColors.pinkLight,
              ),
              const SizedBox(width: 6),
              Text(
                '© 2026 Amour. Secure Audio & Video Calls.',
                style: TextStyle(
                  color: secondaryTextColor.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const AnimatedCustomHeart(
                size: 13,
                isBouncing: true,
                borderColor: AppColors.primaryPink,
                innerColor: AppColors.pinkLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
