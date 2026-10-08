import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentJobOnOffModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentProfileModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';
import 'package:talk24loves/session_controller.dart';

import 'models/AgentFinancialModel.dart';
import 'models/agent_model.dart';

class AgentProfilePage extends StatefulWidget {
  const AgentProfilePage({super.key});

  @override
  State<AgentProfilePage> createState() => _AgentProfilePageState();
}

class _AgentProfilePageState extends State<AgentProfilePage> {
  final ThemeController themeController = Get.find();
  final UserApiService _userApiService = Get.put(UserApiService());

  final AgentModel? agent = AgentStorage.getAgent();
  final AgentFinancialModel? agentFinancials = AgentFinancialModel.current;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  bool _isFetchingProfile = true;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _categoryController;
  late TextEditingController _topicInputController;

  List<String> _currentTopics = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _categoryController = TextEditingController();
    _topicInputController = TextEditingController();

    // Init ke andar API call karke profile data fetch karein[cite: 1]
    _loadProfileFromApi();
  }

  Future<void> _loadProfileFromApi() async {
    setState(() => _isFetchingProfile = true);
    try {
      final fetchedUser = await _userApiService.fetchUserProfile();
      if (fetchedUser != null) {
        setState(() {
          _nameController.text = fetchedUser.name ?? '';
          _categoryController.text = fetchedUser.category ?? '';
        });
      } else {
        _initProfileData();
      }
    } catch (e) {
      print("Error loading profile from API: $e");
      _initProfileData();
    } finally {
      if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    }
  }

  void _initProfileData() {
    final profile = AgentProfileModel.current;
    _nameController.text = profile?.displayName ?? agent?.displayName ?? '';
    _bioController.text = profile?.bio ?? agent?.bio ?? '';
    _categoryController.text = profile?.category ?? agent?.category ?? '';

    if (profile?.topics != null) {
      _currentTopics = List<String>.from(profile!.topics!);
    } else if (agent?.topics != null) {
      _currentTopics = List<String>.from(agent!.topics!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _categoryController.dispose();
    _topicInputController.dispose();
    super.dispose();
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
      await AgentStorage.clearAgent();
      await UserStorage.clearUser();

      AgentProfileModel.current = null;
      AgentFinancialModel.current = null;
      AgentJobOnOffModel.current = null;

      if (!mounted) return;
      Get.until((route) => route.isFirst);
      Get.find<SessionController>().currentScreen.value = const LoginScreen();
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

  Future<void> _handleSaveProfile() async {
    setState(() => _isLoading = true);

    final newName = _nameController.text.trim();
    final newCategory = _categoryController.text.trim();

    bool hasError = false;

    if (newName.isNotEmpty) {
      final res = await _userApiService.updateAgentProfileName(
        displayName: newName,
      );
      if (res['success'] != true && res['statusCode'] != 200) hasError = true;
    }
    if (newCategory.isNotEmpty) {
      final res = await _userApiService.updateAgentCategory(
        category: newCategory,
      );
      if (res['success'] != true && res['statusCode'] != 200) hasError = true;
    }
    if (_currentTopics.isNotEmpty) {
      final res = await _userApiService.updateAgentTopics(
        topics: _currentTopics,
      );
      if (res['success'] != true && res['statusCode'] != 200) hasError = true;
    }

    setState(() => _isLoading = false);

    if (!hasError) {
      setState(() => _isEditing = false);
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update some fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // Double rating ke adhar par dynamic stars render karne ka method
  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int totalStars = 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          fullStars,
          (index) =>
              const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
        ),
        if (hasHalfStar)
          const Icon(Icons.star_half_rounded, color: Colors.amber, size: 15),
        ...List.generate(
          totalStars - fullStars - (hasHalfStar ? 1 : 0),
          (index) => Icon(
            Icons.star_outline_rounded,
            color: Colors.amber.withOpacity(0.5),
            size: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isDarkMode = themeController.isDarkMode;

      final primaryText = isDarkMode
          ? AppColors.darkPrimaryText
          : AppColors.lightPrimaryText;
      final secondaryText = isDarkMode
          ? AppColors.darkSecondaryText
          : AppColors.lightSecondaryText;
      final cardBg = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
      final borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      final profile = AgentProfileModel.current;
      final avatarUrl = profile?.avatar ?? agent?.avatar;
      final agentName = profile?.displayName ?? agent?.displayName;
      final agentId = profile?.agentId ?? agent?.agentId;
      final phoneNumber = profile?.phoneNumber ?? agent?.phoneNumber;
      final bioText = profile?.bio ?? agent?.bio;
      final category = profile?.category ?? agent?.category;
      final location = profile?.location ?? agent?.firebaseLocation ?? 'India';

      return AppBackground(
        isDarkMode: isDarkMode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _isFetchingProfile
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPink,
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              _HeaderButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                color: primaryText,
                                background: cardBg,
                                borderColor: borderColor,
                                onTap: () => Get.back(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profile',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Manage your professional details',
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _HeaderButton(
                                icon: _isEditing
                                    ? Icons.close_rounded
                                    : Icons.edit_rounded,
                                color: _isEditing
                                    ? Colors.redAccent
                                    : AppColors.primaryPink,
                                background: cardBg,
                                borderColor: borderColor,
                                onTap: () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              _HeaderButton(
                                icon: isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: AppColors.primaryPink,
                                background: cardBg,
                                borderColor: borderColor,
                                onTap: () => themeController.toggleTheme(),
                              ),
                              const SizedBox(width: 8),
                              _HeaderButton(
                                icon: Icons.logout_rounded,
                                color: const Color(0xFFC62828),
                                background: const Color(
                                  0xFFC62828,
                                ).withOpacity(0.1),
                                borderColor: const Color(
                                  0xFFC62828,
                                ).withOpacity(0.25),
                                onTap: _isLoggingOut ? () {} : _handleLogout,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: borderColor.withOpacity(0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDarkMode ? 0.20 : 0.04,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ProfileAvatar(
                                      avatarUrl: avatarUrl,
                                      background: isDarkMode
                                          ? Colors.white.withOpacity(0.06)
                                          : AppColors.primaryPink.withOpacity(
                                              0.07,
                                            ),
                                      borderColor: borderColor,
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_isEditing)
                                            TextField(
                                              controller: _nameController,
                                              autofocus:
                                                  true, // First active field requirement
                                              style: TextStyle(
                                                color: primaryText,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: "Enter Name",
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                filled: true,
                                                fillColor: isDarkMode
                                                    ? Colors.black26
                                                    : Colors.grey.shade100,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            )
                                          else
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    agentName ?? 'No Name',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: primaryText,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.verified_rounded,
                                                  color: AppColors.primaryPink,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 6),

                                          if (_isEditing)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: TextField(
                                                controller: _categoryController,
                                                style: TextStyle(
                                                  color: primaryText,
                                                  fontSize: 13,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: "Category",
                                                  isDense: true,
                                                  filled: true,
                                                  fillColor: isDarkMode
                                                      ? Colors.black26
                                                      : Colors.grey.shade100,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 8,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else if ((category ?? '').isNotEmpty)
                                            Text(
                                              category!,
                                              style: TextStyle(
                                                color: AppColors.primaryPink,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: secondaryText,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                location,
                                                style: TextStyle(
                                                  color: secondaryText,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          _buildRatingStars(
                                            agentFinancials!.rating,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.03)
                                        : Colors.black.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: borderColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.badge_outlined,
                                        size: 18,
                                        color: AppColors.primaryPink,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Agent ID',
                                              style: TextStyle(
                                                color: secondaryText,
                                                fontSize: 10.5,
                                              ),
                                            ),
                                            Text(
                                              agentId ?? 'N/A',
                                              style: TextStyle(
                                                color: primaryText,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if ((agentId ?? '').isNotEmpty)
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(text: agentId!),
                                            );
                                            Get.snackbar(
                                              'Copied',
                                              'Agent ID copied',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(
                                              Icons.copy_rounded,
                                              size: 16,
                                              color: AppColors.primaryPink,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.phone_outlined,
                                  title: 'Phone Number',
                                  value: phoneNumber ?? 'Not Provided',
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                  background: cardBg,
                                  borderColor: borderColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.category_outlined,
                                  title: 'Category',
                                  value: category ?? 'General',
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,
                                  background: cardBg,
                                  borderColor: borderColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: borderColor.withOpacity(0.7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.format_quote_rounded,
                                        color: AppColors.primaryPink,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'About / Bio',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_isEditing)
                                  TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    style: TextStyle(color: primaryText),
                                    decoration: InputDecoration(
                                      hintText:
                                          "Write something about yourself...",
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.black26
                                          : Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    bioText ?? 'No bio provided',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: borderColor.withOpacity(0.7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryPink
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.forum_outlined,
                                        color: AppColors.primaryPink,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Conversation Topics',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                if (_isEditing) ...[
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _currentTopics.map((topic) {
                                      return Chip(
                                        label: Text(
                                          topic,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: AppColors.primaryPink
                                            .withOpacity(0.1),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 14,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _currentTopics.remove(topic);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _topicInputController,
                                          style: TextStyle(
                                            color: primaryText,
                                            fontSize: 13,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: "Add topic...",
                                            isDense: true,
                                            filled: true,
                                            fillColor: isDarkMode
                                                ? Colors.black26
                                                : Colors.grey.shade100,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final val = _topicInputController.text
                                              .trim();
                                          if (val.isNotEmpty &&
                                              !_currentTopics.contains(val)) {
                                            setState(() {
                                              _currentTopics.add(val);
                                              _topicInputController.clear();
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryPink,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Add'),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  _currentTopics.isNotEmpty
                                      ? Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _currentTopics.map((topic) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryPink
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: AppColors.primaryPink
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: Text(
                                                topic,
                                                style: const TextStyle(
                                                  color: AppColors.primaryPink,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : Text(
                                          'No topics added',
                                          style: TextStyle(
                                            color: secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (_isEditing)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleSaveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save All Changes',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 30,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withOpacity(0.7)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final Color background;
  final Color borderColor;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: borderColor.withOpacity(0.8), width: 1.2),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryPink.withOpacity(0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.primaryPink,
        size: 36,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color primaryText;
  final Color secondaryText;
  final Color background;
  final Color borderColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.primaryText,
    required this.secondaryText,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
