import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import '../../../data/database/database.dart';
import '../../../main.dart';
import '../services/prediction_dag_orchestrator.dart';
import '../widgets/predictive_timeline_widget.dart';
import 'what_if_simulator_view.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/localization/bilingual_text.dart';

class PredictiveDashboardView extends StatefulWidget {
  final int profileId;

  const PredictiveDashboardView({Key? key, required this.profileId}) : super(key: key);

  @override
  State<PredictiveDashboardView> createState() => _PredictiveDashboardViewState();
}

class _PredictiveDashboardViewState extends State<PredictiveDashboardView> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _triggerPipeline();
  }

  void _triggerPipeline() async {
    setState(() => _isRefreshing = true);
    final orchestrator = PredictionDagOrchestrator(database);
    await orchestrator.executePipeline(widget.profileId);
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: BilingualText(
          english: 'Predictive Intelligence 🔮',
          marathi: 'पूर्वाचा अंदाज बुद्धिमत्ता 🔮',
          languageController: languageController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: _isRefreshing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh),
            onPressed: _triggerPipeline,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Today's Prediction Banner
            _buildTodayPredictionCard(context),
            const SizedBox(height: 16),

            // 2. Today's Opportunity
            _buildOpportunitySection(context),
            const SizedBox(height: 16),

            // 3. Today's Risk
            _buildRiskSection(context),
            const SizedBox(height: 16),

            // 4. Multi-Horizon Predictive Timeline
            BilingualText(
              english: 'Multi-Horizon Cash Flow Forecast 📈',
              marathi: 'बहु-कालावधी रोख प्रवाह अंदाज 📈',
              languageController: languageController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<CashFlowStateData>>(
              stream: (database.select(database.cashFlowState)..where((c) => c.profileId.equals(widget.profileId))).watch(),
              builder: (context, snapshot) {
                final cash = snapshot.data?.firstOrNull?.cashPosition ?? 0.0;
                return PredictiveTimelineWidget(currentCash: cash, dailyVelocity: 150.0);
              },
            ),
            const SizedBox(height: 20),

            // 5. What-If Simulator Launcher Card
            _buildWhatIfCard(context),
            const SizedBox(height: 16),

            // 6. Cost Optimizations
            _buildOptimizationsSection(context),
            const SizedBox(height: 16),

            // 7. Seasonality Spikes
            _buildSeasonalitySection(context),
            const SizedBox(height: 16),

            // 8. Anomalies
            _buildAnomaliesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPredictionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<PredictionStateData>>(
      stream: (database.select(database.predictionState)
            ..where((p) => p.profileId.equals(widget.profileId))
            ..orderBy([(p) => OrderingTerm.desc(p.generatedAt)]))
          .watch(),
      builder: (context, snapshot) {
        final preds = snapshot.data ?? [];
        final latest = preds.firstOrNull;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[900]!, Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BilingualText(
                    english: 'TODAY\'S PREDICTION',
                    marathi: 'आजचा अंदाज',
                    languageController: languageController,
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${l10n?.confidence ?? "Confidence"}: ${((latest?.confidence ?? 0.9) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(latest?.headline ?? 'Generating Predictive Models...', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(latest?.details ?? 'Analyzing 60-day historical spending velocity and recurring schedules.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpportunitySection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<OptimizationStateData>>(
      stream: (database.select(database.optimizationState)..where((o) => o.profileId.equals(widget.profileId))).watch(),
      builder: (context, snapshot) {
        final opts = snapshot.data ?? [];
        if (opts.isEmpty) return const SizedBox.shrink();
        final top = opts.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  BilingualText(
                    english: 'Top Opportunity',
                    marathi: 'मुख्य संधी',
                    languageController: languageController,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(top.opportunityTitle, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(top.whyShown, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskSection(BuildContext context) {
    return StreamBuilder<List<RiskStateData>>(
      stream: (database.select(database.riskState)..where((r) => r.profileId.equals(widget.profileId))).watch(),
      builder: (context, snapshot) {
        final risks = snapshot.data ?? [];
        if (risks.isEmpty) return const SizedBox.shrink();
        final top = risks.first;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  BilingualText(
                    english: 'Predictive Risk Alert',
                    marathi: 'अंदाजित जोखीम सूचना',
                    languageController: languageController,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${top.riskType}: ${top.explanation}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhatIfCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BilingualText(
                    english: 'What-If Simulator Sandbox',
                    marathi: 'व्हाॉट-इफ सिम्युलेटर',
                    languageController: languageController,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n?.simulatePurchasesSubtitle ?? 'Simulate purchases, rent & income changes',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WhatIfSimulatorView(profileId: widget.profileId))),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: Text(
              l10n?.openSandbox ?? 'Open Sandbox',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<OptimizationStateData>>(
      stream: (database.select(database.optimizationState)..where((o) => o.profileId.equals(widget.profileId))).watch(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText(
              english: 'Actionable Cost Optimizations 💰',
              marathi: 'कृतीयोग्य खर्च बचत 💰',
              languageController: languageController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: list.map((o) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(o.opportunityTitle, style: const TextStyle(color: Colors.white, fontSize: 13))),
                    Text('Save ₹${o.potentialYearlySavings.toStringAsFixed(0)}/yr', style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildSeasonalitySection(BuildContext context) {
    return StreamBuilder<List<SeasonalityStateData>>(
      stream: (database.select(database.seasonalityState)..where((s) => s.profileId.equals(widget.profileId))).watch(),
      builder: (context, snapshot) {
        final seasons = snapshot.data ?? [];
        if (seasons.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText(
              english: 'Upcoming Seasonal Spikes 🗓️',
              marathi: 'येणारे हंगामी खर्च 🗓️',
              languageController: languageController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: seasons.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${s.seasonName} Season', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('+${s.expectedSpikePct.toStringAsFixed(0)}% Spike', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            )
          ],
        );
      },
    );
  }

  Widget _buildAnomaliesSection(BuildContext context) {
    return StreamBuilder<List<PredictionStateData>>(
      stream: (database.select(database.predictionState)..where((p) => p.profileId.equals(widget.profileId) & p.predictionType.equals('ANOMALY'))).watch(),
      builder: (context, snapshot) {
        final anomalies = snapshot.data ?? [];
        if (anomalies.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText(
              english: 'Detected Anomalies ⚠️',
              marathi: 'शोधलेल्या विसंगती ⚠️',
              languageController: languageController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: anomalies.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4))),
                child: Text(a.headline, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              )).toList(),
            )
          ],
        );
      },
    );
  }
}
