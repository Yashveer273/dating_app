import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
  }

  static bool hasUser() {
    return _storage.hasData('userModel');
  }

  static Future<void> clearUser() async {
    await _storage.remove('userModel');
    await _storage.remove('role');
  }
}
