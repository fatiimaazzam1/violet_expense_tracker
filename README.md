# Violet Expense Tracker

An offline personal expense-tracking mobile application planned with Flutter, Dart, GetX, and Hive. The approved scope covers expense records, category management, history and filters, a monthly dashboard, theme and currency preferences, and local persistence.

## Current status

The documentation and architecture plan are being finalized. Expense Tracker features have not been implemented; `lib/main.dart` is still the default Flutter counter starter. Do not interpret that starter screen as a working product demo.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml` (Dart `^3.11.3`).
- Android development environment for the internship's on-device target. iOS is a compatibility target; this project environment does not claim an iOS build or device test.

## Run the current starter

From the repository root:

```shell
flutter pub get
flutter run
```

Until implementation begins, this runs the default starter application, not an expense tracker.
These commands are documented setup steps; they were not run as part of the documentation audit.

## Documentation

- Product requirements: [`docs/PRD.md`](docs/PRD.md)
- Accepted technical decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md)
- Design specification: [`docs/DESIGN.md`](docs/DESIGN.md)
- Planned architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Planned QA strategy: [`docs/QA.md`](docs/QA.md)

## Screenshots and delivery

Product screenshots, a working APK, demo, and verified platform/CI results are not available yet. Add genuine screenshots and delivery instructions after the corresponding implementation and validation exist.

CSV/PDF export, monthly budgets, local notifications, multilingual support, cloud sync, and user accounts are outside the approved MVP scope.
