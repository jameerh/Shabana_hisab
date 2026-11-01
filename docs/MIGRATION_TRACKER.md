# Migration Tracker

This document tracks the ongoing migration of the Home screen to the new architectural layers and compositional UI layout.
For a feature or section to be considered fully migrated, it must fulfill all checks, including the removal of legacy code, and an audit trail must be recorded.

## Execution Policy
1. Migrate **one section at a time**.
2. Never migrate multiple sections together.
3. For every section:
   - Read the existing implementation completely.
   - Document its current responsibilities.
   - Implement the new section using the new architecture.
   - Run `flutter analyze`.
   - Run the relevant tests.
   - Verify the voice workflow.
   - Compare screenshots.
   - Remove only the migrated legacy code.
   - Update this tracker and the Audit Trail.

## Migration Stages

| Section | Stage | UI | Logic | Tests | Screenshot | Voice Safe | Performance | Legacy Removed |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Greeting** | 1 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Dashboard** | 1 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Quick Actions** | 1 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Search -> UCC** | 2 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Filters** | 2 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Recent Section** | 2 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Financial Activity Feed** | 3 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Bottom Area** | 3 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Mic Integration & Voice UI** | 4 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| **Legacy Cleanup & Polish** | 5 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

## Audit Trail Requirements
For every migrated section, capture the following in `audit_trail.md`:
* Before screenshot
* After screenshot
* Analyzer result
* Test result
* Performance observation
* Notes (if behavior changed intentionally)
