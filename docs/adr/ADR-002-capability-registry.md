# ADR-002: Capability Registry

## Context
The roadmap initially scaled by plugging "Modules" into the Home screen, leading to a tight dependency where Home needs to know what a "Module" is.

## Decision
Shift to a Capability-centric architecture. Features do not register themselves; they register Capabilities (e.g., Dashboard Card, Quick Action, Timeline Feed).

The registry must be **metadata-driven**. Each capability should declare a descriptor:
- `Name`
- `Version`
- `Dependencies`
- `Dashboard Cards`
- `Actions`
- `Timeline Entries`
- `Command Center Entries`
- `Permissions`

**Registry Lifecycle Management:**
Every registry in the system must explicitly implement the full lifecycle:
1. **Registration**
2. **Discovery**
3. **Execution**
4. **Cleanup**

## Alternatives Considered
Hardcoding module checks (`if (budgetEnabled) showBudget()`).

## Consequences
The UI never knows which features are installed, making it infinitely scalable and future-proof.
