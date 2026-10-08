// ==========================================
// agent_payout_models.dart (Organization Payout & Earnings Models)
// ==========================================

class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;
  final String bankName;
  final String? upiId;

  BankDetails({
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
    required this.bankName,
    this.upiId,
  });
}

class WithdrawalRecord {
  static final List<WithdrawalRecord> testData = [
    WithdrawalRecord(
      id: 'REQ-97942',
      amount: 1200.0,
      timestamp: DateTime(2026, 9, 28, 16, 45),
      formattedTimestamp: '28 Sep 2026, 04:45 PM',
      status: 'Rejected',
      bankName: 'ICICI Bank',
      paidAudioTime: '2hr 0m',
      paidVideoTime: '1hr 0m',
      audioEarnings: 800.0,
      videoEarnings: 400.0,
    ),
  ];

  final String id;
  final double amount;
  final String formattedTimestamp;
  final String status;
  final String bankName;
  final String paidAudioTime;
  final String paidVideoTime;
  final double audioEarnings;
  final DateTime? timestamp;
  final double videoEarnings;

  WithdrawalRecord({
    required this.id,
    required this.timestamp,
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
