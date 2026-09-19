// ==========================================
// CallingAgentMainFile.dart
// ==========================================
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/AgentHistoryPage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/AgentHomePage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/LedgerPage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/AgentMainController.dart';

class CallingAgentMainFile extends StatelessWidget {
  CallingAgentMainFile({super.key});

  final AgentMainController controller = Get.put(AgentMainController());
  final ThemeController themeController = Get.find();

  final List _pages = [AgentHomePage(), LedgerPage(), AgentHistoryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Allows body content to flow nicely behind the floating glass bar
      body: Obx(() => _pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(() {
        final bool isDarkMode = themeController.isDarkMode;

        final Color inactiveColor = isDarkMode
            ? AppColors.darkSecondaryText
            : AppColors.darkBgBottom;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ), // High blur for glass effect
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // True glassmorphism uses lower opacity so background bleeds through
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.25)
                      : Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDarkMode ? 0.15 : 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                      isActive: controller.currentIndex.value == 0,
                      inactiveColor: inactiveColor,
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Ledger',
                      index: 1,
                      isActive: controller.currentIndex.value == 1,
                      inactiveColor: inactiveColor,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'History',
                      index: 2,
                      isActive: controller.currentIndex.value == 2,
                      inactiveColor: inactiveColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required Color inactiveColor,
  }) {
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryPink.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? AppColors.primaryPink : inactiveColor,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
