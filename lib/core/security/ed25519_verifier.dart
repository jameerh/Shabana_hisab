import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'app_hardware_id.dart';

/// Supported Product Identifiers in Shabana Ecosystem
class SupportedProducts {
  static const String expenseManager = "ShabanaHisaab";
  static const String letterhead = "ShabanaLetterhead";
  static const String ime = "ShabanaIME";
}

/// Representation of a parsed offline license payload
class LicensePayload {
  final String app;
  final int days;
  final int exp; // 0 = Lifetime, or UNIX epoch seconds
  final int gen; // Issuance timestamp in UNIX epoch seconds
  final String hwid;
  final String plan;
  final int v;

  LicensePayload({
    required this.app,
    required this.days,
    required this.exp,
    required this.gen,
    required this.hwid,
    required this.plan,
    required this.v,
  });

  bool get isLifetime => exp == 0 || days >= 30000;

  factory LicensePayload.fromJson(Map<String, dynamic> json) {
    return LicensePayload(
      app: json['app'] as String? ?? '',
      days: (json['days'] as num?)?.toInt() ?? 0,
      exp: (json['exp'] as num?)?.toInt() ?? 0,
      gen: (json['gen'] as num?)?.toInt() ?? 0,
      hwid: json['hwid'] as String? ?? '',
      plan: json['plan'] as String? ?? '',
      v: (json['v'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Result of license verification
abstract class VerificationResult {
  const VerificationResult();
}

class VerificationResultValid extends VerificationResult {
  final LicensePayload payload;
  final int remainingDays;
  final bool isLifetime;

  const VerificationResultValid({
    required this.payload,
    required this.remainingDays,
    required this.isLifetime,
  });
}

class VerificationResultInvalid extends VerificationResult {
  final String reason;
  const VerificationResultInvalid(this.reason);
}

/// High-Security Asymmetric Ed25519 Offline License Verifier
class Ed25519Verifier {
  static const String productHisaab = "ShabanaHisaab";

  /// Active Master Public Key (URL-safe Base64, 32 bytes)
  /// Corresponds to Owner Master Signing Key in Shabana CSC Android Keystore.
  static const String primaryPublicKeyB64 = "zmqZrx59u_2DnDJBBm5VHjsu0UEgvphnTNHmE67KnzU";

  static const List<String> trustedPublicKeysB64 = [
    primaryPublicKeyB64,
  ];

  /// Cross-environment URL-safe Base64 decoder
  static Uint8List decodeBase64Url(String input) {
    var s = input.trim().replaceAll('-', '+').replaceAll('_', '/');
    while (s.length % 4 != 0) {
      s += '=';
    }
    return base64Decode(s);
  }

  /// Cross-environment URL-safe Base64 encoder without padding
  static String encodeBase64Url(Uint8List data) {
    return base64UrlEncode(data).replaceAll('=', '');
  }

  /// Generates a compact offline activation request payload (SHABANA-REQ:...)
  /// Scannable by owner's CSC app camera or shareable via WhatsApp
  static String generateActivationRequest(String hwid, {String planId = "1_YEAR"}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cleanHwid = hwid.trim();
    final jsonStr = jsonEncode({
      "app": SupportedProducts.letterhead,
      "hwid": cleanHwid,
      "plan": planId,
      "ts": now,
    });
    final b64 = encodeBase64Url(Uint8List.fromList(utf8.encode(jsonStr)));
    return "SHABANA-REQ:$b64";
  }

  /// Verifies an Ed25519-signed offline license key against the device's hardware ID
  static Future<VerificationResult> verifyLicense(
    String licenseKeyString,
    String currentHwid, {
    int lastRecordedEpochSec = 0,
    List<String> trustedPublicKeys = trustedPublicKeysB64,
  }) async {
    var cleanKey = licenseKeyString.trim();
    if (cleanKey.startsWith("SHABANA-LIC:")) {
      cleanKey = cleanKey.substring("SHABANA-LIC:".length);
    } else if (cleanKey.startsWith("SHABANA-")) {
      cleanKey = cleanKey.substring("SHABANA-".length);
    }

    if (!cleanKey.contains(".")) {
      return const VerificationResultInvalid("Invalid license key format (missing delimiter).");
    }

    final parts = cleanKey.split(".");
    if (parts.length != 2) {
      return const VerificationResultInvalid("Malformed license key structure.");
    }

    final payloadB64 = parts[0];
    final sigB64 = parts[1];

    Uint8List payloadBytes;
    Uint8List sigBytes;

    try {
      payloadBytes = decodeBase64Url(payloadB64);
      sigBytes = decodeBase64Url(sigB64);
    } catch (_) {
      return const VerificationResultInvalid("Invalid Base64URL encoding.");
    }

    if (sigBytes.length != 64) {
      return const VerificationResultInvalid("Invalid signature length (expected 64 bytes).");
    }

    // 1. Asymmetric Cryptographic Verification against Trusted Key Registry
    bool verified = false;
    final algorithm = Ed25519();

    for (final trustedKeyB64 in trustedPublicKeys) {
      try {
        final pubKeyBytes = decodeBase64Url(trustedKeyB64);
        final publicKey = SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519);
        final signature = Signature(sigBytes, publicKey: publicKey);

        final isValid = await algorithm.verify(payloadBytes, signature: signature);
        if (isValid) {
          verified = true;
          break;
        }
      } catch (_) {
        // Try next key if any
      }
    }

    if (!verified) {
      return const VerificationResultInvalid("Digital signature verification failed. Key is invalid or tampered.");
    }

    // 2. Parse Canonical Payload JSON
    final LicensePayload payload;
    try {
      final jsonStr = utf8.decode(payloadBytes);
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return const VerificationResultInvalid("Payload must be a JSON object.");
      }
      payload = LicensePayload.fromJson(decoded);
    } catch (e) {
      return VerificationResultInvalid("Failed to parse license payload: $e");
    }

    // 3. Product Isolation Check (Accepts ShabanaHisaab, or suite compatible)
    if (payload.app != productHisaab && payload.app != SupportedProducts.letterhead) {
      return VerificationResultInvalid("Product isolation violation: License is for '${payload.app}', expected '$productHisaab'.");
    }

    // 4. Plan & Schema Validation
    final validPlans = {"1_MONTH", "6_MONTHS", "1_YEAR", "LIFETIME"};
    if (!validPlans.contains(payload.plan)) {
      return VerificationResultInvalid("Unsupported plan '${payload.plan}'. Must be one of: ${validPlans.join(', ')}.");
    }

    // 5. Hardware ID Binding Check
    if (!AppHardwareId.matches(payload.hwid, currentHwid)) {
      return VerificationResultInvalid("License is bound to another device (${payload.hwid}).");
    }

    // 6. Timestamp & Expiry Consistency Checks
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Generation timestamp skew check (within 1 hour tolerance)
    if (payload.gen > now + 3600) {
      return const VerificationResultInvalid("Invalid issuance timestamp: License was generated in the future.");
    }

    if (payload.isLifetime) {
      if (payload.exp != 0 || payload.days < 30000) {
        return const VerificationResultInvalid("Inconsistent lifetime license specification.");
      }
    } else {
      if (payload.exp <= 0 || payload.days <= 0) {
        return const VerificationResultInvalid("Invalid duration or expiration timestamp for timed license.");
      }
      if (payload.exp < now) {
        return VerificationResultInvalid("Subscription expired on ${_formatDate(payload.exp)}.");
      }
      // Duration consistency check
      final expectedExpiry = payload.gen + (payload.days * 86400);
      if ((payload.exp - expectedExpiry).abs() > 172800) {
        return const VerificationResultInvalid("Inconsistent license duration: Expiry does not match plan duration.");
      }
    }

    // 7. System Clock Rollback Mitigation
    if (lastRecordedEpochSec > 0 && now < (lastRecordedEpochSec - 3600)) {
      return const VerificationResultInvalid("System clock rollback detected. Please set your device date and time correctly.");
    }

    // Calculate Remaining Days
    final int remainingDays;
    if (payload.isLifetime) {
      remainingDays = 99999;
    } else {
      final remainingSec = payload.exp - now;
      remainingDays = remainingSec <= 0 ? 0 : ((remainingSec + 86399) ~/ 86400);
    }

    return VerificationResultValid(
      payload: payload,
      remainingDays: remainingDays,
      isLifetime: payload.isLifetime,
    );
  }

  static String _formatDate(int epochSec) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return "$epochSec";
    }
  }
}
