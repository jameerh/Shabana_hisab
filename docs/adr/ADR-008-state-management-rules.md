# ADR-008: State Management Rules

## Context
Without clear rules on where mutable state lives and how it is managed, future contributors may scatter state across widgets and controllers, leading to bugs, memory leaks, and unpredictable UI behavior.

## Decision
Establish strict state management guidelines:

- **Where does mutable state live?**
  Mutable state must be contained within dedicated State Controllers or Domain Services, never directly in UI Widgets (except for transient, purely visual state like animations).
  
- **Who owns lifecycle?**
  The routing layer or the parent orchestrator (e.g., `HomeCompositionWidget` via its Section Registry) owns the lifecycle of controllers. Controllers should be disposed of when their respective UI scopes are destroyed.

- **Which layer may call `setState`?**
  Only leaf or highly localized Presentation components should manage their own render cycle. Business logic must be reactive (e.g., using streams or observables), and the UI layer simply listens to these states.

- **How are events propagated?**
  Events flow from the UI (actions) to Controllers, which update state, triggering a reactive rebuild of the UI.

- **What is UI state vs domain state?**
  - *UI State:* Scroll position, expanded/collapsed sections, active tabs. This lives in the widget tree or localized view controllers.
  - *Domain State:* User preferences, fetched transactions, cached recommendations. This lives in Repositories or Domain Services.

## Alternatives Considered
Ad-hoc state management using whatever pattern the current developer prefers.

## Consequences
Consistent, predictable, and debuggable state changes across the entire application.
