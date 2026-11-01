# ADR-019: Predictive Feature Flags Policy

## Context
The Predictive Intelligence Platform introduces 11 predictive domain engines and multi-horizon dashboards. To support safe rollout, A/B testing, and emergency isolation of specific predictive models, a granular feature flag service is required.

## Decision
We define and enforce **ADR-019: Predictive Feature Flags**:

### 1. Granular Flag Definitions
Every predictive engine and dashboard section is guarded by a configurable flag:
- `enableTrendEngine` (Default: `true`)
- `enableBehaviorEngine` (Default: `true`)
- `enableSeasonalityEngine` (Default: `true`)
- `enableCashFlowPredictionEngine` (Default: `true`)
- `enableRiskEngine` (Default: `true`)
- `enableOptimizationEngine` (Default: `true`)
- `enableAnomalyEngine` (Default: `true`)
- `enableSimulationEngine` (Default: `true`)
- `enablePredictiveDashboard` (Default: `true`)

### 2. Fallback Behavior
If a feature flag is disabled:
- The `PredictionDagOrchestrator` skips execution of that node and passes cached state downstream.
- Dashboard widgets corresponding to disabled flags gracefully hide without throwing errors.

## Status
- **Status**: APPROVED & LOCKED
- **Scope**: Epic 4 & Future Extensions
