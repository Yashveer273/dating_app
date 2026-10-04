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
    WithdrawalRecord(
      id: 'REQ-98310',
      amount: 5000.0,
      timestamp: DateTime(2026, 10, 1, 11, 15),
      formattedTimestamp: '01 Oct 2026, 11:15 AM',
      status: 'Accepted',
      bankName: 'State Bank of India',
      paidAudioTime: '5hr 0m',
      paidVideoTime: '3hr 0m',
      audioEarnings: 3000.0,
      videoEarnings: 2000.0,
    ),
    WithdrawalRecord(
      id: 'REQ-98421',
      amount: 2500.0,
      timestamp: DateTime(2026, 10, 4, 14, 30),
      formattedTimestamp: '04 Oct 2026, 02:30 PM',
      status: 'Pending',
      bankName: 'HDFC Bank',
      paidAudioTime: '3hr 0m',
      paidVideoTime: '2hr 0m',
      audioEarnings: 1500.0,
      videoEarnings: 1000.0,
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
