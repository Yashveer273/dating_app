import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/EarningsDashboardPage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/ledger_controller.dart.dart';

String formatCurrency(double amount) {
  if (amount >= 100000) {
    return '${(amount / 1000).toStringAsFixed(1)}K';
  } else if (amount >= 10000) {
    return '${(amount / 1000).toStringAsFixed(1)}K';
  }
  return amount.toStringAsFixed(2);
}

class EarningsSummaryCard extends StatelessWidget {
  EarningsSummaryCard({super.key});

  final LedgerController controller = Get.find();
  final ThemeController themeController = Get.find();

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? Colors.white : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Color cardBg = isDarkMode ? AppColors.darkCard : Colors.white;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // PRIMARY BALANCE HERO CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  if (!isDarkMode)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "AVAILABLE BALANCE",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.otpSuccessGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Ready for Payout",
                          style: TextStyle(
                            color: AppColors.otpSuccessGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${formatCurrency(controller.walletBalance.value)}',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Lifetime Earned",
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${formatCurrency(controller.totalEarned.value)}',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () => Get.to(() => EarningsDashboardPage()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'View History',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TALK TIME BREAKDOWN CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PENDING TALK-TIME METRICS',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Icon(
                        Icons.analytics_outlined,
                        color: secondaryText,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.03)
                                : Colors.grey.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.videocam_outlined,
                                    color: AppColors.primaryPink,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Video Calls',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.formatCallDuration(
                                  controller.videoCallDurationSeconds.value,
                                ),
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.03)
                                : Colors.grey.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    color: Colors.blueAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Audio Calls',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.formatCallDuration(
                                  controller.audioCallDurationSeconds.value,
                                ),
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
