# ADR-007: Architecture Dependency Rules

## Context
As the app scales, unstructured dependencies lead to spaghetti code, circular references, and brittle features that break when seemingly unrelated code is modified.

## Decision
Establish and enforce a strict, unidirectional dependency rule across the entire application architecture:

```
Presentation
      ↓
Recommendation Pipeline
      ↓
Capability Coordinator
      ↓
Capabilities
      ↓
Domain Services
      ↓
Repositories
      ↓
Database
```

**Core Rules:**
1. Dependencies must flow only downwards.
2. Dependencies must **never** flow upwards.
3. Dependencies must **never** flow sideways. (Capabilities must never call other capabilities directly; they must interact via the Capability Coordinator).

## Alternatives Considered
Allowing capabilities to directly update other capabilities (e.g., Recurring -> Budget.update()), which creates tightly coupled code that is difficult to maintain and test.

## Consequences
Features remain entirely decoupled. Adding, modifying, or removing a capability does not require changes to other capabilities, ensuring high maintainability and testability.
