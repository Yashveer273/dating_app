import 'package:get_storage/get_storage.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class UserStorage {
  static final GetStorage _storage = GetStorage();

  static UserModel? getUser() {
    final userData = _storage.read('userModel');
    final role = _storage.read('role');
    if (userData == null) {
      return null;
    }

    return UserModel.fromJson(Map<String, dynamic>.from(userData), role);
  }

  static Future<void> saveUser(UserModel user) async {
    await _storage.write('userModel', user.toJson());
    await _storage.write('role', user.role);
  }

  static bool hasUser() {
    return _storage.hasData('userModel');
  }

  static Future<void> clearUser() async {
    await _storage.remove('userModel');
    await _storage.remove('role');
  }
}
