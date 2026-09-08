import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_footer.dart';
import 'package:talk24loves/screens/genderSelection.dart';

// --- Reusable Animated Custom Heart Widget ---
class AnimatedCustomHeart extends StatefulWidget {
  const AnimatedCustomHeart({
    super.key,
    this.size = 20.0,
    this.borderColor = const Color(0xFFE11D48),
    this.innerColor = const Color(0xFFFB7185),
    this.isBouncing = true,
    this.isPulsing = false,
  });

  final double size;
  final Color borderColor;
  final Color innerColor;
  final bool isBouncing;
  final bool isPulsing;

  @override
  State<AnimatedCustomHeart> createState() => _AnimatedCustomHeartState();
}

class _AnimatedCustomHeartState extends State<AnimatedCustomHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (widget.isBouncing) {
      _animation = Tween<double>(
        begin: 0.0,
        end: -5.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } else if (widget.isPulsing) {
      _animation = Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } else {
      _animation = AlwaysStoppedAnimation(0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget heartStack = Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.favorite_rounded,
          size: widget.size,
          color: widget.borderColor,
        ),
        Icon(
          Icons.favorite_rounded,
          size: widget.size * 0.75,
          color: widget.innerColor,
        ),
      ],
    );

    if (widget.isBouncing) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: heartStack,
      );
    } else if (widget.isPulsing) {
      return ScaleTransition(scale: _animation, child: heartStack);
    }

    return heartStack;
  }
}

// --- Professional Dotted Wave Loader Widget ---
class DottedWaveLoader extends StatefulWidget {
  const DottedWaveLoader({
    super.key,
    this.color = Colors.white,
    this.size = 6.0,
  });
  final Color color;
  final double size;

  @override
  State<DottedWaveLoader> createState() => _DottedWaveLoaderState();
}

class _DottedWaveLoaderState extends State<DottedWaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final double wave =
                (sin((_controller.value * 2 * 3.14159) - (index * 0.8)) + 1) /
                2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: widget.size + (wave * 6),
              width: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.4 + (wave * 0.6)),
                borderRadius: BorderRadius.circular(widget.size),
              ),
            );
          }),
        );
      },
    );
  }
}

// --- Professional Footer matching your specifications ---

// --- Professional 4-Digit OTP Screen with Manual Verify Trigger, Dotted Wave Loader & Custom Footer ---
class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.isDarkMode,
  });

  final String phoneNumber;
  final String countryCode;
  final bool isDarkMode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int otpLength = 4;
  final ThemeController themeController = Get.find<ThemeController>();
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _isSuccess = false;
  int _resendTimer = 30;
  Timer? _timer;

  final LinearGradient pinkGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFDB2777), Color(0xFFE11D48)],
  );

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
    startResendTimer();
  }

  void startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _resendTimer--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText => isDarkMode ? Colors.white : const Color(0xFF171717);
  Color get secondaryText =>
      isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF666666);

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    String fullOtp = _controllers.map((c) => c.text).join();
    if (fullOtp.length < otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 4-digit verification code'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenderSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: AppBackground(
          isDarkMode: isDarkMode,
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(.08)
                                : Colors.black.withOpacity(.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: primaryText,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const AnimatedCustomHeart(
                            size: 13,
                            isPulsing: true,
                            borderColor: Color(0xFFF43F5E),
                            innerColor: Color(0xFFFB7185),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Secure Auth',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF43F5E).withOpacity(0.1),
                                border: Border.all(
                                  color: const Color(
                                    0xFFF43F5E,
                                  ).withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const AnimatedCustomHeart(
                              size: 34,
                              isPulsing: true,
                              borderColor: Color(0xFFF43F5E),
                              innerColor: Color(0xFFFB7185),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Verification Code',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Please enter the 4-digit security code sent to\n${widget.countryCode} ${widget.phoneNumber}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Success Message Banner or 4 OTP Input Boxes
                        if (_isSuccess)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Verification Successful!',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(otpLength, (index) {
                              return Container(
                                width: 54,
                                height: 58,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (KeyEvent event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.backspace) {
                                      if (_controllers[index].text.isEmpty &&
                                          index > 0) {
                                        setState(() {
                                          _controllers[index - 1].text = '';
                                        });
                                        _focusNodes[index - 1].requestFocus();
                                      } else if (_controllers[index]
                                          .text
                                          .isNotEmpty) {
                                        setState(() {
                                          _controllers[index].text = '';
                                        });
                                      }
                                    }
                                  },
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? const Color(0xFF1a1a1a)
                                          : Colors.white,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? const Color(0xFF404040)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFF43F5E),
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _onOtpChanged(value, index),
                                  ),
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 28),

                        // Verify Button with Dotted Wave Loader Animation
                        if (!_isSuccess)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: pinkGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF43F5E,
                                    ).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const DottedWaveLoader(
                                        color: Colors.white,
                                        size: 6.0,
                                      )
                                    : const Text(
                                        'Verify & Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                        if (!_isSuccess)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Didn\'t receive code? ',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: _resendTimer == 0
                                    ? () {
                                        startResendTimer();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'OTP Resent Successfully!',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(
                                  _resendTimer > 0
                                      ? 'Resend in ${_resendTimer}s'
                                      : 'Resend Code',
                                  style: TextStyle(
                                    color: _resendTimer > 0
                                        ? secondaryText
                                        : const Color(0xFFF43F5E),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                // Professional Footer attached neatly at the bottom
                LoginFooter(isDarkMode: isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
