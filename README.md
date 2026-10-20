# Ritmo Flutter Frontend 

This is the standalone Flutter project. It consumes the ../backend API via HTTP; it does not access PostgreSQL.

The [main execution guide](../README.md) includes the commands for this computer and for a fresh installation.. The [contrato API](../docs/02-api-contract.md) defines the names and types of the Dart DTOs.

## State and Organization

- `app/store`: Redux for public session identity, account expiration/switching, and theme.
- `core/session`: In-memory token for web and secure storage for Android/iOS.
- `features/*/data`: DTOs and HTTP access repositories.
- `features/*/application`: Riverpod for queries and operation coordination..
- `features/*/presentation`: Responsive screens and widgets.
- `core/invalidate_progress.dart`: Joint update of activities, profile, dashboard, history, and achievements after a mutation.

Switching sessions destroys the previous data container to prevent data from another account from appearing. The progress coordinator retains the same UUID key and amount in the event of a network error or uncertain response; it never adds XP locally.

## Screens

Login/registration, dashboard, activity list/form/details, projects and tasks, history, badges, rewards, and profile. The screens display loading states, recoverable errors, and empty states. The dashboard uses usa `fl_chart` for line, bar, and donut charts; the heatmap calendar uses Flutter widgets with weekly columns, labels, horizontal scrolling, and accessibility aids.

## Execution

From this folder, using an SDK without spaces in its path:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port 5173 --dart-define-from-file=config/development.json
```

On this computer, use `..\scripts\flutter.ps1` from here or `.\scripts\flutter.ps1` from the root. Select the short alias of the installed SDK, because the native asset tools of this version fail when launching Dart from some paths with spaces. The global Flutter installation was not modified.

Web uses `config/development.json`; the Android emulator uses `config/android-emulator.json`. Do not store secrets in `dart-define`: those values become part of the compiled client. The web session ends upon reloading the page, an explicit MVP decision to avoid persisting the JWT in the browser.
