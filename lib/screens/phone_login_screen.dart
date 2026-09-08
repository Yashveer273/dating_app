import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/AnimatedCustomHeart.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_footer.dart';
import 'package:talk24loves/widgets/WaveDotLoader.dart';

import 'otp_screen.dart' hide AnimatedCustomHeart;

class Companion {
  final int id;
  final String name;
  final int age;
  final String topic;
  final String image;

  const Companion({
    required this.id,
    required this.name,
    required this.age,
    required this.topic,
    required this.image,
  });
}

// --- Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Map<String, int> _countryPhoneLength = {
    '+1': 10,
    '+44': 10,
    '+91': 10,
    '+61': 9,
  };

  static int getRequiredPhoneLengthForCode(String code) {
    return _countryPhoneLength[code] ?? 10;
  }

  static bool isValidPhoneNumberForCode(String value, String code) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    final requiredLength = getRequiredPhoneLengthForCode(code);
    return digitsOnly.length == requiredLength;
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final ThemeController themeController = Get.find<ThemeController>();
  String countryCode = '+1';
  bool loading = false;

  bool get isDarkMode => themeController.isDarkMode;

  final LinearGradient pinkGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFDB2777), Color(0xFFE11D48)],
  );

  final List<Companion> companions = const [
    Companion(
      id: 1,
      name: 'Sophia',
      age: 24,
      topic: 'Love & Emotional Healing',
      image:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    ),
    Companion(
      id: 2,
      name: 'Elena',
      age: 26,
      topic: 'Mature Conversations & Life',
      image:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    ),
    Companion(
      id: 3,
      name: 'Chloe',
      age: 23,
      topic: 'Romantic Talk & Connection',
      image:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Color get primaryText => isDarkMode ? Colors.white : const Color(0xFF171717);
  Color get secondaryText =>
      isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF666666);

  int getRequiredPhoneLength(String code) {
    return LoginScreen.getRequiredPhoneLengthForCode(code);
  }

  bool isValidPhoneNumber(String value, String code) {
    return LoginScreen.isValidPhoneNumberForCode(value, code);
  }

  void _updatePhoneInput(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    final requiredLength = getRequiredPhoneLength(countryCode);
    if (digitsOnly.length > requiredLength) {
      phoneController.value = TextEditingValue(
        text: digitsOnly.substring(0, requiredLength),
        selection: TextSelection.collapsed(offset: requiredLength),
      );
    }
    setState(() {});
  }

  Future<void> handlePhoneSubmit() async {
    FocusScope.of(context).unfocus();
    final cleanedPhone = phoneController.text.trim();
    final digitsOnly = cleanedPhone.replaceAll(RegExp(r'\D'), '');
    final requiredLength = getRequiredPhoneLength(countryCode);

    if (!isValidPhoneNumber(cleanedPhone, countryCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid $requiredLength-digit mobile number',
          ),
        ),
      );
      return;
    }

    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(
          phoneNumber: digitsOnly,
          countryCode: countryCode,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AppBackground(
          isDarkMode: isDarkMode,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 250,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 32,
                                top: 14,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: AnimatedCustomHeart(
                                    size: 22,
                                    isBouncing: true,
                                    borderColor: const Color(0xFFE11D48),
                                    innerColor: const Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 60,
                                child: Container(
                                  width: 140,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: const Color(0xFFF43F5E),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: Image.network(
                                      companions[0].image,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(
                                                0xFFE11D48,
                                              ).withOpacity(0.14),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFFF43F5E),
                                                size: 46,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 20,
                                child: Container(
                                  width: 140,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: const Color(0xFFF43F5E),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(100),
                                    child: Image.network(
                                      companions[2].image,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(
                                                0xFFE11D48,
                                              ).withOpacity(0.14),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFFF43F5E),
                                                size: 46,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 120,
                                child: Center(
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFEC4899),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        companions[1].image,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(
                                                  0xFFE11D48,
                                                ).withOpacity(0.14),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  color: Color(0xFFF43F5E),
                                                  size: 32,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Private Audio & Video Talk',
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect directly with empathetic companions for mature discussions, love, and emotional healing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 27),
                        _buildPhoneForm(),
                        const SizedBox(height: 25),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  gradient: pinkGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: 7),
              ShaderMask(
                shaderCallback: (bounds) => pinkGradient.createShader(bounds),
                child: const Text(
                  'AMOUR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              themeController.toggleTheme();
              setState(() {});
            },
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(.08)
                    : Colors.black.withOpacity(.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 17,
                color: isDarkMode
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF404040),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF171717) : Colors.white,
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF404040)
                      : const Color(0xFFD1D5DB),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  dropdownColor: isDarkMode
                      ? const Color(0xFF171717)
                      : Colors.white,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: secondaryText,
                  ),
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  items: const [
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                    DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                    DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => countryCode = value);
                    final digitsOnly = phoneController.text.replaceAll(
                      RegExp(r'\D'),
                      '',
                    );
                    final maxLength = getRequiredPhoneLength(value);
                    if (digitsOnly.length > maxLength) {
                      phoneController.value = TextEditingValue(
                        text: digitsOnly.substring(0, maxLength),
                        selection: TextSelection.collapsed(offset: maxLength),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF171717) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  onSubmitted: (_) {
                    if (!loading) {
                      handlePhoneSubmit();
                    }
                  },
                  onChanged: _updatePhoneInput,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      getRequiredPhoneLength(countryCode),
                    ),
                  ],
                  style: TextStyle(color: primaryText, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Mobile number',
                    hintStyle: const TextStyle(
                      color: Color(0xFF737373),
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(
                        color: isDarkMode
                            ? const Color(0xFF404040)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(
                        color: Color(0xFFF43F5E),
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        GestureDetector(
          onTap: loading ? null : handlePhoneSubmit,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity:
                loading ||
                    !isValidPhoneNumber(
                      phoneController.text.trim(),
                      countryCode,
                    )
                ? .5
                : 1,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: pinkGradient,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE11D48).withOpacity(.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? const WaveDotLoader()
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Send OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
