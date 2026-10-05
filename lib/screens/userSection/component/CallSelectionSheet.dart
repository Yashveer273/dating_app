// ==========================================
// CallSelectionSheet.dart (Updated without 90s timer & with Exit/Background Security)
// ==========================================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/Api/UserApiService.dart';
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
// Call Ringing Screen (Without 90s Timer & With Exit/Background Security)
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String? _roomId;
  StreamSubscription? _roomSubscription;
  DateTime? _requestStartedAt;
  bool _isCallInitiated = false;
  bool _isDisconnecting = false;
  bool _isCallAccepted = false;

  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startCallProcess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dotController.dispose();
    _stopListeners();
    if (!_isCallInitiated && _roomId != null && !_isDisconnecting) {
      _terminateCallAndCleanup(reason: "screen_disposed");
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Agar user app ko minimize karta hai ya background mein bhejta hai
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_isCallAccepted && !_isDisconnecting) {
        _isDisconnecting = true;
        _terminateCallAndCleanup(reason: "app_backgrounded");
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  void _startCallProcess() async {
    final walletApi = UserApiService()..onInit();
    final walletBalance = await walletApi.fetchCurrentWalletBalance();
    if (!mounted) return;
    if (walletBalance == null || walletBalance <= 0) {
      Get.snackbar(
        'Wallet unavailable',
        'Could not verify your wallet balance. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
      _cleanupAndExit('Wallet balance unavailable.');
      return;
    }

    final ratePerMinute = widget.callType == 'video'
        ? widget.agent.pricePerMinute * 1.10
        : widget.agent.pricePerMinute;
    final maxDurationSeconds = ratePerMinute > 0
        ? (walletBalance / ratePerMinute * 60).floor()
        : 0;
    if (maxDurationSeconds <= 0) {
      Get.snackbar(
        'Insufficient balance',
        'Your wallet balance is not enough for this call.',
        snackPosition: SnackPosition.TOP,
      );
      _cleanupAndExit('Insufficient wallet balance.');
      return;
    }

    _requestStartedAt = DateTime.now();
    final result = await CallApiService.requestCall(
      callType: widget.callType,
      customAgentId: widget.agent.agentId,
      customUserName: widget.agent.displayName,
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

      try {
        await FirebaseFirestore.instance.collection('rooms').doc(_roomId).set({
          'maxDurationSeconds': maxDurationSeconds,
          'walletBalanceAtCall': walletBalance,
          'currentWalletBalance': walletBalance,
          'ratePerMinute': ratePerMinute,
          'remainingDurationSeconds': maxDurationSeconds,
          'budgetUpdatedAt': FieldValue.serverTimestamp(),
          'userMuted': false,
          'agentMuted': false,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Could not save wallet call limit: $e');
        await _terminateCallAndCleanup(reason: 'wallet_limit_setup_failed');
        _cleanupAndExit('Could not set the call time limit.');
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
            if (data is! Map) return;

            final status = data!['status']?.toString();

            if (status == 'accepted') {
              if (_isCallAccepted || _isDisconnecting) return;
              _isCallAccepted = true;
              _stopListeners();
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SharedCallScreen(
                    roomId: _roomId!,
                    callType: widget.callType,
                    agentId: widget.agent.id,
                    isUserCaller: true,
                    maxDurationSeconds: maxDurationSeconds,
                    walletBalanceAtCall: walletBalance,
                    ratePerMinute: ratePerMinute,
                  ),
                ),
              );
            } else if ((status == 'ended' || status == 'rejected') &&
                !_isDisconnecting) {
              _cleanupAndExit("Call ended.");
            }
          });
    } else {
      print("Call request failed: ${result['message']}");
      Get.snackbar(
        'Error',
        result['message'],
        snackPosition: SnackPosition.TOP,
      );
      _cleanupAndExit(
        result['message']?.toString() ?? 'Failed to connect call',
      );
    }
  }

  // 🟢 Back button dabane par confirmation dialog aur security check
  Future<bool> _onWillPop() async {
    if (_isCallAccepted) return false;
    if (_isDisconnecting) return true;

    final shouldLeave = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text(
          "Cancel Call?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Kya aap call cancel karna chahte hain?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      setState(() {
        _isDisconnecting = true;
      });
      await _terminateCallAndCleanup(reason: "user_cancelled");
      return true;
    }
    return false;
  }

  // Red Cut Call button press hone par
  void _cancelCall() async {
    if (_isDisconnecting) return;

    final shouldLeave = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text(
          "Cancel Call?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Kya aap call cancel karna chahte hain?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    setState(() {
      _isDisconnecting = true;
    });

    _stopListeners();
    await _terminateCallAndCleanup(reason: "user_cancelled");
    _cleanupAndExit("Call cancelled.");
  }

  Future _terminateCallAndCleanup({required String reason}) async {
    if (_roomId != null && _roomId!.isNotEmpty) {
      final endTime = DateTime.now();
      final startTime = _requestStartedAt ?? endTime;
      final durationInSeconds = endTime
          .difference(startTime)
          .inSeconds
          .clamp(0, 1 << 31)
          .toInt();

      try {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(_roomId!)
            .update({
              'status': 'ended',
              'endedBy': reason,
              'disconnectedAt': FieldValue.serverTimestamp(),
              'startTimeMs': startTime.millisecondsSinceEpoch,
              'endTimeMs': endTime.millisecondsSinceEpoch,
              'durationInSeconds': durationInSeconds,
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
          startTime: startTime,
          endTime: endTime,
          durationInSeconds: durationInSeconds,
        );
      } catch (e) {
        debugPrint("Error ending call via API: $e");
      }
    }
  }

  void _stopListeners() {
    _roomSubscription?.cancel();
  }

  void _cleanupAndExit(String message) {
    _stopListeners();
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
      onWillPop: _onWillPop,
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
                // Triple dots animation with waiting status
                _buildTripleDots(),
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
