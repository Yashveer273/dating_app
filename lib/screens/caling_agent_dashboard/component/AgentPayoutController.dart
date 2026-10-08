import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentPayoutDetailsModel.dart';

import 'models/AgentFinancialModel.dart';

class AgentPayoutController extends GetxController {
  final UserApiService _apiService = Get.put(UserApiService());

  Rx<AgentPayoutDetailsModel?> payoutDetails = Rx<AgentPayoutDetailsModel?>(
    null,
  );
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  final double minimumWithdrawalLimit = 1000.00;
  final AgentFinancialModel? agentFinancials = AgentFinancialModel.current;
  bool get canWithdraw =>
      agentFinancials!.walletBalance >= minimumWithdrawalLimit;
  Future<void> loadPayoutDetails() async {
    isLoading.value = true;
    errorMessage.value = '';

    final details = await _apiService.fetchAgentPayoutDetails();
    printInfo(info: "$details-----------");
    isLoading.value = false;

    if (details == null) {
      errorMessage.value = 'Unable to load payout details.';
      return;
    }

    payoutDetails.value = details;
  }

  Future<bool> savePayoutDetails({
    required String upiId,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    try {
      final response = await _apiService.updateAgentPayoutDetails(
        upiId: upiId,
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        bankName: bankName,
      );
      printInfo(info: "$response");
      if (response['success'] != true) {
        print(
          'Agent payout update failed: ${response['message'] ?? 'Unknown error'} '
          '(statusCode: ${response['statusCode'] ?? 'unknown'})',
        );
        return false;
      }

      payoutDetails.value = AgentPayoutDetailsModel.fromJson(
        Map<String, dynamic>.from(
          response['data']["payoutDetails"] ?? response,
        ),
      );
      return true;
    } catch (e) {
      print('Error updating agent payout details: $e');
      return false;
    }
  }
}
