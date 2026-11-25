# Violet Expense Tracker — QA Record

**Scope:** Approved PRD v1.1.0 MVP. Optional bonuses and QR Menu Admin requirements are excluded.

## Latest automated verification

These are the results of the final code verification run for this implementation:

| Command | Result |
| --- | --- |
| `dart format .` | Passed; 53 Dart files checked, 0 changed. |
| `flutter analyze` | Passed; no issues found. |
| `flutter test` | Passed; all 90 tests passed. |
| `git diff --check` | Passed; no whitespace errors. Git emitted line-ending normalization warnings for `docs/DECISIONS.md` and `docs/DESIGN.md`. |
| `flutter build apk --release` | Passed; created `build/app/outputs/flutter-apk/app-release.apk` (49.2 MB). The APK was not installed or launched on an Android device. |

### Test coverage

- **Startup and bindings:** first-launch startup, route/controller registration, and reuse of the registered services/controllers.
- **Expense controllers and persistence:** expense create/edit/delete, stable IDs on edit, input validation, storage failure behavior, reactive updates, category/date filtering, and local-calendar date boundaries.
- **Expense form:** Add/Edit rendering and prefill, amount/category/note validation, date selection, future-date confirmation, failure value preservation/retry, duplicate-submit protection, edit loading/missing/error states, and post-save navigation.
- **Home and Details:** empty Home state, Add navigation, reactive filter/display behavior, Details navigation, and confirmed deletion including the final expense.
- **Categories:** default seeding and protection, custom category validation/CRUD, linked-expense reassignment, partial failure safety, and Add Expense selector integration.
- **Dashboard and Settings:** current-month totals and category breakdown, empty-month state, currency formatting, persisted preference behavior, theme persistence ordering, and onboarding retry after a failed write.
- **Hive:** adapter/box initialization, CRUD, reopen/reload persistence, and explicit failure behavior.
- **Responsive widget check:** Welcome and Home are exercised at 320px. This is a widget-test result, not physical-device verification.

The suite uses fakes for controller/widget tests and Hive-backed tests where persistence behavior is under test. Passing widget tests do not establish device runtime, pixel-level visual matching, or performance targets.

## Android and platform verification

- `flutter devices` found Windows, Chrome, and Edge, but no Android device or emulator. No physical Android interaction test is claimed.
- Release APK build succeeded at `build/app/outputs/flutter-apk/app-release.apk`; device installation/runtime remain unverified.
- iOS build/device verification: not performed; no claim is made.
- The Android application ID remains the Flutter placeholder `com.example.violet_expense_tracker`; choose/approve a production package identifier before external release.

## Visual, performance, and delivery gaps

- The final Flutter screens were not verified pixel-by-pixel against the Figma Make design. Historical Figma observations and known visual gaps are in `DESIGN.md`.
- No genuine product screenshots are currently recorded as project deliverables.
- NFR-01/02 startup and save/update performance targets were not measured on a documented mid-range Android device.
- Text scaling, keyboard behavior, color contrast, and the full 320–430px range were not verified on Android hardware.
- CI workflow success is not claimed from configuration alone; see actual workflow runs separately.

## Manual Android demonstration checklist

Run on a connected Android phone or emulator after `flutter devices` identifies it:

1. Run `flutter run -d <android-device-id>` and complete the first-launch Welcome flow.
2. Add an expense with amount, category, date, and note; verify Home shows it and the daily total changes.
3. Add a future-dated expense and verify the confirmation dialog; cancel once, then confirm and verify it saves.
4. Open Details, edit the expense, and verify the same record is updated rather than duplicated.
5. Open Details, cancel a delete confirmation, then confirm deletion; verify the list and total update, including when deleting the final item.
6. Apply and clear category/date filters; verify the filtered-empty and ordinary empty states.
7. Review Dashboard totals and category breakdown for the current month.
8. Create a custom category, use it for an expense, reassign linked expenses before deletion, and verify built-in categories cannot be deleted.
9. Change theme and currency, force-stop and relaunch, and verify preferences and expense/category data persist.
10. Capture genuine Home, Dashboard, and Add/Edit screenshots for the README/demonstration. Record the device, Android version, and any issues; do not substitute widget-test images for device screenshots.

## Known scope boundaries

Category editing and the optional PRD §9 bonuses remain out of scope. See `PRD.md`, `MVP.md`, and `REVIEW.md` for the approved scope and readiness summary.
