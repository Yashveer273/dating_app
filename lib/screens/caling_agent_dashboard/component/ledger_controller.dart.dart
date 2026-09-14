// ==========================================
// ledger_controller.dart (Updated for Organization Payout Ledger)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/ledger_models.dart';

class LedgerController extends GetxController {
  // --- Earnings & Withdrawal State (Paid by Organization) ---
  RxDouble audioCallEarnings = 850.00.obs;
  RxDouble videoCallEarnings = 650.00.obs;

  // Updated short talk time format ('1hr 30m')
  RxString pendingAudioTalkTime = '1hr 30m'.obs;
  RxString pendingVideoTalkTime = '0hr 45m'.obs;

  final double minimumWithdrawalLimit = 1000.00;
  Rx savedBankDetails = Rx(null);
  RxList withdrawalHistory = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAgentEarningsFromServer();
    _loadSampleData();
  }

  // ==========================================
  // SIMULATED BACKEND API INTEGRATION
  // ==========================================
  Future fetchAgentEarningsFromServer() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error fetching agent earnings from server: $e');
    }
  }

  void _loadSampleData() {
    withdrawalHistory.value = [
      WithdrawalRecord(
        id: 'w1',
        amount: 1200.0,
        formattedTimestamp: '10 Oct 2026, 04:30 PM',
        status: 'Success',
        bankName: 'State Bank of India',
        paidAudioTime: '5hr 0m',
        paidVideoTime: '3hr 0m',
        audioEarnings: 700.0,
        videoEarnings: 500.0,
      ),
    ];
  }

  double get pendingIncome => audioCallEarnings.value + videoCallEarnings.value;
  bool get canWithdraw => pendingIncome >= minimumWithdrawalLimit;

  void saveBankDetails({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    required String bankName,
  }) {
    savedBankDetails.value = BankDetails(
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      accountHolderName: accountHolderName,
      bankName: bankName,
    );

    Get.snackbar(
      'Bank Details Saved',
      'Your bank account info has been successfully updated.',
      backgroundColor: AppColors.darkCard,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  void requestWithdrawal(double amount) {
    if (!canWithdraw) {
      Get.snackbar(
        'Minimum Limit Required',
        'You need at least ₹${minimumWithdrawalLimit.toStringAsFixed(0)} pending earnings to request a withdrawal.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (savedBankDetails.value == null) {
      Get.snackbar(
        'Bank Details Missing',
        'Please link your bank account before requesting a withdrawal.',
        backgroundColor: AppColors.primaryPink,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (amount > pendingIncome) {
      Get.snackbar(
        'Invalid Amount',
        'Withdrawal amount cannot exceed pending available income.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final String settledAudio = pendingAudioTalkTime.value;
    final String settledVideo = pendingVideoTalkTime.value;
    final double settledAudioEarnings = audioCallEarnings.value;
    final double settledVideoEarnings = videoCallEarnings.value;

    // Reset pending current cycle earnings and strings
    audioCallEarnings.value = 0.0;
    videoCallEarnings.value = 0.0;
    pendingAudioTalkTime.value = '0hr 0m';
    pendingVideoTalkTime.value = '0hr 0m';

    withdrawalHistory.insert(
      0,
      WithdrawalRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        formattedTimestamp: '14 Sep 2026, 10:17 PM',
        status: 'Success',
        bankName: savedBankDetails.value!.bankName,
        paidAudioTime: settledAudio,
        paidVideoTime: settledVideo,
        audioEarnings: settledAudioEarnings,
        videoEarnings: settledVideoEarnings,
      ),
    );

    Get.back();
    Get.snackbar(
      'Withdrawal Requested',
      'Successfully withdrew ₹\({amount.toStringAsFixed(2)} to\){savedBankDetails.value!.bankName}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
