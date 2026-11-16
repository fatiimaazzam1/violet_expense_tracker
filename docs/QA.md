# Violet Expense Tracker — Planned QA Strategy

**Status:** Test plan only; no feature tests or platform validation are claimed
**Product source:** Approved `PRD.md`

## Scope and evidence rules

Test only the offline Personal Expense Tracker. QR Menu Admin requirements and optional PRD §9 bonuses are excluded. The current `test/basic_test.dart` is a placeholder, not feature coverage. This plan describes future checks; it records no successful results.

## Planned test layers

| Layer | Planned coverage |
| --- | --- |
| Unit | Expense input validation; category-name uniqueness/length; date grouping and filters; monthly total and category aggregation; stateless currency/date formatting. |
| Hive integration | Approved adapters and schema; Expense/Category CRUD; stable expense identity on edit; category references; settings and onboarding persistence after reopening boxes/app. |
| Controller/widget | GetX dependency registration; onboarding route selection; Add/Edit validation and state isolation; Home filters/empty states; dashboard refresh and empty month; category reassignment; settings selection. |
| Failure paths | Missing expense vs Hive read error; create/edit/delete write failures; onboarding flag write failure; theme/currency write failure; partial category reassignment and category-delete failure. Implement only after open policies are approved. |
| Device/manual | Layout and text scaling at 320px and 430px; keyboard/dialog usability; Android runtime. iOS compatibility/build is a target, but the PRD states there is no Mac/Xcode for on-device internship testing. |
| CI | Confirm the configured formatting, analysis, and test jobs run on the documented push/PR branches; retain actual workflow results rather than inferring success from YAML. |

## PRD traceability

| PRD requirements | Planned verification |
| --- | --- |
| FR-01–07 | Add/edit valid and invalid data, positive amount, required category, date default/future-date confirmation, note length, and shared Add/Edit rules. |
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

- Approve Hive schema and settings serialization before writing adapter/persistence tests.
- Approve onboarding, settings-write, and partial-category-reassignment failure behavior before locking those expected outcomes.
- Select and document a mid-range Android device and repeatable timing procedure for NFR-01/02.

## Results

No tests, builds, device checks, performance measurements, or CI runs are recorded by this plan.
