import 'package:flutter/material.dart';

abstract class NavigationCapability {
  String get id;
  String get label;
  IconData get icon;
  void navigate(BuildContext context);
}

class NavigationRegistry {
  static final NavigationRegistry _instance = NavigationRegistry._internal();
  factory NavigationRegistry() => _instance;
  NavigationRegistry._internal();

  final List<NavigationCapability> _bottomNavItems = [];
  final List<NavigationCapability> _drawerItems = [];

  void registerBottomNav(NavigationCapability capability) {
    if (!_bottomNavItems.contains(capability)) {
      _bottomNavItems.add(capability);
    }
  }

  void registerDrawerItem(NavigationCapability capability) {
    if (!_drawerItems.contains(capability)) {
      _drawerItems.add(capability);
    }
  }

  List<NavigationCapability> get bottomNavItems => List.unmodifiable(_bottomNavItems);
  List<NavigationCapability> get drawerItems => List.unmodifiable(_drawerItems);
}
