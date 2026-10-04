// ==========================================
// ledger_controller.dart (Fully Corrected & Error-Free)
// ==========================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/ledger_models.dart';

class LedgerController extends GetxController {
  // --- Earnings & Withdrawal State ---
  RxDouble audioCallEarnings = 0.0.obs;
  RxDouble videoCallEarnings = 0.0.obs;
  RxDouble walletBalance = 0.0.obs;
  RxDouble totalEarned = 0.0.obs;
  RxInt audioCallDurationSeconds = 0.obs;
  RxInt videoCallDurationSeconds = 0.obs;
  RxBool isLoadingEarnings = false.obs;
  RxString earningsError = ''.obs;
  final UserApiService _apiService = Get.put(UserApiService());
  RxString pendingAudioTalkTime = '0hr 0m'.obs;
  RxString pendingVideoTalkTime = '0hr 0m'.obs;
  final double minimumWithdrawalLimit = 1000.00;
  Rx savedBankDetails = Rx(
    null,
  ); // Strongly typed list with WithdrawalRecord containing 'timestamp' (DateTime)
  RxList withdrawalHistory = [].obs; // --- Filtering & Sorting State ---
  RxString selectedStatusFilter =
      'All Requests'.obs; // 'All Requests', 'Pending', 'Accepted', 'Rejected'
  RxBool isAscendingSort =
      false.obs; // false = Newest first, true = Oldest first
  final Rxn selectedFilterDate = Rxn();

  DateTime? get selectedFilterDateValue {
    final value = selectedFilterDate.value;
    return value is DateTime ? value : null;
  }

  void onInit() {
    super.onInit();
    ensureSampleData();
  }

  Future fetchAgentEarningsFromServer() async {
    isLoadingEarnings.value = true;
    earningsError.value = '';
    try {
      final response = await _apiService.fetchAgentEarnings();
      final data = response?['data'];
      if (response?['success'] != true || data is! Map) {
        earningsError.value =
            response?['message']?.toString() ?? 'Unable to load earnings.';
        return;
      }

      walletBalance.value = _numberValue(data['walletBalance']);
      totalEarned.value = _numberValue(data['totalEarned']);
      audioCallDurationSeconds.value = _numberValue(
        data['audioCallDurationSeconds'],
      ).round();
      audioCallEarnings.value = _numberValue(data['audioCallEarnings']);
      videoCallDurationSeconds.value = _numberValue(
        data['videoCallDurationSeconds'],
      ).round();
      videoCallEarnings.value = _numberValue(data['videoCallEarnings']);

      pendingAudioTalkTime.value = formatCallDuration(
        audioCallDurationSeconds.value,
      );
      pendingVideoTalkTime.value = formatCallDuration(
        videoCallDurationSeconds.value,
      );
    } catch (e) {
      debugPrint('Error fetching agent earnings: $e');
      earningsError.value = 'Unable to load earnings.';
    } finally {
      isLoadingEarnings.value = false;
    }
  }

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String formatCallDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    // Safe and clean string interpolation without compilation issues
    return '$hours hr $minutes m';
  }

  void _loadSampleData() {
    withdrawalHistory.assignAll(WithdrawalRecord.testData);
  } // --- Filter and Sort Getter ---

  void ensureSampleData() {
    if (withdrawalHistory.isEmpty) {
      _loadSampleData();
    }
  }

  List get filteredPayoutHistory {
    List list = List.from(
      withdrawalHistory,
    ); // 1. Status Filter ('All Requests', 'Pending', 'Accepted', 'Rejected')
    if (selectedStatusFilter.value != 'All Requests') {
      list = list.where((item) {
        return item.status.toLowerCase() ==
            selectedStatusFilter.value.toLowerCase();
      }).toList();
    }

    // 2. Date Filter using DateTime timestamp
    final DateTime? target = selectedFilterDateValue;
    if (target != null) {
      list = list.where((item) {
        final timestamp = item.timestamp;
        return timestamp is DateTime &&
            timestamp.year == target.year &&
            timestamp.month == target.month &&
            timestamp.day == target.day;
      }).toList();
    }

    // 3. Sorting Logic (Newest vs Oldest using actual DateTime object comparison)
    list.sort((a, b) {
      final aTimestamp = a.timestamp;
      final bTimestamp = b.timestamp;
      if (aTimestamp == null) return bTimestamp == null ? 0 : 1;
      if (bTimestamp == null) return -1;

      if (isAscendingSort.value) {
        return aTimestamp.compareTo(bTimestamp); // Oldest first
      } else {
        return bTimestamp.compareTo(aTimestamp); // Newest first (default)
      }
    });

    return list;
  }

  void updateStatusFilter(String status) {
    selectedStatusFilter.value = status;
  }

  void toggleSortOrder() {
    isAscendingSort.value = !isAscendingSort.value;
  }

  void setDateFilter(DateTime date) {
    selectedFilterDate.value = date;
  }

  void clearDateFilter() {
    selectedFilterDate.value = null;
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

    audioCallEarnings.value = 0.0;
    videoCallEarnings.value = 0.0;
    pendingAudioTalkTime.value = '0hr 0m';
    pendingVideoTalkTime.value = '0hr 0m';

    final DateTime now = DateTime.now();
    final List months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final int hour12 = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final String minuteStr = now.minute.toString().padLeft(2, '0');
    final String amPm = now.hour >= 12 ? 'PM' : 'AM';

    // Safely formatted timestamp string avoiding any compiler string interpolation bugs
    final String formattedTime =
        '${now.day}${months[now.month - 1]} ${now.year},$hour12:$minuteStr$amPm';

    withdrawalHistory.insert(
      0,
      WithdrawalRecord(
        id: 'REQ-${now.millisecondsSinceEpoch.toString().substring(5)}',
        amount: amount,
        timestamp: now, // DateTime object preserved for filtering and sorting
        formattedTimestamp: formattedTime,
        status: 'Pending',
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
      'Successfully requested ₹${amount.toStringAsFixed(2)} to ${savedBankDetails.value!.bankName}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
