// views/shared_call_screen.dart

import 'package:flutter/material.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/SharedCallController.dart';

/// =====================================================================
/// UI SCREEN (100% Unchanged UI Layout + Mute & Emoji Animations Connected)
/// =====================================================================
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
  late final SharedCallController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = SharedCallController(
      roomId: widget.roomId,
      agentId: widget.agentId,
      isUserCaller: widget.isUserCaller,
      onStateUpdated: () {
        if (mounted) setState(() {});
      },
      onExit: () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      },
    );

    _controller.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _controller.forceCleanupOnExit(
        endedBy: widget.isUserCaller ? 'user_crash' : 'agent_crash',
      );
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildVideoPlaceholder({
    required bool isCameraOff,
    required bool isMuted,
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
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryPink.withOpacity(0.2),
                      border: Border.all(
                        color: AppColors.primaryPink,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.videocam_off,
                      size: 40,
                      color: AppColors.pinkLight,
                    ),
                  ),
                  if (isMuted)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_off,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                ],
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
            Stack(
              alignment: Alignment.topRight,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.darkCard,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.pinkLight,
                  ),
                ),
                if (isMuted)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
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
    final bool showLocalAsBig = _controller.isLocalFullScreen;

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            title: const Text(
              "Leave Call?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Kya aap wakai call chhodna chahte hain? Aisa karne se call disconnect ho jayegi.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Yes, Leave",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldLeave == true) {
          await _controller.hangupCall();
          return true;
        }
        return false;
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
                        isCameraOff: _controller.isCameraOff,
                        isMuted: _controller.isMuted,
                        label: "You",
                      )
                    : widget.callType == 'video'
                    ? _buildVideoPlaceholder(
                        isCameraOff: _controller.isRemoteCameraOff,
                        isMuted: _controller.isRemoteMuted,
                        label: "Match",
                      )
                    : _buildAudioCallUI(),
              ),

              // 2. FLOATING REACTION ICONS LAYER (Emoji Animation both sides)
              ..._controller.floatingReactions.map((reaction) {
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

              // 3. SMALL FLOATING SCREEN (PiP Box)
              if (widget.callType == 'video')
                Positioned(
                  top: 20,
                  right: 20,
                  width: 110,
                  height: 160,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _controller.isLocalFullScreen =
                            !_controller.isLocalFullScreen;
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
                              isCameraOff: _controller.isRemoteCameraOff,
                              isMuted: _controller.isRemoteMuted,
                              label: "Match",
                            )
                          : _buildVideoPlaceholder(
                              isCameraOff: _controller.isCameraOff,
                              isMuted: _controller.isMuted,
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
                        _controller.formatTime(_controller.secondsElapsed),
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

              // 5. QUICK REACTION ICON BAR (Emoji Controller Actions)
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
                            onTap: () => _controller.sendReaction(key),
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

              // 6. BOTTOM ACTION CONTROLS (Mute, Speaker, Camera, Hangup)
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
                      backgroundColor: _controller.isMuted
                          ? AppColors.primaryPink
                          : AppColors.darkCard,
                      onPressed: () => _controller.toggleMute(),
                      child: Icon(
                        _controller.isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Speaker Button
                    FloatingActionButton(
                      heroTag: 'speaker_btn_${widget.roomId}',
                      backgroundColor: _controller.isSpeakerOn
                          ? AppColors.primaryPink
                          : AppColors.darkCard,
                      onPressed: () => _controller.toggleSpeaker(),
                      child: Icon(
                        _controller.isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Camera Button
                    if (widget.callType == 'video') ...[
                      FloatingActionButton(
                        heroTag: 'cam_btn_${widget.roomId}',
                        backgroundColor: _controller.isCameraOff
                            ? AppColors.primaryPink
                            : AppColors.darkCard,
                        onPressed: () => _controller.toggleCamera(),
                        child: Icon(
                          _controller.isCameraOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                    ],

                    // Hangup Button
                    FloatingActionButton(
                      heroTag: 'hangup_btn_${widget.roomId}',
                      backgroundColor: AppColors.pinkDark,
                      onPressed: () => _controller.hangupCall(),
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
            Stack(
              alignment: Alignment.topRight,
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
                if (_controller.isRemoteMuted)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _controller.isRemoteMuted
                  ? "Match is Muted"
                  : "Dating Audio Call",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _controller.formatTime(_controller.secondsElapsed),
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
