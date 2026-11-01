import 'package:flutter/services.dart';
import '../../core/sms/sms_parser_engine.dart';
import '../../core/sms/sms_parsed_result.dart';

enum SmsScanHorizon { days30, days90, fullInbox }

class SmsScanSummary {
  final int scannedCount;
  final int financialCount;
  final List<SmsParsedResult> parsedResults;

  const SmsScanSummary({
    required this.scannedCount,
    required this.financialCount,
    required this.parsedResults,
  });
}

class SmsService {
  static const MethodChannel _channel = MethodChannel('snaphisaab/sms');

  /// Requests READ_SMS permission from Android OS
  static Future<bool> requestPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestSmsPermission');
      return granted;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Scans SMS Inbox locally on device for the specified horizon
  static Future<SmsScanSummary> scanInbox({
    required SmsScanHorizon horizon,
    List<Map<String, dynamic>>? mockSmsMessages,
  }) async {
    final DateTime cutoff;
    final now = DateTime.now();
    switch (horizon) {
      case SmsScanHorizon.days30:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case SmsScanHorizon.days90:
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case SmsScanHorizon.fullInbox:
        cutoff = DateTime(2000);
        break;
    }

    List<Map<String, dynamic>> smsList = [];
    if (mockSmsMessages != null) {
      smsList = mockSmsMessages;
    } else {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception("SMS Read permission was not granted by user.");
      }

      try {
        final List<dynamic>? rawList = await _channel.invokeMethod('readSmsInbox', {
          'sinceTimestamp': cutoff.millisecondsSinceEpoch,
        });
        if (rawList != null) {
          smsList = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      } on PlatformException catch (e) {
        throw Exception("Failed to read SMS inbox: ${e.message}");
      } catch (e) {
        throw Exception("Failed to read SMS inbox: ${e.toString()}");
      }
    }

    int scanned = 0;
    int financial = 0;
    final List<SmsParsedResult> parsedResults = [];

    for (final sms in smsList) {
      scanned++;
      final String sender = sms['sender'] ?? '';
      final String body = sms['body'] ?? '';
      final int ts = sms['timestamp'] ?? now.millisecondsSinceEpoch;
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);

      if (dt.isBefore(cutoff)) continue;

      final parsed = SmsParserEngine.parse(
        senderId: sender,
        body: body,
        timestamp: dt,
      );

      if (parsed != null) {
        financial++;
        parsedResults.add(parsed);
      }
    }

    return SmsScanSummary(
      scannedCount: scanned,
      financialCount: financial,
      parsedResults: parsedResults,
    );
  }
}
