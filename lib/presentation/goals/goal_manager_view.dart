import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../data/database/database.dart';
import '../../../data/repositories/goal_repository.dart';
import '../../../main.dart';
import '../core/theme/financial_health_theme.dart';
import 'goal_wizard_view.dart';
import 'goal_detail_view.dart';
import 'widgets/health_ring.dart';
import 'models/goal_template.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';

class GoalManagerView extends StatefulWidget {
  final int profileId;
  const GoalManagerView({super.key, required this.profileId});

  @override
  State<GoalManagerView> createState() => _GoalManagerViewState();
}

class _GoalManagerViewState extends State<GoalManagerView> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: BilingualText(
          english: 'Goals & Targets',
          marathi: 'ध्येय आणि उद्दिष्टे',
          languageController: languageController,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => GoalWizardView(profileId: widget.profileId),
          ));
          
          if (result != null) {
            // Write to database
            final goal = GoalsCompanion.insert(
              profileId: widget.profileId,
              title: result['title'],
              goalType: drift.Value('SAVINGS'),
              targetAmount: result['targetAmount'],
              deadline: drift.Value(result['deadline']),
              fundingStrategy: drift.Value(result['fundingStrategy']),
              priority: drift.Value(result['priority']),
            );
            await goalRepository.insertGoal(goal);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n?.newGoal ?? 'New Goal'),
      ),
      body: StreamBuilder<List<GoalWithState>>(
        stream: goalRepository.watchGoalsWithState(widget.profileId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final goals = snapshot.data!;
          if (goals.isEmpty) {
            return _buildEmptyState();
          }
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDashboardSummary(goals),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildGoalCard(context, goals[index]),
                    childCount: goals.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // Space for FAB
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No Active Goals', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Create your first savings goal.', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(List<GoalWithState> goals) {
    int healthy = 0;
    int atRisk = 0;
    double totalTarget = 0;
    double totalSaved = 0;
    double totalMonthly = 0;
    double totalSuggested = 0;
    
    for (var g in goals) {
      if (g.state.healthScore >= 70) healthy++;
      else atRisk++;
      
      totalTarget += g.goal.targetAmount;
      totalSaved += g.state.currentAmount;
      totalMonthly += g.state.monthlyNeeded;
      totalSuggested += g.state.recommendedContribution;
    }
    
    final completion = totalTarget > 0 ? (totalSaved / totalTarget) * 100 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Progress', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 4),
                  Text('${completion.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$healthy Healthy', style: const TextStyle(color: FinancialHealthTheme.excellent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$atRisk At Risk', style: const TextStyle(color: FinancialHealthTheme.critical, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat('Monthly Target', _currencyFormat.format(totalMonthly)),
              _buildSummaryStat('Suggested', _currencyFormat.format(totalSuggested), valueColor: FinancialHealthTheme.excellent),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryStat(String label, String value, {Color valueColor = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalWithState goalWithState) {
    final goal = goalWithState.goal;
    final state = goalWithState.state;
    
    // Find template to get icon/color, or fallback to Custom
    final template = GoalTemplate.all.firstWhere(
      (t) => t.title.toLowerCase() == goal.title.toLowerCase(),
      orElse: () => GoalTemplate.all.last,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => GoalDetailView(goal: goal, state: state, template: template),
          ));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinancialHealthTheme.getColor(state.healthScore).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              HealthRing(
                completionPercent: state.completionPercent,
                healthScore: state.healthScore,
                size: 60,
                strokeWidth: 6,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(template.icon, size: 16, color: template.themeColor),
                        const SizedBox(width: 6),
                        Expanded(child: Text(goal.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${_currencyFormat.format(state.currentAmount)} / ${_currencyFormat.format(goal.targetAmount)}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (state.expectedCompletion != null)
                          Text('ETA: ${DateFormat.yMMM().format(state.expectedCompletion!)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Need: ${_currencyFormat.format(state.recommendedContribution)}/mo', style: const TextStyle(color: FinancialHealthTheme.excellent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
