import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class TrendEngine {
  final AppDatabase _db;

  TrendEngine(this._db);

  Future<void> execute(int profileId) async {
    final now = DateTime.now();
    final past30Days = now.subtract(const Duration(days: 30));
    final prev30Days = now.subtract(const Duration(days: 60));

    final currentTxs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(past30Days)))
        .get();

    final prevTxs = await (_db.select(_db.transactions)
          ..where((t) => t.profileId.equals(profileId) & t.timestamp.isBiggerOrEqualValue(prev30Days) & t.timestamp.isSmallerThanValue(past30Days)))
        .get();

    Map<String, double> currentCategorySpend = {};
    Map<String, double> prevCategorySpend = {};

    for (var t in currentTxs) {
      if (t.type == 'Expense' && t.categoryName != null) {
        currentCategorySpend[t.categoryName!] = (currentCategorySpend[t.categoryName!] ?? 0) + t.amount;
      }
    }

    for (var t in prevTxs) {
      if (t.type == 'Expense' && t.categoryName != null) {
        prevCategorySpend[t.categoryName!] = (prevCategorySpend[t.categoryName!] ?? 0) + t.amount;
      }
    }

    for (var cat in currentCategorySpend.keys) {
      final curr = currentCategorySpend[cat] ?? 0;
      final prev = prevCategorySpend[cat] ?? 0;

      double pct = 0;
      String velocity = 'STABLE';
      if (prev > 0) {
        pct = ((curr - prev) / prev) * 100.0;
        if (pct > 10.0) velocity = 'INCREASING';
        if (pct < -10.0) velocity = 'DECREASING';
      }

      await _db.into(_db.trendState).insertOnConflictUpdate(TrendStateCompanion.insert(
        profileId: profileId,
        categoryName: cat,
        periodType: const Value('MONTHLY'),
        percentageChange: Value(pct),
        velocity: Value(velocity),
        confidence: Value(currentTxs.length > 10 ? 0.9 : 0.6),
        lastCalculated: Value(DateTime.now()),
      ));
    }
  }
}
