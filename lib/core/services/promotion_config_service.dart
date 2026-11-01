import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines an individual promotional item/image in the ad sequence
class AdItem {
  final String id;
  final String imagePath; // Asset path or local file path
  final String title;
  final String subtitle;
  final int durationMs; // Duration to display this specific image in milliseconds

  const AdItem({
    required this.id,
    required this.imagePath,
    this.title = '',
    this.subtitle = '',
    this.durationMs = 500,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'title': title,
        'subtitle': subtitle,
        'durationMs': durationMs,
      };

  factory AdItem.fromJson(Map<String, dynamic> json) => AdItem(
        id: json['id'] as String? ?? 'ad_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: json['imagePath'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        durationMs: json['durationMs'] as int? ?? 500,
      );

  AdItem copyWith({
    String? id,
    String? imagePath,
    String? title,
    String? subtitle,
    int? durationMs,
  }) {
    return AdItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

/// Central Configuration Service for Ads, Banners & Splash Sequences
/// Persisted locally via SharedPreferences and editable on-the-fly.
class PromotionConfigService extends ChangeNotifier {
  static final PromotionConfigService instance = PromotionConfigService._internal();
  PromotionConfigService._internal();

  static const String _keyStartupEnabled = 'PROMO_STARTUP_ENABLED';
  static const String _keyStartupAds = 'PROMO_STARTUP_ADS_JSON';
  static const String _keyShareEnabled = 'PROMO_SHARE_ENABLED';
  static const String _keyShareDurationMs = 'PROMO_SHARE_DURATION_MS';
  static const String _keyShareAds = 'PROMO_SHARE_ADS_JSON';

  bool _initialized = false;
  bool _startupEnabled = true;
  bool _shareEnabled = true;
  int _shareDurationMs = 800;

  List<AdItem> _startupAds = [];
  List<AdItem> _shareAds = [];

  bool get startupEnabled => _startupEnabled;
  bool get shareEnabled => _shareEnabled;
  int get shareDurationMs => _shareDurationMs;
  List<AdItem> get startupAds => List.unmodifiable(_startupAds);
  List<AdItem> get shareAds => List.unmodifiable(_shareAds);

  /// Default predefined items
  static List<AdItem> get defaultStartupAds => const [
        AdItem(
          id: 'startup_1_multiservice',
          imagePath: 'assets/shabana_multi_service_ad.png',
          title: 'Shabana Multi Service',
          subtitle: 'CSC, Financial & Government Services',
          durationMs: 500,
        ),
        AdItem(
          id: 'startup_2_finallogo',
          imagePath: 'assets/shabana_final_fix_logo.png',
          title: 'शबाना हिशेब ॲप',
          subtitle: 'Voice-First Expense Manager',
          durationMs: 500,
        ),
      ];

  static List<AdItem> get defaultShareAds => const [
        AdItem(
          id: 'share_1_multiservice',
          imagePath: 'assets/shabana_multi_service_ad.png',
          title: 'Shabana Multi Service',
          subtitle: 'विश्वसनीय आर्थिक आणि डिजिटल सेवा केंद्र',
          durationMs: 800,
        ),
      ];

  /// Initialize and load configurations from local storage
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    _startupEnabled = prefs.getBool(_keyStartupEnabled) ?? true;
    _shareEnabled = prefs.getBool(_keyShareEnabled) ?? true;
    _shareDurationMs = prefs.getInt(_keyShareDurationMs) ?? 800;

    final startupJsonStr = prefs.getString(_keyStartupAds);
    if (startupJsonStr != null && startupJsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(startupJsonStr);
        _startupAds = list.map((e) => AdItem.fromJson(e)).toList();
      } catch (e) {
        _startupAds = List.from(defaultStartupAds);
      }
    } else {
      _startupAds = List.from(defaultStartupAds);
    }

    final shareJsonStr = prefs.getString(_keyShareAds);
    if (shareJsonStr != null && shareJsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(shareJsonStr);
        _shareAds = list.map((e) => AdItem.fromJson(e)).toList();
      } catch (e) {
        _shareAds = List.from(defaultShareAds);
      }
    } else {
      _shareAds = List.from(defaultShareAds);
    }

    _initialized = true;
    notifyListeners();
  }

  /// Save current configuration to storage
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStartupEnabled, _startupEnabled);
    await prefs.setBool(_keyShareEnabled, _shareEnabled);
    await prefs.setInt(_keyShareDurationMs, _shareDurationMs);
    await prefs.setString(
      _keyStartupAds,
      jsonEncode(_startupAds.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      _keyShareAds,
      jsonEncode(_shareAds.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  /// Update Startup Ads toggle
  Future<void> setStartupEnabled(bool enabled) async {
    _startupEnabled = enabled;
    await save();
  }

  /// Update Share Ads toggle
  Future<void> setShareEnabled(bool enabled) async {
    _shareEnabled = enabled;
    await save();
  }

  /// Update Share Modal display time
  Future<void> setShareDurationMs(int durationMs) async {
    _shareDurationMs = durationMs;
    await save();
  }

  /// Update specific startup item duration
  Future<void> updateStartupItemDuration(int index, int durationMs) async {
    if (index >= 0 && index < _startupAds.length) {
      _startupAds[index] = _startupAds[index].copyWith(durationMs: durationMs);
      await save();
    }
  }

  /// Add new image to Startup sequence
  Future<void> addStartupAd(AdItem item) async {
    _startupAds.add(item);
    await save();
  }

  /// Remove image from Startup sequence
  Future<void> removeStartupAd(int index) async {
    if (index >= 0 && index < _startupAds.length) {
      _startupAds.removeAt(index);
      await save();
    }
  }

  /// Reorder startup ads
  Future<void> reorderStartupAds(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _startupAds.removeAt(oldIndex);
    _startupAds.insert(newIndex, item);
    await save();
  }

  /// Add new image to Share list
  Future<void> addShareAd(AdItem item) async {
    _shareAds.add(item);
    await save();
  }

  /// Remove image from Share list
  Future<void> removeShareAd(int index) async {
    if (index >= 0 && index < _shareAds.length) {
      _shareAds.removeAt(index);
      await save();
    }
  }

  /// Update specific share item duration
  Future<void> updateShareItemDuration(int index, int durationMs) async {
    if (index >= 0 && index < _shareAds.length) {
      _shareAds[index] = _shareAds[index].copyWith(durationMs: durationMs);
      await save();
    }
  }

  /// Reset to factory default configuration
  Future<void> resetToDefaults() async {
    _startupEnabled = true;
    _shareEnabled = true;
    _shareDurationMs = 800;
    _startupAds = List.from(defaultStartupAds);
    _shareAds = List.from(defaultShareAds);
    await save();
  }
}
