import 'package:flutter/material.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/call_item_models.dart';
// Adjust import path as needed

class HistoryCallCard extends StatelessWidget {
  final HistoryCallItem historyItem;
  final Color cardBg;
  final Color borderColor;
  final Color primaryText;
  final Color secondaryText;

  const HistoryCallCard({
    super.key,
    required this.historyItem,
    required this.cardBg,
    required this.borderColor,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(historyItem.avatarUrl),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: historyItem.statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 1.5),
                  ),
                  child: Icon(
                    historyItem.badgeIcon,
                    color: Colors.black,
                    size: 7.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        historyItem.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: historyItem.statusBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        historyItem.statusText,
                        style: TextStyle(
                          color: historyItem.statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      historyItem.callTypeIcon,
                      color: historyItem.callType == 'Video Call'
                          ? AppColors.primaryPink
                          : const Color(0xFF00B4D8),
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      historyItem.callType,
                      style: TextStyle(
                        color: primaryText.withOpacity(0.8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  historyItem.timeDetail,
                  style: TextStyle(color: secondaryText, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
