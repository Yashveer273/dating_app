import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State {
  final ThemeController themeController = Get.find<ThemeController>();
  UserModel? user;
  bool _isLoading = true;
  bool _isEditingName = false;
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

  Future _loadUserProfile() async {
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

  // 🟢 नाम अपडेट करने की एपीआई कॉल
  Future _handleUpdateName() async {
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
          backgroundColor: surfaceColor,
          title: Text(
            "User Profile",
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: IconThemeData(color: primaryText),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
              onPressed: themeController.toggleTheme,
              icon: Icon(
                isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadUserProfile,
            ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // 🟢 Premium Avatar Section
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryPink,
                                    Colors.purpleAccent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
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
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🟢 Editable Name Section
                      if (_isEditingName)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  hintText: "Enter your name",
                                  hintStyle: TextStyle(
                                    color: secondaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: surfaceColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: primaryText.withOpacity(0.12),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryPink,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditingName = false;
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: secondaryText,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleUpdateName,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryPink,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          "Save",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                user!.name != null && user!.name!.isNotEmpty
                                    ? user!.name!
                                    : "No Name Provided",
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: "Edit name",
                              splashRadius: 20,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: secondaryText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditingName = true;
                                });

                                _nameController.text = user!.name ?? "";
                                _nameController.selection =
                                    TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _nameController.text.length,
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        user!.phoneNumber,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 🟢 Call Stats Section (Audio & Video Call Minutes Only)
                      Row(
                        children: [
                          Expanded(
                            child: _buildCallStatCard(
                              title: "Audio Call Minutes",
                              value: "${user!.audioCallTimeMinutes} mins",
                              icon: Icons.phone_in_talk_rounded,
                              gradientColors: [
                                Colors.blue.shade800,
                                Colors.blueAccent,
                              ],
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCallStatCard(
                              title: "Video Call Minutes",
                              value: "${user!.videoCallTimeMinutes} mins",
                              icon: Icons.videocam_rounded,
                              gradientColors: [
                                Colors.purple.shade800,
                                Colors.purpleAccent,
                              ],
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🟢 Sleek & Professional Account Information List Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                10,
                              ),
                              child: Text(
                                "Account Overview",
                                style: TextStyle(
                                  color: secondaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Divider(color: borderColor, height: 1),
                            _buildProfessionalDetailRow(
                              "Gender",
                              user!.gender ?? "Not Specified",
                              Icons.person_outline,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                            _buildProfessionalDetailRow(
                              "Account Status",
                              user!.status.isNotEmpty ? user!.status : "Active",
                              Icons.verified_user_outlined,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                            _buildProfessionalDetailRow(
                              "Phone Verified",
                              user!.phoneVerified ? "Verified" : "Pending",
                              Icons.phone_android_outlined,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                            _buildProfessionalDetailRow(
                              "Profile Completed",
                              user!.profileCompleted ? "Yes" : "No",
                              Icons.assignment_turned_in_outlined,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  // 🟢 Clean & Premium Call Stat Card
  // 🟢 Clean & Premium Call Stat Card (यहाँ List या List कर दें)
  Widget _buildCallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required Color primaryText,
    required Color secondaryText,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  // 🟢 Professional List Row Widget
  Widget _buildProfessionalDetailRow(
    String label,
    String value,
    IconData icon, {
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryPink, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: secondaryText, fontSize: 14),
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
          Divider(color: borderColor, height: 1, indent: 18, endIndent: 18),
      ],
    );
  }
}
