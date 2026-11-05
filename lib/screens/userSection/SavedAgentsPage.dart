// ==========================================
// SavedAgentsPage.dart (Updated with onInit API Call)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/userSection/component/AgentCardWidget.dart';
import 'package:talk24loves/screens/userSection/component/CallSelectionSheet.dart';
import 'package:talk24loves/screens/userSection/component/UserHomeController.dart';
import 'package:talk24loves/screens/userSection/model/AgentListModel.dart';

class SavedAgentsPage extends StatefulWidget {
  const SavedAgentsPage({super.key});

  @override
  State<SavedAgentsPage> createState() => _SavedAgentsPageState();
}

class _SavedAgentsPageState extends State<SavedAgentsPage> {
  final ThemeController themeController = Get.find();
  final UserHomeController homeController =
      Get.isRegistered<UserHomeController>()
      ? Get.find<UserHomeController>()
      : Get.put(UserHomeController());

  @override
  void initState() {
    super.initState();
    // 👉 Jab bhi yeh page khulega, turant backend se saved agents ki API call ho jayegi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeController.fetchSavedAgentsFromApi();
    });
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

      final List<AgentModel> currentSavedAgents =
          homeController.filteredSavedAgents;
      final bool isLoading = homeController.isLoadingSaved.value;

      return Scaffold(
        body: AppBackground(
          isDarkMode: isDarkMode,
          child: SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildHeader(isDarkMode, homeController.savedAgentsList.length),

                // Categories List (Reused from Home Page)
                _buildCategoriesList(isDarkMode, primaryText),

                // Filter Buttons Row (Call Type & Language)
                _buildFilterHeaderRow(
                  context,
                  isDarkMode,
                  primaryText,
                  secondaryText,
                ),

                // Saved List, Loader or Empty View
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPink,
                          ),
                        )
                      : currentSavedAgents.isEmpty
                      ? _buildEmptyState(secondaryText)
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  12,
                                ),
                                child: Text(
                                  "Your Bookmarked Agents (${currentSavedAgents.length})",
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final AgentModel agent =
                                    currentSavedAgents[index];
                                final identifier = agent.agentId.isNotEmpty
                                    ? agent.agentId
                                    : agent.id;

                                return AgentCardWidget(
                                  agent: agent,
                                  isDarkMode: isDarkMode,
                                  primaryText: primaryText,
                                  secondaryText: secondaryText,

                                  onBookmarkTap: () async {
                                    await homeController.toggleSaveAgent(
                                      identifier,
                                    );
                                  },
                                  onCardTap: () {
                                    homeController.setPriorityAgent(agent);
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
                              }, childCount: currentSavedAgents.length),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
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

  Widget _buildHeader(bool isDarkMode, int savedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryPink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.pinkGradient.createShader(bounds),
                child: const Text(
                  'Saved Agents',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryPink.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$savedCount Saved',
              style: const TextStyle(
                color: AppColors.primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(bool isDarkMode, Color primaryText) {
    return SizedBox(
      height: 50,
      child: Obx(() {
        final currentSelectedId = homeController.selectedCategory.value.id;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: homeController.categories.length,
          itemBuilder: (context, index) {
            final CategoryModel category = homeController.categories[index];
            final bool isSelected = currentSelectedId == category.id;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: GestureDetector(
                onTap: () {
                  homeController.setPriorityCategory(category);
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
    );
  }

  Widget _buildFilterHeaderRow(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color secondaryText,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: callTypes.map((type) {
                  return Obx(() {
                    final bool isSelected =
                        homeController.savedSelectedCallType.value == type;

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
                          homeController.setSavedCallTypeFilter(type);
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: languages.map((lang) {
                  return Obx(() {
                    final bool isSelected =
                        homeController.savedSelectedLanguage.value == lang;

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
                          homeController.setSavedLanguageFilter(lang);
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

  Widget _buildEmptyState(Color secondaryText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: secondaryText.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Agents',
            style: TextStyle(
              color: secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
