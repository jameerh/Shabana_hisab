import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';
import 'package:snaphisaab/presentation/accounts/account_manager_view.dart';
import 'package:snaphisaab/data/repositories/account_repository.dart';
import 'package:snaphisaab/data/database/database.dart';

class FakeAccountRepository implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts(int profileId) {
    return Stream.value([]);
  }

  @override
  Future<List<Account>> getAccounts(int profileId) async => [];

  @override
  Future<int> insertAccount(dynamic account) async => 1;

  @override
  Future<bool> updateAccount(dynamic account) async => true;

  @override
  Future<int> softDeleteAccount(int accountId) async => 1;

  @override
  Future<void> adjustBalance(int accountId, double amount, {bool isCredit = true}) async {}

  @override
  Future<void> transferFunds(int fromAccountId, int toAccountId, double amount) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      languageController = LanguageController();
      await languageController.init();
    } catch (_) {}
  });

  Widget buildTestWidget(Widget child) {
    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        return MaterialApp(
          locale: languageController.currentLocale ?? const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        );
      },
    );
  }

  group('L3.1 Accounts Localization Tests', () {
    testWidgets('AccountManagerView renders English header in English mode', (tester) async {
      await languageController.setLanguage(AppLanguage.english);

      await tester.pumpWidget(
        buildTestWidget(AccountManagerView(profileId: 1, repository: FakeAccountRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Manager'), findsOneWidget);
      expect(find.text('खाते व्यवस्थापक'), findsNothing);
    });

    testWidgets('AccountManagerView renders Marathi header in Marathi mode', (tester) async {
      await languageController.setLanguage(AppLanguage.marathi);

      await tester.pumpWidget(
        buildTestWidget(AccountManagerView(profileId: 1, repository: FakeAccountRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text('खाते व्यवस्थापक'), findsOneWidget);
      expect(find.text('Account Manager'), findsNothing);
    });

    testWidgets('AccountManagerView renders both headers in English+Marathi mode', (tester) async {
      await languageController.setLanguage(AppLanguage.englishMarathi);

      await tester.pumpWidget(
        buildTestWidget(AccountManagerView(profileId: 1, repository: FakeAccountRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Manager'), findsOneWidget);
      expect(find.text('खाते व्यवस्थापक'), findsOneWidget);
    });
  });
}
