import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../core/theme/financial_health_theme.dart';
import 'models/goal_template.dart';
import 'widgets/health_ring.dart';

class GoalDetailView extends StatelessWidget {
  final Goal goal;
  final GoalStateData state;
  final GoalTemplate template;

  const GoalDetailView({
    super.key,
    required this.goal,
    required this.state,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Icon(template.icon, color: template.themeColor, size: 24),
            const SizedBox(width: 8),
            Text(goal.title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(context),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: FinancialHealthTheme.getColor(state.healthScore),
        onPressed: () => _showAddFundsDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Funds'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeroSection(currency),
          const SizedBox(height: 24),
          _buildKeyMetricsGrid(currency),
          const SizedBox(height: 24),
          _buildInsightsSection(currency),
          const SizedBox(height: 24),
          _buildForecastTimeline(currency),
          const SizedBox(height: 24),
          _buildContributionHistory(currency),
          const SizedBox(height: 100), // FAB spacing
        ],
      ),
    );
  }

  Widget _buildHeroSection(NumberFormat currency) {
    return Center(
      child: Column(
        children: [
          HealthRing(
            completionPercent: state.completionPercent,
            healthScore: state.healthScore,
            size: 160,
            strokeWidth: 12,
          ),
          const SizedBox(height: 20),
          Text(
            '${currency.format(state.currentAmount)} / ${currency.format(goal.targetAmount)}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${FinancialHealthTheme.getLabel(state.healthScore)} Health',
            style: TextStyle(color: FinancialHealthTheme.getColor(state.healthScore), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(NumberFormat currency) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.0,
      children: [
        _buildMetricCard('Remaining', currency.format(state.remainingAmount)),
        _buildMetricCard('Forecast', state.expectedCompletion != null ? DateFormat.yMMM().format(state.expectedCompletion!) : 'N/A'),
        _buildMetricCard('Velocity', '${currency.format(state.velocity)}/mo'),
        _buildMetricCard('Risk', state.risk, 
          valueColor: state.risk == 'LOW' ? FinancialHealthTheme.excellent : (state.risk == 'CRITICAL' ? FinancialHealthTheme.critical : FinancialHealthTheme.warning)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(NumberFormat currency) {
    final bool isAhead = state.velocity >= state.monthlyNeeded;
    final String title = isAhead ? '✓ Ahead of Schedule' : '⚠ Behind Schedule';
    final Color color = isAhead ? FinancialHealthTheme.excellent : FinancialHealthTheme.warning;
    
    String message = '';
    if (isAhead) {
      message = 'You are saving at a healthy pace. Keep it up!';
    } else {
      final deficit = state.monthlyNeeded - state.velocity;
      message = 'Increase contribution by ${currency.format(deficit)}/mo to reach your goal.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isAhead ? Icons.check_circle : Icons.warning, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTimeline(NumberFormat currency) {
    if (state.velocity <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forecast Timeline', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(4, (index) {
              final date = DateTime.now().add(Duration(days: 30 * index));
              final forecastedAmount = (state.currentAmount + (state.velocity * index)).clamp(0, goal.targetAmount);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(index == 0 ? 'Today' : DateFormat.yMMMM().format(date), style: const TextStyle(color: Colors.white70)),
                    Text(currency.format(forecastedAmount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildContributionHistory(NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contribution History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<List<GoalHistoryData>>(
          stream: goalRepository.watchGoalHistory(goal.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final history = snapshot.data!;
            if (history.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No contributions yet.', style: TextStyle(color: Colors.white54)),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.arrow_downward, color: FinancialHealthTheme.excellent)),
                  title: Text(DateFormat.yMMMd().format(h.date), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(h.source, style: const TextStyle(color: Colors.white54)),
                  trailing: Text(currency.format(h.amount), style: TextStyle(color: FinancialHealthTheme.excellent, fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddFundsDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Contribution', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter amount (e.g. 500)',
            hintStyle: TextStyle(color: Colors.white38),
            prefixText: '₹ ',
            prefixStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigoAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FinancialHealthTheme.excellent),
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                await goalRepository.addHistoryEntry(GoalHistoryCompanion(
                  goalId: Value(goal.id),
                  amount: Value(val),
                  date: Value(DateTime.now()),
                  source: const Value('Manual Contribution'),
                ));

                // Recalculate goal state
                final history = await goalRepository.watchGoalHistory(goal.id).first;
                final newState = goalEngine.evaluateGoal(goal: goal, history: history);
                await goalRepository.upsertGoalState(newState);

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ₹${val.toStringAsFixed(0)} to ${goal.title}')),
                  );
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(goal.status == 'PAUSED' ? Icons.play_arrow : Icons.pause, color: Colors.white),
              title: Text(goal.status == 'PAUSED' ? 'Resume Goal' : 'Pause Goal', style: const TextStyle(color: Colors.white)),
              onTap: () async {
                final newStatus = goal.status == 'PAUSED' ? 'ACTIVE' : 'PAUSED';
                await goalRepository.updateGoalStatus(goal.id, newStatus);
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Goal status updated to $newStatus')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.amber),
              title: const Text('Archive Goal', style: TextStyle(color: Colors.amber)),
              onTap: () async {
                await goalRepository.updateGoalStatus(goal.id, 'ARCHIVED');
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Goal', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await goalRepository.updateGoalStatus(goal.id, 'CANCELLED');
                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
