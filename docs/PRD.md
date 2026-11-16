# Product Requirements Document — Violet Expense Tracker

**Version:** 1.1.0
**Status:** Approved
**Author:** Fatima Azzam (Intern)
**Reviewer:** Senior Engineering Mentor
**Last Updated:** 2026-11-15

## Change Log

| Version | Date | Author | Change |
| :--- | :--- | :--- | :--- |
| 1.0.0 | 2026-11-10 | Fatima Azzam | Initial PRD; added Resolved Decisions RD-01–RD-03; refined FR-05, FR-21, FR-25, FR-26 |
| 1.1.0 | 2026-11-15 | Project Owner (approved update) | Added first-launch onboarding, Expense Details, and explicit missing-record/persistence-failure handling; updated flows, scope, and traceability |

## 1. Product Overview

**Violet Expense Tracker** is a personal finance mobile application that allows users to record, categorize, and analyze their daily expenses. It operates fully offline — all data is stored locally on the device. There is no backend, no user account, and no network dependency. The app is built with Flutter and GetX and targets Android and iOS.

## 2. Problem Statement

Many individuals lose track of where their money goes because expense tracking feels like a chore. Users are forced to choose between complex spreadsheet tools (too much friction) or apps that require an account and internet connection (privacy and availability concerns). There is a need for a **simple, fast, offline-first** expense tracker that works in seconds, without sign-up or connectivity.

## 3. Objectives

1. Allow a user to record an expense in under 10 seconds.
2. Provide a clear daily view of spending history.
3. Give the user a monthly summary with category breakdown.
4. Work reliably with no internet connection.
5. Persist all data across app restarts.

## 4. Target Users

- **Primary:** Individuals who want to track personal spending on their phone without a subscription or account.
- **Secondary:** Students and young professionals on a budget who need a lightweight tool.
- **Technical context:** Users with basic smartphone literacy. The UI must be intuitive without a tutorial.

## 5. Functional Requirements

Requirements are labeled **FR-n** and will be referenced in QA and MVP tracking.

### 5.1 Expense Management

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-01 | The user can add a new expense with an amount, a category, a date, and an optional note. | Must |
| FR-02 | The user can edit an existing expense from Expense Details. All fields (amount, category, date, note) are editable, and the form is prefilled with the current values. | Must |
| FR-03 | The user can permanently delete an expense from Expense Details after confirming. On successful deletion, the app returns to Home, refreshes the expense list and dashboard calculations, and shows a success message. | Must |
| FR-04 | The amount field accepts only positive decimal numbers. Zero and negative values are rejected. | Must |
| FR-05 | The date field defaults to the current date and opens a date picker. If the selected date is after today, a confirmation dialog is shown before saving ("This date is in the future. Save anyway?"). | Must |
| FR-06 | The note field is optional and limited to 200 characters. | Must |
| FR-07 | The app rejects saving an expense with an empty amount or no category selected. | Must |

### 5.2 Expense History

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-08 | Expenses are displayed in a list, grouped by day with date headers (e.g., "Today", "Yesterday", "Nov 12, 2026"). | Must |
| FR-09 | The list is sorted by date descending (most recent first). | Must |
| FR-10 | The user can filter expenses by one or more categories. | Must |
| FR-11 | The user can filter expenses by a date range (start date – end date). | Must |
| FR-12 | When no expenses match the current filter, an empty state message is displayed. | Must |
| FR-13 | When no expenses exist at all, a distinct "first-time empty" state is displayed with a hint to add the first expense. | Must |

### 5.3 Dashboard

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-14 | The dashboard displays the total expense amount for the current calendar month. | Must |
| FR-15 | The dashboard displays a pie chart showing expense distribution by category for the current month. | Must |
| FR-16 | If there are no expenses in the current month, the chart area shows an empty state instead of a blank chart. | Must |
| FR-17 | The dashboard updates automatically when an expense is added, edited, or deleted. | Must |

### 5.4 Categories

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-18 | The app ships with default categories: Food, Transport, Bills, Shopping. | Must |
| FR-19 | The user can create a custom category with a name and an icon. | Must |
| FR-20 | The user can delete a custom category. Default categories cannot be deleted. | Must |
| FR-21 | Deleting a custom category that has existing expenses is **blocked**. The user must reassign those expenses to another category via a dialog before the category can be deleted. | Must |
| FR-22 | Category names must be unique (case-insensitive) and limited to 30 characters. | Must |

### 5.5 Settings

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-23 | The user can toggle between light mode and dark mode. | Must |
| FR-24 | The theme preference persists across app restarts. | Must |
| FR-25 | The user can select a currency **symbol** from a predefined list (USD $, EUR €, LBP ل.ل, GBP £). This changes display formatting only; amounts are never converted. | Must |
| FR-26 | The selected currency symbol is applied everywhere an amount is displayed via `NumberFormat.currency`. | Must |
| FR-27 | The currency preference persists across app restarts. | Must |

### 5.6 Local Storage

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-28 | All expense data is stored locally using Hive. | Must |
| FR-29 | All data persists after the app is closed and reopened. | Must |
| FR-30 | All data persists after the device is restarted. | Must |
| FR-31 | The app operates fully offline. No network calls are required for any core feature. | Must |

### 5.7 First-Launch Onboarding and Expense Details

| ID | Requirement | Priority |
| :--- | :--- | :--- |
| FR-32 | The Welcome screen is shown only on the first application launch. When the user taps Get Started, the app stores an onboarding-completed flag in Hive. On later launches, the app opens the main application directly. No authentication or backend is required. | Must |
| FR-33 | Tapping an expense on Home opens an Expense Details screen showing its amount, category, date, and optional note, with Edit and Delete actions. | Must |
| FR-34 | If an Expense Details request refers to a record that no longer exists, the app shows an explicit not-found state with an action to return to Home. | Must |
| FR-35 | If Hive fails while loading a requested expense or persisting expense creation, editing, or deletion, the app shows an explicit error with a retry path and distinguishes a storage error from a missing record. For failed writes, it does not show success or navigate away as though the operation succeeded and preserves the current form or Details state. | Must |

## 6. Non-Functional Requirements

| ID | Requirement |
| :--- | :--- |
| NFR-01 | The app launches in under 3 seconds on a mid-range Android device. |
| NFR-02 | Adding an expense completes (save + UI update) in under 500ms. |
| NFR-03 | The UI is responsive and usable on screen widths from 320px to 430px (typical phone range). |
| NFR-04 | All user-facing text is in English. |
| NFR-05 | Form validation errors are shown inline, under the relevant field, with a clear message. |
| NFR-06 | The codebase follows the GetX architecture: controllers, bindings, routes, and reactive state. |
| NFR-07 | The project has a working CI pipeline (`flutter analyze` + `flutter test`) on every push to `develop`. |

## 7. User Flows

**Flow 1 — Add an expense:**
Home → Tap FAB (+) → Add Expense screen → Enter amount → Select category → (Optional) Select date, add note → Tap Save → Validation passes → Snackbar "Expense added" → Back to Home → List updates.

**Flow 2 — Edit an expense:**
Home → Tap an expense → Expense Details → Tap Edit → Add/Edit screen pre-filled → Change fields → Save → Snackbar "Expense updated" → Back to Home → List updates.

**Flow 3 — Delete an expense:**
Home → Tap an expense → Expense Details → Tap Delete → Confirm dialog → Confirm → Snackbar "Expense deleted" → Return to Home → List and dashboard calculations update. If persistence fails, show an error and remain on Details.

**Flow 4 — Filter history:**
Home → Tap filter icon → Select category and/or date range → Apply → List shows filtered results → Empty state if no matches.

**Flow 5 — View dashboard:**
Bottom navigation → Dashboard tab → Monthly total card + pie chart by category.

**Flow 6 — Change theme or currency:**
Bottom navigation → Settings → Toggle dark mode / choose currency → App updates instantly and persists.

**Flow 7 — First-launch onboarding:**
First launch → Welcome → Tap Get Started → Persist onboarding-completed flag in Hive → Main application. On subsequent launches, open the main application directly.

## 8. Acceptance Criteria (Summary)

The MVP is accepted when:
1. All **Must** functional requirements (FR-01 through FR-35) are implemented.
2. All non-functional requirements (NFR-01 through NFR-07) are satisfied.
3. The CI pipeline is green on the `develop` branch.
4. Unit tests exist for the `ExpenseController` (CRUD logic) and settings persistence.
5. The app runs on an Android emulator without crashes.
6. The README contains setup steps and at least three screenshots.

## 9. MVP Scope

**In scope (MVP):** Sections 5.1 through 5.7, Section 6, and acceptance criteria in Section 8.

**Out of scope for the MVP (optional bonuses, not required for delivery):**
- CSV or PDF export.
- Monthly budget limit with warnings.
- Local notifications / daily reminders.
- Multi-language support (English/Arabic).
- Cloud sync or user accounts.

These may be considered only after the MVP is complete and only with explicit approval.

## 10. Constraints

- **Time:** 2-week internship window (10 working days).
- **Technology:** Flutter, GetX, Hive. No backend.
- **Platforms:** Android and iOS. Only Android will be tested on-device during the internship (no Mac/Xcode available).
- **Team:** Single developer (intern).
- **Evaluation:** Code quality (25%), GetX usage (25%), UI/UX (20%), features (20%), delivery (10%).

## 11. Assumptions

- The user has a device running Android 8.0+ or iOS 13+.
- The device has at least 50 MB of free storage for the app and its data.
- The user does not need multi-device sync.
- Data loss from an uninstall is acceptable (no export in MVP).

## 12. Resolved Decisions (Formerly Open Questions)

These decisions resolve the ambiguities that existed between the PDF wording and implementation. They are mirrored as ADRs in `docs/DECISIONS.md`.

| ID | Question | Final Decision | Rationale | ADR |
| :--- | :--- | :--- | :--- | :--- |
| RD-01 | Does "currency selection" mean display symbol only, or exchange-rate conversion? | **Display symbol only.** Store only the symbol in settings. Amounts are not recalculated. | The app is offline-first (FR-31). Live exchange rates require network access and violate the core constraint. Matches the PDF wording "currency selection," not "multi-currency accounting." | ADR-005 |
| RD-02 | What happens when deleting a custom category that has expenses? | **Block deletion.** Show a dialog listing the affected expense count and a dropdown to reassign them to another category. Only after reassignment can the category be deleted. | Industry best practice (Actual Budget, Grassfeld). Prevents orphaned transactions and silent data loss. Keeps the pie chart and filters accurate. | ADR-006 |
| RD-03 | Should future-dated expenses be allowed? | **Allow, with confirmation.** If the chosen date is after today, show a confirmation dialog before saving. No extra model field is needed. | Balances flexibility (pre-recording bills) with data integrity (prevents year-typo errors). Precedent: PocketSmith. | ADR-007 |
| RD-04 | When should Welcome appear? | **First launch only.** Persist completion in Hive after Get Started; open the main application directly on later launches. No authentication is added. | Provides the designed welcome experience once while retaining direct access on later offline launches. | ADR-010 |
| RD-05 | What happens when a Home expense is selected? | **Open Expense Details.** Show the expense fields and Edit/Delete actions there; editing opens the existing prefilled form, and deletion requires confirmation. | Gives one consistent details-first path for viewing, editing, and deleting an expense. | ADR-011 |
| RD-06 | How are missing expense records and expense persistence failures handled? | **Report them explicitly.** A missing Details record shows a not-found state with a return-to-Home action. A Hive lookup error is distinct from a missing record and offers retry. A failed create/edit/delete preserves the current form or Details state, shows an error, and does not report success or navigate away; retry remains available. | Prevents false success feedback and protects the user's current data and input. | ADR-012 |

## 13. Traceability

| PDF Requirement | PRD Reference |
| :--- | :--- |
| Add / Edit / Delete expenses | FR-01, FR-02, FR-03 |
| First-launch onboarding | FR-32 |
| Expense Details and missing-record handling | FR-33, FR-34 |
| Expense persistence failure handling | FR-35 |
| Amount, category, date, optional note | FR-01, FR-04, FR-05, FR-06 |
| List grouped by day | FR-08 |
| Filtering by category and date range | FR-10, FR-11 |
| Dashboard monthly total + pie chart | FR-14, FR-15 |
| Default + custom categories | FR-18, FR-19, FR-20 |
| Hive / local storage | FR-28, FR-29, FR-30, FR-31 |
| Light/dark mode + currency | FR-23, FR-24, FR-25, FR-26, FR-27 |
| Form validation and error messages | FR-07, NFR-05 |
| Empty-state and loading screens | FR-12, FR-13, FR-16 |
| Responsive UI | NFR-03 |
| GetX state management | NFR-06 |
| CI pipeline | NFR-07 |

