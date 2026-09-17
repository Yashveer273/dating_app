// services/call_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:talk24loves/Api/AppConfig.dart';

class CallApiService {
  static const String baseUrl = "${AppConfig.rootBaseUrl}/api/call";

  // Real static IDs provided for testing / fallback
  static const String staticUserId = "6aaaa3f6af9ef557a3820e05";
  static const String staticAgentId = "4F115683";

  static Future<Map<String, dynamic>> requestCall({
    required String callType, // 'audio' or 'video'
    String? customUserId,
    String? customAgentId,
    String? customUserName,
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
        }),
      );

      final data = jsonDecode(response.body);
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
          "roomId": roomId,
          "agentId": customAgentId ?? staticAgentId,
        }),
      );
      return jsonDecode(response.body);
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
          "roomId": roomId,
          "agentId": customAgentId ?? staticAgentId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
