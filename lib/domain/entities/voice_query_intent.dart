enum IntentType { query, action, transaction }

enum QueryTarget { todayTotal, monthTotal, categoryTotal, personTotal, unknown }

enum ActionTarget { deleteLast, undo, redo, unknown }

class VoiceQueryIntent {
  final IntentType type;
  final QueryTarget? queryTarget;
  final ActionTarget? actionTarget;
  final String? category;
  final String? person;
  final DateTime? date;

  VoiceQueryIntent({
    required this.type,
    this.queryTarget,
    this.actionTarget,
    this.category,
    this.person,
    this.date,
  });

  @override
  String toString() {
    return 'VoiceQueryIntent(type: $type, queryTarget: $queryTarget, actionTarget: $actionTarget, category: $category, person: $person)';
  }
}
