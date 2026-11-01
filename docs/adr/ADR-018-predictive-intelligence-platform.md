# ADR-018: Predictive Intelligence Platform Architecture

## Context
FOS Core v1.0 is feature-frozen. The **Predictive Intelligence Platform** (Epic 4) introduces forward-looking predictions, pattern recognition, risk modeling, cost optimization, and What-If simulations. To preserve platform stability, all predictive components must execute independently without mutating live core financial data or violating FOS Core contracts.

## Decision
We freeze the **Predictive Intelligence Platform Architecture**:

### 1. FOS Core Non-Interference Guarantee
- All predictive engines consume published FOS Core v1.0 state entities (`ForecastState`, `BudgetState`, `GoalState`, `LiquidityState`, `CashFlowState`, `Transactions`, `Recurring`) in read-only mode.
- Predictive engines publish predictions exclusively to dedicated prediction tables (`PredictionState`, `TrendState`, `BehaviorState`, `SeasonalityState`, `RiskState`, `OptimizationState`, `SimulationState`, `PredictionHistory`).

### 2. Dependency-Driven Orchestration (DAG)
- Engines execute according to a Directed Acyclic Graph (`PredictionDagOrchestrator`):
  $$\text{Trend} \rightarrow \text{Behavior} \rightarrow \text{Seasonality} \rightarrow \text{Cash Flow Forecast} \rightarrow \text{Risk} \rightarrow \text{Health Intel} \rightarrow \text{Optimization} \rightarrow \text{Anomaly} \rightarrow \text{Simulation} \rightarrow \text{Recommendation} \rightarrow \text{Insight}$$

### 3. Simulation Sandbox Isolation
- What-If simulations run inside an isolated `SimulationContext`.
- Simulations clone published core states in memory, apply hypothetical scenario parameters (Salary, Vehicle purchase, Rent, Savings, Loans, Investments, Education, Medical), execute predictive algorithms, and return results without mutating live database tables.

### 4. Freshness Policy & Confidence Factors
- Predictions expose validity windows (`generatedAt`, `expiresAt`, `needsRefresh`).
- Confidence ratings (0.0 to 1.0) must include human-readable factor rationales (`factorsJson`) and an overall **Prediction Confidence Index (0–100)** alongside Financial Health.

### 5. Prediction Versioning & Replay
- Every prediction exposes `engineVersion`, `modelVersion`, and `predictionVersion`.
- Developers can replay historical predictions against actual financial outcomes (`PredictionHistory`) to track model accuracy.

### 6. Explainability Timeline & Influence Traceability
- Exposes delta explainability ("Why Changed: Yesterday vs Today").
- Provides cross-engine influence traceability (`Budget` $\rightarrow$ `Forecast` $\rightarrow$ `Risk` $\rightarrow$ `Recommendation`).

## Status
- **Status**: APPROVED, LOCKED & PRODUCTION
- **Scope**: Epic 4 & Predictive Intelligence Platform

