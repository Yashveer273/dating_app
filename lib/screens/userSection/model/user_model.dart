class UserModel {
  final String id, role;
  final String phoneNumber;
  final bool phoneVerified;
  final String? name;
  final String? avatar;
  final num walletBalance;
  final int audioCallTimeMinutes;
  final int videoCallTimeMinutes;
  final String status;
  final String? gender;
  final int matches;
  final bool profileCompleted;
  final String? fcmToken;
  final String? lastLoginAt;
  final dynamic firebaseLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.role,
    required this.phoneNumber,
    required this.phoneVerified,
    this.name,
    this.avatar,
    required this.walletBalance,
    required this.audioCallTimeMinutes,
    required this.videoCallTimeMinutes,
    required this.status,
    this.gender,
    required this.matches,
    required this.profileCompleted,
    this.fcmToken,
    this.lastLoginAt,
    this.firebaseLocation,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String role) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      role: role,
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      phoneVerified: json['phoneVerified'] == true,
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
      walletBalance: json['walletBalance'] ?? 0,
      audioCallTimeMinutes:
          int.tryParse(json['audioCallTimeMinutes']?.toString() ?? '0') ?? 0,
      videoCallTimeMinutes:
          int.tryParse(json['videoCallTimeMinutes']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      gender: json['gender']?.toString(),
      matches: int.tryParse(json['matches']?.toString() ?? '0') ?? 0,
      profileCompleted: json['profileCompleted'] == true,
      fcmToken: json['fcmToken']?.toString(),
      lastLoginAt: json['lastLoginAt']?.toString(),
      firebaseLocation: json['firebaseLocation'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  UserModel copyWith({String? name, bool? profileCompleted}) {
    return UserModel(
      id: id,
      role: role,
      phoneNumber: phoneNumber,
      phoneVerified: phoneVerified,
      name: name ?? this.name,
      avatar: avatar,
      walletBalance: walletBalance,
      audioCallTimeMinutes: audioCallTimeMinutes,
      videoCallTimeMinutes: videoCallTimeMinutes,
      status: status,
      gender: gender,
      matches: matches,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      fcmToken: fcmToken,
      lastLoginAt: lastLoginAt,
      firebaseLocation: firebaseLocation,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'name': name,
      'avatar': avatar,
      'walletBalance': walletBalance,
      'audioCallTimeMinutes': audioCallTimeMinutes,
      'videoCallTimeMinutes': videoCallTimeMinutes,
      'status': status,
      'gender': gender,
      'matches': matches,
      'profileCompleted': profileCompleted,
      'fcmToken': fcmToken,
      'lastLoginAt': lastLoginAt,
      'firebaseLocation': firebaseLocation,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
