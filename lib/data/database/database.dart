import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// Drift Table Definition
enum ProfileType { SHOP, FARMER, SALON, PERSONAL }

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text().map(const EnumNameConverter(ProfileType.values))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get name => text()();
  TextColumn get type => text()(); // CASH, BANK, UPI, CREDIT_CARD, LOAN, WALLET, INVESTMENT, ASSET, LIABILITY
  RealColumn get openingBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get partyName => text()();
  TextColumn get type => text()(); // Expense, Income, Transfer
  TextColumn get categoryName => text().nullable()(); 
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)(); // Nullable for migration
  IntColumn get toAccountId => integer().nullable().customConstraint('REFERENCES accounts(id)')(); // For Transfers
  DateTimeColumn get timestamp => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get images => text().nullable()(); // stores JSON array of paths
  TextColumn get metadata => text().nullable()(); // stores JSON metadata (e.g., fuel tracking)

  @override
  List<Index> get indexes => [
    Index('idx_profile_time', 'CREATE INDEX idx_profile_time ON transactions (profile_id, timestamp)'),
    Index('idx_transactions_profile', 'CREATE INDEX idx_transactions_profile ON transactions (profile_id)'),
  ];
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get keywords => text()(); 
  TextColumn get type => text()(); 
  TextColumn get profileType => text().nullable()();
  IntColumn get profileId => integer().nullable().references(Profiles, #id)();
  TextColumn get color => text().withDefault(const Constant('#FF9800'))();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // ADMIN | USER
  BoolColumn get canEdit => boolean().withDefault(const Constant(false))();
  BoolColumn get canDelete => boolean().withDefault(const Constant(false))();
  BoolColumn get canExport => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewDashboard => boolean().withDefault(const Constant(false))();
  BoolColumn get isPremiumUser => boolean().withDefault(const Constant(false))();
  TextColumn get planType => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class ShopSettings extends Table {
  IntColumn get id => integer().autoIncrement()(); // Just 1 row
  TextColumn get shopName => text().nullable()();
  TextColumn get ownerName => text().nullable()();
  TextColumn get mobileNumber => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get gstNumber => text().nullable()();
  TextColumn get upiId => text().nullable()();
  TextColumn get invoicePrefix => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class GroceryLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get profileId => integer().references(Profiles, #id)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<Index> get indexes => [
    Index('idx_grocery_list_profile', 'CREATE INDEX idx_grocery_list_profile ON grocery_lists (profile_id)'),
  ];
}

class GroceryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get listId => integer().references(GroceryLists, #id)();
  TextColumn get itemName => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  IntColumn get unitId => integer().nullable().references(Units, #id)();
  TextColumn get unit => text().nullable()(); // Fallback/String unit
  TextColumn get notes => text().nullable()();
  TextColumn get category => text().nullable().withDefault(const Constant('Other'))();
  RealColumn get estimatedPrice => real().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get checkedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Index> get indexes => [
    Index('idx_grocery_items_list', 'CREATE INDEX idx_grocery_items_list ON grocery_items (list_id)'),
  ];
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  IntColumn get profileId => integer().nullable().references(Profiles, #id)();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Index> get indexes => [
    Index('idx_units_profile', 'CREATE INDEX idx_units_profile ON units (profile_id)'),
  ];
}

class CalculatorEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get expression => text()();
  RealColumn get parsedValue => real()();
  TextColumn get sourceType => text()(); // voice, manual, edited
  BoolColumn get isCurrency => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  List<Index> get indexes => [
    Index('idx_calc_profile', 'CREATE INDEX idx_calc_profile ON calculator_entries (profile_id)'),
  ];
}

class VoiceCorrections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawInput => text()();
  TextColumn get correctedText => text()();
  TextColumn get contextType => text()(); // grocery, calculator
  IntColumn get usageCount => integer().withDefault(const Constant(1))();
  IntColumn get profileId => integer().references(Profiles, #id)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class VoiceDictionary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get canonicalName => text()();
  TextColumn get aliases => text()(); // comma separated
  TextColumn get category => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
}

class RecurringRule extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get defaultAmount => real()();
  TextColumn get amountStrategy => text()(); // FIXED, VARIABLE, SUGGESTED
  IntColumn get categoryId => integer().nullable()();
  TextColumn get paymentMode => text().nullable()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get frequency => text()(); // DAILY, WEEKLY, MONTHLY, YEARLY
  IntColumn get interval => integer()();
  TextColumn get weekdays => text().nullable()();
  TextColumn get monthRule => text().nullable()();
  TextColumn get status => text()(); // ACTIVE, PAUSED, ARCHIVED, DELETED
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()();
  DateTimeColumn get lastGenerated => dateTime().nullable()();
  DateTimeColumn get lastCompleted => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get timezone => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class RecurringHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ruleId => integer().references(RecurringRule, #id)();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text()(); // PENDING, PAID, SKIPPED, SNOOZED, CANCELLED
  TextColumn get actionTaken => text().nullable()();
  IntColumn get transactionId => integer().nullable().references(Transactions, #id)();
  RealColumn get amount => real().nullable()();
  TextColumn get categorySnapshot => text().nullable()();
  TextColumn get paymentModeSnapshot => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get snoozeUntil => dateTime().nullable()();
  BoolColumn get notificationSent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [{ruleId, dueDate}];
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get budgetType => text().withDefault(const Constant('MONTHLY'))(); 
  RealColumn get limitAmount => real()();
  RealColumn get warningPercent => real().withDefault(const Constant(80.0))();
  RealColumn get criticalPercent => real().withDefault(const Constant(95.0))();
  TextColumn get rolloverMode => text().withDefault(const Constant('NONE'))();
  RealColumn get carryForward => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BudgetCategoryMappings extends Table {
  IntColumn get budgetId => integer().references(Budgets, #id)();
  TextColumn get categoryId => text()();
  @override
  List<Set<Column>> get uniqueKeys => [{budgetId, categoryId}];
}

class BudgetState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId => integer().references(Budgets, #id)();
  RealColumn get currentSpent => real().withDefault(const Constant(0.0))();
  RealColumn get expectedRemaining => real().withDefault(const Constant(0.0))();
  RealColumn get forecastExpense => real().withDefault(const Constant(0.0))();
  RealColumn get safeToSpend => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('HEALTHY'))(); 
  IntColumn get healthScore => integer().withDefault(const Constant(100))(); 
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class BudgetSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId => integer().references(Budgets, #id)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  RealColumn get spent => real().withDefault(const Constant(0.0))();
  RealColumn get expected => real().withDefault(const Constant(0.0))();
  RealColumn get forecastExpense => real().withDefault(const Constant(0.0))();
  RealColumn get forecastIncome => real().withDefault(const Constant(0.0))();
  RealColumn get expectedIncome => real().withDefault(const Constant(0.0))();
  RealColumn get expectedRecurring => real().withDefault(const Constant(0.0))();
  RealColumn get actualRecurring => real().withDefault(const Constant(0.0))();
  RealColumn get variance => real().withDefault(const Constant(0.0))(); 
  RealColumn get remaining => real().withDefault(const Constant(0.0))();
  RealColumn get safeToSpend => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('HEALTHY'))(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get goalType => text().withDefault(const Constant('SAVINGS'))(); // Savings, Debt, Investment, Purchase
  RealColumn get targetAmount => real()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get fundingStrategy => text().withDefault(const Constant('MANUAL'))(); // MANUAL, SAFE_TO_SPEND, RECURRING, SALARY_PERCENT, ROUND_OFF, AUTO_TRANSFER
  IntColumn get linkedAccountId => integer().nullable().references(Accounts, #id)(); 
  IntColumn get priority => integer().withDefault(const Constant(50))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // DRAFT, ACTIVE, PAUSED, COMPLETED, CANCELLED, ARCHIVED
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class GoalState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id)();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0.0))();
  RealColumn get completionPercent => real().withDefault(const Constant(0.0))();
  RealColumn get monthlyNeeded => real().withDefault(const Constant(0.0))();
  RealColumn get recommendedContribution => real().withDefault(const Constant(0.0))();
  RealColumn get velocity => real().withDefault(const Constant(0.0))(); // Average Monthly Contribution
  TextColumn get risk => text().withDefault(const Constant('LOW'))(); // LOW, MEDIUM, HIGH, CRITICAL
  DateTimeColumn get expectedCompletion => dateTime().nullable()();
  DateTimeColumn get optimisticCompletion => dateTime().nullable()();
  DateTimeColumn get conservativeCompletion => dateTime().nullable()();
  IntColumn get healthScore => integer().withDefault(const Constant(100))(); // 0-100
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class GoalHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(Goals, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  TextColumn get source => text()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  IntColumn get transactionId => integer().nullable().references(Transactions, #id)();
  TextColumn get notes => text().nullable()();
}

class CashFlowSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get period => text()();
  RealColumn get income => real().withDefault(const Constant(0.0))();
  RealColumn get expenses => real().withDefault(const Constant(0.0))();
  RealColumn get expected => real().withDefault(const Constant(0.0))();
  RealColumn get safeToSpend => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ForecastState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  RealColumn get expectedIncome => real().withDefault(const Constant(0.0))();
  RealColumn get expectedExpense => real().withDefault(const Constant(0.0))();
  RealColumn get expectedRecurring => real().withDefault(const Constant(0.0))();
  RealColumn get expectedBalance => real().withDefault(const Constant(0.0))();
  TextColumn get forecastRisk => text().withDefault(const Constant('LOW'))(); // LOW, MEDIUM, HIGH
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class LiquidityState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  RealColumn get liquidAssets => real().withDefault(const Constant(0.0))();
  RealColumn get reserved => real().withDefault(const Constant(0.0))();
  RealColumn get available => real().withDefault(const Constant(0.0))();
  RealColumn get emergencyReserve => real().withDefault(const Constant(0.0))();
  RealColumn get liquidityRatio => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class CashFlowState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  RealColumn get cashPosition => real().withDefault(const Constant(0.0))();
  RealColumn get safeToSpend => real().withDefault(const Constant(0.0))();
  RealColumn get burnRate => real().withDefault(const Constant(0.0))();
  RealColumn get netPosition => real().withDefault(const Constant(0.0))();
  RealColumn get forecastBalance => real().withDefault(const Constant(0.0))();
  IntColumn get healthScore => integer().withDefault(const Constant(100))(); // The Global FOS Hero Metric
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class Recommendations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get score => real()();
  IntColumn get priority => integer()();
  RealColumn get confidence => real()();
  TextColumn get category => text()();
  TextColumn get sourceEngine => text()();
  TextColumn get action => text().nullable()();
  TextColumn get whyShown => text()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Insights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get title => text()();
  TextColumn get observation => text()();
  TextColumn get category => text()(); // SPENDING, SAVINGS, GOALS, BUDGET, NET_WORTH, LIQUIDITY, CASH_FLOW, RECURRING, INCOME, ACCOUNT, SYSTEM
  TextColumn get severity => text().withDefault(const Constant('INFO'))(); // INFO, SUCCESS, WARNING, CRITICAL, MILESTONE
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))(); // ACTIVE, READ, ARCHIVED, DISMISSED, EXPIRED
  TextColumn get metricChange => text().nullable()();
  TextColumn get sourceEngine => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

class FinancialClosing extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get period => text()(); // e.g. '2026-08'
  RealColumn get income => real().withDefault(const Constant(0.0))();
  RealColumn get expense => real().withDefault(const Constant(0.0))();
  RealColumn get recurring => real().withDefault(const Constant(0.0))();
  RealColumn get goalContributions => real().withDefault(const Constant(0.0))();
  RealColumn get budgetSpent => real().withDefault(const Constant(0.0))();
  RealColumn get netWorth => real().withDefault(const Constant(0.0))();
  RealColumn get liquidityAvailable => real().withDefault(const Constant(0.0))();
  IntColumn get healthScore => integer().withDefault(const Constant(100))();
  TextColumn get narrativeJson => text().nullable()();
  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PredictionState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get predictionType => text()(); // SPEND_VELOCITY, HABIT, SEASONAL, CASH_FLOW, RISK, OPTIMIZATION, ANOMALY
  TextColumn get headline => text()();
  TextColumn get details => text()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))(); // 0.0 to 1.0
  TextColumn get confidenceFactorsJson => text().nullable()(); // Array of factor rationale strings
  RealColumn get metricValue => real().withDefault(const Constant(0.0))();
  TextColumn get sourceEngine => text()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  BoolColumn get needsRefresh => boolean().withDefault(const Constant(false))();
  DateTimeColumn get validUntil => dateTime().nullable()();
  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();
}

class TrendState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get categoryName => text()();
  TextColumn get periodType => text().withDefault(const Constant('MONTHLY'))(); // DAILY, WEEKLY, MONTHLY, YEARLY
  RealColumn get percentageChange => real().withDefault(const Constant(0.0))();
  TextColumn get velocity => text().withDefault(const Constant('STABLE'))(); // INCREASING, STABLE, DECREASING
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  DateTimeColumn get lastCalculated => dateTime().withDefault(currentDateAndTime)();
}

class BehaviorState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get patternName => text()();
  TextColumn get frequency => text().withDefault(const Constant('DAILY'))(); // DAILY, WEEKLY, BIWEEKLY, MONTHLY
  RealColumn get typicalAmount => real().withDefault(const Constant(0.0))();
  IntColumn get dayOfWeek => integer().nullable()();
  IntColumn get timeOfDay => integer().nullable()();
  TextColumn get routineScore => text().withDefault(const Constant('ROUTINE'))(); // ROUTINE, OCCASIONAL, RARE
  DateTimeColumn get lastDetected => dateTime().withDefault(currentDateAndTime)();
}

class SeasonalityState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get seasonName => text()(); // RAMADAN, DIWALI, SCHOOL_FEES, VACATION, MONSOON, WEDDING
  RealColumn get expectedSpikePct => real().withDefault(const Constant(0.0))();
  TextColumn get affectedCategories => text().nullable()(); // JSON list
  DateTimeColumn get predictedStartDate => dateTime().nullable()();
  DateTimeColumn get predictedEndDate => dateTime().nullable()();
}

class RiskState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get riskType => text()(); // BUDGET_OVERRUN, GOAL_DELAY, LOW_BALANCE, CASH_SHORTAGE, DEFICIT
  TextColumn get severity => text().withDefault(const Constant('MEDIUM'))(); // LOW, MEDIUM, HIGH, CRITICAL
  RealColumn get probability => real().withDefault(const Constant(0.5))(); // 0.0 - 1.0
  RealColumn get financialImpactAmount => real().withDefault(const Constant(0.0))();
  IntColumn get priorityRank => integer().withDefault(const Constant(50))();
  TextColumn get explanation => text()();
  DateTimeColumn get triggerDate => dateTime().nullable()();
}

class OptimizationState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get opportunityTitle => text()();
  TextColumn get optimizationType => text().withDefault(const Constant('SAVE'))(); // SAVE, ACCELERATE_GOAL, REDUCE_RISK, IMPROVE_HEALTH, IMPROVE_LIQUIDITY, REDUCE_RECURRING
  RealColumn get potentialMonthlySavings => real().withDefault(const Constant(0.0))();
  RealColumn get potentialYearlySavings => real().withDefault(const Constant(0.0))();
  TextColumn get difficulty => text().withDefault(const Constant('EASY'))(); // EASY, MEDIUM, HARD
  TextColumn get recommendationAction => text().nullable()();
  TextColumn get whyShown => text()();
}

class SimulationState extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get scenarioTitle => text()();
  TextColumn get scenarioCategory => text().withDefault(const Constant('PURCHASE'))(); // SALARY, PURCHASE, RENT, SAVINGS, LOAN, INVESTMENT, EDUCATION, VACATION, MEDICAL, HOUSE, BUSINESS
  TextColumn get inputParamsJson => text()();
  RealColumn get impactGoalDelayMonths => real().withDefault(const Constant(0.0))();
  RealColumn get impactCashFlowDelta => real().withDefault(const Constant(0.0))();
  RealColumn get impactSafeToSpendDelta => real().withDefault(const Constant(0.0))();
  IntColumn get simulatedHealthScore => integer().withDefault(const Constant(100))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PredictionHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get predictionType => text()();
  RealColumn get predictedValue => real().withDefault(const Constant(0.0))();
  RealColumn get actualValue => real().withDefault(const Constant(0.0))();
  RealColumn get accuracyPercentage => real().withDefault(const Constant(100.0))();
  DateTimeColumn get evaluatedAt => dateTime().withDefault(currentDateAndTime)();
}

enum SmsAccountStatus { PENDING, PERMITTED, IGNORED, REVOKED }

class SmsTrackedAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get bankName => text()();
  TextColumn get accountNumberLast4 => text()();
  TextColumn get accountType => text()();
  IntColumn get linkedAccountId => integer().nullable().references(Accounts, #id)();
  TextColumn get status => text().map(const EnumNameConverter(SmsAccountStatus.values))();
  DateTimeColumn get discoveredAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}

class SmsImportFingerprints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get hashFingerprint => text()();
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Index> get indexes => [
    Index('idx_sms_fingerprint', 'CREATE UNIQUE INDEX idx_sms_fingerprint ON sms_import_fingerprints (profile_id, hash_fingerprint)'),
  ];
}

class SmsImportHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get scannedCount => integer()();
  IntColumn get financialCount => integer()();
  IntColumn get importedCount => integer()();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Profiles, Accounts, Transactions, Categories, Users, ShopSettings, GroceryLists, GroceryItems, Units, CalculatorEntries, VoiceCorrections, VoiceDictionary, RecurringRule, RecurringHistory, Budgets, BudgetCategoryMappings, BudgetState, BudgetSnapshots, Goals, GoalState, GoalHistory, CashFlowSnapshots, ForecastState, LiquidityState, CashFlowState, Recommendations, Insights, FinancialClosing, PredictionState, TrendState, BehaviorState, SeasonalityState, RiskState, OptimizationState, SimulationState, PredictionHistory, SmsTrackedAccounts, SmsImportFingerprints, SmsImportHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 21;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await customStatement('PRAGMA foreign_keys = OFF');
        
        if (from < 4) {
          try {
            await m.createTable(users);
          } catch (e) {
            print('Migration: users table already exists');
          }
          try {
            await m.createTable(shopSettings);
          } catch (e) {
            print('Migration: shopSettings table already exists');
          }
        }
        
        if (from < 5) {
          try {
            await m.addColumn(transactions, transactions.metadata);
          } catch (e) {
            print('Migration: metadata column already exists');
          }
        }

        if (from < 6) {
          await m.createTable(groceryLists);
          await m.createTable(groceryItems);
          await m.createTable(units);
        }

        if (from < 7) {
          // Robust upgrade to Version 7
          try { await m.createTable(calculatorEntries); } catch(_) {}
          
          // Add new columns to existing tables if they don't exist
          try { await m.addColumn(groceryLists, groceryLists.updatedAt); } catch(_) {}
          try { await m.addColumn(groceryLists, groceryLists.isArchived); } catch(_) {}
          
          try { await m.addColumn(groceryItems, groceryItems.unitId); } catch(_) {}
          try { await m.addColumn(groceryItems, groceryItems.notes); } catch(_) {}
          try { await m.addColumn(groceryItems, groceryItems.createdAt); } catch(_) {}
          try { await m.addColumn(groceryItems, groceryItems.updatedAt); } catch(_) {}
          
          try { await m.addColumn(units, units.normalizedName); } catch(_) {}
          try { await m.addColumn(units, units.isSystem); } catch(_) {}
          try { await m.addColumn(units, units.createdAt); } catch(_) {}

          // For GroceryItems.quantity, we need to handle type change from Text to Real if coming from v6
          // In SQLite, we can't easily change type. But since it's an internal MVP-only version, 
          // we can try to add a new column or just recreate. 
          // Given this is local dev, recreating or adding missing indexes is usually enough.
          await m.createIndex(Index('idx_grocery_list_profile', 'CREATE INDEX idx_grocery_list_profile ON grocery_lists (profile_id)'));
          await m.createIndex(Index('idx_grocery_items_list', 'CREATE INDEX idx_grocery_items_list ON grocery_items (list_id)'));
          await m.createIndex(Index('idx_units_profile', 'CREATE INDEX idx_units_profile ON units (profile_id)'));
          await m.createIndex(Index('idx_calc_profile', 'CREATE INDEX idx_calc_profile ON calculator_entries (profile_id)'));
        }

        if (from < 8) {
          try { await m.createTable(voiceCorrections); } catch(_) {}
          try { await m.createTable(voiceDictionary); } catch(_) {}
        }

        if (from < 9) {
          try { await m.addColumn(calculatorEntries, calculatorEntries.isCurrency); } catch(_) {}
          try { await m.addColumn(calculatorEntries, calculatorEntries.updatedAt); } catch(_) {}
        }

        if (from < 10) {
          try { await m.addColumn(groceryItems, groceryItems.checkedAt); } catch(_) {}
        }

        if (from < 11) {
          try { await m.addColumn(transactions, transactions.metadata); } catch(_) {}
        }
        
        if (from < 12) {
          try { await m.addColumn(groceryItems, groceryItems.category); } catch(_) {}
          try { await m.addColumn(groceryItems, groceryItems.estimatedPrice); } catch(_) {}
        }

        if (from < 13) {
          try { await m.createTable(recurringRule); } catch (_) {}
          try { await m.createTable(recurringHistory); } catch (_) {}
        }
        
        if (from < 14) {
          try { await m.createTable(budgets); } catch (_) {}
          try { await m.createTable(budgetCategoryMappings); } catch (_) {}
          try { await m.createTable(budgetState); } catch (_) {}
          try { await m.createTable(budgetSnapshots); } catch (_) {}
          try { await m.createTable(goals); } catch (_) {}
          try { await m.createTable(goalHistory); } catch (_) {}
          try { await m.createTable(cashFlowSnapshots); } catch (_) {}
        }
        if (from < 15) {
          try { await m.createTable(accounts); } catch (_) {}
          try { await m.addColumn(transactions, transactions.accountId); } catch (_) {}
          try { await m.addColumn(transactions, transactions.toAccountId); } catch (_) {}
          
          // Migrate existing data
          final profileList = await select(profiles).get();
          for (final profile in profileList) {
            final accId = await into(accounts).insert(AccountsCompanion.insert(
              profileId: profile.id,
              name: 'Cash Wallet',
              type: 'CASH',
              color: const Value('#4CAF50'),
              icon: const Value('account_balance_wallet'),
            ));
            
            await (update(transactions)..where((t) => t.profileId.equals(profile.id))).write(
              TransactionsCompanion(accountId: Value(accId))
            );
          }
        }
        
        if (from < 16) {
          // Recreate goal schemas from scratch since they were not used in production yet
          await customStatement('DROP TABLE IF EXISTS goal_history');
          await customStatement('DROP TABLE IF EXISTS goal_state');
          await customStatement('DROP TABLE IF EXISTS goals');
          
          await m.createTable(goals);
          await m.createTable(goalState);
          await m.createTable(goalHistory);
        }

        if (from < 17) {
          await customStatement('DROP TABLE IF EXISTS goal_state');
          await m.createTable(goalState);
        }
        
        if (from < 18) {
          await m.createTable(forecastState);
          await m.createTable(liquidityState);
          await m.createTable(cashFlowState);
          await m.createTable(recommendations);
        }
        
        if (from < 19) {
          try { await m.createTable(insights); } catch(_) {}
          try { await m.createTable(financialClosing); } catch(_) {}
        }
        
        if (from < 20) {
          try { await m.createTable(predictionState); } catch(_) {}
          try { await m.createTable(trendState); } catch(_) {}
          try { await m.createTable(behaviorState); } catch(_) {}
          try { await m.createTable(seasonalityState); } catch(_) {}
          try { await m.createTable(riskState); } catch(_) {}
          try { await m.createTable(optimizationState); } catch(_) {}
          try { await m.createTable(simulationState); } catch(_) {}
          try { await m.createTable(predictionHistory); } catch(_) {}
        }
        
        if (from < 21) {
          try { await m.createTable(smsTrackedAccounts); } catch(_) {}
          try { await m.createTable(smsImportFingerprints); } catch(_) {}
          try { await m.createTable(smsImportHistory); } catch(_) {}
        }
        
        await customStatement('PRAGMA foreign_keys = ON');
      },

      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        // Self-repair: Ensure SMS tables exist even if database was previously updated to v21 without tables
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS sms_tracked_accounts (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id),
              bank_name TEXT NOT NULL,
              account_number_last4 TEXT NOT NULL,
              account_type TEXT NOT NULL,
              linked_account_id INTEGER REFERENCES accounts (id),
              status TEXT NOT NULL,
              discovered_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
              last_synced_at INTEGER
            );
          ''');
        } catch (_) {}
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS sms_import_fingerprints (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id),
              hash_fingerprint TEXT NOT NULL,
              imported_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
            );
          ''');
        } catch (_) {}
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS sms_import_history (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id),
              scanned_count INTEGER NOT NULL,
              financial_count INTEGER NOT NULL,
              imported_count INTEGER NOT NULL,
              scanned_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
            );
          ''');
        } catch (_) {}
        try {
          await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_recurring_history_rule_due ON recurring_history (rule_id, due_date)');
        } catch (_) {}

        // Health Hisaab tables (Self-repair / Auto-creation)
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS health_patients (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id),
              name TEXT NOT NULL,
              relationship TEXT,
              date_of_birth TEXT,
              gender TEXT,
              blood_group TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS health_events (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id),
              patient_id INTEGER NOT NULL REFERENCES health_patients (id),
              event_type TEXT NOT NULL,
              report_type TEXT,
              purpose TEXT NOT NULL,
              event_date TEXT NOT NULL,
              event_time TEXT NOT NULL,
              completion_status TEXT NOT NULL DEFAULT 'CAPTURED',
              source_type TEXT NOT NULL DEFAULT 'MANUAL',
              evidence_status TEXT NOT NULL DEFAULT 'NONE',
              payload_json TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_health_events_patient_date 
            ON health_events (patient_id, event_date);
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_health_events_profile 
            ON health_events (profile_id);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS health_evidence (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              event_id INTEGER NOT NULL REFERENCES health_events (id) ON DELETE CASCADE,
              file_path TEXT NOT NULL,
              original_name TEXT NOT NULL,
              display_name TEXT NOT NULL,
              mime_type TEXT NOT NULL,
              evidence_type TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_health_evidence_event 
            ON health_evidence (event_id);
          ''');
        } catch (_) {}

        // Gadi Hisaab tables (Self-repair / Auto-creation)
        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_vehicles (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              vehicle_type TEXT NOT NULL,
              registration_number TEXT NOT NULL,
              fuel_type TEXT NOT NULL,
              initial_odometer REAL NOT NULL DEFAULT 0.0,
              current_odometer REAL NOT NULL DEFAULT 0.0,
              purchase_date TEXT,
              purchase_price REAL,
              down_payment REAL,
              default_reimbursement_rate REAL DEFAULT 0.0,
              chassis_number TEXT,
              engine_number TEXT,
              insurance_policy_number TEXT,
              insurance_expiry_date TEXT,
              puc_expiry_date TEXT,
              fitness_expiry_date TEXT,
              road_tax_expiry_date TEXT,
              service_due_date TEXT,
              service_due_km REAL,
              service_interval_km REAL,
              service_interval_months INTEGER,
              is_active INTEGER NOT NULL DEFAULT 1,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_vehicles_profile 
            ON gadi_vehicles (profile_id, is_active);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_events (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
              vehicle_id INTEGER NOT NULL REFERENCES gadi_vehicles (id) ON DELETE CASCADE,
              event_type TEXT NOT NULL,
              title TEXT NOT NULL,
              event_date TEXT NOT NULL,
              event_time TEXT NOT NULL,
              odometer_km REAL,
              amount REAL NOT NULL DEFAULT 0.0,
              linked_transaction_id INTEGER REFERENCES transactions (id) ON DELETE SET NULL,
              source_type TEXT NOT NULL DEFAULT 'MANUAL',
              evidence_status TEXT NOT NULL DEFAULT 'NONE',
              payload_json TEXT,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_events_vehicle_date 
            ON gadi_events (vehicle_id, event_date DESC);
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_events_type 
            ON gadi_events (vehicle_id, event_type);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_trips (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
              vehicle_id INTEGER NOT NULL REFERENCES gadi_vehicles (id) ON DELETE CASCADE,
              trip_type TEXT NOT NULL,
              start_date_time TEXT NOT NULL,
              end_date_time TEXT,
              start_odometer REAL NOT NULL,
              end_odometer REAL NOT NULL,
              distance_km REAL NOT NULL,
              start_location TEXT,
              end_location TEXT,
              purpose TEXT,
              reimbursement_rate_per_km REAL,
              reimbursement_amount REAL,
              is_reimbursed INTEGER NOT NULL DEFAULT 0,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_trips_vehicle 
            ON gadi_trips (vehicle_id, start_date_time DESC);
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_trips_type 
            ON gadi_trips (vehicle_id, trip_type);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_evidence (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              event_id INTEGER NOT NULL REFERENCES gadi_events (id) ON DELETE CASCADE,
              file_path TEXT NOT NULL,
              original_name TEXT NOT NULL,
              display_name TEXT NOT NULL,
              mime_type TEXT NOT NULL,
              evidence_type TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_evidence_event 
            ON gadi_evidence (event_id);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_dues (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              profile_id INTEGER NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
              vehicle_id INTEGER NOT NULL REFERENCES gadi_vehicles (id) ON DELETE CASCADE,
              due_type TEXT NOT NULL,
              title TEXT NOT NULL,
              due_date TEXT,
              due_km REAL,
              amount REAL,
              status TEXT NOT NULL DEFAULT 'PENDING',
              snoozed_until TEXT,
              resolved_event_id INTEGER REFERENCES gadi_events (id) ON DELETE SET NULL,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_dues_vehicle 
            ON gadi_dues (vehicle_id, status, due_date);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_odometer_logs (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              vehicle_id INTEGER NOT NULL REFERENCES gadi_vehicles (id) ON DELETE CASCADE,
              odometer_km REAL NOT NULL,
              recorded_date TEXT NOT NULL,
              recorded_time TEXT NOT NULL,
              source_type TEXT NOT NULL DEFAULT 'EVENT',
              source_id INTEGER,
              is_manual_calibration INTEGER NOT NULL DEFAULT 0,
              calibration_reason TEXT,
              created_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_odo_vehicle 
            ON gadi_odometer_logs (vehicle_id, odometer_km DESC);
          ''');
        } catch (_) {}

        try {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS gadi_inspection_logs (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              vehicle_id INTEGER NOT NULL REFERENCES gadi_vehicles (id) ON DELETE CASCADE,
              inspection_date TEXT NOT NULL,
              odometer_km REAL,
              items_json TEXT NOT NULL,
              overall_status TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL
            );
          ''');
          await customStatement('''
            CREATE INDEX IF NOT EXISTS idx_gadi_inspections_vehicle 
            ON gadi_inspection_logs (vehicle_id, inspection_date DESC);
          ''');
        } catch (_) {}
      },
    );
  }

  // Stream of all transactions descending by date for a specific profile (Default fallback)
  Stream<List<Transaction>> watchTransactionsByProfile(int profileId) {
    return (select(transactions)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(50))
        .watch();
  }

  // Filtered stream for the UI
  Stream<List<Transaction>> watchTransactionsFiltered({
    required int profileId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) {
    return (select(transactions)
          ..where((t) {
            var predicate = t.profileId.equals(profileId);
            if (type != null && type != 'All') {
              predicate = predicate & t.type.equals(type);
            }
            if (startDate != null && endDate != null) {
              predicate = predicate & t.timestamp.isBetweenValues(startDate, endDate);
            }
            return predicate;
          })
          ..orderBy([
            (t) {
              if (sortBy == 'DATE_ASC') return OrderingTerm.asc(t.timestamp);
              if (sortBy == 'NAME_ASC') return OrderingTerm.asc(t.partyName);
              if (sortBy == 'AMOUNT_DESC') return OrderingTerm.desc(t.amount);
              if (sortBy == 'AMOUNT_ASC') return OrderingTerm.asc(t.amount);
              return OrderingTerm.desc(t.timestamp);
            }
          ])
          ..limit(50))
        .watch();
  }



  // Raw stream for Analytics without limit (single profile)
  Stream<List<Transaction>> watchAllTransactionsForAnalytics(int profileId) {
    return (select(transactions)..where((t) => t.profileId.equals(profileId))).watch();
  }

  // Raw stream for Analytics (ALL profiles combined)
  Stream<List<Transaction>> watchAllTransactionsForAllProfiles() {
    return select(transactions).watch();
  }

  // Insert a transaction
  Future<int> addTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  // Update a transaction
  Future<bool> updateTransaction(Transaction entry) {
    return update(transactions).replace(entry);
  }

  // Delete a transaction
  Future<int> deleteTransaction(Transaction entry) {
    return delete(transactions).delete(entry);
  }

  // --- Category Subsystem --- //
  Stream<List<Category>> watchAllCategories() {
    return select(categories).watch();
  }

  Future<int> addCategory(CategoriesCompanion entry) {
    return into(categories).insert(entry);
  }

  Future<bool> updateCategory(Category entry) {
    return update(categories).replace(entry);
  }

  Future<int> deleteCategory(Category entry) {
    return delete(categories).delete(entry);
  }

  // --- Profile Subsystem --- //
  Stream<List<Profile>> watchAllProfiles() {
    return select(profiles).watch();
  }

  Future<int> addProfile(ProfilesCompanion entry) {
    return into(profiles).insert(entry);
  }

  Future<bool> updateProfile(Profile entry) {
    return update(profiles).replace(entry);
  }

  Future<int> deleteProfile(Profile entry) {
    return delete(profiles).delete(entry);
  }

  Future<int> deleteTransactionsByProfile(int profileId) {
    return (delete(transactions)..where((t) => t.profileId.equals(profileId))).go();
  }

  Future<List<Transaction>> getTransactionsByProfile(int profileId) {
    return (select(transactions)..where((t) => t.profileId.equals(profileId))).get();
  }

  // --- Users Subsystem --- //
  Future<User?> getUser(String username) async {
    return (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();
  }

  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  Future<int> addUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  Future<bool> updateUser(User entry) {
    return update(users).replace(entry);
  }

  Future<int> deleteUser(User entry) {
    return delete(users).delete(entry);
  }

  // --- Shop Settings Subsystem --- //
  Future<ShopSetting?> getShopSettings() async {
    return (select(shopSettings)..limit(1)).getSingleOrNull();
  }

  Future<bool> updateShopSettings(ShopSetting entry) {
    return update(shopSettings).replace(entry);
  }

  Future<int> addOrUpdateSettings(ShopSettingsCompanion entry) async {
    return into(shopSettings).insertOnConflictUpdate(entry);
  }

  // --- Grocery Subsystem --- //
  Stream<List<GroceryList>> watchGroceryLists(int profileId) {
    return (select(groceryLists)..where((l) => l.profileId.equals(profileId))).watch();
  }

  Future<int> addGroceryList(GroceryListsCompanion entry) {
    return into(groceryLists).insert(entry);
  }

  Future<bool> updateGroceryList(GroceryList entry) {
    return update(groceryLists).replace(entry);
  }

  Future<int> deleteGroceryList(GroceryList entry) {
    return delete(groceryLists).delete(entry);
  }

  Stream<List<GroceryItem>> watchGroceryItems(int listId) {
    return (select(groceryItems)..where((i) => i.listId.equals(listId))).watch();
  }

  Future<int> addGroceryItem(GroceryItemsCompanion entry) {
    return into(groceryItems).insert(entry);
  }

  Future<bool> updateGroceryItem(GroceryItem entry) {
    return update(groceryItems).replace(entry);
  }

  Future<int> deleteGroceryItem(GroceryItem entry) {
    return delete(groceryItems).delete(entry);
  }

  Future<void> deleteItemsByList(int listId) {
    return (delete(groceryItems)..where((i) => i.listId.equals(listId))).go();
  }

  // --- Units Subsystem --- //
  Stream<List<Unit>> watchUnits(int profileId) {
    return (select(units)..where((u) => u.profileId.equals(profileId) | u.profileId.isNull())).watch();
  }

  Future<int> addUnit(UnitsCompanion entry) {
    return into(units).insert(entry);
  }

  Future<bool> updateUnit(Unit entry) {
    return update(units).replace(entry);
  }

  Future<int> deleteUnit(Unit entry) {
    return delete(units).delete(entry);
  }

  // --- Calculator Subsystem --- //
  Stream<List<CalculatorEntry>> watchCalculatorHistory(int profileId) {
    return (select(calculatorEntries)
          ..where((c) => c.profileId.equals(profileId))
          ..orderBy([(c) => OrderingTerm.desc(c.createdAt)])
          ..limit(20))
        .watch();
  }

  Future<int> addCalculatorEntry(CalculatorEntriesCompanion entry) {
    return into(calculatorEntries).insert(entry);
  }

  Future<void> clearCalculatorHistory(int profileId) {
    return (delete(calculatorEntries)..where((c) => c.profileId.equals(profileId))).go();
  }

  // --- Voice AI Subsystem --- //
  Future<List<VoiceCorrection>> getVoiceCorrections(int profileId, String contextType) {
    return (select(voiceCorrections)
          ..where((v) => v.profileId.equals(profileId) & v.contextType.equals(contextType)))
        .get();
  }

  Future<int> addOrUpdateCorrection(VoiceCorrectionsCompanion entry) async {
    final existing = await (select(voiceCorrections)
          ..where((v) => v.profileId.equals(entry.profileId.value) & v.rawInput.equals(entry.rawInput.value)))
        .getSingleOrNull();

    if (existing != null) {
      await update(voiceCorrections).replace(existing.copyWith(
        usageCount: existing.usageCount + 1,
        updatedAt: DateTime.now(),
      ));
      return existing.id;
    } else {
      return into(voiceCorrections).insert(entry);
    }
  }

  Future<List<VoiceDictionaryData>> getSystemDictionary() {
    return (select(voiceDictionary)..where((d) => d.isSystem.equals(true))).get();
  }

  Future<int> addToDictionary(VoiceDictionaryCompanion entry) {
    return into(voiceDictionary).insert(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'shabanahisaab.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
