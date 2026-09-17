// ==========================================
// agent_home_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/AgentMainController.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/AgentProfilePage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentProfileModel.dart';
import 'package:talk24loves/screens/temtest/role_selection_view.dart';

class AgentHomePage extends StatefulWidget {
  const AgentHomePage({super.key});

  @override
  State createState() => _AgentHomePageState();
}

class _AgentHomePageState extends State {
  final AgentMainController controller = Get.find();
  final ThemeController themeController = Get.find();

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

      return AppBackground(
        isDarkMode: isDarkMode,
        child: SafeArea(
          child: Column(
            children: [
              // Header: Earnings & Call Time Overview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Earnings',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                '\$${controller.currentEarnings.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Call Time',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                controller.totalCallTime.value,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),

                        // Profile Avatar using StatefulWidget safely
                        (() {
                          final profile = AgentProfileModel.current;
                          final avatarUrl = profile?.avatar ?? '';

                          return GestureDetector(
                            onTap: () async {
                              await Get.to(() => AgentProfilePage());
                              setState(
                                () {},
                              ); // Refresh UI when coming back from profile page
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryPink,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryPink
                                    .withOpacity(0.15),
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                onBackgroundImageError: avatarUrl.isNotEmpty
                                    ? (_, __) {}
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: AppColors.primaryPink,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        })(),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Go Online / Offline Control Block
                      Obx(() {
                        final bool online = controller.isOnline.value;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: online
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF831843),
                                      Color(0xFF4C0519),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [cardBg, cardBg],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: online
                                  ? AppColors.primaryPink.withOpacity(0.8)
                                  : borderColor,
                              width: online ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: online
                                    ? AppColors.primaryPink.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.04),
                                blurRadius: online ? 18 : 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (online)
                                Positioned(
                                  right: 18,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: TweenAnimationBuilder(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      curve: Curves.easeOut,
                                      builder: (context, value, child) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 26 + (value * 24),
                                              height: 26 + (value * 24),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.primaryPink
                                                      .withOpacity(1.0 - value),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      onEnd: () {},
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: online
                                            ? Colors.white.withOpacity(0.15)
                                            : AppColors.primaryPink.withOpacity(
                                                0.12,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        online
                                            ? Icons.headset_mic_rounded
                                            : Icons.power_settings_new_rounded,
                                        color: online
                                            ? Colors.white
                                            : AppColors.primaryPink,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            online
                                                ? 'Status: ONLINE'
                                                : 'Status: OFFLINE',
                                            style: TextStyle(
                                              color: online
                                                  ? Colors.white
                                                  : primaryText,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            online
                                                ? 'Ready for audio/video calls'
                                                : 'Go online to start earning',
                                            style: TextStyle(
                                              color: online
                                                  ? Colors.white70
                                                  : secondaryText,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Switch.adaptive(
                                      value: online,
                                      activeColor: AppColors.primaryPink,
                                      onChanged: (val) =>
                                          controller.toggleOnlineStatus(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoleSelectionView(),
                            ),
                          );
                        },
                        child: Text("Call Dash"),
                      ),
                      // Feature Cards Grid (Video/Live/Audio)
                      SizedBox(
                        height: 110,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Transform.rotate(
                                angle: -0.02,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryPink.withOpacity(0.8),
                                        AppColors.pinkLight.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
                                          fit: BoxFit.cover,
                                        ),
                                        const Positioned(
                                          bottom: 8,
                                          left: 6,
                                          right: 6,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.videocam_rounded,
                                                color: AppColors.pinkLight,
                                                size: 12,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Video Call',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
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
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryPink,
                                        AppColors.pinkLight,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 36,
                                    backgroundImage: NetworkImage(
                                      'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=500&q=80',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Transform.rotate(
                                angle: 0.02,
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.pinkLight.withOpacity(0.3),
                                        AppColors.primaryPink.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=600&q=80',
                                          fit: BoxFit.cover,
                                        ),
                                        const Positioned(
                                          bottom: 8,
                                          left: 6,
                                          right: 6,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.phone,
                                                color: AppColors.pinkLight,
                                                size: 12,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Audio Call',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
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
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Masterclass Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPink.withOpacity(
                                    0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.primaryPink,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agent Masterclass Playlist',
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Playlist Horizontal List
                      SizedBox(
                        height: 195,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildPlaylistCard(
                              cardBg,
                              borderColor,
                              primaryText,
                              secondaryText,
                              'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=600&q=80',
                              'Mastering Romantic Calls',
                              '5:20 min • Etiquette & Flow',
                            ),
                            const SizedBox(width: 14),
                            _buildPlaylistCard(
                              cardBg,
                              borderColor,
                              primaryText,
                              secondaryText,
                              'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=600&q=80',
                              'Handling Stress & Deep Talk',
                              '4:15 min • Empathy Guide',
                            ),
                            const SizedBox(width: 14),
                            _buildPlaylistCard(
                              cardBg,
                              borderColor,
                              primaryText,
                              secondaryText,
                              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80',
                              'Technical & General Topics',
                              '3:50 min • Versatility Tips',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlaylistCard(
    Color cardBg,
    Color borderColor,
    Color primaryText,
    Color secondaryText,
    String imageUrl,
    String title,
    String subtitle,
  ) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryText, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
