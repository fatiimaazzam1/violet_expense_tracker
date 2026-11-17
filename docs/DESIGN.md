# Violet Expense Tracker — Design Specification

**Status:** Design reference for implementation
**Product authority:** Approved [PRD](./PRD.md) and accepted [decisions](./DECISIONS.md)
**Visual reference:** Authenticated [Figma Make preview](https://www.figma.com/make/uRMVYs3ftoCm63REf8s3q2/Design-Violet-Expense-Tracker)

## 1. Evidence and authority

This document combines the approved product requirements with inspection of the live Figma Make preview. The PRD and accepted ADRs define required behavior; the web prototype is a visual and interaction reference, not a replacement for those requirements.

- **Observed** means seen in a browser screenshot, the live preview's accessible page contents, or by operating a control in that preview. Screenshots were captured for Welcome and Home; other screens were inspected through the live preview's accessible contents.
- **PRD/ADR** means required by the approved product documents, whether or not that state was visible in the prototype.
- **Unverified** means the available preview inspection did not establish the detail. Do not treat it as a new requirement or fill it in with guessed values.

If prototype behavior conflicts with the PRD or an accepted ADR, follow the approved product decision. Translate the product intent into Flutter-native UI; do not reproduce web-specific implementation choices.

The observations above describe the prior authenticated preview inspection; no preview screenshots or MCP retrieval artifacts are stored in this repository. This document does not claim that Figma resources were read through MCP.

## 2. Screen inventory

| Screen | Purpose and observed content | Navigation |
| --- | --- | --- |
| **Welcome** | **Observed:** A portrait, single-column introduction. Expense Tracker branding and a small icon sit above an illustration-like composition of floating summary cards: “This month” with **$157.90**, “Food” with **$18.50**, and “Private / On device”. Below are the “SIMPLE · PRIVATE · OFFLINE” eyebrow, the large headline “Know where your money goes.”, supporting copy, a prominent **Get started** button, and a no-account/on-device privacy note. The illustration was visible in the screenshot; whether it is a bundled asset or built from UI primitives is unverified. **PRD/ADR-010:** Show only on first launch; persist completion after Get started. | **Observed prototype:** Get started opens Home / Expenses. **Target behavior:** First launch opens Home after completion is persisted; subsequent launches bypass Welcome. |
| **Home / Expenses** | **Observed:** Header eyebrow “EXPENSE TRACKER”, title “Expenses”, and a filter icon button. A vertically scrolling history is grouped by date, with a group total and expense rows. Rows show a colored category icon tile, note/title, category, negative formatted amount, and a trailing chevron. The inspected sample showed Today ($23.25), Yesterday ($82.60), Nov 11, 2026 ($42.80), and Nov 7, 2026 ($9.25). A prominent Add expense action sits above a persistent-looking four-item bottom navigation. **PRD:** Sort newest first and show date headers. | Bottom navigation switches tabs. Add expense opens the Add Expense screen. **Target behavior (PRD/ADR-011):** Selecting an expense opens Expense Details; the prototype's action dialog is not the target tap flow. |
| **Dashboard** | **Observed in live page contents:** “Overview” and “Dashboard”, month label **November 2026**, total **$157.90**, **6 recorded expenses**, and “Spending by category” for the current calendar month. The accessible breakdown showed Bills 43% / $68.40, Shopping 27% / $42.80, Transport 15% / $23.45, Food 12% / $18.50, and Coffee & treats 3% / $4.75, followed by an automatic-update note. **PRD:** The monthly breakdown is a pie chart. The chart's rendered geometry was not confirmed in a screenshot. | Open from the Dashboard bottom-navigation tab. |
| **Categories** | **Observed in live page contents:** “Organize” eyebrow, “Categories” title, explanatory copy, a **Default** section and a **Custom** section. Food, Transport, Bills, and Shopping are marked Built in / Protected and show expense counts. The sample custom category “Coffee & treats” shows its count and a delete control. Add category controls appear in the header and at the bottom. | Open from Categories bottom-navigation tab. Add category opens a category form dialog. Delete opens a reassignment dialog when expenses use that category. |
| **Settings** | **Observed in live page contents:** “Preferences” and “Settings”; an Appearance group with Light mode and Dark mode radio choices; a Currency group with USD ($), EUR (€), LBP (ل.ل), and GBP (£); copy explaining that currency changes formatting only; and a “Private by design” on-device/offline statement. Theme and currency selections were operated in the preview. | Open from Settings bottom-navigation tab. Selection takes effect immediately in the preview. |
| **Add Expense** | **Observed in live page contents:** A page header with Go back and “Add Expense”; Amount input with the chosen currency symbol; required Category choices; Date input initially showing **2026-11-15**; optional Note input with a 200-character counter; and Cancel / Save expense actions. Submitting with an empty form showed inline “Enter an amount.” and “Select a category.” messages. | Open from Home's Add expense action. Go back or Cancel returns to Home in the observed flow. |
| **Edit Expense** | **Observed in live page contents:** Same field structure as Add Expense, headed “Edit Expense”, prefilled from the selected record. The inspected Lunch example showed amount 18.5, Food selected, date 2026-11-15, and note “Lunch”. Save changes and Cancel actions are present. | **Observed prototype:** Home → action dialog → Edit. **Target behavior (PRD/ADR-011):** Home → Expense Details → Edit → prefilled form. |
| **Expense Details** | **PRD/ADR-011:** Show the selected expense's amount, category, date, and optional note, with Edit and Delete actions. **Unverified visually:** This screen was not present in the inspected preview; layout, styling, and exact labels are not specified by the available visual evidence. | Home → tap an expense. Edit opens the existing prefilled Edit Expense form. Delete requires confirmation before permanent deletion. |

## 3. Navigation and user flows

### Bottom navigation

**Observed:** Main navigation contains **Home**, **Dashboard**, **Categories**, and **Settings**, with an icon and label for each. The selected tab is visually distinguished. The bar remains at the bottom while switching between these top-level screens. Forms were presented as separate screens without that bottom bar in the accessible preview.

### Expense flows

- **Add:** Home → Add expense → enter amount, choose category, optionally change date and enter a note → Save expense → return to Home. Inline required-field errors were observed. The PRD specifies a success snackbar after a valid save; a successful save was not performed during inspection.
- **Edit (target flow):** Home → select an expense → Expense Details → Edit → update the prefilled fields → Save changes → return to Home. The PRD specifies an “Expense updated” snackbar. The preview's intervening action dialog is observed but superseded by the approved target flow.
- **Delete (target flow):** Home → select an expense → Expense Details → Delete → confirm or cancel in “Delete this expense?” The confirmation prompt and cancel path were observed in the prototype; deletion was not confirmed. The PRD specifies an “Expense deleted” snackbar and return to Home after successful deletion.
- **Missing record / persistence failure:** **PRD/ADR-012:** A missing Details record shows an explicit not-found state with a return-to-Home action. A Hive lookup error is distinct from a missing record and offers retry. A failed expense create/edit/delete displays an error, preserves the current form or Details state, does not report success or navigate away, and allows retry. Exact error presentation is unverified.
- **Return from forms:** The Add and Edit forms expose Go back and Cancel. Cancel was exercised and returned to Home. Successful-save return behavior follows the PRD and was not verified in the live preview.

### Other flows

- **Filter history:** Home → filter icon → choose one or more categories and/or start and end dates → Apply filters. A Food-only filter was applied and showed the one matching $18.50 expense; Clear restored the full list. The filter dialog says category and date filters work together.
- **Category management:** Categories → Add category → enter a name, choose an icon, Save category. The dialog was inspected but not submitted. Deleting a category with linked expenses opens a required-reassignment dialog.
- **Preferences:** Settings → select theme or currency. Theme selection updates immediately. Selecting EUR displayed a “Currency display changed to EUR” snackbar and changed visible amount formatting from `$` to `€`; it did not convert the underlying values. The test selection was restored to Light mode and USD.
- **First-launch onboarding:** **PRD/ADR-010:** First launch → Welcome → Get started → persist completion in Hive → Home. On later launches, open the main application directly. The preview's visual flow was inspected, but repeated-launch behavior was not. What to do if the completion-flag write fails remains **OPEN — NEEDS APPROVAL**.

## 4. Visual design reference

### Color and theme

- **Observed in the light screenshots:** Purple is the primary action/accent color, set against a very light lavender/off-white surface. Primary text is near-black; supporting text is gray. Category icons use distinct softly tinted backgrounds. The welcome illustration also uses pale lavender and light blue areas.
- **Observed:** Light and Dark mode choices are available. The selected theme control updates immediately.
- **Unverified:** Exact color values, semantic token names, contrast ratios, and the rendered dark palette were not established by the screenshots. Do not infer hex codes from image appearance.

### Typography

- **Observed:** The hierarchy uses a large, light-weight welcome headline; bold screen titles and expense names; small uppercase purple eyebrow labels; and quieter gray explanatory text and metadata.
- **Unverified:** Font family, exact font sizes, line heights, weights, and platform-specific font behavior.

### Spacing, layout, and surfaces

- **Observed:** The design is portrait-first and single-column. Content has generous breathing room, with date-group headings separated from rounded expense-list surfaces. The Home list scrolls vertically while the bottom navigation stays at the lower edge. The Welcome screen stacks its brand, illustration, message, and primary action.
- **Observed:** Cards and dialogs use rounded shapes; list group surfaces have a subtle border/separation. The primary action is a high-contrast purple rounded button. The filter is a compact outlined icon button.
- **Unverified:** Exact paddings, gaps, corner radii, border widths, shadows/elevation, animation curves, and maximum content width.

### Icons, forms, and dialogs

- **Observed:** Icons are simple line-style symbols. Expense/category rows use category-specific icons in tinted tiles; navigation uses recognizable home, chart, tag, and settings symbols. Add category presented eight icon choices labelled Dining, Transport, Utilities, Shopping, Coffee, Wallet, Tag, and Card.
- **Observed:** Expense forms use visibly labelled fields, a currency prefix, category choices, a date field, and a note character counter. Category creation is a dialog with a name field and icon choices. **Prototype only:** Expense selection opens an action dialog; the target flow opens Expense Details. Deletion confirmation and category reassignment use dialogs.
- **Unverified:** Exact icon asset source, form focus/keyboard behavior, dialog transition/placement measurements, and button pressed/disabled styling beyond the observed disabled Reassign action before a destination was selected.

## 5. Interactions, validation, and UI states

| State or interaction | Evidence and implementation requirement |
| --- | --- |
| Add/edit validation | **Observed:** Empty Add Expense submission displays inline amount and category errors. **PRD:** Amount must be positive; zero/negative values are rejected, category is required, note is optional and limited to 200 characters. **Unverified in preview:** zero/negative handling, malformed decimal handling, note limit enforcement, and edit validation edge cases. |
| Future date | **PRD/ADR-007:** Date defaults to today; selecting a future date requires “This date is in the future. Save anyway?” confirmation before save. **Unverified:** Date picker and future-date confirmation were not exercised in the preview. |
| Delete expense | **Observed prototype:** “Delete this expense?” identifies the record and amount and offers Cancel/Delete. **PRD:** Expense Details requires confirmation before permanent deletion; on success return Home and show a success snackbar. Confirmation was not accepted in the preview. |
| Category filtering | **Observed:** Select one or more categories, Apply, and Clear. A Food selection returned the Food expense; Clear restored all records. |
| Date filtering | **Observed:** Start date and End date inputs are present, marked Optional, and combine with category filtering. **Unverified:** Actual date-range selection, boundary inclusivity, invalid range feedback, and filtered-empty presentation. |
| Category creation | **Observed:** Name input, 0/30 counter, icon choices, Cancel, and Save category. **PRD:** Name must be unique case-insensitively and no longer than 30 characters. **Unverified:** Successful creation and duplicate/empty-name feedback. |
| Category deletion/reassignment | **Observed:** A category with one expense displayed “Reassign expenses first,” explained that the expense would not be deleted, offered a destination category selector, and kept Reassign disabled until a category was selected. Cancel was exercised. **PRD/ADR-006:** Reassign dependent expenses before deleting the category. **Unverified:** Completing reassignment, post-delete feedback, and the no-linked-expenses confirmation flow. Built-in categories are marked Protected in the preview and cannot be deleted. Recovery after a partial persistence failure is **OPEN — NEEDS APPROVAL**. |
| Theme and currency | **Observed:** Light/Dark and four currency radio options. Theme selection updates immediately; EUR produced a snackbar and changed displayed symbols. **PRD/ADR-005:** Currency changes display formatting only, never converts amounts, and both preferences persist across restarts. Restart persistence was not tested. Preference-write failure behavior and theme serialization are **OPEN — NEEDS APPROVAL**. |
| Empty states | **PRD:** Provide distinct first-time empty and filtered-empty states for history; show an empty state instead of a blank dashboard chart when the current month has no expenses. **Unverified:** The sample preview contained expenses, so none of these states was visually inspected. Their exact copy, artwork, and layout are not specified here. |
| Dashboard updates/chart | **Observed in accessible preview contents:** Month total and category amounts/percentages are exposed and accompanied by an automatic-update note. **PRD:** Current-month total, pie chart by category, empty chart state, and updates after add/edit/delete. **Unverified:** Rendered chart type/legend/interaction and empty-month appearance; successful CRUD-driven refresh was not tested. |
| Expense Details and missing record | **PRD/ADR-011/012:** Details shows amount, category, date, optional note, Edit, and Delete. A missing record shows a not-found state and a return-to-Home action. A Hive lookup error is a separate error state with retry. **Unverified visually:** The screen and states were not present in the preview; exact copy and layout are unspecified. |
| Persistence failure | **PRD/ADR-012:** For failed expense create/edit/delete, show an explicit error, preserve current form/Details state, do not report success or navigate away, and allow retry. **Unverified visually:** Exact message and presentation are unspecified. |
| Loading states | No loading screen was encountered. The PRD does not specify exact loading visuals; do not invent them here. |

## 6. Responsive Flutter implementation guidance

The PRD requires usable layouts from **320px to 430px** (NFR-03). The inspected design is a narrow, portrait, single-column mobile experience; the exact breakpoint and spacing values are not known.

- Use the available width rather than fixed web-style dimensions. Keep expense rows, category options, settings choices, and form controls inside the safe content width at 320px.
- Use `SafeArea` and Flutter's system insets for status/navigation areas. Ensure bottom actions and navigation do not obscure scrollable content or the final form field.
- Prefer `Scaffold` with a native bottom-navigation widget for the four top-level destinations. Keep each tab's body independently scrollable where needed.
- Build Home and long forms with `ListView` or `CustomScrollView`; use flexible rows and wrapping/ellipsis for long expense notes or category names. Do not shrink text to force a single-line fit.
- Use a responsive single-column layout for the target phone widths. Preserve the observed hierarchy and spacing rhythm without hard-coding unverified pixel measurements.
- Keep Expense Details readable at 320px: allow long notes/category names to wrap and keep Edit/Delete actions reachable without horizontal overflow.
- Keep the Add Expense action reachable without covering list content. Verify its placement alongside the bottom navigation at both 320px and 430px.
- Use native Flutter form fields, validators, date picker, modal sheets/dialogs, and buttons. Preserve inline field feedback and the observed confirmation/reassignment flows, rather than recreating browser-specific controls.
- Support text scaling and adequate tap targets; check that dialogs and the category-choice grid remain usable at the narrowest width and with the keyboard open.

## 7. Flutter translation

Translate the design intent into native widgets and the approved app structure:

- **Screen shell:** `Scaffold`, safe areas, scrollable content, and a four-destination bottom navigation.
- **History:** date-group headers and tappable expense cards/list tiles with category icon, description, category, amount, and trailing affordance.
- **Expense Details:** a native screen presenting the selected expense fields and Edit/Delete actions. Use an explicit not-found state with a Home action when the record is unavailable.
- **Dashboard:** monthly total summary card plus the **PRD-required pie chart** and category breakdown; provide the PRD empty state when there is no current-month data.
- **Forms:** native text/number input, category selection controls, date picker, inline validators, note counter, and clear Save/Cancel actions.
- **Dialogs:** native confirmation dialog for expense deletion from Details; category reassignment dialog with affected count and destination selector; category creation dialog/sheet with name and icon selection.
- **Settings:** native theme and currency selection controls, driven by app settings state and persisted as required by the PRD.
- Use Flutter theme data and semantic colors to express the observed purple/light visual character and dark-mode option. Exact palette values remain to be established from an authoritative design token source or approved visual measurement.

Do not port React components, CSS classes, browser navigation, or browser storage into Flutter architecture. Use the approved Flutter/GetX/Hive decisions for implementation while preserving the user-visible flows and product requirements.

## 8. PRD traceability

| PRD requirement | Screen(s) | Design behavior / interaction |
| --- | --- | --- |
| FR-01, FR-04–FR-07 | Add Expense, Edit Expense | Amount, category, date, optional note; validation; future-date confirmation. |
| FR-02 | Expense Details, Edit Expense | Details → Edit opens a prefilled form; save updates the expense and returns Home. |
| FR-03 | Expense Details, Home / Expenses | Details → Delete → confirm permanent deletion; on success return Home and refresh history/dashboard. |
| FR-32 | Welcome | Show only on first launch; persist completion in Hive after Get started and bypass Welcome later. |
| FR-33 | Home / Expenses, Expense Details | Tapping an expense opens Details with its fields and Edit/Delete actions. |
| FR-34 | Expense Details | Missing record displays an explicit not-found state with a return-to-Home action. |
| FR-35 | Add Expense, Edit Expense, Expense Details | Hive lookup/persistence errors show an explicit error and retry path; failed writes preserve current state and avoid false success/navigation. |
| FR-08–FR-09 | Home / Expenses | Descending, date-grouped history with date headers and per-day totals. |
| FR-10–FR-12 | Home / Expenses | Filter by one or more categories and date range; show filtered-empty state. |
| FR-13 | Home / Expenses | Distinct first-time empty state with a hint to add an expense. |
| FR-14–FR-17 | Dashboard | Current-month total and category pie chart; empty-month state; refresh after CRUD. |
| FR-18–FR-20, FR-22 | Categories | Protected defaults; custom category name/icon; case-insensitive uniqueness and 30-character limit. |
| FR-21 | Categories | Block deletion with linked expenses until they are reassigned via a dialog. |
| FR-23–FR-24 | Settings | Light/dark selection with immediate effect and persistence. |
| FR-25–FR-27 | Settings; all amount displays | Select USD/EUR/LBP/GBP symbol only; apply consistently without converting amounts; persist preference. |
| FR-28–FR-31 | All screens / app-wide | Offline-first local data persistence; storage behavior is not a screen-specific visual design. |
| NFR-03 | All screens | Responsive and usable at widths from 320px to 430px. |
| NFR-05 | Add Expense, Edit Expense | Inline validation messages below relevant fields. |

## 9. Remaining visual evidence

The live preview established the Welcome and Home appearance in screenshots and exposed Dashboard, Categories, Settings, Add Expense, Edit Expense, and dialogs through accessible page contents and interactions. The following still need visual confirmation before assigning exact specifications:

- Exact light/dark semantic colors, font family and metrics, spacing, radii, borders, and shadows.
- A screenshot of Dashboard to confirm whether the rendered category visualization is the PRD-required pie chart and how its legend is arranged.
- Rendered empty states (first-time history, filtered history, and empty-month dashboard).
- The product-required Expense Details screen, its missing-record state, and expense-persistence error presentation; these were not part of the inspected prototype.
- The dark-mode palette, date picker and future-date confirmation, successful save/delete snackbars, and completed category reassignment.
- Failure recovery for onboarding, preference writes, and partial category reassignment needs approval; these behaviors were not established by the preview.
- Layout behavior at 320px and 430px, including keyboard, text scaling, and any long labels.

These are evidence gaps, not permission to invent requirements. Keep the approved PRD and accepted decisions as the source of truth.

## 10. Add/Edit form implementation status

The Add and Edit routes now use one shared native Flutter form with labelled amount, category, date, and optional-note controls, inline controller validation, a note counter, Cancel/Save actions, retryable load errors, and a distinct missing-expense state. The future-date dialog uses the approved ADR-007 wording. A successful write displays a Material snackbar and returns to the Home route; a failed write keeps the form and entered values visible.

The category selector currently displays the four PRD-approved built-in categories using the UI-only stable IDs recorded in ADR-015. Category persistence, default-category seeding, and custom categories are not part of this milestone.

The form does not display a currency prefix yet. The app has no implemented settings controller or approved initial currency value to supply one; the inspected prototype's selected-symbol prefix remains a known integration gap, not a change to the approved design. The screen uses a Material deep-purple seeded accent to follow the observed purple direction; this is not a claim that the exact Figma palette or dark palette has been measured. Device layout, keyboard behavior, and color contrast remain unverified.