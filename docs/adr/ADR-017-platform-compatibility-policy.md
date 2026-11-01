# ADR-017: Platform Compatibility Policy

## Context
With **Financial Operating System Core (FOS Core v1.0)** fully established and feature-frozen across ADRs 001–016, a strict compatibility policy is required. As new ecosystem plugins (Predictive Intelligence, AI Coach, Digital Finance Hub, Automation, Family Collaboration, ERP/Investments) are added, core contracts must remain stable and backward compatible to protect data integrity and prevent regression.

## Decision
We freeze the **Platform Compatibility Policy (FOS Core v1.x)**:

### 1. Backward Compatibility Commitment
- All published engine outputs (`ForecastState`, `BudgetState`, `GoalState`, `LiquidityState`, `CashFlowState`, `Recommendations`, `Insights`, `FinancialClosing`) are strictly backward compatible within FOS Core v1.x.
- Core engine signatures and DB table schemas MUST NOT break existing consumers.

### 2. Additive Schema Evolution
- Database schema changes MUST be purely additive (new columns with default values or new tables).
- Non-destructive migration scripts MUST preserve all historical financial records and closing snapshots.

### 3. Registry-Based Plugin Extension
- New capabilities (AI, Investments, Loans, Tax, ERP) MUST register through the `CapabilityRegistry` and publish state via existing pipeline events (`ADR-015`), rather than modifying existing domain engines.

### 4. Deprecation Protocol
- Any contract field or method marked for deprecation MUST remain fully supported for at least one major platform version (v1.x $\rightarrow$ v2.0) before removal.

### 5. Frozen Core Governance
- ADR-001 through ADR-017 are marked as **APPROVED**, **LOCKED**, and **PRODUCTION**.
- Core engine redesigns are prohibited; only non-breaking bug fixes and performance optimizations are permitted.

## Status
- **Status**: APPROVED & LOCKED
- **Scope**: FOS Core v1.0
