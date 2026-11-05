// ==========================================
// CallSelectionSheet.dart (Integrated Rating UI & Call Selection)
// ==========================================
import 'dart:async';
import 'package:firebase_database/firebase_database.dart'; // ⚡ RTDB Import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/shared_call_screen.dart';
import 'package:talk24loves/screens/userSection/model/AgentListModel.dart';

/// Calls Bottom Sheet opening method
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
    isScrollControlled: true,
    backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      return _CallSelectionSheetContent(
        agent: agent,
        isDarkMode: isDarkMode,
        primaryText: primaryText,
        secondaryText: secondaryText,
        audioRate: audioRate,
        videoRate: videoRate,
      );
    },
  );
}

class _CallSelectionSheetContent extends StatefulWidget {
  final AgentModel agent;
  final bool isDarkMode;
  final Color primaryText;
  final Color secondaryText;
  final double audioRate;
  final double videoRate;

  const _CallSelectionSheetContent({
    Key? key,
    required this.agent,
    required this.isDarkMode,
    required this.primaryText,
    required this.secondaryText,
    required this.audioRate,
    required this.videoRate,
  }) : super(key: key);

  @override
  State<_CallSelectionSheetContent> createState() =>
      _CallSelectionSheetContentState();
}

class _CallSelectionSheetContentState
    extends State<_CallSelectionSheetContent> {
  int _selectedRating = 0;
  bool _isCopied = false;

  void _copyHandle(String rawId) {
    final String formattedId = rawId.startsWith('@') ? rawId : '@$rawId';
    Clipboard.setData(ClipboardData(text: formattedId));

    setState(() {
      _isCopied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $formattedId to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryPink.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final isDarkMode = widget.isDarkMode;
    final secondaryText = widget.secondaryText;
    final audioRate = widget.audioRate;
    final videoRate = widget.videoRate;

    // Dynamic Agent Handle/ID Fallback
    final String agentIdText = agent.agentId.isNotEmpty
        ? agent.agentId
        : agent.displayName.replaceAll(' ', '_').toLowerCase();
    final String formattedId = agentIdText.startsWith('@')
        ? agentIdText
        : '@$agentIdText';

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          gradient: isDarkMode
              ? const RadialGradient(
                  center: Alignment(0.0, -0.4),
                  radius: 1.25,
                  colors: [
                    Color(0xFF3A1825), // Soft deep pink tint
                    Color(0xFF1E1016),
                    Color(0xFF120C0F),
                  ],
                  stops: [0.0, 0.5, 1.0],
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Drag Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title: "Give the rating"
            const Text(
              'Give the rating',
              style: TextStyle(
                fontFamily: 'Serif',
                fontStyle: FontStyle.italic,
                fontSize: 22,
                color: Color(0xFFFFD1DC),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Twisted / Tilted Perspective Profile Image Frame
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // perspective tilt
                ..rotateZ(-0.07) // ~ -4 deg rotation
                ..rotateY(0.10) // ~ 6 deg perspective
                ..rotateX(0.03),
              child: Container(
                width: 150,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF80AB).withOpacity(0.4),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    agent.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2E1520),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Color(0xFFFF4081),
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Agent Name
            Text(
              agent.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.primaryText,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Dynamic Handle (@ID) with Pink Copy Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF80AB).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      formattedId,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD1DC),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyHandle(formattedId),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _isCopied ? Icons.check_circle : Icons.copy_rounded,
                        size: 15,
                        color: _isCopied
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFFFF4081),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tap to rate Label
            const Text(
              'TAP TO RATE (1 - 5)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFFFF80AB),
              ),
            ),
            const SizedBox(height: 4),

            // Horizontal 1 to 5 Star Rating Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _selectedRating;
                return IconButton(
                  splashRadius: 22,
                  iconSize: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: isSelected
                        ? const Color(0xFFFF4081)
                        : secondaryText.withOpacity(0.3),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = starNumber;
                    });
                  },
                );
              }),
            ),

            // Rating Feedback text
            AnimatedOpacity(
              opacity: _selectedRating > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  _selectedRating > 0
                      ? 'Rated $_selectedRating star${_selectedRating > 1 ? 's' : ''}!'
                      : '',
                  style: const TextStyle(
                    color: Color(0xFFFF80AB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider Line before Audio/Video Call Buttons
            const Divider(height: 1),
            const SizedBox(height: 24),

            // ==========================================
            // Audio Call & Video Call Buttons Section
            // ==========================================
            Row(
              children: [
                // Audio Call Button
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

                // Video Call Button
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
      ),
    );
  }
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
// Call Ringing Screen (RTDB & Wallet Safe Call System)
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
  StreamSubscription<DatabaseEvent>? _roomSubscription;
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
        await FirebaseDatabase.instance.ref('rooms/$_roomId').update({
          'maxDurationSeconds': maxDurationSeconds,
          'walletBalanceAtCall': walletBalance,
          'currentWalletBalance': walletBalance,
          'ratePerMinute': ratePerMinute,
          'remainingDurationSeconds': maxDurationSeconds,
          'budgetUpdatedAt': ServerValue.timestamp,
          'userMuted': false,
          'agentMuted': false,
        });
      } catch (e) {
        debugPrint('Could not save wallet call limit in RTDB: $e');
        await _terminateCallAndCleanup(reason: 'wallet_limit_setup_failed');
        _cleanupAndExit('Could not set the call time limit.');
        return;
      }

      _roomSubscription = FirebaseDatabase.instance
          .ref('rooms/$_roomId')
          .onValue
          .listen((event) {
            final data = event.snapshot.value as Map?;
            if (data == null) {
              if (!_isDisconnecting) {
                _cleanupAndExit("Call ended by agent.");
              }
              return;
            }

            final status = data['status']?.toString();

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
      debugPrint("Call request failed: $result");
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
        await FirebaseDatabase.instance.ref('rooms/$_roomId').update({
          'status': 'ended',
          'endedBy': reason,
          'disconnectedAt': ServerValue.timestamp,
          'startTimeMs': startTime.millisecondsSinceEpoch,
          'endTimeMs': endTime.millisecondsSinceEpoch,
          'durationInSeconds': durationInSeconds,
        });
      } catch (e) {
        debugPrint("Error updating room on termination in RTDB: $e");
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
