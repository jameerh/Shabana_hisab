# ADR-001: Home Composition Layer

## Context
The `HomeView` widget grew to over 1500 lines, handling everything from UI rendering to Voice parsing, Database querying, and Undo/Redo state management. 

## Decision
Introduce the `HomeCompositionWidget` and a `Section Registry`. `HomeView` is strictly reduced to an orchestrator that composes sections. 

**Rule:** `HomeCompositionWidget` must **never** contain business rules. Its responsibilities are strictly limited to:
- Requesting registered sections from the Section Registry.
- Ordering them.
- Composing the layout.
- Forwarding user interactions to the appropriate controllers.

No recommendation logic, filtering, or scoring should appear in this widget.

## Alternatives Considered
Using a massive `HomeController` with `GetX` or `Provider`, but this still leaves UI tightly coupled.

## Consequences
Complete separation of concerns. The UI never needs to be updated when new sections (like Investments) are added in the future. Easy section-by-section safe migration (Phase 3.5) utilizing central feature flags (see ADR-010) without risking the core voice workflow.
