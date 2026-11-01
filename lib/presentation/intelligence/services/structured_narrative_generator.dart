import '../../../data/database/database.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class StructuredNarrative {
  final String periodName;
  final List<String> achievements;
  final List<String> warnings;
  final List<String> improvements;
  final List<String> forecast;
  final List<String> recommendations;

  StructuredNarrative({
    required this.periodName,
    required this.achievements,
    required this.warnings,
    required this.improvements,
    required this.forecast,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'periodName': periodName,
    'achievements': achievements,
    'warnings': warnings,
    'improvements': improvements,
    'forecast': forecast,
    'recommendations': recommendations,
  };

  factory StructuredNarrative.fromJson(Map<String, dynamic> json) => StructuredNarrative(
    periodName: json['periodName'] ?? 'Monthly Summary',
    achievements: List<String>.from(json['achievements'] ?? []),
    warnings: List<String>.from(json['warnings'] ?? []),
    improvements: List<String>.from(json['improvements'] ?? []),
    forecast: List<String>.from(json['forecast'] ?? []),
    recommendations: List<String>.from(json['recommendations'] ?? []),
  );
}

class StructuredNarrativeGenerator {
  final AppDatabase _db;

  StructuredNarrativeGenerator(this._db);

  Future<StructuredNarrative> generate(int profileId) async {
    final now = DateTime.now();
    final periodName = DateFormat('MMMM yyyy').format(now);

    final cashFlow = await (_db.select(_db.cashFlowState)..where((c) => c.profileId.equals(profileId))).getSingleOrNull();
    final forecast = await (_db.select(_db.forecastState)..where((f) => f.profileId.equals(profileId))).getSingleOrNull();
    final liquidity = await (_db.select(_db.liquidityState)..where((l) => l.profileId.equals(profileId))).getSingleOrNull();
    final budgets = await (_db.select(_db.budgets)..where((b) => b.profileId.equals(profileId) & b.enabled.equals(true))).get();
    final goals = await (_db.select(_db.goals)..where((g) => g.profileId.equals(profileId) & g.status.equals('ACTIVE'))).get();
    final recs = await (_db.select(_db.recommendations)..where((r) => r.profileId.equals(profileId))).get();

    List<String> achievements = [];
    List<String> warnings = [];
    List<String> improvements = [];
    List<String> forecastLines = [];
    List<String> recommendationLines = [];

    // Achievements
    if ((cashFlow?.healthScore ?? 0) >= 70) {
      achievements.add('Maintained a healthy financial index score of ${cashFlow!.healthScore}/100.');
    }
    int healthyBudgets = 0;
    for (var b in budgets) {
      final s = await (_db.select(_db.budgetState)..where((st) => st.budgetId.equals(b.id))).getSingleOrNull();
      if (s != null && s.healthScore >= 70) healthyBudgets++;
    }
    if (healthyBudgets > 0) {
      achievements.add('Kept $healthyBudgets active budget allocations within target threshold.');
    }

    // Warnings
    if (forecast?.forecastRisk == 'CRITICAL' || forecast?.forecastRisk == 'HIGH') {
      warnings.add('Projected end-of-month cash flow indicates elevated expense velocity.');
    }
    if (liquidity != null && liquidity.liquidityRatio < 20.0) {
      warnings.add('Liquidity ratio is currently constrained (${liquidity.liquidityRatio.toStringAsFixed(0)}% available).');
    }

    // Improvements
    if ((liquidity?.available ?? 0) > 0) {
      improvements.add('Available liquidity increased to ₹${liquidity!.available.toStringAsFixed(0)} after allocations.');
    }
    if (goals.isNotEmpty) {
      improvements.add('${goals.length} active savings goals are actively tracking velocity.');
    }

    // Forecast
    if (forecast != null) {
      forecastLines.add('Expected month-end balance is ₹${forecast.expectedBalance.toStringAsFixed(0)}.');
      forecastLines.add('Projected 30-day expenses: ₹${forecast.expectedExpense.toStringAsFixed(0)}.');
    }

    // Recommendations
    for (var r in recs.take(2)) {
      recommendationLines.add('${r.title}: ${r.description}');
    }

    if (achievements.isEmpty) achievements.add('Tracked daily transactions systematically.');
    if (forecastLines.isEmpty) forecastLines.add('Cash flow stability is under continuous evaluation.');

    return StructuredNarrative(
      periodName: periodName,
      achievements: achievements,
      warnings: warnings,
      improvements: improvements,
      forecast: forecastLines,
      recommendations: recommendationLines,
    );
  }
}
