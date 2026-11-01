import 'package:drift/drift.dart';
import '../../data/database/database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Stream<List<Account>> watchAccounts(int profileId) {
    return (_db.select(_db.accounts)
      ..where((a) => a.profileId.equals(profileId) & a.active.equals(true))
      ..orderBy([(a) => OrderingTerm.asc(a.name)])
    ).watch();
  }

  Future<List<Account>> getAccounts(int profileId) async {
    return await (_db.select(_db.accounts)
      ..where((a) => a.profileId.equals(profileId) & a.active.equals(true))
    ).get();
  }

  Future<int> insertAccount(AccountsCompanion account) async {
    return await _db.into(_db.accounts).insert(account);
  }

  Future<bool> updateAccount(AccountsCompanion account) async {
    return await _db.update(_db.accounts).replace(account);
  }
  
  Future<int> softDeleteAccount(int accountId) async {
    return await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId))).write(
      const AccountsCompanion(active: Value(false))
    );
  }

  // Double entry adjustments
  Future<void> adjustBalance(int accountId, double amount, {bool isCredit = true}) async {
    await _db.transaction(() async {
      final account = await (_db.select(_db.accounts)..where((a) => a.id.equals(accountId))).getSingle();
      final newBalance = isCredit ? account.currentBalance + amount : account.currentBalance - amount;
      
      await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId))).write(
        AccountsCompanion(
          currentBalance: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        )
      );
    });
  }

  Future<void> transferFunds(int fromAccountId, int toAccountId, double amount) async {
    await _db.transaction(() async {
      await adjustBalance(fromAccountId, amount, isCredit: false);
      await adjustBalance(toAccountId, amount, isCredit: true);
    });
  }
}
