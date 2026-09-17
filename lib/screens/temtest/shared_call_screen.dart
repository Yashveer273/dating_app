// views/shared_call_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:talk24loves/components/app_colors.dart';
import './call_api_service.dart';

class FloatingReactionIcon {
  final int id;
  final IconData icon;
  final Color color;
  final double startX;
  FloatingReactionIcon({
    required this.id,
    required this.icon,
    required this.color,
    required this.startX,
  });
}

class SharedCallScreen extends StatefulWidget {
  final String roomId;
  final String callType; // 'audio' or 'video'
  final String agentId;
  final bool isUserCaller;

  const SharedCallScreen({
    Key? key,
    required this.roomId,
    required this.callType,
    required this.agentId,
    required this.isUserCaller,
  }) : super(key: key);

  @override
  State<SharedCallScreen> createState() => _SharedCallScreenState();
}

class _SharedCallScreenState extends State<SharedCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isMuted = false;
  bool _isRemoteMuted = false;
  bool _isCameraOff = false;
  bool _isRemoteCameraOff = false;
  bool _isLocalFullScreen = false;
  bool _hasPermissions = false;
  bool _isLoadingPermissions = true;

  int _secondsElapsed = 0;
  Timer? _callTimer;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  late final DateTime _callStartTime;
  bool _isCallEnded = false;

  // Floating Icon Reactions List
  final List<FloatingReactionIcon> _floatingReactions = [];
  int _reactionCounter = 0;
  Timestamp? _lastProcessedReactionTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callStartTime = DateTime.now();
    _requestCallPermissions();
  }

  Future<void> _requestCallPermissions() async {
    List<Permission> permissions = [Permission.microphone];
    if (widget.callType == 'video') {
      permissions.add(Permission.camera);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    bool cameraGranted = widget.callType == 'video'
        ? (statuses[Permission.camera]?.isGranted ?? false)
        : true;

    if (micGranted && cameraGranted) {
      if (mounted) {
        setState(() {
          _hasPermissions = true;
          _isLoadingPermissions = false;
        });
        _startCallTimer();
        _listenToRoomUpdates();
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermissions = false;
          _isLoadingPermissions = false;
        });
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text(
          "Permissions Required",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Microphone ${widget.callType == 'video' ? 'and Camera' : ''} permission is required for this dating call.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text(
              "Open Settings",
              style: TextStyle(color: AppColors.pinkLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _hangupCall();
            },
            child: const Text(
              "Cancel Call",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      _forceCleanupOnExit();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _listenToRoomUpdates() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            _safeExit();
            return;
          }

          final data = snapshot.data() as Map<String, dynamic>?;
          if (data == null) return;

          final status = data['status'];
          if (status == 'ended' || status == 'rejected') {
            _safeExit();
            return;
          }

          // Listen to remote reaction icons
          final reactionData = data['latestReaction'] as Map<String, dynamic>?;
          if (reactionData != null) {
            final sender = reactionData['sender'] as String?;
            final iconKey = reactionData['iconKey'] as String?;
            final timestamp = reactionData['timestamp'] as Timestamp?;

            if (sender != (widget.isUserCaller ? 'user' : 'agent') &&
                iconKey != null &&
                timestamp != null) {
              if (_lastProcessedReactionTime == null ||
                  timestamp.compareTo(_lastProcessedReactionTime!) > 0) {
                _lastProcessedReactionTime = timestamp;
                _triggerFloatingReactionIcon(iconKey);
              }
            }
          }

          setState(() {
            _isRemoteMuted = widget.isUserCaller
                ? (data['agentMuted'] ?? false)
                : (data['userMuted'] ?? false);

            _isRemoteCameraOff = widget.isUserCaller
                ? (data['agentCameraOff'] ?? false)
                : (data['userCameraOff'] ?? false);
          });
        });
  }

  // Map string key to IconData and Color
  Map<String, dynamic> _getIconDetails(String key) {
    switch (key) {
      case 'heart':
        return {'icon': Icons.favorite, 'color': Colors.redAccent};
      case 'fire':
        return {
          'icon': Icons.local_fire_department,
          'color': Colors.orangeAccent,
        };
      case 'star':
        return {'icon': Icons.star, 'color': Colors.amber};
      case 'thumb':
        return {'icon': Icons.thumb_up, 'color': Colors.pinkAccent};
      case 'sparkle':
        return {'icon': Icons.auto_awesome, 'color': Colors.purpleAccent};
      default:
        return {'icon': Icons.favorite, 'color': Colors.redAccent};
    }
  }

  void _triggerFloatingReactionIcon(String iconKey) {
    final random = math.Random();
    final double startX = random.nextDouble() * 250 + 50;
    final reactionId = _reactionCounter++;
    final details = _getIconDetails(iconKey);

    setState(() {
      _floatingReactions.add(
        FloatingReactionIcon(
          id: reactionId,
          icon: details['icon'] as IconData,
          color: details['color'] as Color,
          startX: startX,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _floatingReactions.removeWhere((r) => r.id == reactionId);
        });
      }
    });
  }

  Future<void> _sendReaction(String iconKey) async {
    _triggerFloatingReactionIcon(iconKey);
    try {
      final senderRole = widget.isUserCaller ? 'user' : 'agent';
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'latestReaction': {
              'iconKey': iconKey,
              'sender': senderRole,
              'timestamp': FieldValue.serverTimestamp(),
            },
          });
    } catch (e) {
      debugPrint("Error sending reaction: $e");
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });

    try {
      final updateField = widget.isUserCaller ? 'userMuted' : 'agentMuted';
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({updateField: _isMuted});
    } catch (e) {
      debugPrint("Error updating mute state: $e");
    }
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });

    try {
      final updateField = widget.isUserCaller
          ? 'userCameraOff'
          : 'agentCameraOff';
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({updateField: _isCameraOff});
    } catch (e) {
      debugPrint("Error updating camera state: $e");
    }
  }

  Future<void> _hangupCall() async {
    await _saveCallSessionAndReset();
    _safeExit();
  }

  Future<void> _forceCleanupOnExit() async {
    if (_isCallEnded) return;
    _isCallEnded = true;

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .set({
            'status': 'ended',
            'endedBy': widget.isUserCaller ? 'user' : 'agent',
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('agents')
          .doc(widget.agentId)
          .set({
            'isBusy': false,
            'currentRoomId': null,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error in force cleanup: $e");
    }
  }

  Future<void> _saveCallSessionAndReset() async {
    if (_isCallEnded) return;
    _isCallEnded = true;

    try {
      final DateTime callEndTime = DateTime.now();
      const double ratePerMinute = 5.0;
      const double initialMinutes = 20.0;

      double durationMinutes = _secondsElapsed / 60.0;
      double totalCost = durationMinutes * ratePerMinute;
      double remainingMinutes = (initialMinutes - durationMinutes).clamp(
        0.0,
        initialMinutes,
      );

      await FirebaseFirestore.instance
          .collection('call_sessions')
          .doc(widget.roomId)
          .set({
            'sessionId': widget.roomId,
            'agentId': widget.agentId,
            'userId': CallApiService.staticUserId,
            'callType': widget.callType,
            'ratePerMinute': ratePerMinute,
            'userInitialMinutes': initialMinutes,
            'remainingUserMinutes': remainingMinutes,
            'durationMinutes': durationMinutes,
            'durationSeconds': _secondsElapsed,
            'totalCost': totalCost,
            'callStartTime': _callStartTime.toIso8601String(),
            'callEndTime': callEndTime.toIso8601String(),
            'status': 'completed',
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
            'status': 'ended',
            'endedBy': widget.isUserCaller ? 'user' : 'agent',
            'durationSeconds': _secondsElapsed,
          });

      await FirebaseFirestore.instance
          .collection('agents')
          .doc(widget.agentId)
          .set({
            'isBusy': false,
            'currentRoomId': null,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  void _safeExit() {
    _callTimer?.cancel();
    _roomSubscription?.cancel();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _roomSubscription?.cancel();
    if (!_isCallEnded) {
      _forceCleanupOnExit();
    }
    super.dispose();
  }

  Widget _buildVideoPlaceholder({
    required bool isCameraOff,
    required String label,
  }) {
    if (isCameraOff) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkBgTop, AppColors.darkBgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPink.withOpacity(0.2),
                  border: Border.all(color: AppColors.primaryPink, width: 2),
                ),
                child: const Icon(
                  Icons.videocam_off,
                  size: 40,
                  color: AppColors.pinkLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "$label Camera Off",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.darkBgMid,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.darkCard,
              child: Icon(Icons.person, size: 50, color: AppColors.pinkLight),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPermissions) {
      return const Scaffold(
        backgroundColor: AppColors.darkBgTop,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: AppColors.darkBgTop,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Permissions are missing.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                ),
                onPressed: _requestCallPermissions,
                child: const Text(
                  "Grant Permissions",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool showLocalAsBig = _isLocalFullScreen;

    return WillPopScope(
      onWillPop: () async {
        await _saveCallSessionAndReset();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgTop,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. BIG SCREEN BACKGROUND
              Positioned.fill(
                child: showLocalAsBig
                    ? _buildVideoPlaceholder(
                        isCameraOff: _isCameraOff,
                        label: "You",
                      )
                    : widget.callType == 'video'
                    ? _buildVideoPlaceholder(
                        isCameraOff: _isRemoteCameraOff,
                        label: "Match",
                      )
                    : _buildAudioCallUI(),
              ),

              // 2. FLOATING REACTION ICONS LAYER
              ..._floatingReactions.map((reaction) {
                return Positioned(
                  bottom: 120,
                  left: reaction.startX,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 2500),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -value * 350),
                        child: Opacity(
                          opacity: (1 - value).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.8 + (value * 0.6),
                            child: Icon(
                              reaction.icon,
                              size: 36,
                              color: reaction.color,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              // 3. SMALL FLOATING SCREEN (PiP Box - WhatsApp Style)
              if (widget.callType == 'video')
                Positioned(
                  top: 20,
                  right: 20,
                  width: 110,
                  height: 160,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLocalFullScreen = !_isLocalFullScreen;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryPink,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: showLocalAsBig
                          ? _buildVideoPlaceholder(
                              isCameraOff: _isRemoteCameraOff,
                              label: "Match",
                            )
                          : _buildVideoPlaceholder(
                              isCameraOff: _isCameraOff,
                              label: "You",
                            ),
                    ),
                  ),
                ),

              // 4. TOP INFO & TIMER
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.pinkLight.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: AppColors.primaryPink,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_secondsElapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. QUICK REACTION ICON BAR (Dating App Feature with Icons)
              Positioned(
                bottom: 110,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      [
                        {
                          'key': 'heart',
                          'icon': Icons.favorite,
                          'color': Colors.redAccent,
                        },
                        {
                          'key': 'fire',
                          'icon': Icons.local_fire_department,
                          'color': Colors.orangeAccent,
                        },
                        {
                          'key': 'star',
                          'icon': Icons.star,
                          'color': Colors.amber,
                        },
                        {
                          'key': 'thumb',
                          'icon': Icons.thumb_up,
                          'color': Colors.pinkAccent,
                        },
                        {
                          'key': 'sparkle',
                          'icon': Icons.auto_awesome,
                          'color': Colors.purpleAccent,
                        },
                      ].map((item) {
                        final key = item['key'] as String;
                        final icon = item['icon'] as IconData;
                        final color = item['color'] as Color;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () => _sendReaction(key),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard.withOpacity(0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryPink.withOpacity(0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              // 6. BOTTOM ACTION CONTROLS
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mute Button
                    FloatingActionButton(
                      heroTag: 'mute_btn_${widget.roomId}',
                      backgroundColor: _isMuted
                          ? AppColors.primaryPink
                          : AppColors.darkCard,
                      onPressed: _toggleMute,
                      child: Icon(
                        _isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Camera Toggle Button
                    if (widget.callType == 'video') ...[
                      FloatingActionButton(
                        heroTag: 'cam_btn_${widget.roomId}',
                        backgroundColor: _isCameraOff
                            ? AppColors.primaryPink
                            : AppColors.darkCard,
                        onPressed: _toggleCamera,
                        child: Icon(
                          _isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],

                    // Hangup Button
                    FloatingActionButton(
                      heroTag: 'hangup_btn_${widget.roomId}',
                      backgroundColor: AppColors.pinkDark,
                      onPressed: _hangupCall,
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioCallUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBgTop, AppColors.darkBgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.pinkGradient,
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.darkCard,
                child: Icon(
                  Icons.favorite,
                  size: 60,
                  color: AppColors.primaryPink,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Dating Audio Call",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatTime(_secondsElapsed),
              style: const TextStyle(
                color: AppColors.pinkLight,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
