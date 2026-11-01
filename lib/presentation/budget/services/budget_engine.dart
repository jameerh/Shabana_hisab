import 'package:flutter/material.dart';
import '../../../data/database/database.dart';
import '../../../main.dart';
import 'package:drift/drift.dart';

class SafeToSpendResult {
  final double today;
  final double thisWeek;
  final double thisMonth;

  SafeToSpendResult({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });
}

class BudgetEngine {
  
  /// Calculates Available Cash
  /// Available Cash = Current Balance + Expected Income (remaining) - Expected Expenses (remaining) - Outstanding Recurring Obligations - Reserved Goal Contributions - Emergency Reserve
  Future<double> calculateAvailableCash(int profileId) async {
    // 1. Current Balance
    double currentBalance = await _calculateCurrentBalance(profileId);
    
    // 2. Expected Income (For simplicity, we'll sum historical averages or future planned income)
    double expectedIncome = 0.0; 

    // 3. Expected Expenses (From budget snapshots)
    double expectedExpenses = 0.0;

    // 4. Outstanding Recurring Obligations (From RecurringEngine)
    double recurringObligations = await _calculateRemainingRecurringObligations(profileId);

    // 5. Reserved Goal Contribution (From Goals target)
    double reservedGoalContribution = await _calculateGoalContributions(profileId);

    // 6. Emergency Reserve (From Profile Settings)
    // TODO: Fetch from profile settings, hardcoded to 0 for now
    double emergencyReserve = 0.0; 

    return currentBalance + expectedIncome - expectedExpenses - recurringObligations - reservedGoalContribution - emergencyReserve;
  }

  /// Calculates Safe To Spend across three timeframes
  Future<SafeToSpendResult> calculateSafeToSpend(int profileId) async {
    double availableCash = await calculateAvailableCash(profileId);
    
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    int remainingDaysInMonth = endOfMonth.difference(now).inDays + 1;
    if (remainingDaysInMonth <= 0) remainingDaysInMonth = 1;

    // Remaining days in week
    int daysUntilSunday = DateTime.sunday - now.weekday;
    int remainingDaysInWeek = daysUntilSunday + 1; // including today
    if (remainingDaysInWeek <= 0) remainingDaysInWeek = 1;
    
    // Ensure week doesn't exceed month
    if (remainingDaysInWeek > remainingDaysInMonth) {
      remainingDaysInWeek = remainingDaysInMonth;
    }

    double safeToday = availableCash / remainingDaysInMonth;
    double safeWeek = safeToday * remainingDaysInWeek;
    
    return SafeToSpendResult(
      today: safeToday,
      thisWeek: safeWeek,
      thisMonth: availableCash, // By definition, all available cash is safe to spend this month
    );
  }

  Future<double> _calculateCurrentBalance(int profileId) async {
    final transactions = await (database.select(database.transactions)
      ..where((t) => t.profileId.equals(profileId))).get();
    
    double balance = 0;
    for (var t in transactions) {
      if (t.type == 'INCOME') {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }

  Future<double> _calculateRemainingRecurringObligations(int profileId) async {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final pendingHistory = await (database.select(database.recurringHistory)
      ..where((h) => h.status.equals('PENDING') & h.dueDate.isSmallerOrEqualValue(endOfMonth)))
      .get();
    
    return pendingHistory.fold<double>(0.0, (sum, h) => sum + (h.amount ?? 0)); 
  }

  Future<double> _calculateGoalContributions(int profileId) async {
    final activeGoals = await (database.select(database.goals)
      ..where((g) => g.status.equals('ACTIVE') & g.profileId.equals(profileId))).get();
    
    double total = 0;
    for (var g in activeGoals) {
      final state = await (database.select(database.goalState)..where((s) => s.goalId.equals(g.id))).getSingleOrNull();
      if (state != null) total += state.monthlyNeeded;
    }
    return total;
  }

  // --- State & Snapshot Generation --- //
  
  Future<void> evaluateBudgetStateAndSnapshots(int profileId) async {
    final activeBudgets = await (database.select(database.budgets)
      ..where((b) => b.profileId.equals(profileId))
      ..where((b) => b.enabled.equals(true))).get();
    
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    await database.transaction(() async {
      for (var budget in activeBudgets) {
        
        // 1. Calculate Live Values
        final mappings = await (database.select(database.budgetCategoryMappings)
          ..where((m) => m.budgetId.equals(budget.id))).get();
        final categoryIds = mappings.map((m) => m.categoryId).toList();

        double spent = 0.0;
        if (categoryIds.isNotEmpty) {
          final transactions = await (database.select(database.transactions)
            ..where((t) => t.profileId.equals(profileId))
            ..where((t) => t.categoryName.isIn(categoryIds))
            ..where((t) => t.timestamp.isBetweenValues(periodStart, periodEnd))).get();
          
          spent = transactions.fold(0.0, (sum, t) => sum + t.amount);
        }

        double expectedRemaining = budget.limitAmount - spent;
        double forecastExpense = 0.0; // To be implemented by ForecastEngine
        
        int healthScore = 100;
        String status = 'HEALTHY';
        if (spent > budget.limitAmount) {
          healthScore = 0;
          status = 'EXCEEDED';
        } else if (spent > budget.limitAmount * (budget.criticalPercent / 100.0)) {
          healthScore = 20;
          status = 'CRITICAL';
        } else if (spent > budget.limitAmount * (budget.warningPercent / 100.0)) {
          healthScore = 50;
          status = 'WARNING';
        }

        double safeToSpend = 0.0;
        int remainingDays = periodEnd.difference(now).inDays + 1;
        if (remainingDays > 0) {
          safeToSpend = expectedRemaining / remainingDays;
        }

        // 2. Update Live State
        final existingState = await (database.select(database.budgetState)
          ..where((s) => s.budgetId.equals(budget.id))).getSingleOrNull();
        
        if (existingState == null) {
          await database.into(database.budgetState).insert(
            BudgetStateCompanion.insert(
              budgetId: budget.id,
              currentSpent: Value(spent),
              expectedRemaining: Value(expectedRemaining),
              forecastExpense: Value(forecastExpense),
              safeToSpend: Value(safeToSpend),
              status: Value(status),
              healthScore: Value(healthScore),
            )
          );
        } else {
          await (database.update(database.budgetState)..where((s) => s.id.equals(existingState.id))).write(
            BudgetStateCompanion(
              currentSpent: Value(spent),
              expectedRemaining: Value(expectedRemaining),
              forecastExpense: Value(forecastExpense),
              safeToSpend: Value(safeToSpend),
              status: Value(status),
              healthScore: Value(healthScore),
              lastCalculated: Value(DateTime.now()),
            )
          );
        }

        // 3. Update Snapshot
        final existingSnapshot = await (database.select(database.budgetSnapshots)
          ..where((s) => s.budgetId.equals(budget.id))
          ..where((s) => s.periodStart.equals(periodStart))).getSingleOrNull();
        
        if (existingSnapshot == null) {
          await database.into(database.budgetSnapshots).insert(
            BudgetSnapshotsCompanion.insert(
              budgetId: budget.id,
              periodStart: periodStart,
              periodEnd: periodEnd,
              expected: Value(budget.limitAmount),
              spent: Value(spent),
              remaining: Value(expectedRemaining),
              status: Value(status),
            )
          );
        } else {
          await (database.update(database.budgetSnapshots)..where((s) => s.id.equals(existingSnapshot.id))).write(
            BudgetSnapshotsCompanion(
              spent: Value(spent),
              remaining: Value(expectedRemaining),
              status: Value(status),
            )
          );
        }
      }
    });
  }
}
