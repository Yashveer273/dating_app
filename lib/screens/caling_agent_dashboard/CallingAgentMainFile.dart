import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/AgentHistoryPage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/AgentHomePage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/AgentMainController.dart';

class CallingAgentMainFile extends StatelessWidget {
  CallingAgentMainFile({super.key});

  final AgentMainController controller = Get.put(AgentMainController());

  final List _pages = [AgentHomePage(), AgentHomePage(), AgentHistoryPage()];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDarkMode
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return Scaffold(
      body: Obx(() => _pages[controller.currentIndex.value]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: borderColor.withOpacity(0.6), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    isActive: controller.currentIndex.value == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Ledger',
                    index: 1,
                    isActive: controller.currentIndex.value == 1,
                  ),
                  _buildNavItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    index: 2,
                    isActive: controller.currentIndex.value == 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryPink.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? AppColors.primaryPink
                  : AppColors.darkSecondaryText,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
