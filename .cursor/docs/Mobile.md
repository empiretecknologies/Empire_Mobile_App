# Mobile

## Android Configuration

| Item | Value |
|------|--------|
| Application ID | `com.example.empire_app` |
| Namespace | `com.example.empire_app` |
| Label | `empire_app` |
| Activity | `.MainActivity` (exported, `singleTop`) |
| Flutter embedding | v2 |
| Java/Kotlin target | 17 |
| minSdk / targetSdk / compileSdk | From Flutter defaults (`flutter.minSdkVersion`, etc.) |
| Release signing | Currently uses debug signing config |

Key files:

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`

## iOS Configuration

| Item | Value |
|------|--------|
| Display name | `Empire App` |
| Bundle name | `empire_app` |
| Launch storyboard | `LaunchScreen` |
| Main storyboard | `Main` |
| Orientations (iPhone) | Portrait, Landscape Left/Right |
| Orientations (iPad) | Portrait, Upside Down, Landscape Left/Right |

Key file: `ios/Runner/Info.plist`

## Permissions

- Android: no custom permissions declared in main `AndroidManifest.xml` (only default Flutter text-process `queries` entry).
- iOS: no extra usage description keys (camera, location, etc.) in `Info.plist`.

## Platform-Specific Implementation

None beyond default Flutter Android/iOS host projects. No MethodChannels, platform views, or native plugins in use.

## Device Compatibility

- Targets Android and iOS via Flutter.
- Desktop/web folders exist (windows, linux, macos, web) from Flutter template; primary product focus per rules is Android and iOS.

## Responsive Behavior

No custom mobile responsive rules. Relies on Flutter/Material layout defaults.

## Build Considerations

- Version from `pubspec.yaml`: `1.0.0+1` (`versionName` / `versionCode` on Android; build name/number on iOS).
- Android release build still signed with debug keys (template TODO).
- Analyzer excludes `android/**` and `ios/**` (and other platform folders) in `analysis_options.yaml`.

## Android / iOS Specific Dependencies

None. Current packages:

- `flutter` (SDK)
- `cupertino_icons: ^1.0.8`
- `flutter_lints: ^6.0.0` (dev)
- `flutter_test` (dev)
