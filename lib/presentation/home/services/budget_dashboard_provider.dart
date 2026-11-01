import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_registry.dart';
import '../models/dashboard_card.dart';
import '../../../../data/database/database.dart';
import '../../../../data/services/profile_service.dart';
import '../../../../main.dart';
import '../../budget/budget_manager_view.dart';

class BudgetDashboardProvider implements DashboardCardProvider {

  @override
  Future<List<DashboardCard>> getAvailableCards() async {
    List<DashboardCard> cards = [];
    final profileId = await ProfileService.getActiveProfileId();
    
    if (profileId == null) return cards;

    // Watch active budgets with their live state
    final activeBudgets = await budgetRepository.watchBudgetsWithState(profileId).first;

    for (var item in activeBudgets) {
      final b = item.budget;
      final s = item.state;

      if (s == null) continue;

      double limit = b.limitAmount;
      double spent = s.currentSpent;
      double progress = limit > 0 ? (spent / limit) * 100 : 0;
      
      String title = b.title;
      String subtitle = '${progress.toStringAsFixed(0)}% Forecast ₹${s.forecastExpense.toStringAsFixed(0)}, Safe Today ₹${s.safeToSpend.toStringAsFixed(0)}';

      double score = 0;
      Color? color;
      
      // Recommendation Priority
      // 90 Budget Exceeded
      // 75 Safe To Spend Warning
      
      if (s.status == 'EXCEEDED' || s.status == 'CRITICAL') {
        score = 90.0;
        color = Colors.red;
        subtitle = 'Exceeded by ₹${(spent - limit).toStringAsFixed(0)}';
      } else if (s.status == 'WARNING') {
        score = 75.0;
        color = Colors.orange;
      } else {
        // Healthy budgets get lower priority
        score = 60.0; 
        color = Colors.green;
      }

      cards.add(
        DashboardCard(
          id: 'budget_${b.id}',
          score: score,
          title: title,
          subtitle: subtitle,
          icon: Icons.account_balance_wallet,
          color: color,
          actionLabel: 'Manage',
          onAction: () {
            // Ideally we push the budget manager view. 
            // In a real app we'd use a router or global nav key.
          },
          explanation: CardExplanation(
            reason: s.status == 'HEALTHY' ? 'Budget is on track.' : 'Budget needs attention.',
            confidence: 0.9,
            source: 'BudgetEngine',
            lastUpdated: s.lastCalculated,
          ),
        ),
      );
    }

    return cards;
  }
}
