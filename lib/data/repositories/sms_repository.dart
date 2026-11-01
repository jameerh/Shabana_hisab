import 'package:drift/drift.dart';
import '../database/database.dart';
import '../../core/sms/sms_parsed_result.dart';
import '../../core/sms/sms_deduplicator.dart';
import '../../main.dart';

class DiscoveredAccount {
  final String bankName;
  final String accountNumberLast4;
  final String accountType;
  final int transactionCount;
  SmsAccountStatus status;

  DiscoveredAccount({
    required this.bankName,
    required this.accountNumberLast4,
    required this.accountType,
    required this.transactionCount,
    this.status = SmsAccountStatus.PENDING,
  });
}

class SmsRepository {
  /// Watches all tracked SMS accounts for a profile
  Stream<List<SmsTrackedAccount>> watchTrackedAccounts(int profileId) {
    return (database.select(database.smsTrackedAccounts)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .watch();
  }

  /// Fetches existing non-reversible SHA-256 fingerprints
  Future<Set<String>> getExistingFingerprints(int profileId) async {
    final rows = await (database.select(database.smsImportFingerprints)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .get();
    return rows.map((r) => r.hashFingerprint).toSet();
  }

  /// Processes raw parsed results from SmsService scan:
  /// 1. Discovers accounts and updates/inserts into SmsTrackedAccounts
  /// 2. Filters out results for accounts that are NOT PERMITTED
  /// 3. Applies SHA-256 fingerprint deduplication
  Future<List<SmsParsedResult>> processScanResults({
    required int profileId,
    required List<SmsParsedResult> rawResults,
  }) async {
    // 1. Fetch existing tracked accounts & fingerprints
    final existingAccounts = await (database.select(database.smsTrackedAccounts)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .get();

    final existingFingerprints = await getExistingFingerprints(profileId);
    final existingTx = await (database.select(database.transactions)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .get();

    // 2. Account Discovery Phase: Register new discovered accounts in PENDING status if not present
    for (final result in rawResults) {
      final match = existingAccounts.firstWhere(
        (a) => a.bankName == result.bankName && a.accountNumberLast4 == result.accountNumberLast4,
        orElse: () => SmsTrackedAccount(
          id: -1,
          profileId: profileId,
          bankName: result.bankName,
          accountNumberLast4: result.accountNumberLast4,
          accountType: result.accountType,
          status: SmsAccountStatus.PENDING,
          discoveredAt: DateTime.now(),
        ),
      );

      if (match.id == -1) {
        final insertedId = await database.into(database.smsTrackedAccounts).insert(
          SmsTrackedAccountsCompanion.insert(
            profileId: profileId,
            bankName: result.bankName,
            accountNumberLast4: result.accountNumberLast4,
            accountType: result.accountType,
            status: SmsAccountStatus.PENDING,
          ),
        );
        existingAccounts.add(SmsTrackedAccount(
          id: insertedId,
          profileId: profileId,
          bankName: result.bankName,
          accountNumberLast4: result.accountNumberLast4,
          accountType: result.accountType,
          status: SmsAccountStatus.PENDING,
          discoveredAt: DateTime.now(),
        ));
      }
    }

    // 3. Filter candidates: Permitted Accounts ONLY Invariant
    final permittedMap = {
      for (var a in existingAccounts) '${a.bankName}_${a.accountNumberLast4}': a.status
    };

    final permittedResults = rawResults.where((r) {
      final status = permittedMap['${r.bankName}_${r.accountNumberLast4}'];
      return status == SmsAccountStatus.PERMITTED;
    }).toList();

    // 4. SHA-256 & Financial Deduplication
    return SmsDeduplicator.filterNewResults(
      candidates: permittedResults,
      existingHashes: existingFingerprints,
      existingTransactions: existingTx,
    );
  }

  /// Updates status of a tracked account (PENDING, PERMITTED, IGNORED, REVOKED)
  Future<void> updateAccountStatus(int accountId, SmsAccountStatus status) async {
    await (database.update(database.smsTrackedAccounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .write(SmsTrackedAccountsCompanion(status: Value(status)));
  }

  /// Commits approved SMS transactions to the main Transactions table
  /// and updates core account balances authoritative via existing transaction creation paths.
  Future<int> commitApprovedTransactions({
    required int profileId,
    required List<SmsParsedResult> approvedResults,
  }) async {
    int imported = 0;

    for (final r in approvedResults) {
      // Find matching Account or default
      final accounts = await (database.select(database.accounts)
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .get();

      final matchingAcc = accounts.firstWhere(
        (a) => a.name.toLowerCase().contains(r.bankName.toLowerCase()) || a.name.contains(r.accountNumberLast4),
        orElse: () => accounts.first,
      );

      // Create transaction via standard Drift insert
      final txId = await database.into(database.transactions).insert(
        TransactionsCompanion.insert(
          amount: r.amount,
          partyName: r.partyName,
          type: r.transactionType,
          categoryName: Value(r.suggestedCategory),
          profileId: profileId,
          accountId: Value(matchingAcc.id),
          timestamp: r.timestamp,
        ),
      );

      // Update matching account current balance cleanly
      final newBal = r.transactionType == 'Expense'
          ? matchingAcc.currentBalance - r.amount
          : matchingAcc.currentBalance + r.amount;

      await (database.update(database.accounts)..where((tbl) => tbl.id.equals(matchingAcc.id)))
          .write(AccountsCompanion(currentBalance: Value(newBal)));

      // Record SHA-256 fingerprint in database
      await database.into(database.smsImportFingerprints).insert(
        SmsImportFingerprintsCompanion.insert(
          profileId: profileId,
          hashFingerprint: r.hashFingerprint,
        ),
      );

      imported++;
    }

    return imported;
  }

  /// Clears import history for privacy
  Future<void> deleteImportHistory(int profileId) async {
    await (database.delete(database.smsImportFingerprints)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .go();
    await (database.delete(database.smsImportHistory)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .go();
  }

  /// Deletes all discovered SMS accounts and resets SMS tracking completely
  Future<void> deleteAllSmsData(int profileId) async {
    await deleteImportHistory(profileId);
    await (database.delete(database.smsTrackedAccounts)
          ..where((tbl) => tbl.profileId.equals(profileId)))
        .go();
  }
}
