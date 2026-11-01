import 'package:drift/drift.dart';
import '../../../data/database/database.dart';
import 'dart:math';

class GoalEngine {
  // ADR-013 Contract: Load Inputs -> Validate -> Calculate -> Score -> Cache State
  
  GoalStateCompanion evaluateGoal({
    required Goal goal,
    required List<GoalHistoryData> history,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    
    // 1. Validate
    if (goal.status == 'ARCHIVED' || goal.status == 'CANCELLED') {
      final currentAmount = history.fold<double>(0.0, (sum, entry) => sum + entry.amount);
      return _buildStaticState(goal, currentAmount, 'LOW', 0); // No active calculations
    }
    
    // 2. Calculate Basic Metrics
    final currentAmount = history.fold<double>(0.0, (sum, entry) => sum + entry.amount);
    final remainingAmount = max(0.0, goal.targetAmount - currentAmount);
    final completionPercent = goal.targetAmount > 0 ? (currentAmount / goal.targetAmount) * 100.0 : 0.0;
    
    // 3. Calculate Weighted Velocity
    final velocity = _calculateWeightedVelocity(history, now);
    
    // 4. Calculate Forecasts
    final forecasts = _calculateForecasts(goal, remainingAmount, velocity, now);
    
    // 5. Calculate Required Contributions
    double monthlyNeeded = 0.0;
    if (goal.deadline != null && remainingAmount > 0) {
      final monthsRemaining = _monthsBetween(now, goal.deadline!);
      if (monthsRemaining > 0) {
        monthlyNeeded = remainingAmount / monthsRemaining;
      } else {
        monthlyNeeded = remainingAmount; // Due immediately or overdue
      }
    }
    
    // 6. Score (Risk & Health)
    final risk = _calculateRisk(goal, remainingAmount, velocity, monthlyNeeded, now);
    final healthScore = _calculateHealthScore(completionPercent, risk, velocity, monthlyNeeded);
    
    // 7. Cache State
    return GoalStateCompanion.insert(
      goalId: goal.id,
      currentAmount: Value(currentAmount),
      remainingAmount: Value(remainingAmount),
      completionPercent: Value(completionPercent),
      monthlyNeeded: Value(monthlyNeeded),
      recommendedContribution: Value(max(monthlyNeeded, velocity)), 
      velocity: Value(velocity),
      risk: Value(risk),
      healthScore: Value(healthScore),
      expectedCompletion: Value(forecasts['expected']),
      optimisticCompletion: Value(forecasts['optimistic']),
      conservativeCompletion: Value(forecasts['conservative']),
      lastCalculated: Value(now),
    );
  }
  
  double _calculateWeightedVelocity(List<GoalHistoryData> history, DateTime now) {
    if (history.isEmpty) return 0.0;
    
    // Group by month
    Map<String, double> monthlySums = {};
    for (var entry in history) {
      final monthKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      monthlySums[monthKey] = (monthlySums[monthKey] ?? 0) + entry.amount;
    }
    
    if (monthlySums.isEmpty) return 0.0;
    if (monthlySums.length == 1) return monthlySums.values.first;
    
    // Sort keys descending
    final sortedKeys = monthlySums.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Apply weights (recent months matter more)
    // Month 0 (current) = weight 3
    // Month 1 = weight 2
    // Month 2+ = weight 1
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      double weight = i == 0 ? 3.0 : (i == 1 ? 2.0 : 1.0);
      weightedSum += monthlySums[sortedKeys[i]]! * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }
  
  Map<String, DateTime?> _calculateForecasts(Goal goal, double remaining, double velocity, DateTime now) {
    if (remaining <= 0) {
      return {'expected': now, 'optimistic': now, 'conservative': now};
    }
    if (velocity <= 0) {
      return {'expected': null, 'optimistic': null, 'conservative': null};
    }
    
    final monthsExpected = (remaining / velocity).ceil();
    final monthsOptimistic = (remaining / (velocity * 1.2)).ceil();
    final monthsConservative = (remaining / (velocity * 0.8)).ceil();
    
    return {
      'expected': _addMonths(now, monthsExpected),
      'optimistic': _addMonths(now, monthsOptimistic),
      'conservative': _addMonths(now, monthsConservative),
    };
  }
  
  String _calculateRisk(Goal goal, double remaining, double velocity, double monthlyNeeded, DateTime now) {
    if (remaining <= 0) return 'LOW';
    if (goal.deadline == null) return 'LOW';
    if (now.isAfter(goal.deadline!)) return 'CRITICAL';
    
    if (velocity >= monthlyNeeded) return 'LOW';
    if (velocity >= monthlyNeeded * 0.8) return 'MEDIUM';
    if (velocity >= monthlyNeeded * 0.5) return 'HIGH';
    
    return 'CRITICAL';
  }
  
  int _calculateHealthScore(double completionPercent, String risk, double velocity, double monthlyNeeded) {
    if (completionPercent >= 100) return 100;
    
    int score = 50;
    
    // Reward for progress
    score += (completionPercent / 4).floor(); // up to +25
    
    // Penalize/reward for velocity vs needed
    if (monthlyNeeded > 0) {
      final ratio = velocity / monthlyNeeded;
      if (ratio >= 1.0) score += 25;
      else if (ratio >= 0.8) score += 10;
      else if (ratio < 0.5) score -= 20;
    } else {
      score += 25; // No deadline, no pressure
    }
    
    // Risk penalty
    switch (risk) {
      case 'CRITICAL': score -= 30; break;
      case 'HIGH': score -= 15; break;
      case 'LOW': score += 10; break;
    }
    
    return score.clamp(0, 100);
  }
  
  int _monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }
  
  DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year + ((date.month + months - 1) ~/ 12);
    int newMonth = ((date.month + months - 1) % 12) + 1;
    
    // Handle days exceeding month limits
    int newDay = date.day;
    final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInNewMonth) newDay = daysInNewMonth;
    
    return DateTime(newYear, newMonth, newDay);
  }
  
  GoalStateCompanion _buildStaticState(Goal goal, double currentAmount, String risk, int health) {
    return GoalStateCompanion.insert(
      goalId: goal.id,
      currentAmount: Value(currentAmount),
      remainingAmount: Value(max(0, goal.targetAmount - currentAmount)),
      completionPercent: Value(goal.targetAmount > 0 ? (currentAmount / goal.targetAmount) * 100.0 : 0.0),
      risk: Value(risk),
      healthScore: Value(health),
      expectedCompletion: const Value(null),
      optimisticCompletion: const Value(null),
      conservativeCompletion: const Value(null),
    );
  }
}
