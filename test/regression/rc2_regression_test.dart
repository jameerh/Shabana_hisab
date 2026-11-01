import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:snaphisaab/data/database/database.dart';
import 'package:snaphisaab/data/repositories/health_repository.dart';
import 'package:snaphisaab/data/repositories/goal_repository.dart';
import 'package:snaphisaab/presentation/goals/services/goal_engine.dart';
import 'package:snaphisaab/presentation/home/services/recurring_schedule_engine.dart';
import 'package:snaphisaab/data/services/voice_service.dart';

void main() {
  group('Shabana Hisaab RC2 Full Integration & Regression Gate', () {
    late AppDatabase db;
    late HealthRepository healthRepo;
    late GoalRepository goalRepo;
    late GoalEngine goalEngine;
    late int profileId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      healthRepo = HealthRepository(db);
      goalRepo = GoalRepository(db);
      goalEngine = GoalEngine();

      profileId = await db.into(db.profiles).insert(
        ProfilesCompanion.insert(
          name: 'Shabana RC2 Household',
          type: ProfileType.SHOP,
        ),
      );
    });

    tearDown(() async {
      healthRepo.dispose();
      await db.close();
    });

    test('RC2 Gate: Health Hisaab Fast Fill, CRUD, and Evidence Linkage', () async {
      final patientId = await healthRepo.addPatient(
        profileId: profileId,
        name: 'Fatima',
        relationship: 'Mother',
      );

      // 1. Create health prescription event
      final eventDate = DateTime(2026, 9, 9);
      final eventId = await healthRepo.addQuickPrescription(
        profileId: profileId,
        patientId: patientId,
        purpose: 'Monthly BP & Diabetes Checkup',
        eventDate: eventDate,
        eventTime: '10:30 AM',
        notes: 'Advised morning walk',
      );

      // 2. Attach evidence via database table
      await db.customInsert(
        '''
        INSERT INTO health_evidence (event_id, file_path, original_name, display_name, mime_type, evidence_type, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withInt(eventId),
          Variable.withString('/mock/health_attachments/BP_Report_09-Sep-2026.pdf'),
          Variable.withString('BP_Report_09-Sep-2026.pdf'),
          Variable.withString('BP_Report_Mother_09-Sep-2026.pdf'),
          Variable.withString('application/pdf'),
          Variable.withString('PDF'),
          Variable.withString(DateTime.now().toIso8601String()),
        ],
      );

      // 3. Batch query verification (verifies batched evidence joining without N+1)
      final events = await healthRepo.getEvents(profileId);
      expect(events.length, 1);
      final ev = events.first;
      expect(ev.purpose, 'Monthly BP & Diabetes Checkup');
      expect(ev.eventDate, DateTime(2026, 9, 9));
      expect(ev.evidence.length, 1);
      expect(ev.evidence.first.displayName, 'BP_Report_Mother_09-Sep-2026.pdf');

      // 4. Update event
      await healthRepo.updateEvent(
        eventId: eventId,
        eventDate: DateTime(2026, 9, 9),
        purpose: 'Monthly BP & Diabetes Checkup (Verified)',
        notes: 'Advised morning walk and less salt',
      );

      final updated = await healthRepo.getEventById(eventId);
      expect(updated!.purpose, 'Monthly BP & Diabetes Checkup (Verified)');
      expect(updated.notes, 'Advised morning walk and less salt');
      expect(updated.evidence.length, 1);
    });

    test('RC2 Gate: 31st Recurring Schedule Cycle across Jan-Feb-Mar', () async {
      final scheduleId = await db.into(db.recurringRule).insert(
        RecurringRuleCompanion.insert(
          profileId: profileId,
          title: 'Shop Rent 31st',
          frequency: 'MONTHLY',
          interval: 1,
          amountStrategy: 'FIXED',
          startDate: DateTime(2026, 1, 31),
          nextDueDate: DateTime(2026, 1, 31),
          defaultAmount: 20000.0,
          status: 'ACTIVE',
          monthRule: const Value('31'),
        ),
      );

      final rule = await (db.select(db.recurringRule)..where((r) => r.id.equals(scheduleId))).getSingle();

      // Step 1: Jan 31 -> Feb 28
      final febDue = RecurringScheduleEngine.calculateNextDueDate(
        rule.nextDueDate,
        rule.frequency,
        rule.interval,
        requestedDay: rule.startDate.day,
      );
      expect(febDue, DateTime(2026, 2, 28));

      // Step 2: Feb 28 -> Mar 31 (Rule 31st preserved!)
      final marDue = RecurringScheduleEngine.calculateNextDueDate(
        febDue,
        rule.frequency,
        rule.interval,
        requestedDay: rule.startDate.day,
      );
      expect(marDue, DateTime(2026, 3, 31));
    });

    test('RC2 Gate: Goal Engine & Contribution Lifecycle', () async {
      final goalId = await goalRepo.insertGoal(
        GoalsCompanion.insert(
          profileId: profileId,
          title: 'Emergency Gold Fund',
          targetAmount: 50000.0,
          deadline: Value(DateTime(2027, 1, 1)),
          goalType: const Value('SAVINGS'),
        ),
      );

      // Add contribution
      await goalRepo.addHistoryEntry(
        GoalHistoryCompanion.insert(
          goalId: goalId,
          amount: 10000.0,
          date: DateTime.now(),
          source: 'Cash Deposit',
        ),
      );

      final goal = await (db.select(db.goals)..where((g) => g.id.equals(goalId))).getSingle();
      final history = await goalRepo.watchGoalHistory(goalId).first;
      expect(history.length, 1);
      expect(history.first.amount, 10000.0);

      final state = goalEngine.evaluateGoal(goal: goal, history: history);
      expect(state.completionPercent.value, 20.0);
      expect(state.healthScore.value, greaterThan(0));
    });

    test('RC2 Gate: Voice Service Lifecycle Safety', () {
      final voice = VoiceService();
      expect(voice.isDisposed, isFalse);
      voice.dispose();
      expect(voice.isDisposed, isTrue);
      // Safe idempotent post-disposal call
      voice.dispose();
    });
  });
}
