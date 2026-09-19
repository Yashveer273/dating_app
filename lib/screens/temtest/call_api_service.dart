// services/call_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talk24loves/Api/AppConfig.dart';

class CallApiService {
  static const String baseUrl = "${AppConfig.rootBaseUrl}/api/call";

  static const String staticUserId = "6aaaa3f6af9ef557a3820e05";
  static const String staticAgentId = "4F115683";

  static Future<Map<String, dynamic>> requestCall({
    required String callType,
    String? customUserId,
    String? customAgentId,
    String? customUserName,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": customUserId ?? staticUserId,
          "agentId": customAgentId ?? staticAgentId,
          "callType": callType,
          "userName": customUserName ?? "Test User",
          "avatarUrl": avatarUrl ?? "",
        }),
      );

      final data = jsonDecode(response.body);

      // Backend se callId milne par use roomId ke taur par bhi map karna
      if (data['callId'] != null && data['roomId'] == null) {
        data['roomId'] = data['callId'];
      }
      return data;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> acceptCall({
    required String roomId,
    String? customAgentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/accept'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "callId": roomId, // Backend callId expect karta hai
          "agentId": customAgentId ?? staticAgentId,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['callId'] != null && data['roomId'] == null) {
        data['roomId'] = data['callId'];
      }
      return data;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> endCall({
    required String roomId,
    String? customAgentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/end'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "callId": roomId, // Backend callId expect karta hai
          "agentId": customAgentId ?? staticAgentId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // services/call_api_service.dart mein yeh method add karein:
  static Future<bool> resetAgentState(String agentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-agent'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"agentId": agentId}),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      print("Error calling resetAgentState API: $e");
      return false;
    }
  }
}
