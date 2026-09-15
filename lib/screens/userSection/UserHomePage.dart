// ==========================================
// UserHomePage.dart (Updated with Call Type Filter UI)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/screens/userSection/component/UserHomeController.dart';
import 'package:talk24loves/screens/userSection/model/AgentModel.dart';
import 'package:talk24loves/screens/userSection/component/AgentCardWidget.dart';
import 'package:talk24loves/screens/userSection/component/CallSelectionSheet.dart';

class UserHomePage extends StatelessWidget {
  UserHomePage({super.key});

  final UserHomeController controller = Get.put(UserHomeController());
  final ThemeController themeController = Get.find();

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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildPromoBanner(),
                      _buildCategoriesList(isDarkMode, primaryText),

                      // 👉 Experts Header with both Language & Call Type Filters
                      _buildExpertsHeader(
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
                                  'No experts available matching this filter.',
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 13,
                                  ),
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

                            return AgentCardWidget(
                              agent: agent,
                              isDarkMode: isDarkMode,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
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
              'Connecto',
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
                  children: const [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 14,
                      color: AppColors.primaryPink,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '₹ 120.00',
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryPink, width: 1.5),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
                    ),
                    fit: BoxFit.cover,
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
          // 👉 Get current selected category ID to force reactive trigger inside builder
          final currentSelectedId = controller.selectedCategory.value.id;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              final CategoryModel category = controller.categories[index];

              // 👉 Reactive check based on currentSelectedId
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

  // Experts Header with Language & Call Type Filters
  Widget _buildExpertsHeader(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color secondaryText,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Experts',
              style: TextStyle(
                color: primaryText,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                // 👉 Call Type Filter Button
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
      ),
    );
  }

  // 👉 Call Type Filter Bottom Sheet
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

  // Language Filter Bottom Sheet
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
