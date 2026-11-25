# Agent Guide — Violet Expense Tracker

## Project at a glance

This repository contains an **offline-first personal expense tracker** built with Flutter/Dart, GetX, and Hive. It has no account, backend, cloud sync, or runtime network requirement. The approved product contract is [`docs/PRD.md`](docs/PRD.md) v1.1.0; accepted technical decisions are in [`docs/DECISIONS.md`](docs/DECISIONS.md).

Use this guide to orient yourself, then inspect the relevant source and current Git status before changing code. Do not assume the worktree is clean or that a prior report describes the current checkout.

## Source-of-truth order

1. Approved PRD and accepted ADRs.
2. [`docs/DESIGN.md`](docs/DESIGN.md) for observed Figma intent and what is not verified.
3. Current implementation and tests.
4. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/QA.md`](docs/QA.md), and other project notes.

If Figma observations conflict with the PRD/ADRs, preserve the approved product behavior. Do not infer missing visual specifications or expand scope. Make docs reflect actual code and test results; never claim device, CI, or visual verification that was not run.

## Technology and boundaries

- Flutter with Dart constraint `^3.11.3`; GetX (`get`) for reactive state, named routes, and dependency injection.
- Hive/Hive Flutter for offline expenses, categories, and settings. Existing `fl_chart`, `intl`, and `uuid` dependencies are used.
- Do not add a dependency or introduce a second state-management solution without a genuine, justified requirement.
- Keep presentation in views/widgets, product rules and reactive application state in controllers, and Hive operations in `HiveService`.
- Views/controllers must not access Hive boxes directly. Controllers should not build widget trees. Bindings supply dependencies through constructors; do not register duplicate services/controllers.
- Preserve existing Hive type IDs, field indexes, box names, stable category IDs, and expense IDs. Schema changes require careful compatibility review.
- Preserve user changes. Inspect `git status --short --branch` before work; do not reset, clean, checkout, or overwrite unrelated files. Do not commit or push unless explicitly requested.

## Application structure

```text
lib/
  bindings/     app, main-shell, onboarding, category, expense, and form DI
  controllers/  expense/category/form/navigation/onboarding/settings state
  models/       Expense, Category, generated Hive adapters
  routes/       route names and GetPage definitions
  services/     HiveService (all local storage access)
  utils/        stateless currency formatting helper
  views/        Welcome, main shell, Home, Dashboard, Categories, Settings,
                Expense Details, shared Add/Edit form
  widgets/      reusable form controls, category icon and category dialogs
test/           controller, service, binding, startup, and widget tests
docs/           approved product/design/architecture/decision/QA records
```

Use the existing structure and naming conventions. Some Home components (expense rows, date grouping, filters, and state panels) are private to the view rather than separate public widgets.

## Architecture and application state

### Startup and dependency lifecycle

`main()` initializes Flutter and `HiveService`, loads saved settings, reads onboarding completion, then selects `/welcome` or `/home` before `runApp`. The app binding registers the already initialized `HiveService` and preloaded `SettingsController` once. The `/home` `MainBinding` lazily registers the shared `ExpenseController`, `CategoryController`, and `MainNavigationController`. Details resolves the existing expense controller; it must not create another one. Add/Edit gets a fresh route-scoped `ExpenseFormController`.

### State-management conventions

- Shared app data and preferences are GetX observables (`RxList`, `Rxn`, `RxBool`, etc.); views observe only the smallest areas that need updates with `Obx`.
- Use local widget state for ephemeral dialog drafts and local interactions. Do not wrap an entire screen in a reactive builder unnecessarily.
- Keep async operation outcomes explicit. Update observable state only after persistence succeeds. Expose errors and preserve user-entered values when writes fail.
- Follow existing GetX route and controller lifecycle. Reuse the registered app-wide `HiveService` and shell-owned controllers.

### Models and Hive persistence

- `Expense` Hive type ID **0**: `id` index 0, `amount` index 1, `categoryId` index 2, `date` index 3, nullable `note` index 4.
- `Category` Hive type ID **1**: `id` index 0, `name` index 1, `iconKey` index 2, `isDefault` index 3.
- Boxes: `expenses` (`Box<Expense>`), `categories` (`Box<Category>`), and `settings` (`Box<dynamic>`).
- Settings keys: `themeMode` (`ThemeMode.name`), `currencySymbol`, `onboardingCompleted`.
- Built-in categories use stable IDs `food`, `transport`, `bills`, `shopping`. Seed missing defaults without replacing existing category records; default categories cannot be deleted.
- Expense updates retain their original ID. Categories are referenced by ID, never by display name.
- Default settings are Light theme and USD (`$`). Persist preference changes before applying them; failed writes keep the previous state and show an error.
- Onboarding completion is persisted before navigating. If persistence fails, stay on Welcome and allow retry.
- If category reassignment fails partway, retain the source category. A retry resumes for expenses still linked to it; this is not transactional rollback.

## Implemented screens and navigation

| Route / destination | Implementation |
| --- | --- |
| `/welcome` | First-launch onboarding; completion is persisted before entering the app. |
| `/home` | Main four-destination shell: Home, Dashboard, Categories, Settings. |
| Home tab | Reactive expenses sorted newest-first and grouped by local calendar day; daily totals, note/title, amount, date, and category/icon; category and inclusive date-range filters; separate first-time empty, filtered-empty, loading, and error states; Add action. Expense tap opens Details. |
| Dashboard tab | Current calendar-month total and spending distribution by category, displayed with `fl_chart`; empty-month state instead of an empty chart. |
| Categories tab | Built-in defaults and custom categories, creation with icon, safe deletion, and reassignment of linked expenses. Category editing is not in approved scope. |
| Settings tab | Persisted Light/Dark and USD/EUR/LBP/GBP display-symbol choices. Currency selection changes formatting only; it never converts amounts. |
| `/expense/details` | Selected expense information, Edit and confirmed Delete actions, missing-record state, and retryable read/delete errors. |
| `/expense/add`, `/expense/edit` | Shared native form. Edit loads existing values and retains original ID. Validates positive decimal amount, required category, and optional note up to 200 characters. Date picker defaults to today; future dates require ADR-007 confirmation. Successful persistence gives feedback and returns Home; failed save retains values. |

Route constants and page bindings are defined in `lib/routes/app_routes.dart` and `lib/routes/app_pages.dart`. Check these files before adding or changing navigation.

## Design and visual language

- Design source: [`docs/DESIGN.md`](docs/DESIGN.md) and its linked Figma Make preview. Existing Figma inspection described a portrait, single-column app with violet/purple accents, light lavender/off-white surfaces, dark primary text, muted metadata, softly tinted category icon tiles, rounded cards/dialogs, and four-tab bottom navigation.
- The Flutter app currently uses Material 3 `ThemeData` with `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` for light and dark themes. Prefer the existing theme and semantic `ColorScheme` values rather than scattering new hard-coded colors.
- Typography follows a clear hierarchy: large/light Welcome headline, strong screen and expense titles, small uppercase accent eyebrow labels, and quieter supporting text/metadata. **No authoritative font family, sizes, line heights, exact color tokens, spacing, radii, or shadows have been verified.** Do not invent claims of exact Figma fidelity or introduce a custom font without evidence/approval.
- Use a narrow, portrait-first, responsive layout. PRD targets 320–430px; automated widget coverage includes 320px for selected screens, but physical-device/text-scaling/keyboard checks remain outstanding.
- Use native Flutter controls, date pickers, dialogs, snackbars, and navigation; do not port React/CSS/web-specific behavior. The target expense flow is Home → Details → Edit/Delete, not the prototype's expense action dialog.
- `CategoryIcon` centralizes rendering of persisted `iconKey`s. `CurrencyFormatter` is stateless and receives the amount and selected symbol.
- A user-provided Figma MCP `src/main.tsx` snapshot is not the complete design project. Historical observations do not equal current screenshot-based visual acceptance. See `docs/MCP.md` and `docs/DESIGN.md`.

## Testing and verification

Use the smallest relevant test while iterating, then run the full checks for a broad change:

```powershell
dart format .
flutter analyze
flutter test
git diff --check
```

At the last recorded verification, all 90 tests passed, analysis was clean, formatting checked 53 Dart files with no changes, and the release APK built successfully. These are historical results; rerun required commands after code changes. Check [`docs/QA.md`](docs/QA.md) for the recorded test coverage and limitations.

The last recorded release build is `build/app/outputs/flutter-apk/app-release.apk` (49.2 MB). No Android device/emulator was connected, so that APK was not installed or run on Android. No iOS test, physical-device performance measurement, genuine product screenshots, or final pixel-level Figma comparison is claimed. Do not report presentation readiness until manual Android checks and requested delivery evidence are completed.

## Scope and next-agent checklist

- Approved scope is PRD v1.1.0. CSV/PDF export, budgets, notifications, multilingual support, cloud sync, accounts, and category editing are excluded unless explicitly approved.
- Before implementing: inspect `git status`, relevant code/tests, and the applicable PRD/design/ADR sections. Confirm whether an apparent feature is truly absent.
- Add focused tests for introduced behavior; do not weaken existing tests.
- Update only directly relevant docs and record actual command results.
- Keep the working tree uncommitted unless the user explicitly requests a commit.
- The Android application ID is still the Flutter placeholder `com.example.violet_expense_tracker`; obtain approval for a release identifier before external distribution.
