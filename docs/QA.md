# Violet Expense Tracker — Planned QA Strategy

**Status:** Test plan with recorded implementation-milestone evidence; remaining checks are not claimed complete
**Product source:** Approved `PRD.md`

## Scope and evidence rules

Test only the offline Personal Expense Tracker. QR Menu Admin requirements and optional PRD §9 bonuses are excluded. Existing independent tests cover app startup, model serialization, HiveService, GetX bindings, and expense controllers; these do not constitute UI or platform validation.

## Planned test layers

| Layer | Planned coverage |
| --- | --- |
| Unit | Expense input validation; category-name uniqueness/length; date grouping and filters; monthly total and category aggregation; stateless currency/date formatting. |
| Hive integration | Approved adapters and schema; Expense/Category CRUD; stable expense identity on edit; category references; settings and onboarding persistence after reopening boxes/app. |
| Controller/widget | GetX dependency registration; onboarding route selection; Add/Edit controller state and validation; failed-save preservation and retry; future-date confirmation handoff; Home filters/empty states; dashboard refresh and empty month; category reassignment; settings selection. |
| Failure paths | Missing expense vs Hive read error; create/edit/delete write failures; onboarding flag write failure; theme/currency write failure; partial category reassignment and category-delete failure. Implement only after open policies are approved. |
| Device/manual | Layout and text scaling at 320px and 430px; keyboard/dialog usability; Android runtime. iOS compatibility/build is a target, but the PRD states there is no Mac/Xcode for on-device internship testing. |
| CI | Confirm the configured formatting, analysis, and test jobs run on the documented push/PR branches; retain actual workflow results rather than inferring success from YAML. |

## PRD traceability

| PRD requirements | Planned verification |
| --- | --- |
| FR-01–07 | Add/edit valid and invalid data, positive amount, required category, date default/future-date confirmation, note length, and shared Add/Edit rules. Controller unit tests and Add/Edit widget tests cover field rendering, inline validation, date picker selection, and future-date dialog behavior. |
| FR-08–13 | Date-descending grouping, category/date filtering, filtered-empty and first-time-empty states. |
| FR-14–17 | Current-month total, category pie data, empty-month state, and refresh after every expense mutation. |
| FR-18–22 | Required defaults, custom category create/delete, protected defaults, case-insensitive uniqueness, 30-character limit, linked-expense reassignment. |
| FR-23–27 | Light/dark change, persisted preference, supported currency symbols, consistent display formatting without conversion, and persisted currency. |
| FR-28–31 | Hive persistence across app/device restart and core behavior without network access. |
| FR-32 | Welcome only on first launch and direct main-app launch after completion; failure case awaits approval. |
| FR-33–35 | Details fields/actions, missing-record state, Hive lookup errors, failed writes preserving state, and retry behavior. |
| NFR-01–02 | Measure launch under 3 seconds and save-plus-UI update under 500ms under documented conditions. The mid-range Android test device and measurement procedure still need to be selected and recorded. |
| NFR-03–06 | 320–430px usability, English user-facing text, inline validation, and required GetX patterns. |
| NFR-07 | Verify the actual CI run for `flutter analyze` and `flutter test` on pushes to `develop`; the workflow also includes `main` and pull requests. |

## Open test-design items — OPEN — NEEDS APPROVAL

- Approve settings storage identifiers and serialization before writing settings-persistence tests.
- Approve onboarding, settings-write, and partial-category-reassignment failure behavior before locking those expected outcomes.
- Select and document a mid-range Android device and repeatable timing procedure for NFR-01/02.

## Verified implementation milestone — ExpenseFormController

**Date:** 2026-11-16

The independent `test/controllers/expense_form_controller_test.dart` covers create defaults; edit loading and ID preservation; valid, zero, and negative amounts; required category; the 200-character note boundary; missing records; load failure and retry; failed add/edit preserving form values; delegation to the correct `ExpenseController` operation; duplicate-submit prevention; and the future-date confirmation handoff.

| Command | Result |
| --- | --- |
| `dart format .` | Passed; 19 Dart files formatted. The initial run reformatted `app_binding.dart` and `expense_binding.dart`; the final run reported 0 files changed. |
| `flutter analyze` | Passed; no issues found. |
| `flutter test` | Passed; all 30 tests passed, including 14 ExpenseFormController tests. |
| `git diff --check` | Passed. |

This records controller-only evidence for that milestone; at that point, the form UI, inline error rendering, future-date dialog, platform behavior, performance targets, and CI execution remained unverified. The next milestone records the Add/Edit UI tests.

## Other verification not yet recorded

No platform validation, performance measurements, or CI runs are recorded by this plan.

## Verified implementation milestone — Add/Edit Expense form UI

**Date:** 2026-11-16

`test/views/expense_form_view_test.dart` contains 14 independent widget tests using a fake `ExpenseController` and the real named routes/bindings. Coverage includes Add rendering; Edit prefill; fresh route-scoped controller/mode; inline amount/category validation; note input limit; date picker selection; ADR-007 confirmation; successful Add/Edit feedback and Home navigation; failed Add/Edit preserving entered values and edit identity; disabled duplicate submissions; edit loading and missing-record states; and retry after an edit load error. No widget test opens Hive.

| Command | Result |
| --- | --- |
| `dart format .` | Passed; 27 Dart files checked, 0 changed. |
| `flutter analyze` | Passed; no issues found. |
| `flutter test` | Passed; all 44 tests passed. |
| `git diff --check` | Passed; Git reported CRLF-to-LF normalization warnings for `DECISIONS.md` and `DESIGN.md`, with no whitespace errors. |

Device layout, keyboard behavior, dark-mode appearance, currency-prefix integration, and iOS/Android runtime validation remain unverified. The category selector currently uses ADR-015's UI-only built-in choices; category persistence and custom categories remain outside this milestone.

## Verified implementation milestone — Category data foundation

The independent Hive service tests cover generated adapter registration, typed box opening, default-category seeding with stable IDs, idempotent and partial seeding, preserving existing records, custom-category persistence across reopening, CRUD, and explicit errors for invalid or unsafe storage operations.

The CategoryController tests cover valid creation, trimmed names, empty/duplicate/case-insensitive/overlength validation, the 30-character boundary, protected defaults, safe deletion, blocked deletion for linked expenses, reassignment delegated through ExpenseController, failed and partial writes preserving a valid source category, and read/write error state. Binding tests verify that Home uses both route bindings and CategoryController reuses the app-wide HiveService and ExpenseController.

| Command | Result |
| --- | --- |
| `dart format .` | Passed; 32 Dart files checked, 0 changed. |
| `flutter analyze` | Passed; no issues found. |
| `flutter test` | Passed; all 63 tests passed. |
| `git diff --check` | Passed; Git reported existing CRLF-to-LF normalization warnings for documentation files, with no whitespace errors. |

Category editing and category-management UI remain deferred. The Add/Edit form still uses the approved UI-only category choices until the next integration milestone. Recovery policy after partial reassignment remains open under OPEN-03; a failed reassignment retains its source category and reports the error.
