// views/shared_call_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/SharedCallController.dart';

class SharedCallScreen extends StatefulWidget {
  final String roomId;
  final String callType; // 'audio' or 'video'
  final String agentId;
  final bool isUserCaller;
  final int? maxDurationSeconds;
  final double? walletBalanceAtCall;
  final double? ratePerMinute;

  const SharedCallScreen({
    Key? key,
    required this.roomId,
    required this.callType,
    required this.agentId,
    required this.isUserCaller,
    this.maxDurationSeconds,
    this.walletBalanceAtCall,
    this.ratePerMinute,
  }) : super(key: key);

  @override
  State<SharedCallScreen> createState() => _SharedCallScreenState();
}

class _SharedCallScreenState extends State<SharedCallScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final SharedCallController _controller;
  late final AnimationController _endingPulseController;

  // State variables jo widget properties से इनिशियलाइज होंगी
  late final String _roomId;
  late final String _callType;
  late final String _agentId;
  late final bool _isUserCaller;

  // 🟢 Helper function जैसा आपने समझाया, initState के बाहर वैल्यू डिफाइन करने के लिए
  void _initValues() {
    _roomId = widget.roomId;
    _callType = widget.callType;
    _agentId = widget.agentId;
    _isUserCaller = widget.isUserCaller;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🟢 Function call karke values fetch ki gayi hain
    _initValues();

    _endingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 🟢 Explicitly typed Animation taaki type mismatch error na aaye

    _controller = SharedCallController(
      roomId: _roomId,
      agentId: _agentId,
      isUserCaller: _isUserCaller,
      maxCallDurationSeconds: widget.maxDurationSeconds,
      walletBalanceAtCall: widget.walletBalanceAtCall,
      callRatePerMinute: widget.ratePerMinute,
      onStateUpdated: () {
        if (!mounted) return;
        final remaining = _controller.remainingCallSeconds;
        if (remaining != null && remaining <= 60 && remaining > 0) {
          if (!_endingPulseController.isAnimating) {
            _endingPulseController.repeat(reverse: true);
          }
        } else if (_endingPulseController.isAnimating) {
          _endingPulseController.stop();
          _endingPulseController.reset();
        }
        setState(() {});
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
        endedBy: _isUserCaller ? 'user' : 'agent',
        disconnectReason: 'device_disconnected',
      );
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endingPulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // views/shared_call_screen.dart mein video placeholders ko update karein:

  Widget _buildVideoPlaceholder({
    required bool isCameraOff,
    required bool isMuted,
    required String label,
    required RTCVideoRenderer renderer,
    required bool isRemote,
  }) {
    // Agar camera off hai ya remote ki taraf se camera off kiya gaya hai
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

    // 🟢 Real-time WebRTC Video View Display
    return ClipRRect(
      borderRadius: BorderRadius.circular(isRemote ? 16 : 0),
      child: RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: !isRemote, // Local camera mirror enable karein
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showLocalAsBig = _controller.isLocalFullScreen;

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog(
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
              Positioned.fill(
                child: showLocalAsBig
                    ? _buildVideoPlaceholder(
                        isCameraOff: _controller.isCameraOff,
                        isMuted: _controller.isMuted,
                        label: "You",
                        renderer: _controller.localRenderer,
                        isRemote: false,
                      )
                    : _callType == 'video'
                    ? _buildVideoPlaceholder(
                        isCameraOff: _controller.isRemoteCameraOff,
                        isMuted: _controller.isRemoteMuted,
                        label: "Match",
                        renderer: _controller.remoteRenderer,
                        isRemote: true,
                      )
                    : _buildAudioCallUI(),
              ),
              ..._controller.floatingReactions.map((reaction) {
                return Positioned(
                  bottom: 120,
                  left: reaction.startX,
                  child: TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2500),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -value * 350),
                        child: Opacity(
                          opacity: (1 - value).clamp(0.0, 1.0).toDouble(),
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
              if (_callType == 'video')
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
                              renderer: _controller
                                  .remoteRenderer, // 🟢 Remote renderer yahan pass hoga
                              isRemote: true,
                            )
                          : _buildVideoPlaceholder(
                              isCameraOff: _controller.isCameraOff,
                              isMuted: _controller.isMuted,
                              label: "You",
                              renderer: _controller
                                  .localRenderer, // 🟢 Local renderer yahan pass hoga
                              isRemote: false,
                            ),
                    ),
                  ),
                ),
              // 🟢 Video call ke liye screen ke center/overlay par dikhane wala zero-starting timer widget
              if (_callType == 'video')
                Positioned(
                  top:
                      100, // Ise apne hisab se upar ya neeche adjust kar sakte hain
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        _controller.formatTime(_controller.secondsElapsed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              // 🟢 1. अगर सामने वाला (Remote) म्यूट है
              // 🟢 सिर्फ तब दिखेगा जब सामने वाला (Remote User) म्यूट होगा,
              // और यह मैसेज बिल्कुल सही पर्सन की स्क्रीन पर जाएगा (Opposite direction में)
              if (_controller.isRemoteMuted)
                Positioned(
                  top: _callType == 'video' ? 195 : 150,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE61E1E24),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mic_off_rounded,
                            size: 16,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            // 🟢 यहाँ ध्यान दें:
                            // अगर यूजर कॉलर है और रिमोट (एजेंट) म्यूट है, तो 'Agent is muted' दिखेगा।
                            // अगर एजेंट की तरफ से देखा जा रहा है और रिमोट (यूजर) म्यूट है, तो 'User is muted' दिखेगा।
                            _isUserCaller ? 'Agent is muted' : 'User is muted',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'mute_btn_$_roomId',
                          backgroundColor: _controller.isMuted
                              ? AppColors.primaryPink
                              : AppColors.darkCard,
                          onPressed: () => _controller.toggleMuted(),
                          child: Icon(
                            _controller.isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _controller.isMuted ? "Unmute" : "Mute",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'speaker_btn_$_roomId',
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
                        const SizedBox(height: 4),
                        Text(
                          _controller.isSpeakerOn ? "Speaker" : "Earpiece",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_callType == 'video') ...[
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            heroTag: 'cam_btn_$_roomId',
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
                          const SizedBox(height: 4),
                          Text(
                            _controller.isCameraOff ? "Cam Off" : "Camera",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'hangup_btn_$_roomId',
                          backgroundColor: AppColors.pinkDark,
                          onPressed: () => _controller.hangupCall(),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "End",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
            const SizedBox(height: 10),
            Text(
              _controller.isRemoteMuted
                  ? (_isUserCaller ? "Agent is muted" : "User is muted")
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
