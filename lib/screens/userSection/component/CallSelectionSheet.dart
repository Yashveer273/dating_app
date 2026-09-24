// ==========================================
// CallSelectionSheet.dart (Updated with Dots & Waiting Text)
// ==========================================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/shared_call_screen.dart';

import 'package:talk24loves/screens/userSection/model/AgentModel.dart';

void showCallSelectionSheet({
  required BuildContext context,
  required AgentModel agent,
  required bool isDarkMode,
  required Color primaryText,
  required Color secondaryText,
}) {
  final double videoRate = agent.pricePerMinute * 1.10;
  final double audioRate = agent.pricePerMinute;

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
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
            Row(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: agent.isAudioAvailable
                            ? () {
                                Navigator.pop(context);
                                _showRingingScreen(
                                  context: context,
                                  agent: agent,
                                  callType: 'audio',
                                );
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 28, 12, 20),
                          decoration: BoxDecoration(
                            color: agent.isAudioAvailable
                                ? AppColors.primaryPink.withOpacity(0.06)
                                : Colors.grey.withOpacity(
                                    isDarkMode ? 0.05 : 0.1,
                                  ),
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
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      GestureDetector(
                        onTap: agent.isVideoAvailable
                            ? () {
                                Navigator.pop(context);
                                _showRingingScreen(
                                  context: context,
                                  agent: agent,
                                  callType: 'video',
                                );
                              }
                            : null,
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
                                  ),
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

void _showRingingScreen({
  required BuildContext context,
  required AgentModel agent,
  required String callType,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CallRingingScreen(agent: agent, callType: callType),
    ),
  );
}

// ==========================================
// Call Ringing Screen (With Triple Dots Animation & Waiting Text)
// ==========================================
class CallRingingScreen extends StatefulWidget {
  final AgentModel agent;
  final String callType;

  const CallRingingScreen({
    Key? key,
    required this.agent,
    required this.callType,
  }) : super(key: key);

  @override
  State<CallRingingScreen> createState() => _CallRingingScreenState();
}

class _CallRingingScreenState extends State<CallRingingScreen>
    with SingleTickerProviderStateMixin {
  String? _roomId;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  Timer? _countdownTimer;
  int _remainingSeconds = 90;
  bool _isCallInitiated = false;
  bool _isDisconnecting = false;

  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startCallProcess();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _stopTimers();
    if (!_isCallInitiated && _roomId != null && !_isDisconnecting) {
      _terminateCallAndCleanup(reason: "user_back_pressed");
    }
    super.dispose();
  }

  void _startCallProcess() async {
    _startLocalCountdown();

    final result = await CallApiService.requestCall(
      callType: widget.callType,
      customAgentId: widget.agent.id,
      customUserName: "John Doe",
      avatarUrl: widget.agent.avatarUrl,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _roomId = result['callId']?.toString() ?? result['roomId']?.toString();
      _isCallInitiated = true;

      if (_roomId == null || _roomId!.isEmpty) {
        _cleanupAndExit("Invalid room generated from server.");
        return;
      }

      _roomSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .doc(_roomId)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) {
              if (!_isDisconnecting) {
                _cleanupAndExit("Call ended by agent.");
              }
              return;
            }

            final data = snapshot.data();
            if (data is! Map<String, dynamic>) return;

            final status = data['status']?.toString();

            if (status == 'accepted') {
              _stopTimers();
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SharedCallScreen(
                    roomId: _roomId!,
                    callType: widget.callType,
                    agentId: widget.agent.id,
                    isUserCaller: true,
                  ),
                ),
              );
            } else if ((status == 'ended' ||
                    status == 'rejected' ||
                    status == 'timeout') &&
                !_isDisconnecting) {
              _cleanupAndExit("Call ended.");
            }
          });
    } else {
      _cleanupAndExit(
        result['message']?.toString() ?? 'Failed to connect call',
      );
    }
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _stopTimers();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() async {
    if (_isDisconnecting) return;
    setState(() {
      _isDisconnecting = true;
    });
    await _terminateCallAndCleanup(reason: "user_timeout");
    _cleanupAndExit("Call timed out. No response from agent.");
  }

  void _cancelCall() async {
    if (_isDisconnecting) return;

    setState(() {
      _isDisconnecting = true;
    });

    _stopTimers();
    await _terminateCallAndCleanup(reason: "user_cancelled");
    _cleanupAndExit("Call cancelled.");
  }

  Future<void> _terminateCallAndCleanup({required String reason}) async {
    if (_roomId != null && _roomId!.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_roomId!)
            .update({
              'status': 'ended',
              'endedBy': reason,
              'disconnectedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint("Error updating room on termination: $e");
      }

      try {
        await CallApiService.endCall(
          roomId: _roomId!,
          agentId: widget.agent.id,
          endedBy: reason,
          disconnectReason: reason,
        );
      } catch (e) {
        debugPrint("Error ending call via API: $e");
      }
    }
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _roomSubscription?.cancel();
  }

  void _cleanupAndExit(String message) {
    _stopTimers();
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // Triple Dots Animation Widget
  Widget _buildTripleDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        int dotCount = ((_dotController.value * 3).floor() % 3) + 1;
        String dots = '.' * dotCount;
        return Text(
          _isDisconnecting
              ? "Ending call & resetting$dots"
              : "Waiting for the response$dots",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isDisconnecting,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.agent.avatarUrl),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.agent.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Yahan par ab loader ki jagah "Waiting for the response..." aur triple dots animation aayega
                _buildTripleDots(),
                const SizedBox(height: 16),
                if (!_isDisconnecting)
                  Text(
                    "Timeout in: ${_remainingSeconds}s",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 80),
                Opacity(
                  opacity: _isDisconnecting ? 0.6 : 1.0,
                  child: FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _isDisconnecting ? null : _cancelCall,
                    child: _isDisconnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
