import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';

class LanguageController extends ChangeNotifier {
  static const String _prefsKey = 'app_language';
  
  AppLanguage _currentLanguage = AppLanguage.english;
  bool _isInitialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isBilingual => _currentLanguage.isBilingual;
  bool get isInitialized => _isInitialized;

  Locale? get currentLocale => _currentLanguage.locale;

  /// Loads saved language preference from [SharedPreferences].
  /// Defaults conservatively to [AppLanguage.english] for safe backward compatibility.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefsKey);
      _currentLanguage = AppLanguageExtension.fromStorageKey(savedKey);
    } catch (e) {
      _currentLanguage = AppLanguage.english;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sets the application UI language and notifies presentation listeners instantly.
  /// 
  /// FOS INVARIANCE GUARANTEE (ADR-020):
  /// Changing language updates presentation state ONLY. Zero database mutations occur,
  /// and zero financial or predictive engine pipelines are re-executed.
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.storageKey);
    } catch (_) {}
  }
}
