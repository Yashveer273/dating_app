// ==========================================
// Earnings_summary_card.dart (Displays Organization Payout & Earnings Summary)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/ledger_controller.dart.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/withdrawal_pages.dart';

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

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Get.to(() => EarningsDashboardPage()),
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PENDING PAYOUT",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${formatCurrency(controller.pendingIncome)}',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tap to Withdraw',
                          style: TextStyle(color: secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      onTap: () => Get.to(() => EarningsDashboardPage()),
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "MIN WITHDRAWAL",
                            style: TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${formatCurrency(controller.minimumWithdrawalLimit)}',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Threshold limit',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor),
            ),
            child: InkWell(
              onTap: () => Get.to(() => EarningsDashboardPage()),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PENDING TALK TIME (FOR PAYOUT)',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Icon(
                        Icons.timer_rounded,
                        color: AppColors.primaryPink,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.videocam_rounded,
                                  color: AppColors.primaryPink,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Video (Pending)',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.pendingVideoTalkTime.value,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: borderColor,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Colors.blueAccent,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Audio (Pending)',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.pendingAudioTalkTime.value,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
