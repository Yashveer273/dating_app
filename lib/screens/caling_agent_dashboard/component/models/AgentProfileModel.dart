// ==========================================
// agent_profile_model.dart
// ==========================================
class AgentProfileModel {
  final String id;
  final String displayName;
  final String phoneNumber;
  final String avatar;
  final String bio;
  final String category;
  final List topics;
  final List languages;
  final String agentId;

  // एक स्टैटिक करंट मॉडल इंस्टेंस ताकि पेज सीधे मॉडल से डेटा ले सके
  static AgentProfileModel? current;

  AgentProfileModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.avatar,
    required this.bio,
    required this.category,
    required this.topics,
    required this.languages,
    required this.agentId,
  });

  factory AgentProfileModel.fromJson(Map json) {
    final model = AgentProfileModel(
      id: json['_id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      topics: List.from(json['topics'] ?? []),
      languages: List.from(json['languages'] ?? []),
      agentId: json['agentId']?.toString() ?? '',
    );

    // जैसे ही JSON से बने, इसे current में सेट कर दें
    current = model;
    return model;
  }

  Map toJson() {
    return {
      '_id': id,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'bio': bio,
      'category': category,
      'topics': topics,
      'languages': languages,
      'agentId': agentId,
    };
  }
}
