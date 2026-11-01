# ADR-003: Recommendation Pipeline

## Context
Determining which cards to show on the dashboard using a static Priority integer is inflexible and cannot adapt to user behavior.

## Decision
Introduce a multi-stage pipeline: `Context -> Activity Collector -> Decision Engine -> Scoring Engine -> Ranking Engine -> Presentation Mapper`.

**Stateless Contract:**
Every stage in the pipeline must be **stateless** with clear input/output contracts (no internal mutable state). This functions like middleware, where `Input -> Output`.

**Context Engine Enhancements:**
The Context Engine must support additional properties such as:
- `Device`
- `Battery`
- `Connectivity` (e.g., Offline -> Don't recommend Bank Sync)

## Alternatives Considered
A single monolithic AI function, which is hard to test and debug.

## Consequences
Highly testable logic, as each stage can be tested independently without mock state. Future ML models can replace just the Ranking or Scoring engine without touching UI code. The Presentation Mapper converts ranked recommendations into UI-ready models, keeping the pipeline independent of Flutter widgets.
