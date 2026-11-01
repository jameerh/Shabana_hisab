import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/repositories/sms_repository.dart';
import 'package:snaphisaab/core/sms/sms_parser_engine.dart';
import 'package:snaphisaab/main.dart';

void main() {
  late AppDatabase db;
  late SmsRepository repository;
  late int profileId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    database = db;
    repository = SmsRepository();

    profileId = await db.into(db.profiles).insert(
      ProfilesCompanion.insert(
        name: 'Test Profile',
        type: ProfileType.PERSONAL,
      ),
    );

    await db.into(db.accounts).insert(
      AccountsCompanion.insert(
        profileId: profileId,
        name: 'HDFC Bank Account',
        type: 'BANK',
        currentBalance: const Value(50000.0),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SmsRepository Account Permission Invariant Tests', () {
    test('Unapproved (PENDING) accounts produce ZERO candidate transactions', () async {
      final parse1 = SmsParserEngine.parse(
        senderId: 'AD-HDFCBK',
        body: 'Rs. 1000 debited from A/c **4321 to Swiggy.',
        timestamp: DateTime.now(),
      )!;

      final results = await repository.processScanResults(
        profileId: profileId,
        rawResults: [parse1],
      );

      // Account discovered, status PENDING -> Candidates filtered to 0
      expect(results.isEmpty, isTrue);

      final tracked = await db.select(db.smsTrackedAccounts).get();
      expect(tracked.length, equals(1));
      expect(tracked.first.status, equals(SmsAccountStatus.PENDING));
    });

    test('PERMITTED accounts generate transaction candidates and commit cleanly', () async {
      final parse1 = SmsParserEngine.parse(
        senderId: 'AD-HDFCBK',
        body: 'Rs. 1200 debited from A/c **4321 to Amazon.',
        timestamp: DateTime.now(),
      )!;

      // 1. Initial process scan (creates PENDING)
      await repository.processScanResults(profileId: profileId, rawResults: [parse1]);

      // 2. Set account status to PERMITTED
      final tracked = await db.select(db.smsTrackedAccounts).get();
      await repository.updateAccountStatus(tracked.first.id, SmsAccountStatus.PERMITTED);

      // 3. Re-process scan
      final candidates = await repository.processScanResults(
        profileId: profileId,
        rawResults: [parse1],
      );

      expect(candidates.length, equals(1));

      // 4. Commit transaction
      final count = await repository.commitApprovedTransactions(
        profileId: profileId,
        approvedResults: candidates,
      );

      expect(count, equals(1));

      final tx = await db.select(db.transactions).get();
      expect(tx.length, equals(1));
      expect(tx.first.amount, equals(1200.0));
    });
  });
}
