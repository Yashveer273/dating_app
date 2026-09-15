// ==========================================
// AgentModel.dart (Updated with Call Fields)
// ==========================================
class AgentModel {
  final String id;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final String location;
  final double pricePerMinute;
  final List languages;
  final String category; // Single value: e.g., 'Relationship', 'Marriage', etc.
  final List topics; // List of expertise topics
  final bool isOnline;
  final bool isAudioAvailable; // 👉 New Field for Audio Call support
  final bool isVideoAvailable; // 👉 New Field for Video Call support

  AgentModel({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.location,
    required this.pricePerMinute,
    required this.languages,
    required this.category,
    required this.topics,
    required this.isOnline,
    this.isAudioAvailable = true,
    this.isVideoAvailable = true,
  });

  // A static current agent instance for active reference
  static AgentModel? current;

  // Factory constructor for backend JSON parsing
  factory AgentModel.fromJson(Map json) {
    return AgentModel(
      id: json['_id'] ?? json['id'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['image'] ?? '',
      bio: json['bio'] ?? '',
      location: json['location'] ?? 'India',
      pricePerMinute: (json['pricePerMinute'] ?? 5.0).toDouble(),
      languages: List.from(json['languages'] ?? ['English', 'Hindi']),
      category: json['category'] ?? 'General',
      topics: List.from(json['topics'] ?? []),
      isOnline: json['isOnline'] ?? true,
      isAudioAvailable: json['isAudioAvailable'] ?? true,
      isVideoAvailable: json['isVideoAvailable'] ?? true,
    );
  }

  Map toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'pricePerMinute': pricePerMinute,
      'languages': languages,
      'category': category,
      'topics': topics,
      'isOnline': isOnline,
      'isAudioAvailable': isAudioAvailable,
      'isVideoAvailable': isVideoAvailable,
    };
  }
}

// ==========================================
// CategoryModel.dart
// ==========================================
class CategoryModel {
  final String id;
  final String name;
  final String iconUrl;

  CategoryModel({required this.id, required this.name, this.iconUrl = ''});

  static CategoryModel? current;

  factory CategoryModel.fromJson(Map json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }

  Map toJson() {
    return {'id': id, 'name': name, 'iconUrl': iconUrl};
  }
}
