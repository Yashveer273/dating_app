import 'package:get/get.dart';
import 'package:talk24loves/Api/AppConfig.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentFinancialModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentJobOnOffModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/AgentPayoutDetailsModel.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/models/agent_model.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';

import 'package:talk24loves/screens/userSection/model/user_model.dart';

class UserApiService extends GetConnect {
  final String _userEndpoint = "${AppConfig.rootBaseUrl}/api/userApp/admin";

  final String _authEndpoint = "${AppConfig.rootBaseUrl}/api/commonAuth";

  @override
  void onInit() {
    super.onInit();

    httpClient.defaultContentType = 'application/json';
    httpClient.timeout = const Duration(seconds: 30);
  }

  Future<dynamic> fetchHomeData() async {
    try {
      final response = await get('$_userEndpoint/UseAppHome');
      print("Home API failed: ${response.statusCode}, ${response.body}");
      if (response.statusCode == 200 &&
          response.body is Map &&
          response.body['status'] == true) {
        return response.body['data'];
      }

      return null;
    } catch (e) {
      print("Error fetching home data: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendOtp(String phoneNumber) async {
    try {
      final response = await post(
        '$_authEndpoint/send-otp',
        {'phoneNumber': phoneNumber},
        headers: {'Accept': 'application/json'},
      );

      print("Send OTP Status: ${response.statusCode}");
      print("Send OTP Response: ${response.body}");

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print("Error sending OTP: $e");

      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> verifyAndRegister({
    required String phoneNumber,
    required String verificationId,
    required String otp,
  }) async {
    try {
      final response = await post(
        '$_authEndpoint/verify-and-register',
        {
          'phoneNumber': phoneNumber,
          'verificationId': verificationId,
          'otp': otp,
        },
        headers: {'Accept': 'application/json'},
      );

      print("Verify OTP Status: ${response.statusCode}");
      print("Verify OTP Response: ${response.body}");

      if (response.body is! Map) {
        return {
          'success': false,
          'message': 'Invalid server response',
          'statusCode': response.statusCode,
          'rawResponse': response.body,
        };
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.body,
      );

      if (data['success'] == true) {
        final String? role = data['role']?.toString();

        if (role == 'user') {
          final userData = data['existingUser'];

          if (userData is Map) {
            final userModel = UserModel.fromJson(
              Map<String, dynamic>.from(userData),
              role!,
            );

            await UserStorage.saveUser(userModel);

            print('User model stored successfully');
          }
        } else if (role == 'agent') {
          final agentData = data['existingAgent'];

          if (agentData is Map) {
            final agentJson = Map<String, dynamic>.from(agentData);

            agentJson['role'] = role;

            final agentModel = AgentModel.fromJson(agentJson);

            await AgentStorage.saveAgent(agentModel);

            print('Agent model stored successfully');
          }
        }
      }

      return data;
    } catch (e) {
      print("Error verifying OTP: $e");

      return {'success': false, 'message': e.toString()};
    }
  } // ==========================================

  Future fetchUserProfile() async {
    String userId = AppConfig.user?.id ?? "";
    try {
      if (userId.isNotEmpty) {
        final response = await get(
          '${AppConfig.rootBaseUrl}/api/user/profile/$userId',
          // अपने बैकएंड का सही एंडपॉइंट यहाँ दें
          headers: {'Content-Type': 'application/json'},
        );

        if (response.body["success"]) {
          final data = response.body;
          print("User Profile Data: ${response.body["success"]}");
          final userJson = data['data'];
          print("User JSON: $userJson");
          final userModel = UserModel.fromJson(
            Map<String, dynamic>.from(userJson),
            "user",
          );
          print("User Model: ${userModel.walletBalance} ");
          await UserStorage.saveUser(userModel);

          return userModel;
        } else {
          print("Failed to load user profile: ${response.statusCode}");
          return null;
        }
      } else {
        print("User ID is empty. Cannot fetch profile.");
        return null;
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  Future<bool> updateUserName(String name) async {
    final userId = AppConfig.user?.id ?? "";

    if (userId.isEmpty) {
      print("User ID is empty. Cannot update profile name.");
      return false;
    }

    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/user/profile/$userId',
        {'name': name},
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200 || response.body is! Map) {
        print(
          "Failed to update profile name: ${response.statusCode}, ${response.body}",
        );
        return false;
      }

      final responseData = Map<String, dynamic>.from(response.body);
      if (responseData['success'] != true) {
        print("Profile update failed: $responseData");
        return false;
      }

      final currentUser = AppConfig.user;
      if (currentUser == null) {
        return false;
      }

      final updatedUser = UserModel(
        id: currentUser.id,
        role: currentUser.role,
        phoneNumber: currentUser.phoneNumber,
        phoneVerified: currentUser.phoneVerified,
        name: name,
        avatar: currentUser.avatar,
        walletBalance: currentUser.walletBalance,
        audioCallTimeMinutes: currentUser.audioCallTimeMinutes,
        videoCallTimeMinutes: currentUser.videoCallTimeMinutes,
        status: currentUser.status,
        gender: currentUser.gender,
        matches: currentUser.matches,
        profileCompleted: currentUser.profileCompleted,
        fcmToken: currentUser.fcmToken,
        lastLoginAt: currentUser.lastLoginAt,
        firebaseLocation: currentUser.firebaseLocation,
        createdAt: currentUser.createdAt,
        updatedAt: currentUser.updatedAt,
      );

      await UserStorage.saveUser(updatedUser);
      return true;
    } catch (e) {
      print("Error updating profile name: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> selectGender({
    required String phoneNumber,
    required String gender,
  }) async {
    try {
      final response = await post(
        '$_authEndpoint/select-gender',
        {'phoneNumber': phoneNumber, 'gender': gender},
        headers: {'Accept': 'application/json'},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.body,
      );

      if (data['success'] == true) {
        final String? role = data['role']?.toString();

        if (role == 'user') {
          final userData = data['data'];

          if (userData is Map) {
            final userModel = UserModel.fromJson(
              Map<String, dynamic>.from(userData),
              role!,
            );

            await UserStorage.saveUser(userModel);

            print('User model stored successfully');
            return data;
          }
        } else if (role == 'agent') {
          final agentData = data['data'];

          if (agentData is Map) {
            final agentJson = Map<String, dynamic>.from(agentData);

            agentJson['role'] = role;

            final agentModel = AgentModel.fromJson(agentJson);

            await AgentStorage.saveAgent(agentModel);

            print('Agent model stored successfully');
            return data;
          }
        }
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print("Error selecting gender: $e");

      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // 4. FETCH USER CALL HISTORY (Updated)
  // ==========================================

  Future fetchUserCallHistory({
    int page = 1,
    int limit = 10,
    DateTime? selectedDate,
  }) async {
    String userId = AppConfig.user?.id ?? "";

    try {
      // Format date natively in YYYY-MM-DD format without needing external packages
      String? formattedDate;
      if (selectedDate != null) {
        formattedDate = selectedDate.toIso8601String().split('T')[0];
      }

      // Sending multiple variations to match whatever your backend expects (userId, user_id, or visit.user_id)
      final Map body = {
        "userId": userId,
        "user_id": userId,
        "visit": {"user_id": userId},
        "page": page,
        "limit": limit,
      };

      if (formattedDate != null && formattedDate.isNotEmpty) {
        body["date"] = formattedDate;
      }

      final response = await post(
        '${AppConfig.rootBaseUrl}/api/user-agent-call-logs/user',
        body,
        headers: {'Accept': 'application/json'},
      );

      if (response.body is Map) {
        return Map.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print("Error fetching call history: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<double?> fetchCurrentWalletBalance() async {
    final response = await fetchUserCallHistory(page: 1, limit: 1);
    if (response is Map && response['success'] == true) {
      final balance = response['currentWalletBalance'];
      if (balance is num) return balance.toDouble();
      return double.tryParse(balance?.toString() ?? '');
    }
    return null;
  }

  Future fetchAgentCallHistory({
    int page = 1,
    int limit = 10,
    DateTime? selectedDate,
  }) async {
    String userId = AppConfig.agent?.agentId ?? "";
    try {
      // Format date natively in YYYY-MM-DD format without needing external packages
      String? formattedDate;
      if (selectedDate != null) {
        formattedDate = selectedDate.toIso8601String().split('T')[0];
      }

      // Sending multiple variations to match whatever your backend expects (userId, user_id, or visit.user_id)
      final Map body = {
        "agentId": userId,
        "agent_id": userId,
        "visit": {"user_id": userId},
        "page": page,
        "limit": limit,
      };

      if (formattedDate != null && formattedDate.isNotEmpty) {
        body["date"] = formattedDate;
      }

      final response = await post(
        '${AppConfig.rootBaseUrl}/api/user-agent-call-logs/agent',
        body,
        headers: {'Accept': 'application/json'},
      );

      if (response.body is Map) {
        var res = Map.from(response.body);

        return res;
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print("Error fetching call history: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // AGENT APIs
  // Base: /api/agents
  // All agent APIs require Authorization: Bearer <agent-token>
  // ==========================================

  Map<String, String> _agentHeaders() {
    String agentToken = AppConfig.agent?.authToken ?? "";
    return {
      'Accept': 'application/json',

      'Authorization': 'Bearer $agentToken',
    };
  }

  Future<AgentJobOnOffModel?> changeJobOnOffStatus(bool isOnline) async {
    String userId = AppConfig.agent?.id ?? "";

    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/agents/me/job-on-off/$userId?isOnline=$isOnline',
        {},
        headers: _agentHeaders(),
      );
      print("Agent jobOnOff Details Response: ${response.body}");
      if (response.body is Map && response.body['success'] == true) {
        final responseData = Map<String, dynamic>.from(response.body);
        final data = responseData['data'];
        if (data is Map) {
          return AgentJobOnOffModel.fromJson(Map<String, dynamic>.from(data));
        }
      }

      return null;
    } catch (e) {
      print('Error changing agent jobOnOff status: $e');
      return null;
    }
  }

  Future<AgentJobOnOffModel?> getJobOnOffStatus() async {
    String userId = AppConfig.agent?.id ?? "";

    try {
      final response = await get(
        '${AppConfig.rootBaseUrl}/api/agents/me/job-on-off/$userId',
        headers: _agentHeaders(),
      );
      print("Agent jobOnOff Details Response: ${response.body}");
      if (response.body is Map && response.body['success'] == true) {
        final responseData = Map<String, dynamic>.from(response.body);
        final data = responseData['data'];
        if (data is Map) {
          return AgentJobOnOffModel.fromJson(Map<String, dynamic>.from(data));
        }
      }

      return null;
    } catch (e) {
      print('Error fetching agent jobOnOff status: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchcatagories() async {
    try {
      final response = await get(
        '${AppConfig.rootBaseUrl}/api/agents/admin/category',
        headers: _agentHeaders(),
      );
      print("category Details Response: ${response.body}");
      if (response.body is Map &&
          (response.body['success'] == true ||
              response.body['status'] == true)) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error fetching agent financial details: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAgentFinancialsDetails() async {
    String userId = AppConfig.agent?.id ?? "";
    print("Fetching financial details for agent ID: $userId");
    try {
      final response = await get(
        '${AppConfig.rootBaseUrl}/api/agents/me/financialsDetails/$userId',
        headers: _agentHeaders(),
      );
      print("Agent Financials Details Response: ${response.body}");
      if (response.body['success'] == true && response.body is Map) {
        final Map<String, dynamic> responseData = Map<String, dynamic>.from(
          response.body,
        );

        final financialData = responseData['data'];
        if (financialData is Map) {
          final model = AgentFinancialModel.fromJson(
            Map<String, dynamic>.from(financialData),
          );

          return model.toJson();
        }
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error fetching agent financial details: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAgentProfileName({
    required String displayName,
  }) async {
    String userId = AppConfig.agent?.id ?? "";
    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/agents/me/profile/$userId',
        {'displayName': displayName},
        headers: _agentHeaders(),
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error updating agent profile name: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAgentTopics({
    required List<String> topics,
  }) async {
    if (topics.isEmpty) {
      return {'success': false, 'message': 'Topics must be a non-empty array'};
    }
    String userId = AppConfig.agent?.id ?? "";
    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/agents/me/topics/$userId',
        {'topics': topics},
        headers: _agentHeaders(),
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error updating agent topics: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAgentLanguages({
    required List<String> languages,
  }) async {
    if (languages.isEmpty) {
      return {
        'success': false,
        'message': 'Languages must be a non-empty array',
      };
    }
    String userId = AppConfig.agent?.id ?? "";
    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/agents/me/languages/$userId',
        {'languages': languages},
        headers: _agentHeaders(),
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error updating agent languages: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAgentCategory({
    required String category,
  }) async {
    String userId = AppConfig.agent?.id ?? "";
    try {
      final response = await put(
        '${AppConfig.rootBaseUrl}/api/agents/me/category/$userId',
        {'category': category},
        headers: {..._agentHeaders(), 'Content-Type': 'application/json'},
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error updating agent category: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAgentPayoutDetails({
    String? upiId,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
  }) async {
    if (upiId == null || upiId.trim().isEmpty) {
      return {
        'success': false,
        'message': 'UPI ID is required',
        'statusCode': 400,
      };
    }

    // Validate that each value is strictly less than 30 characters
    final values = {
      'upiId': upiId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
    };

    for (var entry in values.entries) {
      if (entry.value != null && entry.value!.trim().length >= 30) {
        return {
          'success': false,
          'message': '${entry.key} must be under 30 characters',
          'statusCode': 400,
        };
      }
    }

    String userId = AppConfig.agent?.id ?? "";
    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'Agent ID is missing',
        'statusCode': 400,
      };
    }

    try {
      // Build URI with query parameters
      final uri =
          Uri.parse(
            '${AppConfig.rootBaseUrl}/api/agents/me/payout-details/$userId',
          ).replace(
            queryParameters: {
              'upiId': upiId.trim(),
              if (accountHolderName != null &&
                  accountHolderName.trim().isNotEmpty)
                'accountHolderName': accountHolderName.trim(),
              if (accountNumber != null && accountNumber.trim().isNotEmpty)
                'accountNumber': accountNumber.trim(),
              if (ifscCode != null && ifscCode.trim().isNotEmpty)
                'ifscCode': ifscCode.trim(),
              if (bankName != null && bankName.trim().isNotEmpty)
                'bankName': bankName.trim(),
            },
          );

      final response = await put(
        uri.toString(),
        {},
        headers: {'Accept': 'application/json'},
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error updating agent payout details: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<AgentPayoutDetailsModel?> fetchAgentPayoutDetails() async {
    String userId = AppConfig.agent?.id ?? "";
    try {
      final response = await get(
        '${AppConfig.rootBaseUrl}/api/agents/me/payout-details/$userId',
        headers: _agentHeaders(),
      );

      if (response.body is! Map) return null;

      final responseData = Map<String, dynamic>.from(response.body);
      if (responseData['success'] == false) return null;

      final data = responseData['data'];
      final payoutData = data is Map ? data['payoutDetails'] : null;
      final detailsData = payoutData is Map ? payoutData : data;

      if (detailsData is! Map) return null;

      return AgentPayoutDetailsModel.fromJson(
        Map<String, dynamic>.from(detailsData),
      );
    } catch (e) {
      print('Error fetching agent payout details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> requestAgentWithdrawal({
    required double amount,
    required String upiId,
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
  }) async {
    String userId = AppConfig.agent?.id ?? "";

    if (userId.isEmpty) {
      return {
        'success': false,
        'message': 'Agent ID is required',
        'statusCode': 400,
      };
    }

    final body = <String, dynamic>{
      'amount': amount,
      'upiId': upiId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
    };

    try {
      final response = await post(
        '${AppConfig.rootBaseUrl}/api/agents/me/withdrawals',
        body,
        headers: _agentHeaders(),
      );

      if (response.body is Map) {
        return Map<String, dynamic>.from(response.body);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
        'statusCode': response.statusCode,
        'rawResponse': response.body,
      };
    } catch (e) {
      print('Error requesting agent withdrawal: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
