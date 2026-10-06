import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/Api/call_api_service.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/CallAgentController.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/call_item_models.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/callreceive/shared_call_screen.dart';

class CallActionHandler {
  // 🟢 कॉल एक्सेप्ट करने का मेथड
  static Future handleAcceptCall(
    BuildContext context,
    IncomingCallItemModel call,
  ) async {
    final CallAgentController controller = Get.find();

    // Firebase पर 'accepted' अपडेट और क्यू से सफाई
    bool isSuccess = await controller.acceptCall(call.id);

    if (isSuccess && context.mounted) {
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
  }

  // 🔴 कॉल डिक्लाइन/रिजेक्ट करने का मेथड
  static Future handleDeclineCall(IncomingCallItemModel call) async {
    final CallAgentController controller = Get.find();

    await controller.declineCall(call.id);
    controller.fetchAndLoadCallHistory();
  }
}
