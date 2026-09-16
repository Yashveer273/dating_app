import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/AnimatedCustomHeart.dart';
import 'package:talk24loves/components/DottedWaveLoader.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';

import 'package:talk24loves/screens/caling_agent_dashboard/CallingAgentMainFile.dart';

import 'package:talk24loves/screens/userSection/UserMainFile.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserApiService _authApiService = UserApiService();

  String? selectedGender; // 'male' or 'female'
  bool _isLoading = false;

  // Placeholder avatar image URLs
  static const String maleAvatarUrl =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';
  static const String femaleAvatarUrl =
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80';

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? AppColors.darkPrimaryText : AppColors.darkBgMid;

  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  Future<void> _onProceed() async {
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call backend select-gender API
    final response = await _authApiService.selectGender(
      phoneNumber: widget.phoneNumber,
      gender: selectedGender!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response != null && response['success'] == true) {
      final String role =
          response['role'] ?? (selectedGender == 'female' ? 'agent' : 'user');

      // Navigate based on assigned role or selected gender
      if (role == 'agent' || selectedGender == 'female') {
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
    } else {
      final errorMessage =
          response?['message'] ?? 'Gender selection failed. Please try again.';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'your',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gender',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const AnimatedCustomHeart(
                        size: 28,
                        isPulsing: true,
                        borderColor: AppColors.primaryPink,
                        innerColor: AppColors.pinkLight,
                      ),
                    ],
                  ),
                ),

                // Center Column Selection Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // 1. Male Option Box
                        GestureDetector(
                          onTap: () => setState(() => selectedGender = 'male'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedGender == 'male'
                                    ? AppColors.primaryPink
                                    : (isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                width: selectedGender == 'male' ? 2 : 1,
                              ),
                              boxShadow: [
                                if (selectedGender == 'male')
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.15,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedGender == 'male'
                                          ? AppColors.primaryPink
                                          : AppColors.primaryPink.withOpacity(
                                              0.3,
                                            ),
                                      width: 2,
                                    ),
                                    image: const DecorationImage(
                                      image: NetworkImage(maleAvatarUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Male',
                                        style: TextStyle(
                                          color: primaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Standard Profile Setup',
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectedGender == 'male'
                                        ? AppColors.primaryPink
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selectedGender == 'male'
                                          ? AppColors.primaryPink
                                          : (isDarkMode
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                      width: 2,
                                    ),
                                  ),
                                  child: selectedGender == 'male'
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 2. Female Option Box
                        GestureDetector(
                          onTap: () =>
                              setState(() => selectedGender = 'female'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedGender == 'female'
                                    ? AppColors.primaryPink
                                    : (isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                width: selectedGender == 'female' ? 2 : 1,
                              ),
                              boxShadow: [
                                if (selectedGender == 'female')
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.15,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryPink,
                                      width: 2,
                                    ),
                                    image: const DecorationImage(
                                      image: NetworkImage(femaleAvatarUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Female',
                                        style: TextStyle(
                                          color: primaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryPink
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'audio verification is needed',
                                          style: TextStyle(
                                            color: AppColors.primaryPink,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selectedGender == 'female'
                                        ? AppColors.primaryPink
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selectedGender == 'female'
                                          ? AppColors.primaryPink
                                          : (isDarkMode
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                      width: 2,
                                    ),
                                  ),
                                  child: selectedGender == 'female'
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // 3. Notice Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Gender cannot be changed later.',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: selectedGender != null
                                  ? AppColors.pinkGradient
                                  : null,
                              color: selectedGender == null
                                  ? (isDarkMode
                                        ? AppColors.darkCard
                                        : AppColors.lightBorder)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: selectedGender != null
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: (_isLoading || selectedGender == null)
                                  ? null
                                  : _onProceed,
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
                                  : Text(
                                      'Continue to App',
                                      style: TextStyle(
                                        color: selectedGender != null
                                            ? Colors.white
                                            : secondaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
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
