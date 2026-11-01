import 'package:flutter/material.dart';
import '../intelligence/models/engine_metadata.dart';
import 'package:intl/intl.dart';

class EngineMonitorView extends StatelessWidget {
  const EngineMonitorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FOS Engine Telemetry Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.grey[900],
      ),
      body: AnimatedBuilder(
        animation: EngineTelemetryRegistry(),
        builder: (context, child) {
          final metadataList = EngineTelemetryRegistry().allMetadata;
          if (metadataList.isEmpty) {
            return const Center(
              child: Text('No engines registered yet.', style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metadataList.length,
            itemBuilder: (context, index) {
              final m = metadataList[index];
              Color statusColor = Colors.greenAccent;
              if (m.healthStatus == 'DEGRADED') statusColor = Colors.orangeAccent;
              if (m.healthStatus == 'ERROR') statusColor = Colors.redAccent;

              final timeFormatted = DateFormat('HH:mm:ss').format(m.lastExecution);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(m.engineId, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(m.healthStatus, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Execution Duration: ${m.executionTimeMs} ms', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('Last Run: $timeFormatted', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 6),
                    Text('Inputs: ${m.inputStates.join(", ")}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    Text('Outputs: ${m.outputStates.join(", ")}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                    if (m.lastError != null) ...[
                      const SizedBox(height: 6),
                      Text('Error: ${m.lastError}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
