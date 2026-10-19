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
import 'agent_profile_widgets.dart';

class AgentProfilePage extends StatefulWidget {
  const AgentProfilePage({super.key});

  @override
  State<AgentProfilePage> createState() => _AgentProfilePageState();
}

class _AgentProfilePageState extends State<AgentProfilePage> {
  final ThemeController themeController = Get.find();
  final UserApiService _userApiService = Get.put(UserApiService());

  AgentModel? agent = AgentStorage.getAgent();
  final AgentFinancialModel? agentFinancials = AgentFinancialModel.current;

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isLoggingOut = false;
  bool _isFetchingProfile = true;

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _topicInputController;

  List<String> _currentTopics = [];
  List<String> _availableCategories = [];
  List<String> _selectedCategories = [];

  // 🌐 Languages State (List format)
  List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = [
    'Hindi',
    'English',
    'Bhojpuri',
    'Tamil',
    'Telugu',
    'Gujarati',
    'Marathi',
  ];

  // 📍 Location State
  String _selectedState = 'Uttar Pradesh';
  String _selectedCity = 'Aligarh';
  String _currentLocation = 'India, Uttar Pradesh, Aligarh';

  final Map<String, List<String>> _indiaStatesAndCities = {
    'Uttar Pradesh': [
      'Aligarh',
      'Agra',
      'Lucknow',
      'Kanpur',
      'Varanasi',
      'Noida',
      'Ghaziabad',
      'Meerut',
    ],
    'Delhi': [
      'New Delhi',
      'North Delhi',
      'South Delhi',
      'East Delhi',
      'West Delhi',
    ],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane'],
    'Bihar': ['Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Mangaluru', 'Hubballi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Salem'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota'],
  };

  bool _isAudioAvailable = true;
  bool _isVideoAvailable = false;
  bool _isSavingCallTypes = false;
  String bioText = "";
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _topicInputController = TextEditingController();

    _loadProfileFromApi();
  }

  // 🚀 GET API Call & AgentModel Integration
  Future<void> _loadProfileFromApi() async {
    setState(() => _isFetchingProfile = true);
    try {
      final fetchedUser = await _userApiService.fetchUserProfile();
      if (fetchedUser != null) {
        setState(() {
          _nameController.text =
              _firstNonEmpty([
                fetchedUser.name,
                AgentProfileModel.current?.displayName,
                agent?.displayName,
              ]) ??
              '';
          _selectedCategories = _parseCategories(fetchedUser.category);
        });
      } else {
        _initProfileData();
      }

      // Language aur Location API call jisme languages ko list mein convert kiya gaya hai
      final langLocRes = await _userApiService.getAgentLanguageAndLocation();
      if (langLocRes['success'] == true && langLocRes['data'] != null) {
        final data = langLocRes['data'];
        setState(() {
          if (data['location'] != null &&
              data['location'].toString().isNotEmpty) {
            _currentLocation = data['location'].toString();
            _parseLocationString(_currentLocation);
          }

          // Languages handling (List form mein assign karna)
          var langs = data['languages'];
          if (langs is List) {
            _selectedLanguages = langs.map((e) => e.toString().trim()).toList();
          } else if (langs is String && langs.isNotEmpty) {
            _selectedLanguages = langs.split(',').map((e) => e.trim()).toList();
          }

          if (_selectedLanguages.isEmpty) {
            _selectedLanguages = ['Hindi', 'English'];
          }
        });
      }

      final callTypesRes = await _userApiService.getAgentCallTypes();
      if (callTypesRes['success'] == true && callTypesRes['data'] != null) {
        final callData = callTypesRes['data'];
        setState(() {
          _isAudioAvailable = callData['isAudioAvailable'] ?? true;
          _isVideoAvailable = callData['isVideoAvailable'] ?? false;
          bioText = callData["bio"];
        });
      }
      await _loadCategoryOptions();
    } catch (e) {
      print("Error loading profile from API: $e");
      _initProfileData();
      await _loadCategoryOptions();
    } finally {
      if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    }
  }

  void _parseLocationString(String loc) {
    List<String> parts = loc.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      _selectedState = parts[1];
      _selectedCity = parts[2];
    } else if (parts.length == 2) {
      _selectedState = parts[1];
    }
  }

  Future<void> _handleUpdateCallTypes(bool newAudio, bool newVideo) async {
    if (!newAudio && !newVideo) {
      Get.snackbar(
        'Validation Error',
        'At least one call type (Audio or Video) must remain enabled.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isSavingCallTypes = true);

    final response = await _userApiService.updateAgentCallTypes(
      isAudioAvailable: newAudio,
      isVideoAvailable: newVideo,
    );

    setState(() => _isSavingCallTypes = false);

    if (response['success'] == true) {
      setState(() {
        _isAudioAvailable = newAudio;
        _isVideoAvailable = newVideo;
      });
      Get.snackbar(
        'Success',
        'Call availability updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        response['message'] ?? 'Failed to update call availability',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _loadCategoryOptions() async {
    try {
      final response = await _userApiService.fetchcatagories();
      final data = response['data'];
      final rawCategories =
          response['categories'] ?? (data is Map ? data['categories'] : data);
      final fetchedCategories = rawCategories is List
          ? rawCategories
                .map((item) {
                  if (item is Map) {
                    return (item['name'] ?? item['category'] ?? '')
                        .toString()
                        .trim();
                  }
                  return item.toString().trim();
                })
                .where((name) => name.isNotEmpty)
          : const <String>[];

      if (!mounted) return;
      setState(() {
        _availableCategories = _uniqueCategories([
          ...fetchedCategories,
          ..._selectedCategories,
        ]);
      });
    } catch (e) {
      print('Error loading agent categories: $e');
      if (!mounted) return;
      setState(() {
        _availableCategories = List<String>.from(_selectedCategories);
      });
    }
  }

  List<String> _parseCategories(String? value) {
    if (value == null || value.trim().isEmpty) return [];
    return _uniqueCategories(value.split(','));
  }

  List<String> _uniqueCategories(Iterable<String> categories) {
    final uniqueCategories = <String>[];
    final seenCategories = <String>{};
    for (final category in categories) {
      final trimmedCategory = category.trim();
      if (trimmedCategory.isNotEmpty &&
          trimmedCategory.toLowerCase() != 'all' &&
          seenCategories.add(trimmedCategory.toLowerCase())) {
        uniqueCategories.add(trimmedCategory);
      }
    }
    return uniqueCategories;
  }

  String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmedValue = value?.trim();
      if (trimmedValue != null && trimmedValue.isNotEmpty) {
        return trimmedValue;
      }
    }
    return null;
  }

  void _initProfileData() {
    final profile = AgentProfileModel.current;
    _nameController.text =
        _firstNonEmpty([profile?.displayName, agent?.displayName]) ?? '';
    _bioController.text = bioText;
    _selectedCategories = _parseCategories(
      profile?.category ?? agent?.category,
    );

    _currentLocation =
        profile?.location ?? agent?.location ?? 'India, Uttar Pradesh, Aligarh';
    _parseLocationString(_currentLocation);

    if (agent?.languages != null && agent!.languages!.isNotEmpty) {
      _selectedLanguages = List<String>.from(agent!.languages!);
    } else {
      _selectedLanguages = ['Hindi', 'English'];
    }

    if (profile?.topics != null) {
      _currentTopics = List<String>.from(profile!.topics);
    } else if (agent?.topics != null) {
      _currentTopics = List<String>.from(agent!.topics);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
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

  // 🚀 PUT API Call & AgentModel / AgentStorage Update Integration
  Future<void> _handleSaveProfile() async {
    setState(() => _isLoading = true);

    final newName = _nameController.text.trim();
    final newCategory = _selectedCategories.join(', ');
    final finalLocation = "India, $_selectedState, $_selectedCity";
    final updatedBio = _bioController.text.trim();
    bool hasError = false;

    if (newName.isNotEmpty) {
      final res = await _userApiService.updateAgentProfileName(
        displayName: newName,
        updatedBio: updatedBio,
      );
      if (res['success'] != true && res['statusCode'] != 200) hasError = true;
    }

    final categoryResponse = await _userApiService.updateAgentCategory(
      category: newCategory,
    );
    if (categoryResponse['success'] != true &&
        categoryResponse['statusCode'] != 200) {
      hasError = true;
    }

    try {
      // Languages ko list/comma separated bhej kar save karna
      final langLocRes = await _userApiService.updateAgentLanguageAndLocation(
        languages: _selectedLanguages,
        location: finalLocation,
      );
      if (langLocRes['success'] != true && langLocRes['statusCode'] != 200) {
        hasError = true;
      } else {
        // AgentModel mein update karke AgentStorage mein save karna
        if (agent != null) {
          // Note: AgentModel ke constructor ya copyWith ke anusaar update karein
          // Yahan hum local state update kar rahe hain
          setState(() {
            _currentLocation = finalLocation;
            bioText = updatedBio;
          });
        }
      }
    } catch (e) {
      print("Error updating languages/location: $e");
      hasError = true;
    }

    if (_currentTopics.isNotEmpty) {
      final res = await _userApiService.updateAgentTopics(
        topics: _currentTopics,
      );
      if (res['success'] != true && res['statusCode'] != 200) hasError = true;
    }

    setState(() {
      _isLoading = false;
    });

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
      final agentName =
          _firstNonEmpty([
            _nameController.text,
            profile?.displayName,
            agent?.displayName,
          ]) ??
          'No Name';
      final agentId = profile?.agentId ?? agent?.agentId;
      final phoneNumber = profile?.phoneNumber ?? agent?.phoneNumber;

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
                      // Header Navigation
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              HeaderButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                color: primaryText,
                                background: cardBg,
                                borderColor: borderColor,
                                onTap: () => Get.back(),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              HeaderButton(
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
                              HeaderButton(
                                icon: isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: AppColors.primaryPink,
                                background: cardBg,
                                borderColor: borderColor,
                                onTap: () => themeController.toggleTheme(),
                              ),
                              const SizedBox(width: 8),
                              HeaderButton(
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

                      // Profile Info Header Card
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
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ProfileAvatar(
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
                                                    agentName,
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
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: secondaryText,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  _currentLocation,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: secondaryText,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (agentFinancials != null)
                                            _buildRatingStars(
                                              agentFinancials!.rating,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==========================================
                      // 📍 Location Section (India -> State -> City)
                      // ==========================================
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
                                        Icons.map_rounded,
                                        color: AppColors.primaryPink,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Location (India)',
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.black26
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '🇮🇳 India',
                                            style: TextStyle(
                                              color: primaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            showSearchableBottomSheet(
                                              context: context,
                                              title: 'Select State',
                                              items: _indiaStatesAndCities.keys
                                                  .toList(),
                                              isDarkMode: isDarkMode,
                                              onSelected: (val) {
                                                setState(() {
                                                  _selectedState = val;
                                                  _selectedCity =
                                                      _indiaStatesAndCities[val]!
                                                          .first;
                                                });
                                              },
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Colors.black26
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .spaceBetween, // 👈 spaceBetween used
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _selectedState,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: primaryText,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () {
                                      final cities =
                                          _indiaStatesAndCities[_selectedState] ??
                                          ['Aligarh'];
                                      showSearchableBottomSheet(
                                        context: context,
                                        title: 'Select City in $_selectedState',
                                        items: cities,
                                        isDarkMode: isDarkMode,
                                        onSelected: (val) {
                                          setState(() {
                                            _selectedCity = val;
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.black26
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // 👈 spaceBetween used
                                        children: [
                                          Text(
                                            _selectedCity,
                                            style: TextStyle(
                                              color: primaryText,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else
                                  Text(
                                    _currentLocation,
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==========================================
                      // 🌐 Languages Spoken Section
                      // ==========================================
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
                                        Icons.language_rounded,
                                        color: AppColors.primaryPink,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Languages Spoken',
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
                                  InkWell(
                                    onTap: () {
                                      showSearchableBottomSheet(
                                        context: context,
                                        title: 'Select Language',
                                        items: _availableLanguages
                                            .where(
                                              (lang) => !_selectedLanguages.any(
                                                (selected) =>
                                                    selected.toLowerCase() ==
                                                    lang.toLowerCase(),
                                              ),
                                            )
                                            .toList(),
                                        isDarkMode: isDarkMode,
                                        onSelected: (selection) {
                                          setState(() {
                                            if (!_selectedLanguages.contains(
                                              selection,
                                            )) {
                                              _selectedLanguages.add(selection);
                                            }
                                          });
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.black26
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween, // 👈 spaceBetween used
                                        children: [
                                          Text(
                                            'Tap to select languages...',
                                            style: TextStyle(
                                              color: secondaryText,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _selectedLanguages
                                        .map(
                                          (lang) => Chip(
                                            label: Text(
                                              lang,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedLanguages.remove(lang);
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ] else if (_selectedLanguages.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedLanguages
                                        .map(
                                          (lang) => Container(
                                            padding: const EdgeInsets.symmetric(
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
                                              lang,
                                              style: const TextStyle(
                                                color: AppColors.primaryPink,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  )
                                else
                                  Text(
                                    'Hindi, English',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Phone Number Tile
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: InfoTile(
                            icon: Icons.phone_outlined,
                            title: 'Phone Number',
                            value: phoneNumber ?? 'Not Provided',
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            background: cardBg,
                            borderColor: borderColor,
                          ),
                        ),
                      ),

                      // Categories Section
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
                                        Icons.category_outlined,
                                        color: AppColors.primaryPink,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Categories',
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
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(
                                      _selectedCategories.join('|'),
                                    ),
                                    value: null,
                                    items: _availableCategories
                                        .where(
                                          (option) => !_selectedCategories.any(
                                            (selected) =>
                                                selected.toLowerCase() ==
                                                option.toLowerCase(),
                                          ),
                                        )
                                        .map(
                                          (option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(option),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (selection) {
                                      if (selection == null) return;
                                      setState(() {
                                        _selectedCategories = _uniqueCategories(
                                          [..._selectedCategories, selection],
                                        );
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Select category',
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
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _selectedCategories
                                        .map(
                                          (selectedCategory) => Chip(
                                            label: Text(
                                              selectedCategory,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedCategories.remove(
                                                  selectedCategory,
                                                );
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ] else if (_selectedCategories.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedCategories
                                        .map(
                                          (selectedCategory) => Container(
                                            padding: const EdgeInsets.symmetric(
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
                                              selectedCategory,
                                              style: const TextStyle(
                                                color: AppColors.primaryPink,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  )
                                else
                                  Text(
                                    'No categories selected',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bio Section
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
                                    bioText,
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

                      // Save All Changes Button
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
