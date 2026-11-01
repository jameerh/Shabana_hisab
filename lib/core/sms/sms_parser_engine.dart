import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'sms_parse_confidence.dart';
import 'sms_parsed_result.dart';

class SmsParserEngine {
  /// Regular Expression for standard Indian Financial Sender Headers
  /// e.g. AD-HDFCBK, BZ-SBIINB, AX-ICICIB, VM-PAYTM, JX-KOTAKB
  static final RegExp _senderIdRegExp = RegExp(
    r'^[A-Z]{2}-([A-Z0-9]{5,8})$|^([A-Z]{4,8})$',
    caseSensitive: false,
  );

  /// Known Financial Institution Map
  static final Map<String, String> _bankHeaderMap = {
    'HDFCBK': 'HDFC Bank',
    'HDFC': 'HDFC Bank',
    'SBIINB': 'State Bank of India',
    'SBIPSG': 'State Bank of India',
    'SBI': 'State Bank of India',
    'ICICIB': 'ICICI Bank',
    'ICICI': 'ICICI Bank',
    'AXISBK': 'Axis Bank',
    'AXIS': 'Axis Bank',
    'KOTAKB': 'Kotak Mahindra Bank',
    'KOTAK': 'Kotak Mahindra Bank',
    'PAYTM': 'Paytm Wallet',
    'PAYTMB': 'Paytm Bank',
    'BOBTXN': 'Bank of Baroda',
    'BARODA': 'Bank of Baroda',
    'PNBSMS': 'Punjab National Bank',
    'PNB': 'Punjab National Bank',
    'INDUSB': 'IndusInd Bank',
    'CANBNK': 'Canara Bank',
    'UNIONB': 'Union Bank of India',
    'IDFCFB': 'IDFC FIRST Bank',
    'CRED': 'Cred Credit Card',
    'PHONEPE': 'PhonePe',
    'GPAY': 'Google Pay',
  };

  /// Parses a raw SMS message locally on device.
  /// Returns null if the SMS is non-financial, OTP-only, or invalid.
  static SmsParsedResult? parse({
    required String senderId,
    required String body,
    required DateTime timestamp,
  }) {
    final cleanSender = senderId.trim().toUpperCase();
    final cleanBody = body.trim();
    final lowerBody = cleanBody.toLowerCase();

    // 1. Rejection Filter: Ignore OTP, Security Alerts, Passwords
    if (_isOtpOrSecurityAlert(lowerBody)) {
      return null;
    }

    // 2. Identify Bank / Institution Name
    final bankName = _detectBankName(cleanSender, cleanBody);
    if (bankName == null) {
      return null;
    }

    // 3. Extract Amount
    final amount = _extractAmount(cleanBody);
    if (amount == null || amount <= 0) {
      return null;
    }

    // 4. Extract Debit (Expense) vs Credit (Income)
    final isDebit = _isDebitTransaction(lowerBody);
    final isCredit = _isCreditTransaction(lowerBody);
    if (!isDebit && !isCredit) {
      return null; // Ignore informational/balance updates without transaction
    }
    final transactionType = isDebit ? 'Expense' : 'Income';

    // 5. Extract Account / Card Last 4 Digits
    final last4 = _extractAccountLast4(cleanBody) ?? '0000';
    final accountType = _detectAccountType(lowerBody, bankName);

    // 6. Extract Merchant / Beneficiary Party Name
    final partyName = _extractPartyName(cleanBody) ?? bankName;

    // 7. Auto-Categorize Category
    final category = _suggestCategory(partyName, lowerBody);

    // 8. Calculate Parse Confidence Score
    final confidence = SmsParseConfidence(
      amountConfidence: 1.0,
      accountConfidence: last4 != '0000' ? 1.0 : 0.6,
      typeConfidence: (isDebit != isCredit) ? 0.95 : 0.6,
      merchantConfidence: partyName != bankName ? 0.90 : 0.5,
      categoryConfidence: category != 'Other' ? 0.85 : 0.5,
    );

    // 9. Compute Non-Reversible SHA-256 Fingerprint
    final rawString = '$cleanSender|${timestamp.millisecondsSinceEpoch}|$cleanBody';
    final hashFingerprint = sha256.convert(utf8.encode(rawString)).toString();

    return SmsParsedResult(
      senderId: cleanSender,
      bankName: bankName,
      accountNumberLast4: last4,
      accountType: accountType,
      transactionType: transactionType,
      amount: amount,
      partyName: partyName,
      suggestedCategory: category,
      timestamp: timestamp,
      confidence: confidence,
      hashFingerprint: hashFingerprint,
    );
  }

  static bool _isOtpOrSecurityAlert(String lowerBody) {
    if (lowerBody.contains('otp') ||
        lowerBody.contains('one time password') ||
        lowerBody.contains('verification code') ||
        lowerBody.contains('secret code') ||
        lowerBody.contains('do not share')) {
      return true;
    }
    return false;
  }

  static String? _detectBankName(String senderId, String body) {
    for (final entry in _bankHeaderMap.entries) {
      if (senderId.contains(entry.key)) {
        return entry.value;
      }
    }
    // Fallback: check if sender ID matches general Indian SMS header pattern
    final match = _senderIdRegExp.firstMatch(senderId);
    if (match != null) {
      final code = (match.group(1) ?? match.group(2) ?? '').toUpperCase();
      for (final entry in _bankHeaderMap.entries) {
        if (code.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    // Secondary Fallback: search body text for bank keywords
    final upperBody = body.toUpperCase();
    for (final entry in _bankHeaderMap.entries) {
      if (upperBody.contains(entry.key) || upperBody.contains(entry.value.toUpperCase())) {
        return entry.value;
      }
    }
    return null;
  }

  static double? _extractAmount(String body) {
    final amountRegExp = RegExp(
      r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final match = amountRegExp.firstMatch(body);
    if (match != null) {
      final rawStr = match.group(1)?.replaceAll(',', '');
      if (rawStr != null) {
        return double.tryParse(rawStr);
      }
    }
    return null;
  }

  static bool _isDebitTransaction(String lowerBody) {
    return lowerBody.contains('debited') ||
        lowerBody.contains('spent') ||
        lowerBody.contains('paid') ||
        lowerBody.contains('sent') ||
        lowerBody.contains('transfer to') ||
        lowerBody.contains('transferred to') ||
        lowerBody.contains('withdrawn') ||
        lowerBody.contains('purchase of') ||
        lowerBody.contains('txn of rs');
  }

  static bool _isCreditTransaction(String lowerBody) {
    return lowerBody.contains('credited') ||
        lowerBody.contains('received') ||
        lowerBody.contains('deposited') ||
        lowerBody.contains('refunded') ||
        lowerBody.contains('added to');
  }

  static String? _extractAccountLast4(String body) {
    final patterns = [
      RegExp(r'(?:a/c|account|card)\s*(?:no\.?|ending)?\s*\*+([0-9]{4})', caseSensitive: false),
      RegExp(r'xx+([0-9]{4})', caseSensitive: false),
      RegExp(r'\*+([0-9]{4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null && match.group(1) != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String _detectAccountType(String lowerBody, String bankName) {
    if (lowerBody.contains('credit card') || lowerBody.contains('card ending') || bankName.contains('Credit Card')) {
      return 'CREDIT_CARD';
    }
    if (lowerBody.contains('wallet') || bankName.contains('Wallet') || lowerBody.contains('paytm')) {
      return 'WALLET';
    }
    if (lowerBody.contains('upi') || lowerBody.contains('vpa')) {
      return 'UPI';
    }
    return 'BANK';
  }

  static String? _extractPartyName(String body) {
    final partyPatterns = [
      RegExp(r'(?:paid to|spent on|at|to)\s+([A-Za-z0-9\.\s&]+?)(?:\s+on|\s+ref|\s+vpa|\s+aval|\s+bal|\.|$)', caseSensitive: false),
      RegExp(r'info:\s*([A-Za-z0-9\.\s&]+?)(?:\.|$)', caseSensitive: false),
      RegExp(r'vpa\s+([A-Za-z0-9\.\@\s&]+?)(?:\s+|\.|$)', caseSensitive: false),
    ];

    for (final pattern in partyPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final party = match.group(1)?.trim();
        if (party != null && party.length > 2 && !party.toLowerCase().contains('account') && !party.toLowerCase().contains('card')) {
          return party;
        }
      }
    }
    return null;
  }

  static String _suggestCategory(String partyName, String lowerBody) {
    final text = '$partyName $lowerBody'.toLowerCase();

    if (text.contains('petrol') || text.contains('shell') || text.contains('hpcl') || text.contains('bpcl') || text.contains('iocl') || text.contains('fuel')) {
      return 'Fuel';
    }
    if (text.contains('swiggy') || text.contains('zomato') || text.contains('mcdonald') || text.contains('domino') || text.contains('starbucks') || text.contains('restaurant') || text.contains('cafe')) {
      return 'Food';
    }
    if (text.contains('amazon') || text.contains('flipkart') || text.contains('myntra') || text.contains('zudio') || text.contains('dmart') || text.contains('supermarket')) {
      return 'Shopping';
    }
    if (text.contains('uber') || text.contains('ola') || text.contains('irctc') || text.contains('indigo') || text.contains('redbus') || text.contains('flight') || text.contains('metro')) {
      return 'Travel';
    }
    if (text.contains('electricity') || text.contains('bescom') || text.contains('mseb') || text.contains('jio') || text.contains('airtel') || text.contains('vi') || text.contains('broadband') || text.contains('bill')) {
      return 'Utilities';
    }
    return 'Other';
  }
}
