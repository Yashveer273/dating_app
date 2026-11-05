import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'models/agent_model.dart';

class AgentStorage {
  static final GetStorage _storage = GetStorage();

  // Storage Keys
  static const String _keySavedAgentIds = 'saved_agent_ids';
  static const int maxSavedLimit = 30;

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

  // ====================================================================
  // 🚀 SAVED AGENT IDs STORAGE MANAGEMENT (Max 30 FIFO Queue)
  // ====================================================================

  /// 1. Clean & Validate single ID format (Strips leading '@', trims spaces)
  static String? sanitizeAgentId(String? rawId) {
    if (rawId == null) return null;
    return rawId.trim().isEmpty ? null : rawId.trim();
  }

  /// 2. Get list of all saved Agent IDs (Returns exact List<String> format)
  static List<String> getSavedAgentIds() {
    final rawList = _storage.read<List>(_keySavedAgentIds);
    print("Retrieved saved agent IDs from storage: $rawList");
    if (rawList == null || rawList.isEmpty) {
      return [];
    }

    // Sanitize and return unique valid IDs list
    final List<String> validIds = [];
    for (var item in rawList) {
      final clean = sanitizeAgentId(item?.toString());
      if (clean != null && !validIds.contains(clean)) {
        validIds.add(clean);
      }
    }
    return validIds;
  }

  /// 3. Toggle / Add / Remove Agent ID with 30 items FIFO Queue limit
  static Future<List<String>> toggleSaveAgentId(String agentId) async {
    final cleanId = sanitizeAgentId(agentId);
    if (cleanId == null) return getSavedAgentIds();

    List<String> currentIds = getSavedAgentIds();

    if (currentIds.contains(cleanId)) {
      // Remove if already exists
      currentIds.remove(cleanId);
    } else {
      // Add new ID
      currentIds.add(cleanId);
      // 🔥 Limit Management: If count > 30, remove oldest from the start (FIFO)
      while (currentIds.length > maxSavedLimit) {
        currentIds.removeAt(0);
      }
    }

    await _storage.write(_keySavedAgentIds, currentIds);
    return currentIds;
  }

  /// 4. Check if an Agent ID is bookmarked
  static bool isAgentSaved(String agentId) {
    final cleanId = sanitizeAgentId(agentId);
    if (cleanId == null) return false;
    return getSavedAgentIds().contains(cleanId);
  }

  /// 5. Clear all Saved Agent IDs
  static Future<void> clearSavedAgentIds() async {
    await _storage.remove(_keySavedAgentIds);
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
