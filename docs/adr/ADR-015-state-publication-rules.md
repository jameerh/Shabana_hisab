# ADR-015: State Publication Rules

## Context
As the Shabana Hisab Financial Operating System (FOS) scales, keeping domain engines decoupled is paramount. Direct inter-engine calls create tight coupling, circular dependency risks, fragile testing environments, and race conditions.

## Decision
We freeze **State Publication Rules** across all financial intelligence engines:

```text
Read Published Input States
           │
           ▼
    Compute State
           │
           ▼
Publish New Immutable State (Drift DB)
           │
           ▼
    Raise Event / Bus Signal
```

### Mandated Rules
1. **Zero Direct Engine Calls**: No engine may invoke another engine's private methods or services.
   - **Allowed**: `CashFlowEngine` reads `ForecastState` from SQLite/Drift DB.
   - **Prohibited**: `CashFlowEngine` instantiates or calls `forecastEngine.calculate()`.
2. **Immutable Published States**: Each engine writes its calculated metrics exclusively to dedicated, immutable Drift DB state tables (`ForecastState`, `BudgetState`, `GoalState`, `LiquidityState`, `CashFlowState`, `Recommendations`, `Insights`, `FinancialClosing`).
3. **Sequential Pipeline Orchestration**: The `IntelligenceOrchestrator` manages execution order externally, measuring execution telemetry per ADR-016.

## Consequences
- Engine implementations can be refactored, optimized, or replaced independently.
- New modules (Debt Payoff, Investments, AI Assistants) connect as state subscribers/publishers without modifying core engines.
- Testability is completely deterministic: engines are tested by mocking standard database state tables.
