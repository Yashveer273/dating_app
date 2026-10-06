import 'package:get_storage/get_storage.dart';
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
  }

  static bool hasAgent() {
    return _storage.hasData('agentModel');
  }

  static Future<void> clearAgent() async {
    await _storage.remove('agentModel');
  }
}
