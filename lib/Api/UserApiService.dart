import 'package:get/get.dart';
import 'package:talk24loves/Api/AppConfig.dart';

class UserApiService extends GetConnect {
  final String _userEndpoint = "${AppConfig.rootBaseUrl}/api/userApp/admin";

  final String _authEndpoint = "${AppConfig.rootBaseUrl}/api/commonAuth";

  @override
  void onInit() {
    super.onInit();

    httpClient.defaultContentType = 'application/json';
    httpClient.timeout = const Duration(seconds: 30);
  }

  // ==========================================
  // HOME DATA
  // ==========================================

  Future<dynamic> fetchHomeData() async {
    try {
      final response = await get('$_userEndpoint/UseAppHome');

      if (response.statusCode == 200 &&
          response.body is Map &&
          response.body['status'] == true) {
        return response.body['data'];
      }

      print("Home API failed: ${response.statusCode}, ${response.body}");

      return null;
    } catch (e) {
      print("Error fetching home data: $e");
      return null;
    }
  }

  // ==========================================
  // 1. SEND OTP
  // POST /api/commonAuth/send-otp
  //
  // BODY:
  // {
  //   "phoneNumber": "+919876543210"
  // }
  // ==========================================

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

  // ==========================================
  // 2. VERIFY OTP
  // POST /api/commonAuth/verify-and-register
  //
  // IMPORTANT:
  // Backend expects ONLY:
  //
  // {
  //   "phoneNumber": "+919876543210",
  //   "otp": "1234"
  // }
  //
  // verificationId is NOT used by the backend.
  // ==========================================

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
      print("Error verifying OTP: $e");

      return {'success': false, 'message': e.toString()};
    }
  }
  // ==========================================
  // 3. SELECT GENDER & REGISTER
  // POST /api/commonAuth/select-gender
  //
  // BODY:
  // {
  //   "phoneNumber": "+919876543210",
  //   "gender": "male"
  // }
  //
  // male   -> User
  // female -> Agent
  // ==========================================

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

      print("Select Gender Status: ${response.statusCode}");
      print("Select Gender Response: ${response.body}");

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
      print("Error selecting gender: $e");

      return {'success': false, 'message': e.toString()};
    }
  }
}
