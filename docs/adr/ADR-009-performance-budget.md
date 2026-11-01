# ADR-009: Performance Budget

## Context
Performance degradation typically happens incrementally. Without objective targets, "fast enough" is subjective and leads to bloated apps.

## Decision
Define strict, measurable performance budgets for critical application flows:

- **Dashboard Render:** `< 500 ms`
- **Recommendation Pipeline:** `< 100 ms`
- **Search (Universal Command Center):** `< 100 ms`
- **Activity Feed Scrolling:** `60 FPS target`
- **Memory Allocation:** No unnecessary object churn in build methods.
- **Large Dataset Handling:** The application must remain responsive with `5k+ activities` loaded.

## Alternatives Considered
Relying solely on developer intuition and subjective testing during QA.

## Consequences
Provides the team with clear, objective targets. Features that fail to meet these budgets must be optimized before they can be merged.
