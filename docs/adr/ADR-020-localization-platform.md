# ADR-020: Multilingual & Localization Platform Architecture

## Context
With **FOS Core v1.0** (ADRs 001–017) and **Predictive Intelligence Platform v1.0** (ADRs 018–019) fully feature-frozen, adding multilingual UI capabilities (English 🇬🇧, Marathi 🇮🇳, English + Marathi 🌐) requires a strict architectural boundary. UI localization must be introduced as a pure presentation and platform capability without altering core financial engines, mutating database contracts, or introducing performance regressions.

## Decision
We freeze the **Multilingual & Localization Platform Architecture (Epic 0.5)**:

### 1. Presentation Boundary Guarantee
- Localization operates strictly within the presentation layer (`lib/presentation/` and `lib/core/localization/`).
- Domain engines (`CashFlowEngine`, `BudgetEngine`, `GoalEngine`, `LiquidityEngine`, `ForecastEngine`, `RecommendationEngineV2`, `PredictionDagOrchestrator`, `TrendEngine`, `BehaviorEngine`, `SeasonalityEngine`, `RiskEngine`, `OptimizationEngine`, `AnomalyEngine`, `SimulationEngine`) remain 100% language-neutral and produce structured metrics/tokens.

### 2. Zero Core Engine Re-execution
- Switching UI language modes (`Follow Device` $\leftrightarrow$ `English` $\leftrightarrow$ `Marathi` $\leftrightarrow$ `English + Marathi`) triggers UI widget rebuilds only.
- ZERO financial or predictive engine pipelines may re-execute upon language change.

### 3. Primary Localization API (`AppLocalizations`) & Locale Handling
- Standard Flutter `AppLocalizations` generated from `.arb` files (`app_en.arb`, `app_mr.arb`) is the primary localization interface (`context.l10n`).
- `AppLanguage.english` maps to `Locale('en')`. `AppLanguage.marathi` maps to `Locale('mr')`.
- `AppLanguage.englishMarathi` is a **presentation mode** (`bilingualPresentationMode = true`) using `Locale('en')` under the hood, not a fake `en_MR` locale.
- `BilingualText` is a specialized presentation widget for stacked dual-language rendering in `englishMarathi` mode.

### 4. Historical & User Data Non-Mutation
- Historical financial records (`FinancialClosing`, past `Recommendations`, `Insights`, `Transactions`) and user-entered content (merchant names, party names, account names, goal titles, transaction notes, OCR text) are preserved untouched in their original form.

### 5. Independent Voice & UI Languages
- UI Display Language (`AppLanguage`) and Voice Speech-to-Text Language (`VoiceService` locale `mr_IN` / `en_IN` / `hi_IN`) are strictly decoupled settings.

### 6. Separation of Financial Numerals & Localization
- Financial values (currency amounts `₹`, numbers, percentages, confidence scores, health ratings) are formatted independently via `NumberFormat` / formatters using standard Western digits (`₹12,500`) and are never concatenated inside translated ARB strings.

### 7. Structured Financial Intelligence Translation
- Dynamic engine messages are emitted as structured tokens or parameters. The `FinancialIntelligenceLocalizer` converts them at presentation time. Legacy plain-text strings fallback gracefully to stored text without database migrations.

### 8. Extensible Language Architecture
- Adding future Indian languages (Hindi, Gujarati, Kannada, Telugu) requires creating corresponding `.arb` files and updating `AppLanguage`, with zero modifications to financial domain logic.

## Status
- **Status**: APPROVED & LOCKED
- **Scope**: Epic 0.5 & Platform Presentation Layer
