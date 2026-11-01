# ADR-004: Financial Activity Feed

## Context
The Home screen displayed a "Transaction Timeline", which limits the scope of the app to expense tracking.

## Decision
Upgrade the timeline to a Financial Activity Feed. 

**Decomposition:**
To prevent the Activity Feed from becoming a massive monolithic 1500-line widget, it must be split internally into:
`Feed Controller -> Grouping -> Sorting -> Rendering`

## Alternatives Considered
Separate tabs for Reminders, Transactions, and AI Insights.

## Consequences
A unified feed that organically supports imports, family activity, budget warnings, and goal milestones in one scrollable view, while maintaining clean internal separation of responsibilities.
