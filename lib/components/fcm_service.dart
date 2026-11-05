import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'package:talk24loves/Api/UserApiService.dart';

class FCMService {
  static final GetStorage _storage = GetStorage();
  static const String _fcmTokenKey = 'fcm_device_token';
  static const String _fcmTimestampKey = 'fcm_token_timestamp';
  static UserApiService apiService = UserApiService();

  static const Duration _tokenValidityDuration = Duration(days: 15);
  static Future<String?> getDeviceToken() async {
    try {
      String? cachedToken = _storage.read<String>(_fcmTokenKey);
      int? savedTimestamp = _storage.read<int>(_fcmTimestampKey);

      // 1. Check karo ki token cache mein hai ya nahi, aur kya woh expired toh nahi hua?
      if (cachedToken != null &&
          cachedToken.isNotEmpty &&
          savedTimestamp != null) {
        DateTime savedTime = DateTime.fromMillisecondsSinceEpoch(
          savedTimestamp,
        );
        Duration age = DateTime.now().difference(savedTime);

        // Agar token valid duration ke andar hai, toh cache se hi de do (No Firebase hit)
        if (age < _tokenValidityDuration) {
          print("✅ FCM Token Cache Hit: Valid (Age: ${age.inDays} days old).");
          var res = await apiService.updateFCM(fcmToken: cachedToken);
          print(res);
          return cachedToken;
        } else {
          print(
            "⚠️ FCM Token Expired: Older than ${_tokenValidityDuration.inDays} days. Fetching fresh from Firebase...",
          );
        }
      } else {
        print("⚠️ FCM Token Cache Miss: No token found in storage.");
      }

      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await _storage.write(_fcmTokenKey, token);

        await _storage.write(
          _fcmTimestampKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        await apiService.updateFCM(fcmToken: token);

        print(
          "✅ Fresh FCM Token fetched from Firebase and cached with new timestamp.",
        );
      }

      return token;
    } catch (e) {
      print("❌ Error fetching FCM token: $e");
      return _storage.read<String>(
        _fcmTimestampKey != null ? _fcmTokenKey : '',
      );
    }
  }

  static String? getSavedToken() {
    return _storage.read<String>(_fcmTokenKey);
  }

  static void initTokenListener({Function(String newToken)? onTokenUpdated}) {
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
      await _storage.write(_fcmTokenKey, newToken);
      await _storage.write(
        _fcmTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print(
        "🔄 FCM Token automatically refreshed and updated with new timestamp: $newToken",
      );

      if (onTokenUpdated != null) {
        onTokenUpdated(newToken);
      }
    });
  }

  static Future<void> clearFCMToken() async {
    await _storage.remove(_fcmTokenKey);
    await _storage.remove(_fcmTimestampKey);
    print("✅ FCM Token and timestamp cleared from local storage.");
  }
}
