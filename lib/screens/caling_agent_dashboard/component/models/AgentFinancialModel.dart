class AgentFinancialModel {
  final double rating;
  final double walletBalance;
  final double totalEarned;
  final double audioCallDurationSeconds;
  final double audioCallEarnings;
  final double videoCallDurationSeconds;
  final double videoCallEarnings;

  AgentFinancialModel({
    required this.rating,
    required this.walletBalance,
    required this.totalEarned,
    required this.audioCallDurationSeconds,
    required this.audioCallEarnings,
    required this.videoCallDurationSeconds,
    required this.videoCallEarnings,
  });

  static AgentFinancialModel? current;
  factory AgentFinancialModel.fromJson(Map<String, dynamic> json) {
    return current = AgentFinancialModel(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      audioCallDurationSeconds:
          (json['audioCallDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      audioCallEarnings: (json['audioCallEarnings'] as num?)?.toDouble() ?? 0.0,
      videoCallDurationSeconds:
          (json['videoCallDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      videoCallEarnings: (json['videoCallEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'walletBalance': walletBalance,
      'totalEarned': totalEarned,
      'audioCallDurationSeconds': audioCallDurationSeconds,
      'audioCallEarnings': audioCallEarnings,
      'videoCallDurationSeconds': videoCallDurationSeconds,
      'videoCallEarnings': videoCallEarnings,
    };
  }
}
