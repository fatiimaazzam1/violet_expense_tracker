# Violet Expense Tracker — Planned Architecture

**Status:** Implementation in progress; planned and implemented responsibilities are identified below
**Scope:** Flutter mobile application for Android and iOS, running offline
**Project:** Violet Expense Tracker — Offline Personal Expense Tracking Mobile Application
**Authority order:** Approved [PRD](./PRD.md); Personal Expense Tracker requirements in the challenge PDF; accepted [ADRs](./DECISIONS.md); [design specification](./DESIGN.md); this architecture; remaining project documentation and repository configuration.

This document describes the target architecture and records implementation status where known. The source tree below is a target structure, not a claim that every listed file or feature exists.

## 1. Architecture principles

1. Keep the approved Flutter, GetX, and Hive choices.
2. Keep screens focused on presentation and user input. Put product rules in controllers and persistence operations in services.
3. Keep expense and category data on-device. Core features must not require a backend or network access.
4. Use small, direct classes that the developer can explain. Add an abstraction only when it solves a real need.
5. Treat the PRD as the functional contract, accepted ADRs as the technical decisions, and DESIGN.md as the user-interface reference.
6. Clearly distinguish planned files and features from those already implemented.

## 2. Planned `lib/` structure

The existing folders are reused; no `app/` folder or new top-level source folder is planned.

```text
lib/
├── bindings/
│   ├── app_binding.dart
│   ├── main_binding.dart
│   ├── onboarding_binding.dart
│   └── expense_form_binding.dart
├── controllers/
│   ├── category_controller.dart
│   ├── expense_controller.dart
│   ├── expense_form_controller.dart
│   ├── main_navigation_controller.dart
│   ├── onboarding_controller.dart
│   └── settings_controller.dart
├── models/
│   ├── category.dart
│   └── expense.dart
├── routes/
│   ├── app_pages.dart
│   └── app_routes.dart
├── services/
│   └── hive_service.dart
├── utils/
│   ├── category_icon_mapper.dart
│   ├── currency_formatter.dart
│   └── date_formatter.dart
├── views/
│   ├── expense_form_view.dart
│   ├── categories_view.dart
│   ├── dashboard_view.dart
│   ├── expense_details_view.dart
│   ├── home_view.dart
│   ├── main_navigation_view.dart
│   ├── settings_view.dart
│   └── welcome_view.dart
├── widgets/
│   ├── category_form_dialog.dart
│   ├── category_icon.dart
│   ├── category_reassignment_dialog.dart
│   ├── expense_card.dart
│   ├── expense_filter_dialog.dart
│   ├── expense_group_header.dart
│   ├── expense_amount_field.dart
│   ├── expense_category_selector.dart
│   ├── expense_date_selector.dart
│   ├── expense_form_actions.dart
│   └── expense_note_field.dart
└── main.dart
```

The names and class names are proposals. Implement only files needed for the planned features, and keep each file limited to its responsibility.

## 3. Folder and layer responsibilities

| Folder or file | Planned responsibility |
| --- | --- |
| `models/` | Plain application data structures and Hive model definitions. `Expense` and `Category` will have Hive adapters; generated adapter code will be produced by the configured Hive generator tooling. Models do not contain screen widgets or database orchestration. |
| `controllers/` | GetX controllers for application state and product rules. Controllers expose reactive state, validate operations, coordinate services, and provide derived values to views. `OnboardingController` persists completion of the first-launch Welcome flow. Controllers do not build widget trees or perform direct box access. |
| `views/` | Complete screens: Welcome, the main navigation shell, Home / Expenses, Dashboard, Categories, Settings, Add Expense, Edit Expense, and Expense Details. Views render controller state, collect input, and call controller methods. |
| `widgets/` | Reusable presentation components used by views, including expense cards, group headers, category icons, filter UI, and category dialogs. Expense deletion confirmation is presented from Details; do not add a separate action-menu flow. Widgets should not own persistence or duplicate business rules. |
| `services/` | Technical operations. `HiveService` initializes Hive, opens typed boxes, and provides explicit local read/write methods for expenses, categories, settings, and the onboarding flag. It does not decide which screen is selected or render UI. |
| `bindings/` | GetX dependency registration. The app binding registers initialized app-wide dependencies with `Get.put`; route bindings register screen-scoped controllers with `Get.lazyPut`. |
| `routes/` | Route-name constants and the `GetPage` route table, including each route's view and binding. |
| `utils/` | Small, stateless helpers for formatting and mapping stable category icon keys to Flutter icons. Keep business decisions in controllers. Avoid using this folder as a general dumping ground. |
| `main.dart` | Application entry point. It initializes Flutter and Hive, loads settings needed for the first frame, registers global dependencies, and starts `GetMaterialApp`. It should not contain feature screens or expense business logic. |

### How the layers communicate

```text
View -> GetX controller -> HiveService -> Hive
  ^              |
  +-- Obx / GetBuilder observes controller state
```

Views do not read Hive directly. Controllers do not contain widget layout. `HiveService` handles persistence but does not make product decisions. Bindings connect controllers to their required services. This separation keeps UI changes, business rules, and storage changes understandable and independently testable.

## 4. Planned models and persistence boundary

The Expense and Category Hive schemas below are approved by ADR-014. Once data is persisted, type IDs and field indexes become part of the local storage format and must not be changed or reused casually.

| Model | Approved Hive type ID | Approved Hive fields (`@HiveField` index) |
| --- | ---: | --- |
| `Expense` | `0` | `id` (0, UUID string), `amount` (1, `double`), `categoryId` (2, UUID string), `date` (3, `DateTime`), `note` (4, nullable `String`) |
| `Category` | `1` | `id` (0, stable built-in ID or custom UUID string), `name` (1, `String`), `iconKey` (2, stable `String`), `isDefault` (3, `bool`) |

`uuid` creates each Expense and custom Category ID once. The four built-in Category IDs are the stable lowercase identifiers approved by ADR-015. Each ID is stored in the model and used as the Hive box key. Editing an expense updates the value under the same ID; it must not create a replacement ID. Expenses refer to categories by `categoryId`, never by category name. Category rename is not in the approved product scope; if later approved, change only the name and preserve the category ID so existing references remain valid.

**Approved box names:** open `expenses` as `Box<Expense>` and `categories` as `Box<Category>`. No settings box name or settings keys have been approved; do not infer or add them as part of this persistence milestone.

`hive_generator` generates `ExpenseAdapter` and `CategoryAdapter` from `@HiveType` / `@HiveField` annotations. `HiveService.initialize()` initializes the Hive Flutter path, registers both generated adapters exactly once, and opens the typed `expenses` and `categories` boxes. It seeds missing built-in categories by their stable IDs without overwriting existing category records. Do not open a settings box until its name and keys are approved. `hive_generator` 2.0.1 validates field indexes as unique values from 0 through 255. Hive 2.2.3's registered built-in adapters use type IDs 16–18. Do not access boxes directly from Views or controllers.

The initial category persistence implementation seeds only missing built-in IDs and preserves all existing category records; it does not migrate or rewrite existing expense references. Before a future persisted schema change, retain type IDs and existing field indexes; add new fields at unused indexes and assess read defaults or a migration only if the actual change requires one.

`HiveService` ensures the four required built-in categories (Food, Transport, Bills, Shopping) are present when local category data is initialized. Their stable IDs are `food`, `transport`, `bills`, and `shopping`, matching ADR-015 and existing expense references. `CategoryController` protects these built-ins from deletion. `uuid` generates unique identifiers for newly created expense and custom category records.

## 5. Controllers and state ownership

- **`ExpenseController`**: Owns the reactive expense collection, initial-load status, expense CRUD, date-descending history, applied category/date filters, and monthly expense calculations. Keep aggregation functions straightforward and unit-testable, as required by ADR-001. Store only persisted records through `HiveService`. An update changes the existing expense under its original UUID; it never replaces the ID.
- **`CategoryController` (implemented)**: Owns the reactive category collection, initial-load status, default-category protection, custom-category validation (case-insensitive uniqueness and 30-character limit), creation, and deletion/reassignment rules. Category editing remains deferred. It coordinates category reassignment with `ExpenseController`; it does not edit expense records directly.
- **`SettingsController`**: App-wide controller and single source of app preference state. It owns reactive `Rx<ThemeMode>` and currency-symbol values, loads/saves them through `HiveService`, and never converts expense amounts.
- **`OnboardingController`**: Route-scoped controller used by Welcome. It persists the onboarding-completed flag through the already initialized `HiveService` after Get Started; it does not own another copy of persisted state.
- **`ExpenseFormController` (implemented)**: Owns temporary Add/Edit values and reactive loading, saving, not-found, error, and field-validation state. Edit mode loads through `ExpenseController`, distinguishes a missing expense from a load failure, and can retry. It validates a positive finite amount, a selected category, and the 200-character note limit, then delegates persistence to `ExpenseController` while preserving the original ID. `submit` reports success, failure, or `confirmationRequired`; for a future date the UI presents the ADR-007 dialog and retries with explicit confirmation. The controller does not show dialogs or access Hive.
- **`MainNavigationController`**: Holds the selected bottom-navigation destination for the main shell. This is local UI state, not persisted product data.

### GetX state approach

- Use `.obs` for shared application state such as expenses, categories, filters, theme, and currency. Views that render these values use small `Obx` regions so only dependent UI rebuilds.
- Use `GetBuilder` for isolated, form- or screen-local state that does not need to be shared, such as a form's saving/validation presentation, draft filter selections, or the selected main-shell tab, following ADR-004.
- Do not wrap a whole screen in `Obx` when only a small portion needs to react.
- `GetMaterialApp` defines both `theme` and `darkTheme`; its initial `themeMode` is read from the already-loaded `SettingsController`. On a user change, `SettingsController` owns the `Rx<ThemeMode>`, persists the selected value through `HiveService`, and calls `Get.changeThemeMode(mode)` to apply it immediately. Do not add a second reactive theme state or rebuild the app root with another theme owner. The failure behavior and serialized representation of the saved mode remain **OPEN — NEEDS APPROVAL**; do not imply that a preference change succeeded when persistence fails.
- `CurrencyFormatter` is stateless: it accepts the amount and selected currency symbol as arguments and formats those values. It does not read a controller, call `Get.find`, or access application state.
- Controllers report operation results explicitly. The Add/Edit form uses a Material `ScaffoldMessenger` snackbar after a successful write and an inline error message after a failed write; it does not show success or navigate away on failure. Confirmation/reassignment flows use dialogs where appropriate.

### Category reassignment coordination

When a custom category has linked expenses, the category controller requires a valid destination and delegates matching expense updates to `ExpenseController.reassignExpenses(sourceCategoryId, destinationCategoryId)`. `ExpenseController` persists each updated category ID through `HiveService` and updates its reactive collection only after that write succeeds. The source category is deleted only after all reassignment writes succeed. If reassignment fails partway through, or category deletion fails afterward, retain the source category and surface the error; partially reassigned expenses still reference an existing category, so no expense is orphaned. `HiveService.deleteCategory` also rejects deletion while any stored expense still references that category. This does not roll back already-written expense updates, and retry/resume behavior is **OPEN — NEEDS APPROVAL**. For a custom category with no linked expenses, the caller still obtains the simple confirmation required by ADR-006 before deletion.

## 6. Route and binding plan

`app_routes.dart` will define route-name constants. `app_pages.dart` will define named `GetPage` entries with the matching view and binding.

**Current implementation status:** The temporary `/home` route uses `ExpenseBinding` and `CategoryBinding`, both of which resolve the single app-wide `HiveService` registered by `AppBinding`. The `/expense/add` and `/expense/edit` routes use a shared `ExpenseFormView` and `ExpenseFormBinding`. Each form route lazily creates a fresh `ExpenseFormController` with create mode or the edit ID from route arguments. The `/main` shell and Details route remain planned.

| Planned route | View | Binding / behavior |
| --- | --- | --- |
| `/welcome` | `WelcomeView` | `OnboardingBinding` lazily registers `OnboardingController`. Get Started persists completion before navigating to the main shell. This route is selected only when the Hive onboarding flag is incomplete. |
| `/main` | `MainNavigationView` | `MainBinding` lazily registers the navigation, expense, and category controllers. The shell contains the four bottom-navigation destinations: `HomeView`, `DashboardView`, `CategoriesView`, and `SettingsView`. |
| `/expense/details` | `ExpenseDetailsView` | Receives an expense ID as route arguments and uses the existing MainBinding-owned `ExpenseController` (for example, through `GetView<ExpenseController>`). It does not register a duplicate controller. Missing records render the explicit not-found state. |
| `/expense/add` | `ExpenseFormView` | `ExpenseFormBinding` creates a fresh `ExpenseFormController` in create mode with empty inputs and the PRD default date. |
| `/expense/edit` | `ExpenseFormView` | `ExpenseFormBinding` creates a fresh `ExpenseFormController` in edit mode with the selected expense ID passed as a string route argument. The controller loads that expense from `ExpenseController`. |

The bottom-navigation destinations are child views of the main shell rather than four independent full-screen routes. This keeps the navigation bar in one place and allows the selected tab state to be retained. Expense Details and Add/Edit Expense are named routes without the main tab bar. Tapping a Home expense opens Details; Edit opens the existing prefilled form, and Delete uses a confirmation dialog before permanently deleting the expense. Filter, category creation, deletion confirmation, and category reassignment are transient dialogs/sheets, not persistent top-level routes. Do not implement the prototype's expense action dialog as the target Home interaction.

### Dependency injection lifecycle

1. `main.dart` initializes Hive and loads saved settings before starting the first screen.
2. `AppBinding` registers those same initialized/preloaded instances of `HiveService` and `SettingsController` exactly once with `Get.put`, consistent with ADR-003. It does not initialize Hive, reload settings, or construct duplicates.
3. `OnboardingBinding` uses `Get.lazyPut` for `OnboardingController`, supplying the same registered `HiveService`. It is created only when the Welcome route is opened.
4. `MainBinding` uses `Get.lazyPut` for `ExpenseController`, `CategoryController`, and `MainNavigationController`. It supplies `HiveService` to the expense controller and both `HiveService` and `ExpenseController` to the category controller. Push Details over the still-active `/main` route so it can resolve that same `ExpenseController`; do not register a duplicate controller.
5. `ExpenseFormBinding` uses non-permanent `Get.lazyPut` for a new `ExpenseFormController` on each Add or Edit route entry, supplying the already registered `ExpenseController` through `Get.find`. Do not set `fenix: true` for this temporary controller. The view gets its controller from the binding; views do not construct storage services.

`Get.find` should be used in bindings to resolve dependencies, not scattered throughout business logic. Constructor parameters make each controller's required services/controllers explicit.

### Expense form initialization and disposal

- On `/expense/add`, the binding passes create mode. The controller starts with no amount, category, or note and uses today's date, then owns only the transient values for that form operation.
- On `/expense/edit`, the binding passes edit mode and the expense ID. The controller loads the matching record through `ExpenseController` and populates the fields. If the ID is invalid or the record is unavailable, show an explicit failure instead of silently displaying an empty Add form.
- Add and Edit route entries each receive a fresh, route-scoped controller. Do not reuse a permanent controller or persist unfinished form values. `ExpenseFormView` owns and disposes its amount/note `TextEditingController`s and GetX workers; the controller owns only reactive form values. When the route is removed, GetX disposes the route-scoped controller. Opening a later form operation must start with its own clean Add state or data loaded for its own Edit ID.
- `ExpenseCategorySelector` still presents only the four PRD-approved built-in choices using the stable lowercase IDs in ADR-015. The category data layer now persists those IDs and custom categories, but the form selector is not yet integrated with `CategoryController`.

## 7. Application data flows

### A. Startup

```text
main.dart
  -> HiveService.initialize() once
       -> Hive.initFlutter() initializes the Flutter binding and Hive path
       -> Hive.registerAdapter(ExpenseAdapter())
       -> Hive.registerAdapter(CategoryAdapter())
       -> open Box<Expense>("expenses")
       -> open Box<Category>("categories") and seed missing built-in IDs
       -> defer settings storage until its box name and keys are approved
  -> construct SettingsController with that HiveService and load saved theme/currency
  -> read onboardingCompleted from the same Hive settings storage
  -> runApp(GetMaterialApp(
       initialBinding: AppBinding(the same HiveService, the same loaded SettingsController),
       initialRoute: onboardingCompleted ? Routes.main : Routes.welcome,
       theme: lightTheme,
       darkTheme: darkTheme,
       themeMode: loaded SettingsController.themeMode.value,
     ))
  -> AppBinding registers each supplied global instance once with Get.put
  -> GetPage selects a route and runs its binding
  -> binding registers route controllers with Get.lazyPut
  -> view renders
```

Do not initialize Hive again in `AppBinding`, register the same global a second time, or reload the preferences there. At runtime, `SettingsController` updates its owned `Rx<ThemeMode>`, persists the selected mode through the same `HiveService`, and calls `Get.changeThemeMode(mode)`. The GetMaterialApp configuration uses the saved mode for its initial theme; no extra root-level reactive theme owner is introduced. Hive initialization and category seeding happen once before `runApp`; `AppBinding` only registers the supplied instances.

On the first launch, the initial route is Welcome. `OnboardingController` writes the completion flag through the registered `HiveService` before navigating to `/main`. On later launches, `main.dart` selects `/main` directly.

### B. Adding an expense

```text
ExpenseFormView (create mode)
  -> ExpenseFormController validates amount, category, date, and note
  -> ExpenseController.addExpense(...)
  -> HiveService writes Expense to Hive
  -> ExpenseController updates its reactive collection
  -> Obx rebuilds affected Home and Dashboard regions
  -> show the success snackbar and return to Home only after persistence succeeds
```

The form controller owns temporary input state. The expense controller enforces expense rules and updates application state. The service performs the Hive write. Future-date confirmation happens before committing a future-dated expense (FR-05 / ADR-007). If persistence fails, the form remains open with its values intact, displays an error, and allows retry; it does not show success or navigate away (FR-35 / ADR-012).

### C. Displaying expenses

```text
Hive expense box
  -> HiveService reads Expense records
  -> ExpenseController loads and sorts by date descending
  -> controller applies any active category/date filters
  -> Obx renders Home list and empty states
```

The first-time empty state and filtered-empty state are distinct product states (FR-12 / FR-13). They are rendered by the view based on controller state; they are not synthetic expense records.

The task PDF also asks for loading states. Controllers expose initial-load status so views can distinguish loading from an empty collection. The exact loading appearance is not specified by the source documents and should follow the approved visual language without obscuring empty-state messaging.

### D. Dependency injection

```text
main.dart initializes Hive
  -> AppBinding: Get.put(HiveService, SettingsController)
  -> /welcome GetPage when onboarding is incomplete:
       OnboardingBinding uses Get.lazyPut(OnboardingController)
  -> /main GetPage: MainBinding uses Get.lazyPut(...)
       -> ExpenseController(HiveService)
       -> CategoryController(HiveService)
       -> MainNavigationController()
  -> /expense/add or /expense/edit GetPage:
       ExpenseFormBinding uses Get.lazyPut(ExpenseFormController)
  -> /expense/details GetPage:
       ExpenseDetailsView uses the retained MainBinding-owned ExpenseController
```

Services and shared settings live for the app session. Feature controllers are registered by route bindings and follow GetX route lifecycle rules. A controller obtains dependencies from constructor arguments supplied by its binding, not by opening Hive itself.

### E. Dashboard calculations

```text
ExpenseController reactive expenses
  -> select records whose date is in the current calendar month
  -> calculate monthly total
  -> group amounts by categoryId
  -> combine category names/icons from CategoryController
  -> DashboardView renders total, fl_chart pie chart, and category breakdown
```

Monthly totals and category distribution are derived from locally stored expenses in Dart, in line with ADR-001. `fl_chart` displays the result; it is not the source of the data. Empty current-month data must render the PRD-required empty state instead of an empty/blank chart. Reactive expense changes refresh the derived values (FR-14 through FR-17).

### F. Viewing, editing, and deleting an expense

```text
Home expense tap
  -> /expense/details with expense ID
  -> ExpenseDetailsView reads the record from ExpenseController
       -> if missing: show not-found state and Home action
       -> if Hive lookup fails: show an error distinct from not-found and allow retry
       -> Edit: open /expense/edit with ID; form is prefilled
       -> Delete: confirm permanent deletion -> ExpenseController.deleteExpense(...)
            -> HiveService deletes record permanently
            -> only on successful write: ExpenseController updates reactive expenses
            -> Home and Dashboard update
            -> show success and return Home
```

If a Hive lookup fails, show an explicit error distinct from the not-found state and allow retry. If a create, edit, or delete write fails, preserve the current form or Details screen and its data, show an error, and allow retry. Do not report success or navigate away as though the write succeeded (FR-34–FR-35 / ADR-012). Successful edit follows the existing PRD form flow back to Home.

### G. First-launch onboarding

```text
main.dart reads onboardingCompleted from Hive before runApp
  -> false: /welcome -> OnboardingController persists true -> /main
  -> true: /main directly
```

The flag is stored with existing settings through `HiveService`; no separate model, box, service, or backend is planned (FR-32 / ADR-010). **Failure behavior is pending approval:** the recommended behavior is to remain on Welcome, keep the flag incomplete, show a clear error, and allow retry if Hive cannot save the flag. Do not navigate to `/main` or report onboarding complete unless the write succeeds.

## 8. Planned screen responsibilities

| Screen / shell | Main responsibility |
| --- | --- |
| `WelcomeView` | Present the approved welcome design on first launch and invoke onboarding completion. Do not add a sign-in or account flow. |
| `MainNavigationView` | Host the four main destinations and bottom navigation. |
| `HomeView` | Render date-grouped expenses, totals, add action, filters, and first-time/filtered empty states. |
| `DashboardView` | Render the current-month total, category pie chart, category breakdown, and empty-month state. |
| `CategoriesView` | Show protected defaults and custom categories; launch create/delete/reassignment UI. |
| `SettingsView` | Change and persist theme and display currency symbol. |
| `ExpenseFormView` | Shared Add/Edit screen; renders reusable amount, category, date, note, and action widgets. Delegates validation and writes to `ExpenseFormController`, handles ADR-007 confirmation, and returns to Home with success feedback only after a successful write. |
| `ExpenseDetailsView` | Show the selected expense and Edit/Delete actions; report a missing record explicitly. |

The interactions, labels, and visual direction are defined in DESIGN.md; the exact widget composition is implementation work and must remain usable from 320px to 430px (NFR-03).

## 9. Formatting and currency rules

- Use `intl` for user-facing date and currency formatting. A stateless `CurrencyFormatter` accepts the amount and selected currency symbol as arguments and formats them without conversion (FR-25 / FR-26, ADR-005). The caller supplies the current symbol; the formatter never reads controller or application state.
- Use a shared `DateFormatter` for date group headings and form dates, with “Today”, “Yesterday”, and a readable date for other days as required by FR-08.
- Use `category_icon_mapper.dart` to map a persisted icon key to a Flutter icon. Keep the mapping centralized so persisted category data remains independent of widget implementation.
- Keep date/month boundary logic consistent: Home grouping uses local calendar dates, and the dashboard uses the current calendar month. Exact timezone policy is not specified in the source documents and should not be expanded into a product requirement.

## 10. Coding and quality conventions

- Use meaningful, consistent Dart filenames and class names: `expense_controller.dart` / `ExpenseController`, `home_view.dart` / `HomeView`, and so on.
- Keep methods small and make each method responsible for one clear operation.
- Reuse widgets when a component appears in multiple screens; do not duplicate business logic to avoid a small widget.
- Keep presentation, business rules, and persistence in their assigned layers.
- Add brief comments only to explain non-obvious intent or constraints. Do not repeat what the code already says.
- Prefer straightforward GetX/Hive patterns over unnecessary abstractions or complicated generic frameworks.
- Surface storage and validation failures clearly. Do not report a successful save, deletion, or preference change if persistence failed.
- Design controllers and pure calculation methods so the PRD-required `ExpenseController` CRUD and settings-persistence tests can be written. No tests are created by this architecture document.

## 11. Project source and challenge alignment

### Correct project scope and source authority

This project is exclusively the **Violet Expense Tracker — Offline Personal Expense Tracking Mobile Application**. The approved PRD is the primary product contract. Only the challenge PDF sections explicitly labelled **Personal Expense Tracker** are applicable; they request Flutter/Dart, GetX controllers/reactivity, GetX named routing and bindings, GetX helpers where useful, a clean models/controllers/views/widgets/services/bindings/routes structure, local storage, form validation, empty/loading states, responsive Android/iOS UI, readable code, Git history, README screenshots, a working APK (and an iOS build if possible), and a short demo. The PRD and accepted ADRs refine the product scope and select Hive. The configured `pubspec.yaml` already lists GetX, Hive, `fl_chart`, `intl`, `uuid`, and Hive code-generation tooling; this task does not change dependencies.

The same PDF also contains a separate **QR Menu Admin** assignment (including PHP/MySQL, menu categories/items, users, and menu synchronization). That is historical source-document context only, not a requirement for this project. QR menu, restaurant administration, customer-facing menus, QR generation/scanning, PHP/MySQL, and menu synchronization are all excluded. The Expense Tracker remains offline with no backend or login.

### Optional challenge bonuses

The challenge PDF lists CSV/PDF export, monthly budgets, local notifications, and English/Arabic support as optional bonuses. The approved PRD §9 explicitly excludes each from the MVP. They are not planned for this architecture and require explicit approval before being considered later.

### Expense Tracker challenge alignment

For expense data, the challenge permits Hive or SQLite (`sqflite`) and mentions `get_storage` for settings; ADR-001 selects Hive for local persistence. The challenge lists both Android and iOS compatibility, while the PRD says only Android will be tested on-device during the internship. This plan does not claim either platform has been validated.

### Conflicts, gaps, and follow-up

- **Timeline mismatch in the PDF:** Project Info says two weeks / 10 working days, while the suggested schedule includes work through Day 14. The architecture does not resolve this planning contradiction; confirm the expected schedule with the internship owner.
- **Storage options:** The PDF offers Hive or SQLite (`sqflite`) for local data and mentions `get_storage` for settings. ADR-001 selects Hive, so the plan uses Hive and introduces no alternative storage package.
- **CI scope:** PRD NFR-07 calls for CI on pushes to `develop`; ADR-009 describes pushes and pull requests for both `main` and `develop`. The accepted ADR's broader coverage includes the PRD's `develop` push requirement; the architecture does not change either document.
- **Expense Details visuals:** The approved PRD/ADRs require a Details screen and explicit missing-record/persistence-failure behavior, but the inspected Figma preview did not include that screen or those error states. Implement the specified behavior using the established visual language; exact copy and styling remain unverified and are not requirements.
- **POC evidence:** `docs/POC.md` records that no runtime POC results are available; the package/API snapshot is not a runtime test.
- **MCP evidence:** `docs/MCP.md` records the configured HTTP endpoint and clearly states that authentication, project access, and Resources support have not been verified in this record.
- **QA plan:** `docs/QA.md` contains planned, PRD-traceable checks only. It does not claim that tests or platform validation were performed.
- **README:** The README identifies the Expense Tracker and accurately states that the implementation is still the Flutter starter. Setup commands are provided; product screenshots, a working APK, demo, and verified results remain delivery work.
- **Other named documents:** `MVP.md` and `REVIEW.md` are absent. PRD §9 already defines MVP scope, so a separate MVP document is not required for this plan; a review report is not appropriate before implementation.

## 12. Package and API verification snapshot

Versions below were checked against `pubspec.yaml`, the resolved `pubspec.lock`, the installed SDK, and the locally resolved package sources on 2026-11-15. This table records the current environment; it does not change or pin dependencies.

| Component | Declared constraint | Resolved / installed version |
| --- | --- | --- |
| Flutter | SDK dependency | Flutter 3.41.5 stable; lockfile requires `>=3.38.4` |
| Dart | `^3.11.3` | Dart 3.11.3 stable; lockfile requires `>=3.11.3 <4.0.0` |
| `cupertino_icons` | `^1.0.8` | 1.0.9 |
| GetX (`get`) | `^4.6.6` | 4.7.3 |
| Hive (`hive`) | `^2.2.3` | 2.2.3 |
| Hive Flutter (`hive_flutter`) | `^1.1.0` | 1.1.0 |
| Hive generator | `^2.0.1` | 2.0.1 |
| `build_runner` | `^2.4.8` | 2.4.13 |
| `fl_chart` | `^0.66.0` | 0.66.2 |
| `intl` | `^0.19.0` | 0.19.0 |
| `uuid` | `^4.3.3` | 4.6.0 |
| `flutter_lints` | `^6.0.0` | 6.0.0 |

The locked SDK constraints include the installed Flutter/Dart versions. The resolved GetX 4.7.3 source provides `GetMaterialApp`, `GetPage`, `Get.lazyPut`, and `Get.changeThemeMode`; Hive 2.2.3 and Hive Flutter 1.1.0 provide adapter registration, box-opening, and `Hive.initFlutter` APIs; `hive_generator` provides `@HiveType` / `@HiveField` adapter generation; `uuid` 4.6.0 provides `Uuid.v4`; `fl_chart` 0.66.2 provides `PieChart`; and `intl` 0.19.0 provides `NumberFormat.currency`. This verifies the planned API surface and package resolution; execution evidence is recorded in `docs/QA.md`.

## 13. Open decisions — OPEN — NEEDS APPROVAL

1. **Settings storage identifiers:** Approve a settings box name and its keys before implementing settings persistence. No settings box name or keys are approved in Section 4.
2. **Onboarding write failure:** Choose the behavior if Hive cannot persist the completion flag. The recommended option is to remain on Welcome, keep completion false, show an error, and allow retry. Until approved, this is not accepted product behavior. If the choice changes the user-visible contract, update PRD §5.7 FR-32, §7 Flow 7, and §12 RD-04, plus ADR-010.
3. **Partial category reassignment failure:** Choose whether recovery is retry/resume, rollback, or another explicit policy. The current plan retains the source category but can leave expenses split across source and destination.
4. **Settings persistence failure and encoding:** Define behavior if saving theme/currency fails and the stable representation of `ThemeMode` in Hive. Do not add a second theme state.

This remains the target architecture for features not yet implemented. Implemented foundations include the Expense and Category models and generated adapters, expense and category persistence with default seeding, `ExpenseController`, `CategoryController`, their bindings, `ExpenseFormController`, `ExpenseFormBinding`, and the shared Add/Edit `ExpenseFormView` with reusable field/action widgets. Category management UI, Home history, Expense Details, the main navigation shell, dashboard, settings, onboarding, and the remaining product screens are not implemented.
