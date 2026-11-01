import 'package:drift/drift.dart';
import '../../../data/database/database.dart';

class SeasonalityEngine {
  final AppDatabase _db;

  SeasonalityEngine(this._db);

  Future<void> execute(int profileId) async {
    final now = DateTime.now();

    // Check upcoming calendar events (e.g. Diwali in Oct/Nov, Ramadan, School Fees in June)
    if (now.month == 10 || now.month == 11) {
      await _db.into(_db.seasonalityState).insertOnConflictUpdate(SeasonalityStateCompanion.insert(
        profileId: profileId,
        seasonName: 'DIWALI',
        expectedSpikePct: const Value(25.0),
        affectedCategories: const Value('["Shopping", "Gifts", "Sweets"]'),
        predictedStartDate: Value(DateTime(now.year, 10, 20)),
        predictedEndDate: Value(DateTime(now.year, 11, 15)),
      ));
    } else if (now.month == 5 || now.month == 6) {
      await _db.into(_db.seasonalityState).insertOnConflictUpdate(SeasonalityStateCompanion.insert(
        profileId: profileId,
        seasonName: 'SCHOOL_FEES',
        expectedSpikePct: const Value(40.0),
        affectedCategories: const Value('["Education", "Books", "Fees"]'),
        predictedStartDate: Value(DateTime(now.year, 5, 25)),
        predictedEndDate: Value(DateTime(now.year, 6, 20)),
      ));
    } else {
      await _db.into(_db.seasonalityState).insertOnConflictUpdate(SeasonalityStateCompanion.insert(
        profileId: profileId,
        seasonName: 'MONSOON',
        expectedSpikePct: const Value(15.0),
        affectedCategories: const Value('["Rainwear", "Vehicle Maintenance"]'),
        predictedStartDate: Value(DateTime(now.year, 6, 1)),
        predictedEndDate: Value(DateTime(now.year, 8, 31)),
      ));
    }
  }
}
