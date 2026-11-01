import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/core/sms/sms_parser_engine.dart';
import 'package:snaphisaab/core/sms/sms_deduplicator.dart';

void main() {
  group('SmsParserEngine Indian Banking SMS Tests', () {
    test('Parses HDFC Bank Debit SMS correctly', () {
      final result = SmsParserEngine.parse(
        senderId: 'AD-HDFCBK',
        body: 'Rs. 1,250.00 debited from A/c **4321 on 10-AUG-26 to Swiggy. Avl bal: Rs 45,200.',
        timestamp: DateTime(2026, 8, 10, 12, 30),
      );

      expect(result, isNotNull);
      expect(result!.bankName, equals('HDFC Bank'));
      expect(result.accountNumberLast4, equals('4321'));
      expect(result.amount, equals(1250.00));
      expect(result.transactionType, equals('Expense'));
      expect(result.partyName.toLowerCase(), contains('swiggy'));
      expect(result.suggestedCategory, equals('Food'));
      expect(result.confidence.isHighConfidence, isTrue);
    });

    test('Parses SBI Credit Card Debit SMS correctly', () {
      final result = SmsParserEngine.parse(
        senderId: 'BZ-SBIINB',
        body: 'Spent Rs. 450.00 on SBI Credit Card ending **9876 at Shell Petrol Pump.',
        timestamp: DateTime(2026, 8, 10, 11, 15),
      );

      expect(result, isNotNull);
      expect(result!.bankName, equals('State Bank of India'));
      expect(result.accountNumberLast4, equals('9876'));
      expect(result.accountType, equals('CREDIT_CARD'));
      expect(result.amount, equals(450.00));
      expect(result.transactionType, equals('Expense'));
      expect(result.partyName, contains('Shell Petrol Pump'));
      expect(result.suggestedCategory, equals('Fuel'));
    });

    test('Parses ICICI Bank Credit SMS correctly', () {
      final result = SmsParserEngine.parse(
        senderId: 'AX-ICICIB',
        body: 'INR 25,000.00 credited to A/c XX5678 on 10-AUG-26. Info: Salary Transfer.',
        timestamp: DateTime(2026, 8, 10, 10, 0),
      );

      expect(result, isNotNull);
      expect(result!.bankName, equals('ICICI Bank'));
      expect(result.accountNumberLast4, equals('5678'));
      expect(result.amount, equals(25000.00));
      expect(result.transactionType, equals('Income'));
    });

    test('Rejects OTP and Security Messages', () {
      final result = SmsParserEngine.parse(
        senderId: 'AD-HDFCBK',
        body: '482910 is your OTP for HDFC Bank NetBanking transaction. Do not share with anyone.',
        timestamp: DateTime(2026, 8, 10, 12, 0),
      );

      expect(result, isNull);
    });
  });

  group('SmsDeduplicator Tests', () {
    test('Deduplicates identical SHA-256 fingerprints', () {
      final result1 = SmsParserEngine.parse(
        senderId: 'AD-HDFCBK',
        body: 'Rs. 500 debited from A/c **4321 to Uber.',
        timestamp: DateTime(2026, 8, 10, 12, 0),
      )!;

      final filtered = SmsDeduplicator.filterNewResults(
        candidates: [result1, result1],
        existingHashes: {},
        existingTransactions: [],
      );

      expect(filtered.length, equals(1));
    });
  });
}
