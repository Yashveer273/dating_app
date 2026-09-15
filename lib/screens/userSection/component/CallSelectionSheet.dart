// ==========================================
// CallSelectionSheet.dart (With Dead UI Handling)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/userSection/model/AgentModel.dart';

void showCallSelectionSheet({
  required BuildContext context,
  required AgentModel agent,
  required bool isDarkMode,
  required Color primaryText,
  required Color secondaryText,
}) {
  final double videoRate =
      agent.pricePerMinute * 1.10; // Video rate is base + 10%
  final double audioRate = agent.pricePerMinute; // Audio rate is base rate

  showModalBottomSheet(
    context: context,
    backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Agent Info Preview
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(agent.avatarUrl),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect with ${agent.displayName}',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        agent.category,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            // Call Type Selection Options (With Dead UI for Unavailable Options)
            Row(
              children: [
                // 1. Audio Call Option
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: agent.isAudioAvailable
                            ? () {
                                Navigator.pop(context);
                                Get.snackbar(
                                  'Audio Call',
                                  'Connecting audio call with ${agent.displayName}...',
                                  backgroundColor: AppColors.primaryPink,
                                  colorText: Colors.white,
                                );
                              }
                            : null, // 👉 Dead UI: Unclickable if audio is not available
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 28, 12, 20),
                          decoration: BoxDecoration(
                            color: agent.isAudioAvailable
                                ? AppColors.primaryPink.withOpacity(0.06)
                                : Colors.grey.withOpacity(
                                    isDarkMode ? 0.05 : 0.1,
                                  ), // 👉 Dead UI Background
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: agent.isAudioAvailable
                                  ? AppColors.primaryPink.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                color: agent.isAudioAvailable
                                    ? AppColors.primaryPink
                                    : secondaryText.withOpacity(0.4),
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                agent.isAudioAvailable
                                    ? 'Audio Call'
                                    : 'Not Available',
                                style: TextStyle(
                                  color: agent.isAudioAvailable
                                      ? AppColors.primaryPink
                                      : secondaryText.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top Floating Price Badge
                      Positioned(
                        top: -11,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.darkBgMid
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: agent.isAudioAvailable
                                  ? AppColors.primaryPink.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            agent.isAudioAvailable
                                ? '₹${audioRate.toStringAsFixed(0)} / min'
                                : 'Offline',
                            style: TextStyle(
                              color: agent.isAudioAvailable
                                  ? AppColors.primaryPink
                                  : secondaryText.withOpacity(0.5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Video Call Option
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: agent.isVideoAvailable
                            ? () {
                                Navigator.pop(context);
                                Get.snackbar(
                                  'Video Call',
                                  'Connecting video call with ${agent.displayName}...',
                                  backgroundColor: AppColors.primaryPink,
                                  colorText: Colors.white,
                                );
                              }
                            : null, // 👉 Dead UI: Unclickable if video is not available
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 28, 12, 20),
                          decoration: BoxDecoration(
                            gradient: agent.isVideoAvailable
                                ? AppColors.pinkGradient
                                : null,
                            color: agent.isVideoAvailable
                                ? null
                                : Colors.grey.withOpacity(
                                    isDarkMode ? 0.05 : 0.1,
                                  ), // 👉 Dead UI Background
                            borderRadius: BorderRadius.circular(20),
                            border: agent.isVideoAvailable
                                ? null
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                            boxShadow: agent.isVideoAvailable
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryPink.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                color: agent.isVideoAvailable
                                    ? Colors.white
                                    : secondaryText.withOpacity(0.4),
                                size: 28,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                agent.isVideoAvailable
                                    ? 'Video Call'
                                    : 'Not Available',
                                style: TextStyle(
                                  color: agent.isVideoAvailable
                                      ? Colors.white
                                      : secondaryText.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top Floating Price Badge
                      Positioned(
                        top: -11,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.darkBgMid
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: agent.isVideoAvailable
                                  ? AppColors.primaryPink.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            agent.isVideoAvailable
                                ? '₹${videoRate.toStringAsFixed(0)} / min'
                                : 'Offline',
                            style: TextStyle(
                              color: agent.isVideoAvailable
                                  ? AppColors.primaryPink
                                  : secondaryText.withOpacity(0.5),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
