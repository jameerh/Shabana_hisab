import 'package:flutter/material.dart';

abstract class HomeSectionProvider {
  String get id;
  int get order; // Lower number = higher up on screen
  Widget buildSection(BuildContext context);
}

class HomeSectionRegistry {
  static final HomeSectionRegistry _instance = HomeSectionRegistry._internal();
  factory HomeSectionRegistry() => _instance;
  HomeSectionRegistry._internal();

  final List<HomeSectionProvider> _providers = [];

  void registerProvider(HomeSectionProvider provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
      _providers.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  void unregisterProvider(String id) {
    _providers.removeWhere((p) => p.id == id);
  }

  List<Widget> buildAllSections(BuildContext context) {
    return _providers.map((p) => p.buildSection(context)).toList();
  }
}
