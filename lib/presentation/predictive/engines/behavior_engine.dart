import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class BehaviorEngine {
  final AppDatabase _db;

  BehaviorEngine(this._db);

  Future<void> execute(int profileId) async {
    final now = DateTime.now();
    final past60Days = now.subtract(const Duration(days: 60));

    final txs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(past60Days)))
        .get();

    Map<String, List<Transaction>> partyMap = {};
    for (var t in txs) {
      partyMap.putIfAbsent(t.partyName.toLowerCase(), () => []).add(t);
    }

    for (var entry in partyMap.entries) {
      final list = entry.value;
      if (list.length >= 3) {
        double totalAmt = 0;
        for (var t in list) totalAmt += t.amount;
        double avgAmt = totalAmt / list.length;

        String frequency = 'MONTHLY';
        if (list.length >= 15) frequency = 'DAILY';
        else if (list.length >= 6) frequency = 'WEEKLY';

        String score = list.length >= 8 ? 'ROUTINE' : 'OCCASIONAL';

        await _db.into(_db.behaviorState).insertOnConflictUpdate(BehaviorStateCompanion.insert(
          profileId: profileId,
          patternName: entry.key,
          frequency: Value(frequency),
          typicalAmount: Value(avgAmt),
          dayOfWeek: Value(list.first.timestamp.weekday),
          routineScore: Value(score),
          lastDetected: Value(DateTime.now()),
        ));
      }
    }
  }
}
