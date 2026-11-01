import 'package:flutter/material.dart';

class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onExecute;
  final int order;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onExecute,
    this.order = 100,
  });
}

abstract class ActionProvider {
  Future<List<QuickAction>> getQuickActions(BuildContext context);
}

class ActionRegistry {
  static final ActionRegistry _instance = ActionRegistry._internal();
  factory ActionRegistry() => _instance;
  ActionRegistry._internal();

  final List<ActionProvider> _providers = [];

  void registerProvider(ActionProvider provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
    }
  }

  void unregisterProvider(ActionProvider provider) {
    _providers.remove(provider);
  }

  Future<List<QuickAction>> getAvailableActions(BuildContext context) async {
    List<QuickAction> allActions = [];
    for (var provider in _providers) {
      final actions = await provider.getQuickActions(context);
      allActions.addAll(actions);
    }
    
    allActions.sort((a, b) => a.order.compareTo(b.order));
    return allActions;
  }
}
