import 'package:talk24loves/screens/caling_agent_dashboard/component/models/agent_model.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/user_storage.dart';
import 'package:talk24loves/screens/userSection/model/user_model.dart';

class AppConfig {
  static const String rootBaseUrl = "https://server.omipet.in";
  //  http://192.168.1.11:3000
  static UserModel? get user => UserStorage.getUser();
  static AgentModel? get agent => AgentStorage.getAgent();
}
