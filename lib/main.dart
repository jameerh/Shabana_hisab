import 'package:flutter/material.dart';
import 'presentation/auth/login_view.dart';
import 'data/database/database.dart';
import 'data/services/profile_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/security_service.dart';
import 'presentation/auth/lock_screen.dart';
import 'presentation/home/services/recurring_schedule_engine.dart';
import 'data/repositories/calculator_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/goal_repository.dart';
import 'presentation/budget/services/budget_engine.dart';
import 'presentation/goals/services/goal_engine.dart';
import 'presentation/home/services/budget_dashboard_provider.dart';
import 'presentation/home/services/dashboard_registry.dart';
import 'presentation/intelligence/intelligence_orchestrator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/localization/language_controller.dart';
import 'data/repositories/health_repository.dart';
import 'data/repositories/gadi_repository.dart';
import 'core/security/subscription_manager.dart';
import 'presentation/core/widgets/sequential_splash_screen.dart';

// Global database instance
late AppDatabase database;
late final AuthService authService;
late final CalculatorRepository calculatorRepository;
late final BudgetRepository budgetRepository;
late final AccountRepository accountRepository;
late final GoalRepository goalRepository;
late HealthRepository healthRepository;
late GadiRepository gadiRepository;
late final BudgetEngine budgetEngine;
late final GoalEngine goalEngine;
late final BudgetDashboardProvider budgetDashboardProvider;
late final IntelligenceOrchestrator intelligenceOrchestrator;
late final LanguageController languageController;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShabanaHisaabApp());
}

class ShabanaHisaabApp extends StatefulWidget {
  const ShabanaHisaabApp({super.key});

  @override
  State<ShabanaHisaabApp> createState() => _ShabanaHisaabAppState();
}

class _ShabanaHisaabAppState extends State<ShabanaHisaabApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isInitialized = false;
  bool _splashComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      database = AppDatabase();
      authService = AuthService(database);
      
      // Initialize services
      await ProfileService.ensureInitialized();
      await authService.init();

      // Initialize Repositories and Engines
      calculatorRepository = CalculatorRepository();
      budgetRepository = BudgetRepository(database);
      accountRepository = AccountRepository(database);
      goalRepository = GoalRepository(database);
      healthRepository = HealthRepository(database);
      gadiRepository = GadiRepository(database);
      budgetEngine = BudgetEngine();
      goalEngine = GoalEngine();
      
      budgetDashboardProvider = BudgetDashboardProvider();
      DashboardRegistry().registerProvider(budgetDashboardProvider);
      
      intelligenceOrchestrator = IntelligenceOrchestrator(database);

      // Initialize Recurring Schedule Engine
      final recurringEngine = RecurringScheduleEngine(database);
      await recurringEngine.processDueSchedules();
      
      // Initialize Language Controller
      languageController = LanguageController();
      await languageController.init();

      // Initialize Subscription Manager
      await SubscriptionManager.instance.initialize();

      // Check lock status
      final lockEnabled = await SecurityService.isLockEnabled();
      if (mounted) {
        setState(() {
          _isLocked = lockEnabled;
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("Initialization error: $e\n$stack");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized && _error == null) {
      _checkLockStatus();
      RecurringScheduleEngine(database).processDueSchedules();
    }
  }

  Future<void> _checkLockStatus() async {
    final lockEnabled = await SecurityService.isLockEnabled();
    if (mounted) {
      setState(() {
        _isLocked = lockEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || !_splashComplete) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SequentialSplashScreen(
          onComplete: () {
            if (mounted) {
              setState(() {
                _splashComplete = true;
              });
            }
          },
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Initialization Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _isInitialized = false;
                      _error = null;
                      _initializeApp();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLocked) {
      return ListenableBuilder(
        listenable: languageController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: languageController.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
            home: LockScreen(onAuthenticated: () {
              setState(() => _isLocked = false);
            }),
          );
        },
      );
    }

    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Shabana Hisaab',
          debugShowCheckedModeBanner: false,
          locale: languageController.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          home: LoginView(authService: authService),
        );
      },
    );
  }
}
