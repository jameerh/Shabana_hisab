import 'transaction_model.dart';

enum ActionType { add, edit, delete }

class TransactionAction {
  final ActionType type;
  final TransactionModel current;
  final TransactionModel? previous;

  TransactionAction({
    required this.type,
    required this.current,
    this.previous,
  });
}
