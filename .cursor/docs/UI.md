# UI

## UI Structure

Single-screen Material Design demo:

- `MaterialApp` → `MyHomePage` (`Scaffold`)
- `AppBar` with title from `widget.title`
- Centered `Column` with helper text + counter value
- `FloatingActionButton` with `Icons.add` to increment

## Theme

Defined in `MyApp`:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
)
```

- Seed color: `Colors.deepPurple`
- AppBar background uses `Theme.of(context).colorScheme.inversePrimary`
- Counter text uses `Theme.of(context).textTheme.headlineMedium`
- Material Icons enabled (`uses-material-design: true` in `pubspec.yaml`)

## Colors

No custom color palette file. Colors come from Material 3 `ColorScheme.fromSeed` with `deepPurple`.

## Typography

No custom fonts in `pubspec.yaml`. Uses default Material text theme (`headlineMedium` for counter).

## Common Widgets (Currently Used)

| Widget | Usage |
|--------|--------|
| `Scaffold` | Page layout |
| `AppBar` | Top bar |
| `Center` / `Column` | Body layout |
| `Text` | Labels and counter |
| `FloatingActionButton` | Increment action |
| `Icon` | Add icon on FAB |

## Forms

None.

## Buttons

- One `FloatingActionButton` (`onPressed: _incrementCounter`, tooltip: `Increment`)

## Dialogs

None.

## Lists

None.

## Responsive Design Approach

No custom responsive breakpoints or adaptive layouts. Default Flutter layout widgets only; works on phone/tablet via Material defaults.

## Android / iOS UI Considerations

- Android launch/normal themes: `LaunchTheme` / `NormalTheme` (light, no title bar) under `android/app/src/main/res/values/`
- Night variants exist under `values-night/`
- iOS display name: `Empire App` (`Info.plist` `CFBundleDisplayName`)
- No platform-specific UI widgets (no `Cupertino*` widgets used in `main.dart`; `cupertino_icons` package is present but unused in current UI)
