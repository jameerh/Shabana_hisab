import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VoiceLogService {
  static Future<File> get _logFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/voice_calibration.log');
  }

  static Future<void> logEntry({
    required String expected,
    required String raw,
    required String normalized,
    required String parsedAmount,
    required String parsedType,
  }) async {
    final file = await _logFile;
    final timestamp = DateTime.now().toIso8601String();
    final entry = """
-----------------------------------------
TIME: $timestamp
EXPECTED: $expected
RAW_STT:  $raw
NORMAL:   $normalized
PARSED:   Amt: $parsedAmount, Type: $parsedType
-----------------------------------------
\n""";
    await file.writeAsString(entry, mode: FileMode.append);
  }

  static Future<String> readLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
      return "No logs found.";
    } catch (e) {
      return "Error reading logs: $e";
    }
  }

  static Future<void> clearLogs() async {
    final file = await _logFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
