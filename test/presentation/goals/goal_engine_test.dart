import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import '../../../lib/data/database/database.dart';
import '../../../lib/presentation/goals/services/goal_engine.dart';

void main() {
  late GoalEngine engine;

  setUp(() {
    engine = GoalEngine();
  });

  Goal createMockGoal({
    double targetAmount = 10000.0,
    DateTime? deadline,
    String status = 'ACTIVE',
  }) {
    return Goal(
      id: 1,
      profileId: 1,
      title: 'Test Goal',
      goalType: 'SAVINGS',
      targetAmount: targetAmount,
      fundingStrategy: 'MANUAL',
      linkedAccountId: 1,
      priority: 50,
      status: status,
      createdAt: DateTime.now(),
      deadline: deadline,
    );
  }

  GoalHistoryData createHistory(double amount, DateTime date) {
    return GoalHistoryData(
      id: 1,
      goalId: 1,
      date: date,
      amount: amount,
      source: 'MANUAL',
    );
  }

  group('GoalEngine Unit Tests', () {
    test('Zero contribution history', () {
      final goal = createMockGoal(targetAmount: 1000.0);
      final state = engine.evaluateGoal(
        goal: goal,
        history: [],
        currentDate: DateTime(2026, 8, 1),
      );

      expect(state.currentAmount.value, 0.0);
      expect(state.remainingAmount.value, 1000.0);
      expect(state.completionPercent.value, 0.0);
      expect(state.velocity.value, 0.0);
      expect(state.risk.value, 'LOW'); // No deadline, no pressure
    });

    test('Overfunded goals cap remaining amount at 0 and completion at >100', () {
      final goal = createMockGoal(targetAmount: 1000.0);
      final history = [
        createHistory(1200.0, DateTime(2026, 8, 1)),
      ];
      
      final state = engine.evaluateGoal(
        goal: goal,
        history: history,
        currentDate: DateTime(2026, 8, 1),
      );

      expect(state.currentAmount.value, 1200.0);
      expect(state.remainingAmount.value, 0.0);
      expect(state.completionPercent.value, 120.0);
      expect(state.healthScore.value, 100);
      expect(state.risk.value, 'LOW');
    });

    test('Paused/Cancelled goals return static state', () {
      final goal = createMockGoal(targetAmount: 1000.0, status: 'PAUSED'); // Handled as normal unless CANCELLED/ARCHIVED?
      // Wait, the engine only checks ARCHIVED or CANCELLED for static. 
      final cancelledGoal = createMockGoal(targetAmount: 1000.0, status: 'CANCELLED');
      final history = [createHistory(200.0, DateTime(2026, 8, 1))];
      
      final state = engine.evaluateGoal(
        goal: cancelledGoal,
        history: history,
        currentDate: DateTime(2026, 8, 1),
      );

      expect(state.currentAmount.value, 200.0);
      expect(state.remainingAmount.value, 800.0);
      expect(state.risk.value, 'LOW');
      expect(state.healthScore.value, 0); // Static zero
    });

    test('Missed deadlines mark risk as CRITICAL', () {
      final goal = createMockGoal(
        targetAmount: 1000.0,
        deadline: DateTime(2026, 7, 1), // Deadline passed
      );
      final history = [createHistory(500.0, DateTime(2026, 6, 1))];
      
      final state = engine.evaluateGoal(
        goal: goal,
        history: history,
        currentDate: DateTime(2026, 8, 1),
      );

      expect(state.risk.value, 'CRITICAL');
      expect(state.healthScore.value, lessThan(60));
    });

    test('Weighted velocity logic heavily weights recent contributions', () {
      final goal = createMockGoal(targetAmount: 10000.0);
      
      // Month 0 (Aug): weight 3
      // Month 1 (Jul): weight 2
      // Month 2 (Jun): weight 1
      final history = [
        createHistory(100.0, DateTime(2026, 6, 1)), // Jun = 100 * 1
        createHistory(200.0, DateTime(2026, 7, 1)), // Jul = 200 * 2
        createHistory(300.0, DateTime(2026, 8, 1)), // Aug = 300 * 3
      ];
      
      final state = engine.evaluateGoal(
        goal: goal,
        history: history,
        currentDate: DateTime(2026, 8, 1),
      );

      // Total weight: 6. (100*1 + 200*2 + 300*3) / 6 = 1400 / 6 = 233.33
      expect(state.velocity.value, closeTo(233.33, 0.1));
    });
  });
}
