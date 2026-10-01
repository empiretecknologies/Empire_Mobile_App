# Development Guidelines

## Naming Conventions

- Package/app name: `empire_app` (snake_case).
- Widgets: PascalCase (`MyApp`, `MyHomePage`).
- Private state/fields: leading underscore (`_MyHomePageState`, `_counter`, `_incrementCounter`).
- Android applicationId/namespace: `com.example.empire_app`.

## Coding Patterns

- Entry point: `lib/main.dart` → `main()` → `runApp`.
- Root app: `StatelessWidget` + `MaterialApp`.
- Screens with local state: `StatefulWidget` + `setState`.
- Prefer `const` constructors where used in the template (`const MyApp()`, `const MyHomePage(...)`).

## File Organization

- All Dart app code currently lives in `lib/main.dart`.
- Tests in `test/`.
- When adding features, keep structure minimal; add folders (`screens`, `widgets`, `models`, `services`) only when needed.
- Project reference docs: `.cursor/docs/`.
- Project rules: `.cursor/rules/`.

## API Usage Pattern

- Not implemented yet.
- When added: call .NET Core Web API only; no direct SQL; no invented endpoints; models must match API contracts.

## State Management Rules

- Current approach: local `setState`.
- Do not add a state-management package unless required and requested.

## Widget Usage

- Use Material widgets consistent with existing UI.
- Reuse existing widgets before creating new ones.
- Keep UI simple and responsive across Android/iOS.

## Error Handling

- No API/error-handling layer yet.
- When API is integrated: handle loading/success/empty/validation/unauthorized/server/network with user-friendly messages (no raw exceptions).

## Resource Disposal

- No controllers, focus nodes, animations, or subscriptions in current code.
- When added: dispose `TextEditingController`, `FocusNode`, `AnimationController`, `StreamSubscription`, and similar resources.

## Package Usage

Current dependencies only: `flutter`, `cupertino_icons`, `flutter_test`, `flutter_lints`.

Rules:

- Do not add a package if Dart/Flutter already covers the need.
- New packages must support Android and iOS.
- Prefer reusing existing dependencies.

## Linting / Analysis

- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- Analyzer excludes `build/**` and platform folders (`android`, `ios`, `web`, `windows`, `macos`, `linux`).
