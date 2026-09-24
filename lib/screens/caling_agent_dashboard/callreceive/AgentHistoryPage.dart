import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/CallAgentController.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/call_item_models.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/history_call_card.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/incoming_call_card.dart';

import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/shared_call_screen.dart';

class AgentHistoryPage extends StatefulWidget {
  const AgentHistoryPage({super.key});

  @override
  State createState() => _AgentHistoryPageState();
}

class _AgentHistoryPageState extends State with TickerProviderStateMixin {
  final CallAgentController controller = Get.put(CallAgentController());
  final ThemeController themeController = Get.find();

  final RxString selectedFilter = 'All Calls'.obs;
  final RxString historySortOrder = 'Newest First'.obs;
  final Rxn selectedDateFilter = Rxn();

  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey _animatedListKey = GlobalKey();

  late final AnimationController _gradientController;
  late final AnimationController _blinkController;
  late final AnimationController _emptyStatePulseController;

  final RxList historyList = [].obs;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _emptyStatePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // यहाँ से _addInitialCall वाले डमी डेटा पूरी तरह हटा दिए गए हैं।
  }

  @override
  void dispose() {
    for (var call in controller.incomingQueue) {
      call.dispose();
    }
    _gradientController.dispose();
    _blinkController.dispose();
    _emptyStatePulseController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  List get _filteredHistoryList {
    var list = controller.historyList.where((item) {
      if (selectedFilter.value == 'Video Calls Only' &&
          item.callType != 'Video Call')
        return false;
      if (selectedFilter.value == 'Audio Calls Only' &&
          item.callType != 'Audio Call')
        return false;
      if (selectedFilter.value == 'Attended Successfully' &&
          !item.statusText.contains('Successfully Attended'))
        return false;
      if (selectedFilter.value == 'Missed / Unattended' &&
          !item.statusText.contains('Missed') &&
          !item.statusText.contains('Declined') &&
          !item.statusText.contains('Cancelled'))
        return false;

      if (selectedDateFilter.value != null) {
        final d = selectedDateFilter.value!;
        if (item.timestamp.year != d.year ||
            item.timestamp.month != d.month ||
            item.timestamp.day != d.day) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (historySortOrder.value == 'Newest First') {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return list;
  }

  Future _pickDateFilter(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      selectedDateFilter.value = picked;
      selectedFilter.value =
          'Date: ${picked.toLocal().toString().split(' ')[0]}';
    }
  }

  void _removeItemSmoothly(
    IncomingCallItemModel call,
    bool isAccepted, {
    bool isTimeout = false,
  }) async {
    if (isTimeout) {
      controller.handleCallTimeout(call.id);
    } else if (isAccepted) {
      // 🟢 1. पहले कंट्रोलर के जरिए Firebase पर 'accepted' अपडेट और क्यू से सफाई करें
      bool isSuccess = await controller.acceptCall(call.id);

      // 2. जब Firebase का काम सफल हो जाए, तब Navigator.push के जरिए आगे बढ़ें (रिप्लेस नहीं करना है)
      if (isSuccess && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedCallScreen(
              roomId: call.id,
              callType: call.isVideoCall ? 'video' : 'audio',
              agentId: CallApiService.staticAgentId,
              isUserCaller: false,
            ),
          ),
        );
      }
    } else {
      // 🔴 3. अगर डिलीट/रिजेक्ट किया है
      await controller.declineCall(call.id);
    }

    // एनिमेटेड लिस्ट से आइटम हटाने का UI एनीमेशन लॉजिक यहाँ रहेगा...
  }

  void _showFilterBottomSheet(
    BuildContext context,
    bool isDarkMode,
    Color primaryText,
    Color cardBg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Call Logs',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: primaryText,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFilterOptionTile(
                'All Calls',
                Icons.list_alt_rounded,
                primaryText,
              ),
              _buildFilterOptionTile(
                'Video Calls Only',
                Icons.videocam_rounded,
                primaryText,
              ),
              _buildFilterOptionTile(
                'Audio Calls Only',
                Icons.phone_in_talk_rounded,
                primaryText,
              ),
              _buildFilterOptionTile(
                'Attended Successfully',
                Icons.check_circle_rounded,
                primaryText,
              ),
              _buildFilterOptionTile(
                'Missed / Unattended',
                Icons.timer_off_rounded,
                primaryText,
              ),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primaryPink,
                    size: 18,
                  ),
                  title: Text(
                    'Calendar Date Picker...',
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickDateFilter(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOptionTile(
    String title,
    IconData icon,
    Color primaryText,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryPink, size: 18),
        title: Text(
          title,
          style: TextStyle(
            color: primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          selectedFilter.value = title;
          selectedDateFilter.value = null;
          Get.back();
        },
      ),
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

      return AppBackground(
        isDarkMode: isDarkMode,
        child: SafeArea(
          child: Column(
            children: [
              // Header Title Area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: AppColors.primaryPink,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Call Activity & Log',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Incoming requests & history overview',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            color: Colors.greenAccent,
                            size: 7,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'You Are Online',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Scrollable Area
              Expanded(
                child: SingleChildScrollView(
                  controller: _mainScrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto-scroll Toggle Control (Driven by Controller)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.swap_vert_rounded,
                                  color: AppColors.primaryPink,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Auto-scroll to top on new call',
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Obx(
                              () => Switch(
                                value: controller.autoScrollOnNewCall.value,
                                activeColor: AppColors.primaryPink,
                                onChanged: (val) {
                                  controller.toggleAutoScroll(val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section header for live incoming requests queue
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryPink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Obx(
                                () => Text(
                                  'Live Incoming Requests (${controller.incomingQueue.length})',
                                  style: TextStyle(
                                    color: primaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Live Incoming Requests Section (Displays Custom Pulse Graphic Container when Empty)
                      Obx(() {
                        if (controller.incomingQueue.isEmpty) {
                          return AnimatedBuilder(
                            animation: _emptyStatePulseController,
                            builder: (context, child) {
                              final double pulseVal =
                                  _emptyStatePulseController.value;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.4 + (pulseVal * 0.4),
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryPink.withOpacity(
                                        0.1 + (pulseVal * 0.15),
                                      ),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryPink
                                                .withOpacity(
                                                  0.12 + (pulseVal * 0.18),
                                                ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primaryPink
                                                .withOpacity(0.25),
                                            border: Border.all(
                                              color: AppColors.primaryPink
                                                  .withOpacity(0.6),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.graphic_eq_rounded,
                                            color: AppColors.primaryPink,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Listening for Incoming Calls',
                                                style: TextStyle(
                                                  color: primaryText,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryPink
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: AppColors.primaryPink
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryPink,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Your line is active and ready to receive requests.',
                                            style: TextStyle(
                                              color: secondaryText,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                isDarkMode ? 0.04 : 0.06,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  isDarkMode ? 0.06 : 0.08,
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.inbox_rounded,
                                                  size: 14,
                                                  color: secondaryText
                                                      .withOpacity(0.7),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'No incoming requests yet',
                                                  style: TextStyle(
                                                    color: secondaryText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }

                        return AnimatedList(
                          key: _animatedListKey,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: controller.incomingQueue.length,
                          itemBuilder: (context, index, animation) {
                            if (index >= controller.incomingQueue.length) {
                              return const SizedBox.shrink();
                            }
                            final call = controller.incomingQueue[index];
                            return SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.vertical,
                              child: FadeTransition(
                                opacity: animation,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Dismissible(
                                    key: Key(call.id),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.greenAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Accepting & Moving to History...',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Declining & Erasing...',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.call_end_rounded,
                                            color: Colors.redAccent,
                                          ),
                                        ],
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      final isAccepted =
                                          direction ==
                                          DismissDirection.startToEnd;
                                      _removeItemSmoothly(call, isAccepted);
                                      return true;
                                    },
                                    onDismissed: (_) {},
                                    child: IncomingCallCard(
                                      call: call,
                                      isTopPriority: index == 0,
                                      isDarkMode: isDarkMode,
                                      cardBg: cardBg,
                                      gradientController: _gradientController,
                                      blinkController: _blinkController,
                                      // ✅ यहाँ लाइव कार्ड के लिए एक्सेप्ट और डिलीट बटन कनेक्ट कर दिए गए हैं
                                      onAccept: () =>
                                          _removeItemSmoothly(call, true),
                                      onDelete: () =>
                                          _removeItemSmoothly(call, false),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 16),

                      // Section Header with Filter Trigger and Sort Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Call Archives',
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  historySortOrder.value =
                                      historySortOrder.value == 'Newest First'
                                      ? 'Oldest First'
                                      : 'Newest First';
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort_rounded,
                                        color: primaryText,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Obx(
                                        () => Text(
                                          historySortOrder.value,
                                          style: TextStyle(
                                            color: primaryText,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showFilterBottomSheet(
                                  context,
                                  isDarkMode,
                                  primaryText,
                                  cardBg,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPink.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: AppColors.primaryPink.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.filter_list_rounded,
                                        color: AppColors.primaryPink,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Obx(
                                        () => Text(
                                          selectedFilter.value,
                                          style: const TextStyle(
                                            color: AppColors.primaryPink,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                          ),
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

                      // History Archives List
                      Obx(() {
                        final items = _filteredHistoryList;
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No history found for selected filter.',
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final hist = items[index];
                            return HistoryCallCard(
                              historyItem: hist,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                            );
                          },
                        );
                      }),

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
}
