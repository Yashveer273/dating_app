// ==========================================
// withdrawal_pages.dart (Displays Payout & Organization Earnings History)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/ledger_controller.dart.dart';

class EarningsDashboardPage extends StatelessWidget {
  EarningsDashboardPage({super.key});

  final LedgerController controller = Get.find();
  final ThemeController themeController = Get.find();

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? Colors.white : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Color cardBg = isDarkMode ? AppColors.darkCard : Colors.white;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;

      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBgTop : Colors.white,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: isDarkMode ? 0 : 1,
          iconTheme: IconThemeData(color: primaryText),
          title: Text(
            'Agent Earnings & Payouts',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENDING WITHDRAWABLE INCOME',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.withdrawalHistory.isEmpty
                          ? 'Last Payout: None'
                          : 'Last Payout: ${controller.withdrawalHistory.first.formattedTimestamp}',
                      style: TextStyle(color: secondaryText, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${controller.pendingIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.canWithdraw
                          ? 'Minimum threshold met (₹1000+). Ready for withdrawal.'
                          : 'Min. ₹1000 required to withdraw.',
                      style: TextStyle(
                        color: controller.canWithdraw
                            ? Colors.green
                            : AppColors.primaryPink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        onPressed: () => Get.to(() => WithdrawScreen()),
                        child: const Text(
                          'Withdraw Funds',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pending Cycle Talk Time & Breakdown',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 12),
              _buildBreakdownCard(
                title: 'Audio Call (Pending Settlement)',
                earnings: controller.audioCallEarnings.value,
                talkTime: controller.pendingAudioTalkTime.value,
                icon: Icons.phone_in_talk_rounded,
                accentColor: Colors.blueAccent,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
              const SizedBox(height: 10),
              _buildBreakdownCard(
                title: 'Video Call (Pending Settlement)',
                earnings: controller.videoCallEarnings.value,
                talkTime: controller.pendingVideoTalkTime.value,
                icon: Icons.videocam_rounded,
                accentColor: AppColors.primaryPink,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Payout History',
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 12),
              controller.withdrawalHistory.isEmpty
                  ? Text(
                      'No past payout history found.',
                      style: TextStyle(color: secondaryText, fontSize: 11),
                    )
                  : ListView.builder(
                      itemCount: controller.withdrawalHistory.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final record = controller.withdrawalHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Bank: ${record.bankName}',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total: ₹${record.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Paid Date: ${record.formattedTimestamp}',
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Success',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: borderColor, height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_in_talk_rounded,
                                    size: 13,
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Audio Call Share',
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${record.audioEarnings.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.videocam_rounded,
                                    size: 13,
                                    color: AppColors.primaryPink,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Video Call Share',
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${record.videoEarnings.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
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
      );
    });
  }

  Widget _buildBreakdownCard({
    required String title,
    required double earnings,
    required String talkTime,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Talk Time: $talkTime',
                  style: TextStyle(color: secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '₹${earnings.toStringAsFixed(2)}',
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
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

      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBgTop : Colors.white,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: isDarkMode ? 0 : 1,
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
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
