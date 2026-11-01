import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_hardware_id.dart';
import 'ed25519_verifier.dart';

class LicensePlan {
  final String id;
  final String name;
  final String nameMr;
  final int price;
  final String durationText;
  final String badge;
  final bool isRecommended;

  const LicensePlan({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.price,
    required this.durationText,
    required this.badge,
    this.isRecommended = false,
  });
}

class SubscriptionManager extends ChangeNotifier {
  static final SubscriptionManager instance = SubscriptionManager._internal();
  SubscriptionManager._internal();

  static const List<LicensePlan> availablePlans = [
    LicensePlan(
      id: "1_MONTH",
      name: "1 Month",
      nameMr: "१ महिना",
      price: 99,
      durationText: "30 Days",
      badge: "Starter",
    ),
    LicensePlan(
      id: "6_MONTHS",
      name: "6 Months",
      nameMr: "६ महिने",
      price: 499,
      durationText: "180 Days",
      badge: "Popular",
    ),
    LicensePlan(
      id: "1_YEAR",
      name: "1 Year Pro",
      nameMr: "१ वर्ष प्रो",
      price: 899,
      durationText: "365 Days",
      badge: "Best Value",
      isRecommended: true,
    ),
    LicensePlan(
      id: "LIFETIME",
      name: "Lifetime",
      nameMr: "आजीवन",
      price: 1499,
      durationText: "Permanent",
      badge: "Lifetime",
    ),
  ];

  // Secure Storage Keys
  static const String _keyActiveLicense = "SEC_ACTIVE_LICENSE_KEY";
  static const String _keyActivePlanId = "SEC_ACTIVE_PLAN_ID";
  static const String _keyIsLifetime = "SEC_IS_LIFETIME";
  static const String _keyExpiryEpochSec = "SEC_EXPIRY_EPOCH_SEC";
  static const String _keyLastVerifiedEpochSec = "SEC_LAST_VERIFIED_EPOCH_SEC";
  static const String _keyClockTamperFlag = "SEC_CLOCK_TAMPER_FLAG";
  static const String _keyInstallTimestamp = "APP_INSTALL_TIMESTAMP";

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool _isPro = false;
  String _activePlanId = "TRIAL";
  bool _isLifetime = false;
  int _expiryEpochSec = 0;
  String _hardwareId = "";
  String _lastActivationError = "";

  bool get isInitialized => _isInitialized;
  bool get isPro => _isPro;
  String get activePlanId => _activePlanId;
  bool get isLifetime => _isLifetime;
  int get expiryEpochSec => _expiryEpochSec;
  String get hardwareId => _hardwareId;
  String get lastActivationError => _lastActivationError;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _hardwareId = await AppHardwareId.getHardwareId();

    // Record initial install time if not already present (7 Days free trial default)
    if (_prefs!.getInt(_keyInstallTimestamp) == null) {
      await _prefs!.setInt(_keyInstallTimestamp, DateTime.now().millisecondsSinceEpoch);
    }

    await refreshSubscriptionState();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshSubscriptionState() async {
    try {
      final activeKey = await _secureStorage.read(key: _keyActiveLicense);
      if (activeKey != null && activeKey.isNotEmpty) {
        final isLifetimeStr = await _secureStorage.read(key: _keyIsLifetime);
        final isLifetime = isLifetimeStr == 'true';

        final expirySecStr = await _secureStorage.read(key: _keyExpiryEpochSec);
        final expirySec = int.tryParse(expirySecStr ?? '0') ?? 0;

        final lastVerifiedSecStr = await _secureStorage.read(key: _keyLastVerifiedEpochSec);
        final lastVerifiedSec = int.tryParse(lastVerifiedSecStr ?? '0') ?? 0;

        final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Clock rollback check (1 hour tolerance)
        if (lastVerifiedSec > 0 && nowSec < (lastVerifiedSec - 3600)) {
          await _secureStorage.write(key: _keyClockTamperFlag, value: 'true');
          _isPro = false;
          _activePlanId = "EXPIRED";
          notifyListeners();
          return;
        }

        if (isLifetime) {
          _isPro = true;
          _isLifetime = true;
          _activePlanId = "LIFETIME";
          _expiryEpochSec = 0;
          notifyListeners();
          return;
        }

        if (expirySec > 0 && nowSec <= expirySec) {
          _isPro = true;
          _isLifetime = false;
          _expiryEpochSec = expirySec;
          _activePlanId = (await _secureStorage.read(key: _keyActivePlanId)) ?? "PRO";
          await _secureStorage.write(key: _keyLastVerifiedEpochSec, value: nowSec.toString());
          notifyListeners();
          return;
        }
      }

      // Check Trial status
      _isPro = false;
      _isLifetime = false;
      _expiryEpochSec = 0;
      _activePlanId = isTrialExpired() ? "EXPIRED" : "TRIAL";
    } catch (e) {
      _isPro = false;
    }
    notifyListeners();
  }

  bool isTrialExpired() {
    if (_isPro) return false;
    final installMs = _prefs?.getInt(_keyInstallTimestamp) ?? DateTime.now().millisecondsSinceEpoch;
    final elapsed = DateTime.now().millisecondsSinceEpoch - installMs;
    const trialDurationMs = 7 * 24 * 60 * 60 * 1000; // 7 days trial
    return elapsed >= trialDurationMs;
  }

  String getRemainingTimeStr() {
    if (_isLifetime) return "Lifetime License";

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_expiryEpochSec > 0) {
      final remainingSec = _expiryEpochSec - nowSec;
      if (remainingSec <= 0) return "Plan Expired";
      final d = remainingSec ~/ 86400;
      final h = (remainingSec % 86400) ~/ 3600;
      final m = (remainingSec % 3600) ~/ 60;
      final sb = StringBuffer();
      if (d > 0) sb.write("${d}d ");
      if (h > 0 || d > 0) sb.write("${h}h ");
      sb.write("${m}m");
      return sb.toString().trim();
    }

    final installMs = _prefs?.getInt(_keyInstallTimestamp) ?? DateTime.now().millisecondsSinceEpoch;
    const trialDurationMs = 7 * 24 * 60 * 60 * 1000;
    final remainingMs = trialDurationMs - (DateTime.now().millisecondsSinceEpoch - installMs);
    if (remainingMs <= 0) return "Trial Expired";

    final d = remainingMs ~/ (1000 * 60 * 60 * 24);
    final h = (remainingMs % (1000 * 60 * 60 * 24)) ~/ (1000 * 60 * 60);
    final m = (remainingMs % (1000 * 60 * 60)) ~/ (1000 * 60);
    final sb = StringBuffer();
    if (d > 0) sb.write("${d}d ");
    if (h > 0 || d > 0) sb.write("${h}h ");
    sb.write("${m}m");
    return sb.toString().trim();
  }

  String generateActivationRequest({String planId = "1_YEAR"}) {
    return Ed25519Verifier.generateActivationRequest(_hardwareId, planId: planId);
  }

  Future<bool> activateLicense(String licenseKeyInput) async {
    final cleanKey = licenseKeyInput.trim();
    if (cleanKey.isEmpty) {
      _lastActivationError = "License key cannot be empty.";
      notifyListeners();
      return false;
    }

    final lastVerifiedSecStr = await _secureStorage.read(key: _keyLastVerifiedEpochSec);
    final lastVerifiedSec = int.tryParse(lastVerifiedSecStr ?? '0') ?? 0;

    final result = await Ed25519Verifier.verifyLicense(
      cleanKey,
      _hardwareId,
      lastRecordedEpochSec: lastVerifiedSec,
    );

    if (result is VerificationResultValid) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _secureStorage.write(key: _keyActiveLicense, value: cleanKey);
      await _secureStorage.write(key: _keyActivePlanId, value: result.payload.plan);
      await _secureStorage.write(key: _keyIsLifetime, value: result.isLifetime ? 'true' : 'false');
      await _secureStorage.write(key: _keyExpiryEpochSec, value: result.payload.exp.toString());
      await _secureStorage.write(key: _keyLastVerifiedEpochSec, value: nowSec.toString());
      await _secureStorage.write(key: _keyClockTamperFlag, value: 'false');

      _isPro = true;
      _isLifetime = result.isLifetime;
      _expiryEpochSec = result.payload.exp;
      _activePlanId = result.payload.plan;
      _lastActivationError = "";

      notifyListeners();
      return true;
    } else if (result is VerificationResultInvalid) {
      _lastActivationError = result.reason;
      notifyListeners();
      return false;
    }

    _lastActivationError = "Unexpected verification error.";
    notifyListeners();
    return false;
  }
}
