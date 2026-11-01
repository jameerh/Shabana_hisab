import 'sms_parse_confidence.dart';

class SmsParsedResult {
  final String senderId;
  final String bankName;
  final String accountNumberLast4;
  final String accountType; // BANK, CREDIT_CARD, WALLET, UPI
  final String transactionType; // Expense (Debit) or Income (Credit)
  final double amount;
  final String partyName;
  final String suggestedCategory;
  final DateTime timestamp;
  final SmsParseConfidence confidence;
  final String hashFingerprint;

  const SmsParsedResult({
    required this.senderId,
    required this.bankName,
    required this.accountNumberLast4,
    required this.accountType,
    required this.transactionType,
    required this.amount,
    required this.partyName,
    required this.suggestedCategory,
    required this.timestamp,
    required this.confidence,
    required this.hashFingerprint,
  });

  @override
  String toString() {
    return 'SmsParsedResult($bankName •••• $accountNumberLast4, $transactionType: ₹$amount at $partyName, Score: ${(confidence.overallScore * 100).toStringAsFixed(0)}%)';
  }
}
