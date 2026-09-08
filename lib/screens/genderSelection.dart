import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/components/app_footer.dart';
import 'package:talk24loves/screens/home_screen.dart';
import 'package:talk24loves/screens/otp_screen.dart';
import 'package:talk24loves/widgets/WaveDotLoader.dart';

// --- Rich Gender Selection Screen ---
class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  final themeController = Get.find<ThemeController>();
  String? selectedGender; // 'male' or 'female'
  bool _isLoading = false;

  // Placeholder avatar image URLs from the internet
  static const String maleAvatarUrl =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';
  static const String femaleAvatarUrl =
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80';

  final LinearGradient pinkGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFDB2777), Color(0xFFE11D48)],
  );

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText => isDarkMode ? Colors.white : AppColors.darkBgMid;
  Color get secondaryText =>
      isDarkMode ? const Color(0xFFA3A3A3) : const Color(0xFF666666);

  void _onProceed() {
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender to continue')),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Proceed to next main app experience
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
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
                // Top Header Section with "your" (small, grey) & "Gender" (black/bold/large)
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
                        borderColor: Color(0xFFF43F5E),
                        innerColor: Color(0xFFFB7185),
                      ),
                    ],
                  ),
                ),

                // Center Column Selection Area with generous spacing and expanded area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // 1. Male Box with Internet Avatar
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
                                    ? const Color(0xFFF43F5E)
                                    : (isDarkMode
                                          ? const Color(0xFF333333)
                                          : AppColors.lightBorder),
                                width: selectedGender == 'male' ? 2 : 1,
                              ),
                              boxShadow: [
                                if (selectedGender == 'male')
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF43F5E,
                                    ).withOpacity(0.15),
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
                                          ? const Color(0xFFF43F5E)
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
                                        ? const Color(0xFFF43F5E)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selectedGender == 'male'
                                          ? const Color(0xFFF43F5E)
                                          : (isDarkMode
                                                ? const Color(0xFF555555)
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

                        // 2. Female Box with Circular Internet Avatar & Audio Verification Subtitle
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
                                    ? const Color(0xFFF43F5E)
                                    : (isDarkMode
                                          ? const Color(0xFF333333)
                                          : AppColors.lightBorder),
                                width: selectedGender == 'female' ? 2 : 1,
                              ),
                              boxShadow: [
                                if (selectedGender == 'female')
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF43F5E,
                                    ).withOpacity(0.15),
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
                                      color: const Color(0xFFF43F5E),
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
                                          color: const Color(
                                            0xFFF43F5E,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'audio verification is needed',
                                          style: TextStyle(
                                            color: Color(0xFFF43F5E),
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
                                        ? const Color(0xFFF43F5E)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: selectedGender == 'female'
                                          ? const Color(0xFFF43F5E)
                                          : (isDarkMode
                                                ? const Color(0xFF555555)
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

                        // Generous spacing to fill vertical gap smoothly and push notice + proceed button nicely
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

                        // 4. Proceed Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: selectedGender != null
                                  ? pinkGradient
                                  : null,
                              color: selectedGender == null
                                  ? (isDarkMode
                                        ? const Color(0xFF262626)
                                        : AppColors.lightBorder)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: selectedGender != null
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF43F5E,
                                        ).withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading || selectedGender == null
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
                                  ? const WaveDotLoader(
                                      color: Colors.white,
                                      size: 6.0,
                                    )
                                  : Text(
                                      'Proceed',
                                      style: TextStyle(
                                        color: selectedGender != null
                                            ? Colors.white
                                            : (isDarkMode
                                                  ? const Color(0xFF737373)
                                                  : const Color(0xFF9CA3AF)),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Footer at the bottom
                LoginFooter(isDarkMode: isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
