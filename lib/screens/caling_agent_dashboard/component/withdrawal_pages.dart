// ==========================================
// earnings_dashboard_page.dart (Clean & Corrected)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/ledger_controller.dart.dart';

class EarningsDashboardPage extends StatelessWidget {
  EarningsDashboardPage({super.key}) {
    controller.ensureSampleData();
  }

  final LedgerController controller = Get.find();
  final ThemeController themeController = Get.find();

  bool get isDarkMode => themeController.isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AppBackground(
        isDarkMode: isDarkMode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Obx(() {
              final Color cardBg = isDarkMode
                  ? AppColors.darkCard
                  : Colors.white;
              final Color textColor = isDarkMode
                  ? Colors.white
                  : AppColors.lightPrimaryText;
              final Color subText = isDarkMode
                  ? AppColors.darkSecondaryText
                  : AppColors.lightSecondaryText;
              final Color borderColor = isDarkMode
                  ? AppColors.darkBorder
                  : AppColors.lightBorder;

              final payoutList = controller.filteredPayoutHistory;
              final hasDateFilter = controller.selectedFilterDateValue != null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar with Back, Sort & Date Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 18,
                                color: textColor,
                              ),
                              onPressed: () => Get.back(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Payout Requests & Status',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Newest / Oldest Sort Button
                            InkWell(
                              onTap: () => controller.toggleSortOrder(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sort_rounded,
                                      size: 14,
                                      color: AppColors.primaryPink,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      controller.isAscendingSort.value
                                          ? 'Oldest'
                                          : 'Newest',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Calendar Filter Button
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      controller.selectedFilterDateValue ??
                                      DateTime.now(),
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: isDarkMode
                                          ? ThemeData.dark()
                                          : ThemeData.light(),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  controller.setDateFilter(picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: hasDateFilter
                                      ? AppColors.primaryPink.withOpacity(0.1)
                                      : cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasDateFilter
                                        ? AppColors.primaryPink
                                        : borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: AppColors.primaryPink,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasDateFilter ? 'Filtered' : 'Date',
                                      style: TextStyle(
                                        color: hasDateFilter
                                            ? AppColors.primaryPink
                                            : textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (hasDateFilter) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () =>
                                            controller.clearDateFilter(),
                                        child: const Icon(
                                          Icons.close,
                                          size: 12,
                                          color: AppColors.primaryPink,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: borderColor, height: 1),

                  // Main List Area
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Status Filter Tabs (All Requests, Pending, Accepted, Rejected)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusTabBadge(
                                'All Requests',
                                cardBg,
                                borderColor,
                                subText,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusTabBadge(
                                'Pending',
                                cardBg,
                                borderColor,
                                subText,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusTabBadge(
                                'Accepted',
                                cardBg,
                                borderColor,
                                subText,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusTabBadge(
                                'Rejected',
                                cardBg,
                                borderColor,
                                subText,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // List Items
                        payoutList.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 36,
                                      color: subText,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No payout requests found.',
                                      style: TextStyle(
                                        color: subText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: payoutList.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final record = payoutList[index];

                                  Color statusColor = Colors.green;
                                  Color statusBg = Colors.green.withOpacity(
                                    0.1,
                                  );
                                  if (record.status.toLowerCase() ==
                                      'pending') {
                                    statusColor = Colors.orangeAccent;
                                    statusBg = Colors.orangeAccent.withOpacity(
                                      0.1,
                                    );
                                  } else if (record.status.toLowerCase() ==
                                      'rejected') {
                                    statusColor = AppColors.primaryPink;
                                    statusBg = AppColors.primaryPink
                                        .withOpacity(0.1);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              record.id,
                                              style: TextStyle(
                                                color: subText,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusBg,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                record.status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${record.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                            Text(
                                              record.bankName,
                                              style: TextStyle(
                                                color: subText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Divider(color: borderColor, height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 12,
                                                  color: subText,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  record.formattedTimestamp,
                                                  style: TextStyle(
                                                    color: subText,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabBadge(
    String title,
    Color cardBg,
    Color borderColor,
    Color subText,
  ) {
    final bool isSelected = controller.selectedStatusFilter.value == title;
    return InkWell(
      onTap: () => controller.updateStatusFilter(title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : borderColor,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : subText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class WithdrawScreen extends StatelessWidget {
  WithdrawScreen({super.key});

  final LedgerController controller = Get.find();
  final ThemeController themeController = Get.find();
  final TextEditingController amountController = TextEditingController();

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? Colors.white : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  @override
  Widget build(BuildContext context) {
    amountController.text = controller.pendingIncome.toStringAsFixed(0);

    return Obx(() {
      final Color cardBg = isDarkMode ? AppColors.darkCard : Colors.white;
      final Color fillColor = isDarkMode ? AppColors.darkBgMid : Colors.white;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      return AppBackground(
        isDarkMode: isDarkMode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: primaryText),
            title: Text(
              'Request Payout',
              style: TextStyle(
                color: primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BankDetailsSection(),
                const SizedBox(height: 20),
                Text(
                  'Withdrawal Amount (₹)',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: TextField(
                    controller: amountController,
                    style: TextStyle(color: primaryText, fontSize: 12),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: AppColors.primaryPink,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    onPressed: () {
                      final amt = double.tryParse(amountController.text) ?? 0.0;
                      controller.requestWithdrawal(amt);
                    },
                    child: const Text(
                      'Submit Payout Request',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
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

class BankDetailsSection extends StatelessWidget {
  BankDetailsSection({super.key});

  final LedgerController controller = Get.find();
  final ThemeController themeController = Get.find();
  final TextEditingController accountNumController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();
  final TextEditingController holderController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? Colors.white : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  @override
  Widget build(BuildContext context) {
    if (controller.savedBankDetails.value != null) {
      final b = controller.savedBankDetails.value!;
      holderController.text = b.accountHolderName;
      accountNumController.text = b.accountNumber;
      ifscController.text = b.ifscCode;
      bankNameController.text = b.bankName;
    }

    return Obx(() {
      final Color cardBg = isDarkMode ? AppColors.darkCard : Colors.white;
      final Color fillColor = isDarkMode ? AppColors.darkBgMid : Colors.white;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Account Details',
              style: TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              'Account Holder Name',
              holderController,
              fillColor,
              borderColor,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Account Number',
              accountNumController,
              fillColor,
              borderColor,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'IFSC Code',
              ifscController,
              fillColor,
              borderColor,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Bank Name',
              bankNameController,
              fillColor,
              borderColor,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  if (accountNumController.text.isNotEmpty &&
                      ifscController.text.isNotEmpty) {
                    controller.saveBankDetails(
                      accountNumber: accountNumController.text.trim(),
                      ifscCode: ifscController.text.trim().toUpperCase(),
                      accountHolderName: holderController.text.trim(),
                      bankName: bankNameController.text.trim(),
                    );
                  }
                },
                child: const Text(
                  'Save / Update Bank Details',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    Color fillColor,
    Color borderColor, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: primaryText, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: secondaryText, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: AppColors.primaryPink,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
