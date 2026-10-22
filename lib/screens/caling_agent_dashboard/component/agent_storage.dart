import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'models/agent_model.dart';

class AgentStorage {
  static final GetStorage _storage = GetStorage();

  static AgentModel? getAgent() {
    final agentData = _storage.read('agentModel');

    if (agentData == null) {
      return null;
    }

    return AgentModel.fromJson(Map<String, dynamic>.from(agentData));
  }

  static Future<void> saveAgent(AgentModel agent) async {
    await _storage.write('agentModel', agent.toJson());
    await _storage.write('role', agent.role);
  }

  static bool hasAgent() {
    return _storage.hasData('agentModel');
  }

  static Future<void> clearAgent() async {
    await _storage.remove('agentModel');
    await _storage.remove('role');
  }

  /// 🔥 100% Complete App Clean: Erases GetStorage data + Image/Temp Cache
  static Future<void> clearAllAppData() async {
    try {
      // 1. GetStorage का सारा डेटा पूरी तरह से मिटा देगा (Erase)
      await _storage.erase();
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
