# Architecture

## Project Overview

`empire_app` is a Flutter project (Dart SDK `^3.13.4`) currently at the default Flutter counter-demo stage. Planned stack (per project rules): Flutter client + .NET Core Web API backend. No custom feature modules exist yet.

## Folder Structure

```
Empire_App/
├── lib/
│   └── main.dart          # App entry, MyApp, MyHomePage
├── test/
│   └── widget_test.dart   # Counter smoke test
├── android/               # Android host project
├── ios/                   # iOS host project
├── web/                   # Web target (default Flutter)
├── windows/               # Windows desktop target
├── linux/                 # Linux desktop target
├── macos/                 # macOS desktop target
├── pubspec.yaml
└── analysis_options.yaml
```

There are no `lib/screens`, `lib/widgets`, `lib/models`, `lib/services`, or `lib/api` folders yet.

## Main Application Flow

1. `main()` calls `runApp(const MyApp())`.
2. `MyApp` (StatelessWidget) builds a `MaterialApp`.
3. `home` is `MyHomePage` (StatefulWidget) with title `Flutter Demo Home Page`.
4. `_MyHomePageState` holds `_counter` and increments it via `setState` when the FAB is pressed.

## Screen Structure

| Screen / Widget | Type | Role |
|-----------------|------|------|
| `MyApp` | StatelessWidget | Root `MaterialApp` + theme |
| `MyHomePage` | StatefulWidget | Single home screen (counter) |
| `_MyHomePageState` | State | Counter UI and increment logic |

No additional screens exist.

## Navigation Structure

- Uses `MaterialApp.home` only.
- No named routes, `Navigator` pushes, `GoRouter`, or tab navigation.

## State Management Approach

- Local widget state via `StatefulWidget` + `setState`.
- No Provider, Riverpod, Bloc, GetX, or other state-management packages.

## Reusable Components

None extracted. UI is built inline in `MyHomePage` with `Scaffold`, `AppBar`, `Column`, `Text`, and `FloatingActionButton`.

## Important Architectural Conventions

- Keep implementation in Flutter; business data should come from .NET Core Web API (planned; not implemented yet).
- Do not connect Flutter directly to SQL Server.
- Prefer minimal new files/classes; follow existing structure when adding features.
- Lint baseline: `flutter_lints` via `analysis_options.yaml`.
