# Violet Expense Tracker MVP

## Product scope

This implementation follows approved PRD v1.1.0: an offline, single-user expense tracker using Flutter, GetX, and Hive. This document reports implementation status and does not replace or expand the approved PRD.

## Implemented

- First-launch Welcome flow with persisted completion.
- Add, read, edit, and confirmed-delete expense flows using stable expense IDs.
- Reactive Home history grouped by date, daily totals, category labels/icons, and category/date filters.
- Empty, loading, missing-record, and recoverable error states where applicable.
- Current-calendar-month dashboard total and category breakdown.
- Protected default categories, custom-category creation/deletion, and linked-expense reassignment.
- Persisted light/dark mode and display-currency preferences.
- Hive persistence for expenses, categories, settings, and onboarding.

## Excluded

CSV/PDF export, budgets, notifications, multilingual support, cloud sync, accounts, and category editing remain outside the approved MVP scope.

## Completion evidence and limitations

See `docs/QA.md` for current test counts and command results. Automated tests do not establish Android device usability, presentation screenshots, physical-device performance targets, or pixel-level Figma parity. Those items must be considered separately in the readiness decision in `docs/REVIEW.md`.
