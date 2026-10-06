class AgentPayoutDetails {
  final String upiId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;

  AgentPayoutDetails({
    required this.upiId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
  });

  factory AgentPayoutDetails.fromJson(Map<String, dynamic> json) {
    return AgentPayoutDetails(
      upiId: json['upiId']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upiId': upiId,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
    };
  }
}

class AgentModel {
  final String role;
  final AgentPayoutDetails payoutDetails;
  final String id;
  final dynamic firebaseLocation;
  final String agentId;
  final String displayName;
  final String phoneNumber;
  final String? avatar;
  final String? bio;
  final String category;
  final List<String> topics;
  final List<String> languages;
  final String? authToken;
  final String? fcmToken;
  final bool isLoggedIn;
  final bool isOnline;
  final bool isBusyOnCall;
  final bool isAudioAvailable;
  final bool isVideoAvailable;
  final double rating;
  final String location;
  final num audioRatePerMinute;
  final num videoRatePerMinute;
  final num walletBalance;
  final num totalEarned;
  final int audioCallDurationSeconds;
  final num audioCallEarnings;
  final int videoCallDurationSeconds;
  final num videoCallEarnings;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AgentModel({
    required this.role,
    required this.payoutDetails,
    required this.id,
    this.firebaseLocation,
    required this.agentId,
    required this.displayName,
    required this.phoneNumber,
    this.avatar,
    this.bio,
    required this.category,
    required this.topics,
    required this.languages,
    this.authToken,
    this.fcmToken,
    required this.isLoggedIn,
    required this.isOnline,
    required this.isBusyOnCall,
    required this.isAudioAvailable,
    required this.isVideoAvailable,
    required this.rating,
    required this.location,
    required this.audioRatePerMinute,
    required this.videoRatePerMinute,
    required this.walletBalance,
    required this.totalEarned,
    required this.audioCallDurationSeconds,
    required this.audioCallEarnings,
    required this.videoCallDurationSeconds,
    required this.videoCallEarnings,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      role: json['role']?.toString() ?? 'agent',
      payoutDetails: AgentPayoutDetails.fromJson(
        Map<String, dynamic>.from(json['payoutDetails'] ?? {}),
      ),
      id: json['_id']?.toString() ?? '',
      firebaseLocation: json['firebaseLocation'],
      agentId: json['agentId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      bio: json['bio']?.toString(),
      category: json['category']?.toString() ?? '',
      topics: json['topics'] is List
          ? List<String>.from((json['topics'] as List).map((e) => e.toString()))
          : [],
      languages: json['languages'] is List
          ? List<String>.from(
              (json['languages'] as List).map((e) => e.toString()),
            )
          : [],
      authToken: json['authToken']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      isLoggedIn: json['isLoggedIn'] == true,
      isOnline: json['isOnline'] == true,
      isBusyOnCall: json['isBusyOnCall'] == true,
      isAudioAvailable: json['isAudioAvailable'] == true,
      isVideoAvailable: json['isVideoAvailable'] == true,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      location: json['location']?.toString() ?? '',
      audioRatePerMinute: json['audioRatePerMinute'] ?? 0,
      videoRatePerMinute: json['videoRatePerMinute'] ?? 0,
      walletBalance: json['walletBalance'] ?? 0,
      totalEarned: json['totalEarned'] ?? 0,
      audioCallDurationSeconds:
          int.tryParse(json['audioCallDurationSeconds']?.toString() ?? '0') ??
          0,
      audioCallEarnings: json['audioCallEarnings'] ?? 0,
      videoCallDurationSeconds:
          int.tryParse(json['videoCallDurationSeconds']?.toString() ?? '0') ??
          0,
      videoCallEarnings: json['videoCallEarnings'] ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'payoutDetails': payoutDetails.toJson(),
      '_id': id,
      'firebaseLocation': firebaseLocation,
      'agentId': agentId,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'bio': bio,
      'category': category,
      'topics': topics,
      'languages': languages,
      'authToken': authToken,
      'fcmToken': fcmToken,
      'isLoggedIn': isLoggedIn,
      'isOnline': isOnline,
      'isBusyOnCall': isBusyOnCall,
      'isAudioAvailable': isAudioAvailable,
      'isVideoAvailable': isVideoAvailable,
      'rating': rating,
      'location': location,
      'audioRatePerMinute': audioRatePerMinute,
      'videoRatePerMinute': videoRatePerMinute,
      'walletBalance': walletBalance,
      'totalEarned': totalEarned,
      'audioCallDurationSeconds': audioCallDurationSeconds,
      'audioCallEarnings': audioCallEarnings,
      'videoCallDurationSeconds': videoCallDurationSeconds,
      'videoCallEarnings': videoCallEarnings,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
