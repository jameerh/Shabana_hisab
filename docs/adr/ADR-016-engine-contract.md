# ADR-016: Engine Contract & Telemetry Metadata

## Context
In an enterprise Financial Operating System (FOS), engine health, performance telemetry, and contracts must be observable. Without explicit metadata, diagnostic tracing, performance profiling, and plugin integration become ambiguous.

## Decision
We freeze the **Engine Metadata Contract** (`EngineMetadata`). Every FOS engine MUST expose standard metadata and execution telemetry:

```dart
class EngineMetadata {
  final String engineId;
  final String engineVersion;
  final List<String> inputStates;
  final List<String> outputStates;
  final int executionOrder;
  final String executionFrequency;
  final int executionTimeMs;
  final DateTime lastExecution;
  final String healthStatus; // 'HEALTHY', 'DEGRADED', 'ERROR'
  final String? lastError;
}
```

## Contract Requirements
1. **Metadata Expose**: Engines register their contract ID, version, input state dependencies, output state entities, and scheduled execution frequency.
2. **Telemetry Tracking**: `IntelligenceOrchestrator` measures stopwatch execution duration in milliseconds for every pipeline run.
3. **Developer Diagnostics**: Engine telemetry is exposed via the **Engine Monitor** developer tool (`Settings -> Developer -> Engine Monitor`).
4. **Health Status Classification**:
   - `HEALTHY`: Engine executed within target performance budget (< 50ms) with zero exceptions.
   - `DEGRADED`: Engine execution exceeded target budget (> 50ms).
   - `ERROR`: Engine threw an unhandled exception during pipeline execution.

## Consequences
- Provides real-time visibility into financial pipeline execution speed and stability.
- Enables developer diagnostic monitoring without requiring external APM tooling.
- Establishes a formal plugin contract for future ecosystem modules.
