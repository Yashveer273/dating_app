// ==========================================
// earnings_dashboard_page.dart (Clean & Corrected)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_background.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/AgentPayoutController.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/ledger_controller.dart.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentPayoutDetailsModel.dart';

class WithdrawScreen extends StatefulWidget {
  WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
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
                    keyboardType: TextInputType.number,
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
                    onPressed: () async {
                      final amt = double.tryParse(amountController.text) ?? 0.0;
                      await controller.requestWithdrawal(amt);
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

class BankDetailsSection extends StatefulWidget {
  const BankDetailsSection({super.key});

  @override
  State<BankDetailsSection> createState() => _BankDetailsSectionState();
}

class _BankDetailsSectionState extends State<BankDetailsSection> {
  final LedgerController controller = Get.find();
  final AgentPayoutController payoutController = Get.put(
    AgentPayoutController(),
  );
  final UserApiService apiService = Get.put(UserApiService());
  final ThemeController themeController = Get.find();
  late final TextEditingController upiController = TextEditingController();
  late final TextEditingController accountNumController =
      TextEditingController();
  late final TextEditingController ifscController = TextEditingController();
  late final TextEditingController holderController = TextEditingController();
  late final TextEditingController bankNameController = TextEditingController();

  bool get isDarkMode => themeController.isDarkMode;

  Color get primaryText =>
      isDarkMode ? Colors.white : AppColors.lightPrimaryText;
  Color get secondaryText =>
      isDarkMode ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

  @override
  void initState() {
    super.initState();
    payoutController.loadPayoutDetails();
  }

  @override
  void dispose() {
    upiController.dispose();
    accountNumController.dispose();
    ifscController.dispose();
    holderController.dispose();
    bankNameController.dispose();
    super.dispose();
  }

  void _populateControllers(AgentPayoutDetailsModel details) {
    upiController.text = details.upiId;
    holderController.text = details.accountHolderName;
    accountNumController.text = details.accountNumber;
    ifscController.text = details.ifscCode;
    bankNameController.text = details.bankName;
    controller.loadBankDetails(
      upiId: details.upiId,
      accountNumber: details.accountNumber,
      ifscCode: details.ifscCode,
      accountHolderName: details.accountHolderName,
      bankName: details.bankName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Color cardBg = isDarkMode ? AppColors.darkCard : Colors.white;
      final Color fillColor = isDarkMode ? AppColors.darkBgMid : Colors.white;
      final Color borderColor = isDarkMode
          ? AppColors.darkBorder
          : AppColors.lightBorder;
      final payoutDetails = payoutController.payoutDetails.value;

      if (payoutDetails != null) {
        _populateControllers(payoutDetails);
      }

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
            if (payoutController.isLoading.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
              )
            else if (payoutController.errorMessage.value.isNotEmpty)
              Text(
                payoutController.errorMessage.value,
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              )
            else
              Column(
                children: [
                  _buildTextField(
                    'UPI ID',
                    upiController,
                    fillColor,
                    borderColor,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 255,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Account Holder Name',
                    holderController,
                    fillColor,
                    borderColor,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Account Number',
                    accountNumController,
                    fillColor,
                    borderColor,
                    keyboardType: TextInputType.number,
                    maxLength: 18,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'IFSC Code',
                    ifscController,
                    fillColor,
                    borderColor,
                    keyboardType: TextInputType.text,
                    maxLength: 11,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Bank Name',
                    bankNameController,
                    fillColor,
                    borderColor,
                    maxLength: 100,
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
                      onPressed: () async {
                        final upiId = upiController.text.trim();
                        if (upiId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your UPI ID'),
                            ),
                          );
                          return;
                        }

                        if (accountNumController.text.isNotEmpty &&
                            ifscController.text.isNotEmpty) {
                          final saved = await payoutController
                              .savePayoutDetails(
                                upiId: upiId,
                                accountHolderName: holderController.text.trim(),
                                accountNumber: accountNumController.text.trim(),
                                ifscCode: ifscController.text
                                    .trim()
                                    .toUpperCase(),
                                bankName: bankNameController.text.trim(),
                              );

                          if (saved) {
                            controller.saveBankDetails(
                              accountNumber: accountNumController.text.trim(),
                              ifscCode: ifscController.text
                                  .trim()
                                  .toUpperCase(),
                              accountHolderName: holderController.text.trim(),
                              bankName: bankNameController.text.trim(),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Save Bank Details',
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
    int? maxLength,
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
        maxLength: 40,
        style: TextStyle(
          color: primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: secondaryText, fontSize: 12),
          counterText: "", // 👈 Hides the character count UI below the field
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: borderColor, width: 1),
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
