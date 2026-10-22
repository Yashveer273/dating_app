// ==========================================
// UserStorage.dart (Updated with Complete Storage & Image/Temp Cache Cleanup)
// ==========================================
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class UserStorage {
  static final GetStorage _storage = GetStorage();
  static RxString role = "".obs;

  static UserModel? getUser() {
    final userData = _storage.read('userModel');
    final ogrole = _storage.read('role');
    role.value = ogrole?.toString() ?? "";
    if (userData == null) {
      return null;
    }

    return UserModel.fromJson(Map<String, dynamic>.from(userData), role.value);
  }

  static Future<void> saveUser(UserModel user) async {
    await _storage.write('userModel', user.toJson());
    await _storage.write('role', user.role);
    role.value = user.role;
  }

  static bool hasUser() {
    return _storage.hasData('userModel');
  }

  static Future<void> clearUser() async {
    await _storage.remove('userModel');
    await _storage.remove('role');
    role.value = "";
  }

  /// 🔥 Complete App Clean: Erases GetStorage data, resets role, & clears image/temp cache
  static Future<void> clearAllAppData() async {
    try {
      // 1. GetStorage का सारा डेटा पूरी तरह से मिटा देगा
      await _storage.erase();
      role.value = "";
      print("✅ GetStorage successfully erased.");

      // 2. Temporary Directory (जहाँ इमेज कैश और टेम्परेरी फाइल्स स्टोर होती हैं)
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        print("✅ Temporary & Image cache directory cleared.");
      }

      // 3. Application Cache Directory
      final appCacheDir = await getApplicationCacheDirectory();
      if (appCacheDir.existsSync()) {
        appCacheDir.deleteSync(recursive: true);
        print("✅ Application cache directory cleared.");
      }

      print(
        "🎉 All application data, local storage, and image cache successfully wiped!",
      );
    } catch (e) {
      print("❌ Error clearing app storage and cache: $e");
    }
  }
}
