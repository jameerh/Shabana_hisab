import '../../main.dart';
import '../database/database.dart';
import 'package:drift/drift.dart';

class CalculatorRepository {
  Stream<List<CalculatorEntry>> watchHistory(int profileId) {
    return database.watchCalculatorHistory(profileId);
  }

  Future<void> saveEntry({
    required int profileId,
    required String expression,
    required double value,
    required String source,
    bool isCurrency = false,
  }) async {
    await database.addCalculatorEntry(CalculatorEntriesCompanion.insert(
      profileId: profileId,
      expression: expression,
      parsedValue: value,
      sourceType: source,
      isCurrency: Value(isCurrency),
    ));
  }

  Future<void> clearHistory(int profileId) async {
    await database.clearCalculatorHistory(profileId);
  }

  Future<void> updateEntry(CalculatorEntry entry) async {
    await database.update(database.calculatorEntries).replace(entry);
  }

  Future<void> deleteEntry(CalculatorEntry entry) async {
    await database.delete(database.calculatorEntries).delete(entry);
  }
}
