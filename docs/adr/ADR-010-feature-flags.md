# ADR-010: Feature Flags

## Context
Major architectural changes and migrations (such as the Home Screen composition or the new Recommendation Pipeline) carry significant risk if deployed globally all at once.

## Decision
Implement a centralized feature flag mechanism to manage the staged rollout and testing of new features.

Examples of central feature flags:
- `enableNewDashboard`
- `enableActivityFeed`
- `enableCommandCenter`
- `enableRecommendationPipeline`
- `enableAI`
- `enableRecurring`

## Alternatives Considered
Using a single monolithic boolean for the entire migration, or relying on distinct build flavors for testing new features.

## Consequences
Allows for safe, staged rollouts. Developers can switch between old and new implementations during the migration until feature parity and performance budgets are confirmed. It drastically reduces the risk of breaking existing functionality.
