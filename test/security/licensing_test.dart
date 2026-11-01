import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/core/security/app_hardware_id.dart';
import 'package:snaphisaab/core/security/ed25519_verifier.dart';

void main() {
  group('Security & Offline Licensing Tests', () {
    test('Hardware ID generation format is stable and canonicalizes', () {
      const hwid1 = "LH-A1B2-C3D4-E5F6-7890";
      const hwid2 = "lh-a1b2-c3d4-e5f6-7890";
      const hwid3 = "A1B2C3D4E5F67890";

      expect(AppHardwareId.matches(hwid1, hwid2), isTrue);
      expect(AppHardwareId.matches(hwid1, hwid3), isTrue);
      expect(AppHardwareId.matches("LH-1111", "LH-2222"), isFalse);
    });

    test('Activation request generation produces valid SHABANA-REQ format', () {
      const hwid = "LH-A1B2-C3D4-E5F6-7890";
      final req = Ed25519Verifier.generateActivationRequest(hwid, planId: "1_YEAR");

      expect(req.startsWith("SHABANA-REQ:"), isTrue);
      final b64 = req.substring("SHABANA-REQ:".length);
      final decodedBytes = Ed25519Verifier.decodeBase64Url(b64);
      final jsonStr = String.fromCharCodes(decodedBytes);

      expect(jsonStr.contains("hwid"), isTrue);
      expect(jsonStr.contains("plan"), isTrue);
      expect(jsonStr.contains("1_YEAR"), isTrue);
    });

    test('Tampered or forged license key is rejected by Ed25519 verifier', () async {
      const forgedKey = "SHABANA-LIC:eyJhcHAiOiJTaGFiYW5hTGV0dGVyaGVhZCIsImRheXMiOjM2NSwiZXhwIjoxODAwMDAwMDAwLCJnZW4iOjE3MDAwMDAwMDAsImh3aWQiOiJMSC1BMUIyLUMzRDQtRTVGNi03ODkwIiwicGxhbiI6IjFfWUVBUiIsInYiOjF9.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
      final result = await Ed25519Verifier.verifyLicense(forgedKey, "LH-A1B2-C3D4-E5F6-7890");

      expect(result is VerificationResultInvalid, isTrue);
    });
  });
}
