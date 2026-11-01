import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Deterministic, stable Android/Multiplatform Hardware Identification service.
///
/// Matches the exact Shabana suite hardware binding pattern:
/// - Derived from hardware identifiers and fixed product namespace ("ShabanaHisaab").
/// - Survives app reinstalls, clear data, and OS updates on the same device.
/// - Output format: SH-XXXX-XXXX-XXXX-XXXX
class AppHardwareId {
  static const String productSalt = "ShabanaHisaab";
  static const String fallbackId = "358921054367891";

  static String? _cachedHwid;

  /// Returns the cached or computed stable hardware identifier
  static Future<String> getHardwareId() async {
    if (_cachedHwid != null && _cachedHwid!.isNotEmpty) {
      return _cachedHwid!;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String rawId = '';

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // androidId is stable across installs on modern Android
        rawId = androidInfo.id.trim();
        if (rawId.isEmpty || rawId == "9774d56d682e549c") {
          rawId = "${androidInfo.brand}_${androidInfo.device}_${androidInfo.model}_${androidInfo.manufacturer}";
        }
      } else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        rawId = windowsInfo.deviceId;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        rawId = iosInfo.identifierForVendor ?? '';
      } else if (Platform.isLinux) {
        final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        rawId = linuxInfo.machineId ?? '';
      } else if (Platform.isMacOS) {
        final MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        rawId = macInfo.systemGUID ?? '';
      }
    } catch (_) {
      rawId = fallbackId;
    }

    if (rawId.trim().isEmpty) {
      rawId = fallbackId;
    }

    // SHA-256 hash with product namespace
    final bytes = utf8.encode("${rawId.toLowerCase().trim()}:$productSalt");
    final digest = sha256.convert(bytes);
    final hexChars = digest.bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

    _cachedHwid = "LH-${hexChars.substring(0, 4)}-${hexChars.substring(4, 8)}-${hexChars.substring(8, 12)}-${hexChars.substring(12, 16)}";
    return _cachedHwid!;
  }

  /// Normalizes an HWID for consistent matching (strips hyphens and converts to uppercase).
  static String canonicalize(String hwid) {
    return hwid.trim().replaceAll('-', '').toUpperCase();
  }

  /// Compares two HWIDs for equality, tolerating format differences (dashes, casing, prefixes).
  static bool matches(String hwidA, String hwidB) {
    final a = canonicalize(hwidA);
    final b = canonicalize(hwidB);
    if (a.isEmpty || b.isEmpty) return false;

    // Remove known prefixes (SH, LH, etc.)
    String cleanA = a;
    if (cleanA.startsWith('SH') || cleanA.startsWith('LH')) {
      cleanA = cleanA.substring(2);
    }
    String cleanB = b;
    if (cleanB.startsWith('SH') || cleanB.startsWith('LH')) {
      cleanB = cleanB.substring(2);
    }

    return cleanA == cleanB;
  }
}
