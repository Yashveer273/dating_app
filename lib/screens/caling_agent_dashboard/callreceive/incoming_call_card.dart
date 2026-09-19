import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/call_item_models.dart';

class IncomingCallCard extends StatelessWidget {
  final IncomingCallItemModel call;
  final bool isTopPriority;
  final bool isDarkMode;
  final Color cardBg;
  final AnimationController? gradientController;
  final AnimationController? blinkController;
  final VoidCallback onAccept;
  final VoidCallback onDelete;

  const IncomingCallCard({
    super.key,
    required this.call,
    required this.isTopPriority,
    required this.isDarkMode,
    required this.cardBg,
    this.gradientController,
    this.blinkController,
    required this.onAccept,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color callAccentColor = call.isVideoCall
        ? AppColors.primaryPink
        : const Color(0xFF00B4D8);

    Widget cardContent = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? (call.isVideoCall
                  ? const Color(0xFF120814)
                  : const Color(0xFF081018))
            : (call.isVideoCall
                  ? const Color(0xFFFFF0F5)
                  : const Color(0xFFF0F8FF)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: call.isBrandNew.value
              ? Colors.greenAccent
              : callAccentColor.withOpacity(0.4),
          width: call.isBrandNew.value ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: call.isBrandNew.value
                          ? Colors.greenAccent
                          : callAccentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      call.isBrandNew.value
                          ? Icons.fiber_new_rounded
                          : Icons.ring_volume_rounded,
                      color: call.isBrandNew.value
                          ? Colors.black
                          : Colors.white,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    call.isBrandNew.value
                        ? 'New Incoming Request'
                        : 'Incoming Call Ringing',
                    style: TextStyle(
                      color: call.isBrandNew.value
                          ? Colors.greenAccent
                          : callAccentColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: callAccentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      call.isVideoCall
                          ? Icons.videocam_rounded
                          : Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      call.isVideoCall ? 'VIDEO CALL' : 'AUDIO CALL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: call.isBrandNew.value
                        ? Colors.greenAccent
                        : callAccentColor,
                    width: 1.8,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(call.avatarUrl),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Plain language countdown text for normal people / non-technical agents
                    Obx(
                      () => Text(
                        call.timeDisplay.value,
                        style: TextStyle(
                          color: call.remainingSeconds.value <= 10
                              ? Colors.redAccent
                              : Colors.orange.shade800,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.12),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.call_end_rounded, size: 15),
                  label: const Text(
                    'Decline',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: callAccentColor,
                    foregroundColor: Colors.white,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 15),
                  label: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return cardContent;
  }
}
