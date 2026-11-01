import 'package:flutter/material.dart';
import '../services/action_registry.dart';

class QuickActionsSection extends StatefulWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  _QuickActionsSectionState createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  List<QuickAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final actions = await ActionRegistry().getAvailableActions(context);
    setState(() {
      _actions = actions;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _actions.map((action) => _buildActionChip(action)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(QuickAction action) {
    return ActionChip(
      avatar: Icon(action.icon, color: action.color, size: 18),
      label: Text(action.label),
      onPressed: action.onExecute,
      backgroundColor: action.color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
