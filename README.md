# Violet Expense Tracker

An offline personal expense tracker built with Flutter, Dart, GetX, and Hive. The approved MVP includes expense CRUD, date-grouped history and filters, a monthly dashboard, category management, onboarding, and theme/currency preferences.

## Requirements

- Flutter SDK compatible with the Dart constraint in `pubspec.yaml` (`^3.11.3`).
- Android toolchain for building and running the Android app.

## Run

From the repository root:

```shell
flutter pub get
flutter run
```

On a fresh install, complete the Welcome screen to continue to the app. Expense and preference data are stored locally with Hive.

## Build Android APK

```shell
flutter build apk --release
```

The current release build is at `build/app/outputs/flutter-apk/app-release.apk`. It builds successfully but has not been installed or run on a connected Android device; see [`docs/QA.md`](docs/QA.md).

## Validate

```shell
dart format .
flutter analyze
flutter test
git diff --check
```

The actual results for the current implementation, Android build/device status, and known validation gaps are recorded in [`docs/QA.md`](docs/QA.md).

## Project documentation

- Approved requirements: [`docs/PRD.md`](docs/PRD.md)
- Design observations and visual-verification status: [`docs/DESIGN.md`](docs/DESIGN.md)
- Implemented structure and data flow: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Accepted technical decisions: [`docs/DECISIONS.md`](docs/DECISIONS.md)
- MVP scope/status: [`docs/MVP.md`](docs/MVP.md)
- QA results and limitations: [`docs/QA.md`](docs/QA.md)
- Proof-of-concept evidence: [`docs/POC.md`](docs/POC.md)
- Final implementation review: [`docs/REVIEW.md`](docs/REVIEW.md)

## Delivery status

The MVP implementation is present in the source tree. Do not treat automated widget tests as Android device validation or as a substitute for presentation screenshots. See the QA and review documents for the current readiness assessment. Genuine product screenshots, a device demonstration, and any APK delivery artifact must be captured/verified before claiming those deliverables.

CSV/PDF export, monthly budgets, local notifications, multilingual support, cloud sync, and user accounts are outside the approved MVP scope.
