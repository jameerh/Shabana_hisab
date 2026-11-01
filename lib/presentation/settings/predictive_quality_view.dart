import 'package:flutter/material.dart';
import '../predictive/services/predictive_telemetry.dart';

class PredictiveQualityView extends StatelessWidget {
  const PredictiveQualityView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final telemetry = PredictiveTelemetryRegistry();
    final items = telemetry.allTelemetry;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Predictive Quality Telemetry 🎯'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cache Hit Rate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${telemetry.cacheHitRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.tealAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hits / Misses', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${telemetry.cacheHits} / ${telemetry.cacheMisses}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Engine Runtimes & Health Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text('No telemetry recorded yet. Trigger pipeline in Predictive Intelligence Hub.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            )
          else
            ...items.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.isHealthy ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.engineId, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      if (t.errorMessage != null) Text(t.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ],
                  ),
                  Text('${t.executionTimeMs} ms', style: const TextStyle(color: Colors.purpleAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }
}
