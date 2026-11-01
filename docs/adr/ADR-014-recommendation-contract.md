# ADR-014: Recommendation Contract

## Context
The Shabana Hisab Financial Operating System (FOS) relies on multiple autonomous domain engines (`GoalEngine`, `BudgetEngine`, `ForecastEngine`, `LiquidityEngine`, `CashFlowEngine`). To maintain complete decoupling, engines must publish recommendation candidates using a unified, standardized contract rather than managing independent recommendation UI components or direct cross-engine dependencies.

## Decision
We freeze the **Recommendation Contract** schema (`Recommendations` Drift entity). Every financial intelligence engine MUST produce candidate recommendations matching this exact structure.

```sql
Recommendations (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  profileId    INTEGER NOT NULL,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  score        REAL NOT NULL,        -- Priority rank score (0.0 to 100.0)
  priority     INTEGER NOT NULL,     -- Ordinal rank (1 = highest urgency)
  confidence   REAL NOT NULL,        -- Engine confidence score (0.0 to 1.0)
  category     TEXT NOT NULL,        -- 'RISK', 'LIQUIDITY', 'BUDGET', 'GOAL', 'SYSTEM'
  sourceEngine TEXT NOT NULL,        -- e.g., 'ForecastEngine', 'LiquidityEngine', 'BudgetEngine', 'GoalEngine'
  action       TEXT,                 -- Optional action route/token e.g. 'REVIEW_BUDGETS', 'CONTRIBUTE_GOAL'
  whyShown     TEXT NOT NULL,        -- Plain language explainability rationale
  expiresAt    DATETIME,             -- Optional expiry timestamp
  createdAt    DATETIME NOT NULL
)
```

## Contract Invariants
1. **Engine Independence**: Engines publish candidate state without assuming UI rendering details or other engines' private logic.
2. **Standardized Categories**:
   - `RISK`: Cash flow deficit, critical budget breach, or overdraft risk.
   - `LIQUIDITY`: Low liquid reserves, emergency reserve depletion, or discretionary spend warnings.
   - `BUDGET`: Velocity warning, budget overuse, or reallocation suggestions.
   - `GOAL`: Acceleration opportunities, deadline risk, or milestone progress.
   - `SYSTEM`: Data backup, security, or profile configuration.
3. **Explainability (`whyShown`)**: Every recommendation must include a human-readable statement explaining why the engine flagged it.
4. **Scoring & Ranking**: `RecommendationEngineV2` collects candidate recommendations, sorts by `score` descending, deduplicates redundant items, assigns ordinal `priority`, and persists top actionable items for the Home Dashboard.

## Consequences
- New financial engines (e.g., Debt Payoff, Tax Planner, Investment Advisor) can seamlessly publish recommendations by complying with this contract.
- The UI layer renders recommendations using a single, high-converting, consistent card component.
