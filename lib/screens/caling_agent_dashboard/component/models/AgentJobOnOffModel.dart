class AgentJobOnOffModel {
  final String id;
  final bool isOnline;

  const AgentJobOnOffModel({required this.id, required this.isOnline});

  static AgentJobOnOffModel? current;

  factory AgentJobOnOffModel.fromJson(Map<String, dynamic> json) {
    return AgentJobOnOffModel(
      id: json['_id']?.toString() ?? '',
      isOnline: json['isOnline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'isOnline': isOnline};
  }
}
