import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/data/repositories/calculator_repository.dart';
import 'package:snaphisaab/data/repositories/budget_repository.dart';
import 'package:snaphisaab/data/repositories/account_repository.dart';
import 'package:snaphisaab/data/repositories/goal_repository.dart';
import 'package:snaphisaab/presentation/budget/services/budget_engine.dart';
import 'package:snaphisaab/presentation/goals/services/goal_engine.dart';
import 'package:snaphisaab/presentation/home/services/budget_dashboard_provider.dart';
import 'package:snaphisaab/presentation/home/services/dashboard_registry.dart';
import 'package:snaphisaab/presentation/intelligence/intelligence_orchestrator.dart';
import 'package:snaphisaab/data/services/auth_service.dart';
import 'package:snaphisaab/data/services/profile_service.dart';
import 'package:snaphisaab/presentation/home/home_view.dart';
import 'package:snaphisaab/core/localization/language_controller.dart';
import 'package:snaphisaab/core/localization/app_language.dart';
import 'package:snaphisaab/l10n/app_localizations.dart';
import 'package:snaphisaab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    languageController = LanguageController();
    await languageController.init();
  });

  testWidgets('Drawer menu contains Health Hisaab alongside Kirana & Grocery', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    database = db;
    authService = AuthService(db);
    calculatorRepository = CalculatorRepository();
    budgetRepository = BudgetRepository(db);
    accountRepository = AccountRepository(db);
    goalRepository = GoalRepository(db);
    healthRepository = HealthRepository(db);
    budgetEngine = BudgetEngine();
    goalEngine = GoalEngine();
    budgetDashboardProvider = BudgetDashboardProvider();
    DashboardRegistry().registerProvider(budgetDashboardProvider);
    intelligenceOrchestrator = IntelligenceOrchestrator(db);

    await ProfileService.ensureInitialized();

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await languageController.setLanguage(AppLanguage.english);

    await tester.pumpWidget(
      ListenableBuilder(
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
            home: HomeView(),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Open drawer
    final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Tap on Utilities ExpansionTile to expand it
    await tester.tap(find.text('Utilities'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify Kirana & Grocery is present
    expect(find.text('Kirana & Grocery'), findsOneWidget);

    // Verify Health Hisaab is present right in the menu
    expect(find.text('Health Hisaab'), findsOneWidget);

    await db.close();
  });
}
