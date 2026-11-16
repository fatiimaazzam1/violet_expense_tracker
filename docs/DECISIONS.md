# Architecture Decision Records — Violet Expense Tracker

**Format:** Based on Michael Nygard's ADR standard.
**Purpose:** Records every significant technical decision, the context that forced it, and the trade-offs accepted. This is the "why" behind the code.

| ADR | Title | Status | Date |
| :--- | :--- | :--- | :--- |
| ADR-001 | Use Hive for local storage instead of SQLite | Accepted | 2026-11-10 |
| ADR-002 | Use GetX for state management, routing, and DI | Accepted | 2026-11-10 |
| ADR-003 | Use `Get.lazyPut` in Bindings, `Get.put` for globals | Accepted | 2026-11-10 |
| ADR-004 | Use reactive `Obx` for core data, `GetBuilder` for local UI state | Accepted | 2026-11-10 |
| ADR-005 | Currency selection changes display symbol only (no conversion) | Accepted | 2026-11-10 |
| ADR-006 | Block deletion of categories that have expenses | Accepted | 2026-11-10 |
| ADR-007 | Allow future-dated expenses with a confirmation warning | Accepted | 2026-11-10 |
| ADR-008 | Enforce LF line endings via `.gitattributes` | Accepted | 2026-11-10 |
| ADR-009 | Run `flutter analyze` + `flutter test` on every push via GitHub Actions | Accepted | 2026-11-10 |
| ADR-010 | Show Welcome only on first launch using a Hive completion flag | Accepted | 2026-11-15 |
| ADR-011 | Open Expense Details before edit or delete actions | Accepted | 2026-11-15 |
| ADR-012 | Handle missing expenses and persistence failures explicitly | Accepted | 2026-11-15 |
| ADR-013 | Persist and apply the selected `ThemeMode` through GetX | Accepted | 2026-11-16 |

---

## ADR-001: Use Hive for Local Storage Instead of SQLite

**Status:** Accepted
**Context:** The PDF allows Hive, SQLite (`sqflite`), or `get_storage`. The app stores expenses and settings locally. The data model has a simple one-to-many relationship (Expense → Category).
**Decision:** Use **Hive** (`hive` + `hive_flutter`) with generated `TypeAdapter`s.
**Rationale:**
1. **Speed of development:** Hive requires no SQL schema, no migrations, and no query strings. A `Box<Expense>` is enough for CRUD.
2. **Performance:** Hive reads/writes Dart objects in binary form directly, without JSON serialization overhead.
3. **Offline-first fit:** Hive is pure Dart, no native dependencies beyond `path_provider`. It works on Android, iOS, and even desktop.
4. **Simplicity of relationship:** For a single one-to-many link (Expense → Category), storing a `categoryId` string on the Expense is sufficient. SQL joins are unnecessary.
**Consequences:**
- **Positive:** Less boilerplate, faster startup, simpler tests.
- **Negative:** No built-in aggregation queries. Monthly totals and pie-chart sums will be computed in Dart inside the controller. For a personal tracker (thousands of records at most), this is fast enough. If the dataset grew to millions of rows, SQLite would be the correct choice.
- **Mitigation:** Keep aggregations in `ExpenseController` as pure functions so they can be unit-tested and, if needed later, replaced with SQLite without touching the UI.

---

## ADR-002: Use GetX for State Management, Routing, and DI

**Status:** Accepted
**Context:** The internship PDF explicitly requires GetX. The project needs state management, navigation, and dependency injection.
**Decision:** Use GetX (`get` package) for all three concerns.
**Rationale:**
1. **Mandatory requirement:** The PDF states "State Management: GetX (required)."
2. **One package, three problems:** GetX combines reactive state, named routing, and DI. Using it for all three avoids introducing Riverpod + GoRouter + GetIt, which would violate the "avoid unnecessary packages" rule.
3. **Minimal boilerplate:** A controller is a plain Dart class extending `GetxController`. Observables are created with `.obs`. The learning curve is shallow, which suits a 2-week internship.
**Consequences:**
- **Positive:** Clean separation of UI, logic, and navigation. Easy to test controllers in isolation.
- **Negative:** GetX is sometimes criticized for "magic" (global `Get.find`). **Mitigation:** Always use Bindings with `Get.lazyPut` (see ADR-003) so dependencies are explicit and scoped, rather than relying on global singletons.

---

## ADR-003: Use `Get.lazyPut` in Bindings, `Get.put` for Globals

**Status:** Accepted
**Context:** GetX offers `Get.put` (eager) and `Get.lazyPut` (lazy) for registering controllers.
**Decision:**
- Use **`Get.lazyPut`** inside all route `Bindings`. The controller is instantiated only when its route is opened.
- Use **`Get.put`** only for app-wide dependencies (e.g., `SettingsController`, `HiveService`) registered once at startup.
**Rationale:**
1. **Memory efficiency:** `lazyPut` avoids creating controllers for screens the user never opens.
2. **Correct DI lifecycle:** Bindings run *before* the view is built, so the controller is ready when the view calls `Get.find()`. This is the intended GetX pattern.
3. **Predictability:** `Get.put` for globals ensures the theme and currency are available on every screen from the first frame.
**Consequences:**
- **Positive:** Minimal memory footprint. Clear separation between "app-wide" and "screen-scoped" dependencies.
- **Negative:** If a controller is disposed when its route closes, state is lost. **Mitigation:** For bottom-navigation tabs that must retain state, use `Get.lazyPut(..., fenix: true)` or hold the controller with `Get.put` in the parent widget.

---

## ADR-004: Use Reactive `Obx` for Core Data, `GetBuilder` for Local UI State

**Status:** Accepted
**Context:** The PDF requires both `Obx` and `GetBuilder`. Using only one would fail the technical requirement. Using both arbitrarily would be poor engineering.
**Decision:**
- **`Obx` + `.obs`** for data that drives the main UI: the expense list, the monthly total, the selected theme, the currency symbol.
- **`GetBuilder` + `update()`** for isolated, form-local state: the "is saving" flag on the Save button, the "is form valid" flag, filter-sheet selections.
**Rationale:**
1. **Performance:** `Obx` rebuilds only the widget subtree that reads the observable. For the main data, this is exactly what we want. For a single button's loading spinner, `GetBuilder` gives tighter control and avoids accidental rebuilds elsewhere.
2. **Requirement coverage:** Using both proves to the evaluator that the intern understands the two GetX paradigms and can justify the choice.
3. **Testability:** `Obx` state is easy to unit-test by reading `.value`. `GetBuilder` state is easy to test by calling the method and checking the getter.
**Consequences:**
- **Positive:** Clear mental model: "shared data → Obx; screen-local data → GetBuilder."
- **Negative:** Two paradigms to document. **Mitigation:** This ADR *is* the documentation.

---

## ADR-005: Currency Selection Changes Display Symbol Only (No Conversion)

**Status:** Accepted
**Context:** The PDF requires "currency selection." It is ambiguous whether this means converting amounts or just changing the symbol.
**Decision:** Changing the currency updates only the **display symbol** used by `NumberFormat.currency`. Amounts are stored as raw `double` values and are never recalculated.
**Rationale:**
1. **Offline-first constraint:** Live exchange rates require network calls, violating FR-31 (no network required for core features).
2. **Target-user reality:** A personal tracker user who changes currency usually wants to see their spending in a different symbol, not perform FX accounting.
3. **PDF wording:** The PDF says "currency selection," not "multi-currency accounting."
**Consequences:**
- **Positive:** Zero network complexity. Settings screen is simple.
- **Negative:** A user who genuinely moves between currencies will see mixed-meaning totals. **Mitigation:** Document this limitation in README "Known Limitations." A future v2 could add a `currencyCode` field per expense and an `exchangeRate` table, but that is out of MVP scope.
- **Product traceability:** PRD §12, RD-01.

---

## ADR-006: Block Deletion of Categories That Have Expenses

**Status:** Accepted
**Context:** Deleting a custom category that is referenced by existing expenses could orphan those expenses or silently delete them.
**Decision:** When the user attempts to delete a custom category that has at least one expense, **block the deletion** and show a dialog guiding them to reassign the expenses to another category first. If the category has zero expenses, allow deletion after a simple confirmation.
**Rationale:**
1. **Industry best practice:** Actual Budget forces reassignment; Grassfeld archives rather than deletes. Silent cascade-delete is universally considered data loss.
2. **Data integrity:** Orphaned `categoryId` references would break the pie chart and filters.
3. **User trust:** A confirmation dialog that explains *why* the delete is blocked is better UX than a cryptic error.
**Consequences:**
- **Positive:** No orphaned data. Category list stays clean.
- **Negative:** One extra dialog for the user. **Mitigation:** Make the dialog helpful—show the count of affected expenses and a dropdown of valid target categories.
- **Product traceability:** PRD §12, RD-02; FR-21 upgraded to Must.

---

## ADR-007: Allow Future-Dated Expenses With a Confirmation Warning

**Status:** Accepted
**Context:** Users may want to pre-record upcoming bills, but typos (e.g., year 2099) can corrupt reports.
**Decision:** The date picker allows any date. If the chosen date is **after today**, show a confirmation dialog before saving: *"This date is in the future. Save anyway?"*
**Rationale:**
1. **Balance:** Outright blocking frustrates legitimate use (pre-recording rent). Silent acceptance allows data errors. A warning is the compromise.
2. **Precedent:** PocketSmith added a future-date warning for the same reason. Peer-reviewed engineering sources flag silent future dates as a data-integrity risk.
3. **MVP scope:** No extra field is needed in the data model—the date itself carries the information.
**Consequences:**
- **Positive:** Flexible, safe.
- **Negative:** Slightly more friction for the rare legitimate future expense. **Mitigation:** The dialog is one tap to confirm.
- **Product traceability:** PRD §12, RD-03; FR-05 refined.

---

## ADR-008: Enforce LF Line Endings via `.gitattributes`

**Status:** Accepted
**Context:** Development happens on Windows (CRLF), but CI runs on Linux (LF). `dart format --set-exit-if-changed` failed on the first CI run because of this mismatch.
**Decision:** Use `.gitattributes` to normalize text files to LF. The current rule `* text=auto eol=lf` applies to text files generally; explicit `.dart`, `.yaml`, and `.yml` rules are also present. The one-time repository normalization was historical and is not an instruction to rerun it.
**Rationale:**
1. **Reproducibility:** The same file must produce the same formatting on Windows and Linux.
2. **CI stability:** Prevents "formatting failed" false positives.
3. **Team readiness:** If another developer joins on macOS, they get identical behavior.
**Consequences:**
- **Positive:** CI formatting step is now deterministic.
- **Negative:** One-time re-normalization commit showed as 4,563 line changes. **Mitigation:** Already applied; future commits are unaffected.

---

## ADR-009: Run `flutter analyze` + `flutter test` on Every Push

**Status:** Accepted
**Context:** Manual local checks are error-prone and not auditable.
**Decision:** Use GitHub Actions (`.github/workflows/ci.yml`) to run `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze --no-fatal-infos --no-fatal-warnings`, and `flutter test --coverage` on every push and pull request to `main` and `develop`.
**Rationale:**
1. **Quality gate:** No red code reaches `develop` unnoticed.
2. **Evidence for the internship:** A green CI badge on the README is proof of engineering discipline.
3. **Learning:** The intern experiences real CI/CD, not just local builds.
**Consequences:**
- **Positive:** Automated regression detection from day one.
- **Negative:** A failing CI blocks merging. **Mitigation:** That is the point—it forces a fix before merge.
- **Note:** `--no-fatal-infos --no-fatal-warnings` is intentional. `flutter analyze` exits with code 1 for any info-level lint, which would make CI permanently red on a fresh Flutter project. Only actual errors should fail the pipeline.

---

## ADR-010: Show Welcome Only on First Launch Using a Hive Completion Flag

**Status:** Accepted
**Context:** The Welcome screen exists in the design, but its launch policy was not previously specified. The approved product decision is to show it only once.
**Decision:** Store an `onboardingCompleted` flag in the existing Hive settings storage. On startup, read it before selecting the initial route. The first launch opens Welcome; Get Started persists completion before navigating to the main application. Later launches open the main application directly. Do not add authentication, a backend, or another storage package.
**Rationale:**
1. The welcome experience is retained without interrupting returning users.
2. Hive is already the approved offline persistence technology (ADR-001).
3. The flag is a small app preference and does not justify a separate model or storage layer.
**Consequences:**
- **Positive:** First-launch behavior survives app restarts and works offline.
- **Negative:** Startup must load the flag before choosing the initial route. The existing settings persistence path must remain the single source for the flag.
- **Product traceability:** PRD §5.7, FR-32; PRD §12, RD-04.

---

## ADR-011: Open Expense Details Before Edit or Delete Actions

**Status:** Accepted
**Context:** The Home prototype shows an expense action dialog, while the approved product interaction requires tapping a Home expense to open a dedicated Details screen.
**Decision:** Tapping a Home expense opens Expense Details, which presents amount, category, date, optional note, and Edit/Delete actions. Edit opens the existing prefilled expense form. Delete requires confirmation before permanently deleting the expense. After successful deletion, return to Home and refresh the expense list and dashboard calculations.
**Rationale:**
1. A dedicated screen supports viewing the selected expense and gives Edit/Delete a consistent location.
2. Reusing the existing form avoids a second edit flow.
3. This is an approved product interaction; it does not require another controller or package.
**Consequences:**
- **Positive:** Expense selection and subsequent actions have a clear route and context.
- **Negative:** The Details screen's visual treatment is not established by the inspected prototype and must follow the approved design language without inventing requirements.
- **Product traceability:** PRD §5.1 and §5.7, FR-02, FR-03, FR-33; PRD §12, RD-05.

---

## ADR-012: Handle Missing Expenses and Persistence Failures Explicitly

**Status:** Accepted
**Context:** A Details route can reference a record that no longer exists, and a local Hive write can fail. The UI must not imply a successful operation when data was not persisted.
**Decision:** If an Expense Details request has no matching record, show an explicit not-found state with a return-to-Home action. A Hive lookup error is distinct from a missing record and presents an error with a retry path. If expense creation, editing, or deletion fails to persist, show an explicit error, preserve the current form or Details state, do not show success or navigate away as though the operation succeeded, and allow retry.
**Rationale:**
1. Explicit outcomes protect user trust and avoid false success feedback.
2. Preserving the current screen and form state gives the user a retry path without losing input.
3. This behavior uses the existing Hive/GetX architecture and adds no dependency.
**Consequences:**
- **Positive:** Missing data and write failures are visible and recoverable.
- **Negative:** Exact error copy and visual treatment remain a UI implementation detail; DESIGN.md marks them as visually unverified.
- **Product traceability:** PRD §5.7, FR-34–FR-35; PRD §12, RD-06.

---

## ADR-013: Persist and Apply the Selected `ThemeMode` Through GetX

**Status:** Accepted
**Context:** The PRD requires light/dark selection and persistence (FR-23–FR-24). The project owner approved GetX's theme-mode support rather than introducing a second theme owner.
**Decision:** `SettingsController` owns the reactive `Rx<ThemeMode>`. Hive persists the selected mode. `GetMaterialApp` supplies `theme`, `darkTheme`, and the saved initial `themeMode`; settings changes are applied with `Get.changeThemeMode(mode)`. Load the saved mode before the first screen. Do not introduce a second source of truth.
**Rationale:**
1. It follows the accepted GetX and Hive architecture and the approved theme implementation.
2. It ensures the first screen uses the persisted preference.
3. It keeps theme state in one controller.
**Consequences:**
- **Positive:** Theme changes are reactive, applied immediately, and persisted locally.
- **Negative:** The Hive serialization format and behavior if the preference write fails remain open and must be approved before implementation.
- **Product traceability:** PRD §5.5, FR-23–FR-24.

---

## Open decisions — not accepted ADRs

These are not approved technical decisions. Do not implement them as settled behavior until the owner approves them.

| ID | Status | Open decision | Related reference |
| :--- | :--- | :--- | :--- |
| OPEN-01 | OPEN — NEEDS APPROVAL | Confirm the Expense/Category Hive type IDs, field indexes, box names, and settings keys. | ARCHITECTURE.md §4 |
| OPEN-02 | OPEN — NEEDS APPROVAL | Define the user-visible outcome if saving the onboarding completion flag fails. | PRD FR-32; ADR-010 |
| OPEN-03 | OPEN — NEEDS APPROVAL | Define retry/rollback behavior after partial category reassignment persistence. | PRD FR-21; ADR-006 |
| OPEN-04 | OPEN — NEEDS APPROVAL | Define preference-save failure behavior and the stable Hive encoding for `ThemeMode`. | PRD FR-23–FR-27; ADR-013 |

---

## How to Add a New Decision

When a new technical decision is made:
1. Assign the next ADR number.
2. Add a row to the summary table.
3. Write the ADR using the four sections: **Context → Decision → Rationale → Consequences**.
4. Reference the PRD section if the decision has product impact.
5. Commit with the message `docs: add ADR-XXX <title>`.

**Status values:** Proposed → Accepted → Deprecated → Superseded.