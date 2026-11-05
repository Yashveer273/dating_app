// ==========================================
// UserHomePage.dart (Updated with Search Bar & "Find Your Match" title)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/AppConfig.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/screens/userSection/UserProfileScreen.dart';

import 'package:talk24loves/screens/userSection/component/UserHomeController.dart';
import 'package:talk24loves/screens/userSection/model/AgentListModel.dart';
import 'package:talk24loves/screens/userSection/component/AgentCardWidget.dart';
import 'package:talk24loves/screens/userSection/component/CallSelectionSheet.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class UserHomePage extends StatefulWidget {
  UserHomePage({super.key});

  static final UserModel? user = AppConfig.user;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final UserHomeController controller = Get.put(UserHomeController());
  double? _walletBalance;
  final ThemeController themeController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    final apiService = UserApiService()..onInit();
    final balance = await apiService.fetchCurrentWalletBalance();

    if (mounted) setState(() => _walletBalance = balance);
  }

  DateTime? _lastRefreshTime;

  static final UserModel? user = AppConfig.user;
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = themeController.isDarkMode;

    final Color primaryText = isDarkMode
        ? AppColors.darkPrimaryText
        : AppColors.lightPrimaryText;
    final Color secondaryText = isDarkMode
        ? AppColors.darkSecondaryText
        : AppColors.lightSecondaryText;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: AppBackground(
          isDarkMode: isDarkMode,
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(isDarkMode, primaryText),

                // Main Scrollable Content
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryPink,
                    onRefresh: () async {
                      final now = DateTime.now();
                      if (_lastRefreshTime != null &&
                          now.difference(_lastRefreshTime!) <
                              const Duration(seconds: 3)) {
                        Get.snackbar(
                          'Slow down',
                          'Please wait a moment before refreshing again.',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }

                      _lastRefreshTime = now;
                      _searchController.clear();
                      await controller.loadHomeDataFromApi();
                      await _loadWalletBalance();
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildPromoBanner(),
                        _buildCategoriesList(isDarkMode, primaryText),

                        // 👉 Find Your Match Header & Search Bar
                        _buildExpertsHeaderWithSearch(
                          context,
                          isDarkMode,
                          primaryText,
                          secondaryText,
                        ),

                        // Filtered Expert List Builder
                        Obx(() {
                          final list = controller.filteredAgents;
                          if (list.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Center(
                                  child: Text(
                                    'No experts available matching this search or filter.',
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }

                          return SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final AgentModel agent = list[index];
                              final identifier = agent.agentId.isNotEmpty
                                  ? agent.agentId
                                  : agent.id;

                              // Match ID status from controller storage helper

                              return AgentCardWidget(
                                agent: agent,
                                isDarkMode: isDarkMode,
                                primaryText: primaryText,
                                secondaryText: secondaryText,

                                onBookmarkTap: () {
                                  controller.toggleSaveAgent(identifier);
                                },
                                onCardTap: () {
                                  controller.setPriorityAgent(agent);
                                },
                                onCallTap: () {
                                  showCallSelectionSheet(
                                    context: context,
                                    agent: agent,
                                    isDarkMode: isDarkMode,
                                    primaryText: primaryText,
                                    secondaryText: secondaryText,
                                  );
                                },
                              );
                            }, childCount: list.length),
                          );
                        }),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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

  Widget _buildTopBar(bool isDarkMode, Color primaryText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.pinkGradient.createShader(bounds),
            child: const Text(
              'Talk 24',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryPink.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: AppColors.primaryPink,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹ ${_walletBalance != null ? _walletBalance!.toStringAsFixed(2) : 0.0}',
                      style: TextStyle(
                        color: AppColors.primaryPink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryPink,
                      width: 1.5,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(user?.avatar ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Container(
          height: 145,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Live Connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Find Your Spark Today',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Real conversations starting at just ₹5/min',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(bool isDarkMode, Color primaryText) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 50,
        child: Obx(() {
          final currentSelectedId = controller.selectedCategory.value.id;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final CategoryModel category = controller.categories[index];
              final bool isSelected = currentSelectedId == category.id;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: GestureDetector(
                  onTap: () {
                    controller.setPriorityCategory(category);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPink
                          : (isDarkMode
                                ? AppColors.darkCard
                                : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPink
                            : (isDarkMode
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // 👉 Find Your Match Header & Search Bar
  Widget _buildExpertsHeaderWithSearch(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color secondaryText,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.pinkGradient.createShader(bounds),
                  child: const Text(
                    'Find Your Match',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Call Type Filter Button
                    GestureDetector(
                      onTap: () => _showCallTypeFilterSheet(
                        context,
                        isDarkMode,
                        primaryText,
                        secondaryText,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.video_call_rounded,
                              size: 14,
                              color: AppColors.primaryPink,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Call Type',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Language Filter Button
                    GestureDetector(
                      onTap: () => _showLanguageFilterSheet(
                        context,
                        isDarkMode,
                        primaryText,
                        secondaryText,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primaryPink.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 14,
                              color: AppColors.primaryPink,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Language',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 👉 ID Search Bar Component
            // 👉 Row Direction Search Bar & Standalone Pill-Shaped Search Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              child: Row(
                children: [
                  // Input Box (Pill-shaped / Elliptical with generous height)
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Pill / Ellipse shape
                        border: Border.all(
                          color: AppColors.primaryPink.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense:
                              true, // Reduces default internal vertical spacing
                          hintText: 'Search e.g. @D0F81DEB',
                          hintStyle: TextStyle(
                            color: secondaryText.withOpacity(0.6),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 10),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryPink,
                              size: 22,
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: secondaryText,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.searchAgentsById('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          // Adjust vertical padding so it sits dead-center within your 44px container
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical:
                                10, // Reduced from 15 to center it vertically
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Standalone Search Button (Row direction, Pill-shaped, Bold text)
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            30,
                          ), // Pill / Ellipse shape
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        controller.searchAgentsById(_searchController.text);
                        FocusScope.of(context).unfocus();
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppColors.pinkGradient,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          alignment: Alignment.center,
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallTypeFilterSheet(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color secondaryText,
  ) {
    final List callTypes = ['All', 'Audio', 'Video'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Call Type',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select service type to sort available experts:',
                style: TextStyle(color: secondaryText, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: callTypes.map((type) {
                  return Obx(() {
                    final bool isSelected =
                        controller.selectedCallType.value == type;

                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(type),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selectedColor: AppColors.primaryPink,
                      backgroundColor: isDarkMode
                          ? AppColors.darkBgMid
                          : Colors.grey.shade200,
                      onSelected: (selected) {
                        if (selected) {
                          controller.setCallTypeFilter(type);
                          Navigator.pop(context);
                        }
                      },
                    );
                  });
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageFilterSheet(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color secondaryText,
  ) {
    final List languages = ['All', 'Urdu', 'Hindi', 'English', 'Punjabi'];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Language',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a language to instantly sort available experts:',
                style: TextStyle(color: secondaryText, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: languages.map((lang) {
                  return Obx(() {
                    final bool isSelected =
                        controller.selectedLanguage.value == lang;

                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(lang),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      selectedColor: AppColors.primaryPink,
                      backgroundColor: isDarkMode
                          ? AppColors.darkBgMid
                          : Colors.grey.shade200,
                      onSelected: (selected) {
                        if (selected) {
                          controller.setLanguageFilter(lang);
                          Navigator.pop(context);
                        }
                      },
                    );
                  });
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
