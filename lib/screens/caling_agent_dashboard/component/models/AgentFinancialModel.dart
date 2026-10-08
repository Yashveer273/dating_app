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
    final model = AgentFinancialModel(
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      audioCallDurationSeconds: json['audioCallDurationSeconds'],
      audioCallEarnings: (json['audioCallEarnings'] as num?)?.toDouble() ?? 0.0,
      videoCallDurationSeconds: json['videoCallDurationSeconds'],
      videoCallEarnings: (json['videoCallEarnings'] as num?)?.toDouble() ?? 0.0,
    );

    current = model;

    return model;
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
