import 'package:flutter/material.dart';

enum AppLanguage {
  followDevice,
  english,
  marathi,
  englishMarathi,
}

extension AppLanguageExtension on AppLanguage {
  String get storageKey {
    switch (this) {
      case AppLanguage.followDevice:
        return 'follow_device';
      case AppLanguage.english:
        return 'english';
      case AppLanguage.marathi:
        return 'marathi';
      case AppLanguage.englishMarathi:
        return 'english_marathi';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.followDevice:
        return 'Follow Device (सिस्टमनुसार)';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.marathi:
        return 'मराठी';
      case AppLanguage.englishMarathi:
        return 'English + मराठी';
    }
  }

  bool get isBilingual => this == AppLanguage.englishMarathi;

  /// Returns the underlying Flutter [Locale] for [MaterialApp].
  /// Note: [englishMarathi] is a presentation mode that maps to [Locale('en')],
  /// rather than inventing an artificial locale string.
  Locale? get locale {
    switch (this) {
      case AppLanguage.followDevice:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.marathi:
        return const Locale('mr');
      case AppLanguage.englishMarathi:
        return const Locale('en');
    }
  }

  static AppLanguage fromStorageKey(String? key) {
    switch (key) {
      case 'follow_device':
        return AppLanguage.followDevice;
      case 'marathi':
        return AppLanguage.marathi;
      case 'english_marathi':
        return AppLanguage.englishMarathi;
      case 'english':
      default:
        return AppLanguage.english;
    }
  }
}
