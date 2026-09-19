import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/AnimatedCustomHeart.dart';
import 'package:talk24loves/components/DottedWaveLoader.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/components/app_footer.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/CallingAgentMainFile.dart';
import 'package:talk24loves/screens/genderSelection.dart';
import 'package:talk24loves/screens/userSection/UserMainFile.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    required this.verificationId,
    required this.isDarkMode,
  });

  final String phoneNumber;
  final String countryCode;
  final String verificationId;
  final bool isDarkMode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int otpLength = 4;
  final ThemeController themeController = Get.find<ThemeController>();
  final UserApiService _authApiService = UserApiService();

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _isSuccess = false;
  int _resendTimer = 30;
  Timer? _timer;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
    startResendTimer();

    // Automatically focus the first OTP digit input field upon entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
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

  Color get primaryText =>
      isDarkMode ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  // यहाँ हमने कॉपी-पेस्ट और ऑटो-फिल का स्मार्ट लॉजिक हैंडल किया है
  void _onOtpChanged(String value, int index) {
    // यदि यूजर ने एक साथ पूरा OTP (या 2-4 डिजिट) पेस्ट कर दिया है
    if (value.length > 1) {
      // केवल डिजिट्स निकालकर साफ़ करें
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < otpLength; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        }
      }
      // सही बॉक्स पर फोकस सेट करें
      int nextIndex = digits.length < otpLength ? digits.length : otpLength - 1;
      _focusNodes[nextIndex].requestFocus();
    } else {
      // सामान्य सिंगल डिजिट टाइपिंग लॉजिक
      if (value.isNotEmpty && index < otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else if (value.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // चेक करें कि क्या पूरा OTP भर गया है
    String fullOtp = _controllers.map((c) => c.text).join();
    if (fullOtp.length == otpLength && !_isLoading) {
      _verifyOtp();
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

    final fullPhoneNumber = "${widget.countryCode}${widget.phoneNumber}";
    final response = await _authApiService.verifyAndRegister(
      phoneNumber: fullPhoneNumber,
      verificationId: _currentVerificationId,
      otp: fullOtp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response != null && response['success'] == true) {
      setState(() => _isSuccess = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final bool isNewUser = response['isNewUser'] ?? false;
      final bool isGenderSelected = response['isGenderSelected'] ?? false;
      final String role = response['role'] ?? '';

      if (isNewUser && !isGenderSelected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GenderSelectionScreen(phoneNumber: fullPhoneNumber),
          ),
        );
      } else {
        if (role == 'agent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CallingAgentMainFile()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserMainFile()),
          );
        }
      }
    } else {
      final errorMessage = response?['message'] ?? 'Invalid verification code';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
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
                            borderColor: AppColors.primaryPink,
                            innerColor: AppColors.pinkLight,
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
                                color: AppColors.primaryPink.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.primaryPink.withOpacity(
                                    0.25,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            const AnimatedCustomHeart(
                              size: 34,
                              isPulsing: true,
                              borderColor: AppColors.primaryPink,
                              innerColor: AppColors.pinkLight,
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
                          'Please enter the 4-digit security code sent to\n${widget.countryCode}${widget.phoneNumber}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_isSuccess)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.otpSuccessGreen.withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.otpSuccessGreen,
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.otpSuccessGreen,
                                  size: 24,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Verification Successful!',
                                  style: TextStyle(
                                    color: AppColors.otpSuccessGreen,
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
                                    maxLength:
                                        4, // 4 ताकि कॉपी-पेस्ट के वक्त टेक्स्टफील्ड लंबी स्ट्रिंग ले सके
                                    textInputAction: index == otpLength - 1
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    onSubmitted: (_) {
                                      if (index == otpLength - 1) {
                                        _verifyOtp();
                                      }
                                    },
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
                                          ? AppColors.otpFieldBgDark
                                          : AppColors.lightCard,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryPink,
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
                        if (!_isSuccess)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.pinkGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.3,
                                    ),
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
                                    ? () async {
                                        startResendTimer();
                                        final res = await _authApiService.sendOtp(
                                          "${widget.countryCode}${widget.phoneNumber}",
                                        );
                                        if (res != null &&
                                            res['verificationId'] != null) {
                                          setState(() {
                                            _currentVerificationId =
                                                res['verificationId'];
                                          });
                                        }
                                        if (!mounted) return;
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
                                        : AppColors.primaryPink,
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
                LoginFooter(isDarkMode: isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
