import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';

import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';
import 'package:talk24loves/session_controller.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  UserModel? user;
  bool _isLoading = true;
  bool _isEditingName = false;
  bool _isLoggingOut = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    UserStorage.getUser;
    setState(() => _isLoading = true);
    final userModel = await UserApiService().fetchUserProfile();

    setState(() {
      user = userModel;
      if (user != null) {
        _nameController.text = user!.name ?? "";
      }
      _isLoading = false;
    });
  }

  Future<void> _handleUpdateName() async {
    if (_nameController.text.trim().isEmpty) return;

    final updatedName = _nameController.text.trim();
    setState(() => _isLoading = true);

    final success = await UserApiService().updateUserName(updatedName);

    if (success && user != null) {
      user = user!.copyWith(name: updatedName, profileCompleted: true);
      await UserStorage.saveUser(user!);

      setState(() {
        _isLoading = false;
        _isEditingName = false;
      });
      _nameController.text = updatedName;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      }
    } else {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update name. Try again.")),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will be signed out of this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await UserStorage.clearUser();

      final sessionController = Get.find<SessionController>();
      sessionController.logout();

      if (!mounted) return;

      Get.offAll(() => const LoginScreen());
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);

      Get.snackbar(
        'Logout failed',
        'Unable to clear your session. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFC62828),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isDarkMode = themeController.isDarkMode;
      final Color primaryText = isDarkMode
          ? AppColors.darkPrimaryText
          : AppColors.lightPrimaryText;
      final Color secondaryText = isDarkMode
          ? AppColors.darkSecondaryText
          : AppColors.lightSecondaryText;
      final Color surfaceColor = isDarkMode
          ? AppColors.darkCard
          : AppColors.lightCard;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      return Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBgTop
            : AppColors.lightBgTop,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "User Profile",
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          iconTheme: IconThemeData(color: primaryText),
          actions: [
            // Professional standalone Refresh Icon Button in AppBar
            IconButton(
              tooltip: "Refresh Profile",
              icon: const Icon(Icons.refresh_rounded, size: 22),
              color: AppColors.primaryPink,
              onPressed: _loadUserProfile,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: AppBackground(
          isDarkMode: isDarkMode,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                  ),
                )
              : user == null
              ? Center(
                  child: Text(
                    "Failed to load profile data.",
                    style: TextStyle(color: secondaryText),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Profile Header Area
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: borderColor.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryPink,
                                        Colors.purpleAccent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.5),
                                    child: ClipOval(
                                      child: Image.network(
                                        user!.avatar != null &&
                                                user!.avatar!.isNotEmpty
                                            ? user!.avatar!
                                            : "https://via.placeholder.com/150",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: surfaceColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isEditingName) ...[
                                    TextField(
                                      controller: _nameController,
                                      autofocus: true,
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                        filled: true,
                                        fillColor: isDarkMode
                                            ? AppColors.darkBgTop
                                            : AppColors.lightBgTop,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => setState(
                                            () => _isEditingName = false,
                                          ),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        InkWell(
                                          onTap: _handleUpdateName,
                                          child: const Text(
                                            "Save",
                                            style: TextStyle(
                                              color: AppColors.primaryPink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user!.name != null &&
                                                    user!.name!.isNotEmpty
                                                ? user!.name!
                                                : "No Name",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: primaryText,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () {
                                            setState(
                                              () => _isEditingName = true,
                                            );
                                            _nameController.text =
                                                user!.name ?? "";
                                          },
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: AppColors.primaryPink,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user!.phoneNumber,
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Settings Section (Dark Theme Toggle Switch)
                      Text(
                        "SETTINGS & PREFERENCES",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor.withOpacity(0.4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: AppColors.primaryPink,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "Dark Theme",
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: isDarkMode,
                                activeColor: AppColors.primaryPink,
                                onChanged: (val) {
                                  themeController.toggleTheme();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Activity Metrics Section
                      Text(
                        "CALL ACTIVITY METRICS",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActivityBadge(
                              title: "Audio Minutes",
                              value: "${user!.audioCallTimeMinutes}m",
                              icon: Icons.phone_in_talk_rounded,
                              iconColor: const Color(0xFF1E88E5),
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActivityBadge(
                              title: "Video Minutes",
                              value: "${user!.videoCallTimeMinutes}m",
                              icon: Icons.videocam_rounded,
                              iconColor: const Color(0xFF8E24AA),
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 4. Account Information (Flat Native List with Dividers)
                      Text(
                        "ACCOUNT DETAILS",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            _buildFlatDetailRow(
                              icon: Icons.person_outline_rounded,
                              label: "Gender",
                              value: user!.gender ?? "Not Specified",
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                            _buildFlatDetailRow(
                              icon: Icons.verified_user_outlined,
                              label: "Status",
                              value: user!.status.isNotEmpty
                                  ? user!.status
                                  : "Active",
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                            _buildFlatDetailRow(
                              icon: Icons.assignment_turned_in_outlined,
                              label: "Profile Setup",
                              value: user!.name != null
                                  ? "Completed"
                                  : "Incomplete",
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 5. Centered White Background Logout Button with Bold Black Text
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isLoggingOut ? null : _handleLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text(
                              "Log Out",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  // Activity Badge Tile
  Widget _buildActivityBadge({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color primaryText,
    required Color secondaryText,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: secondaryText, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Flat Native Detail Row with Dividers
  Widget _buildFlatDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryPink, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: borderColor.withOpacity(0.4), height: 1, indent: 34),
      ],
    );
  }
}
