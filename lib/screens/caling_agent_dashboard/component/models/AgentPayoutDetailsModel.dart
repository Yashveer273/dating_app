class AgentPayoutDetailsModel {
  final String upiId;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;

  const AgentPayoutDetailsModel({
    required this.upiId,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
  });

  factory AgentPayoutDetailsModel.fromJson(Map<String, dynamic> json) {
    return AgentPayoutDetailsModel(
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
