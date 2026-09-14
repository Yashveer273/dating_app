// ==========================================
// agent_payout_models.dart (Organization Payout & Earnings Models)
// ==========================================

class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String bankName;

  BankDetails({
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    required this.bankName,
  });
}

class WithdrawalRecord {
  final String id;
  final double amount;
  final String formattedTimestamp;
  final String status;
  final String bankName;
  final String paidAudioTime;
  final String paidVideoTime;
  final double audioEarnings;
  final double videoEarnings;

  WithdrawalRecord({
    required this.id,
    required this.amount,
    required this.formattedTimestamp,
    required this.status,
    required this.bankName,
    required this.paidAudioTime,
    required this.paidVideoTime,
    required this.audioEarnings,
    required this.videoEarnings,
  });
}
