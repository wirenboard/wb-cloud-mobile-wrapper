# wb-cloud-mobile-wrapper

Flutter mobile wrapper for [Wiren Board Cloud](https://wirenboard.cloud) — turns the web UI into a native Android/iOS app with offline bookmarks and navigation controls.

## Features

- Full-screen WebView of `wirenboard.cloud` with JavaScript enabled
- Speed Dial FAB (bottom-right) for navigation: add bookmark, bookmarks list, reload, home
- FAB auto-dims to 25% opacity after 3 seconds of inactivity to avoid obscuring content
- Splash screen on startup showing app version
- Bookmarks stored locally via `shared_preferences`
- Navigation restricted to `wirenboard.cloud` domain; external links open in the system browser
- Android intent support — accepts shared URLs when the app is already running
- Material 3 design with light/dark theme following system preference

## Requirements

- Flutter SDK ≥ 3.6.1
- Dart SDK ≥ 3.0
- Android or iOS device/emulator

## Getting started

```bash
git clone https://github.com/wirenboard/wb-cloud-mobile-wrapper.git
cd wb-cloud-mobile-wrapper
flutter pub get
flutter run
```

## Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ipa --release
```

## Versioning

Version follows [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH+BUILD`.

| Part | When to bump |
|---|---|
| `patch` | Bug fixes, minor tweaks |
| `minor` | New features, UI changes (backward compatible) |
| `major` | Breaking changes, major redesign |

The build number (`+N`) increments automatically on every bump and maps to `versionCode` on Android and `CFBundleVersion` on iOS.

Version is tracked in `pubspec.yaml` and mirrored to `lib/version.dart` (displayed on the splash screen at startup).

### Releasing a new version

**1. Make sure all changes are committed:**
```bash
git status
```

**2. Bump the version:**
```bash
./bump_version.sh patch   # bug fixes      → e.g. 1.1.0 → 1.1.1
./bump_version.sh minor   # new features   → e.g. 1.1.1 → 1.2.0
./bump_version.sh major   # breaking/major → e.g. 1.2.0 → 2.0.0
```

The script:
- Updates `pubspec.yaml` and `lib/version.dart`
- Creates a git commit `chore: bump version to X.Y.Z+N`
- Creates a git tag `vX.Y.Z`

**3. Build and push:**
```bash
# Push commits and tags
git push && git push --tags

# Android
flutter pub get --offline
flutter build apk --release
# or for Play Store:
flutter build appbundle --release

# iOS
flutter build ipa --release
```

> **Note:** Do not edit `lib/version.dart` manually — it is overwritten by `bump_version.sh`.

## Project structure

```
lib/
  main.dart                   # App entry point, theme setup
  version.dart                # Auto-generated version constants (do not edit)
  screens/
    main_screen.dart          # WebView + Speed Dial navigation + splash
  widgets/
    bookmarks_sheet.dart      # Bottom sheet with bookmark list
  data/
    bookmark.dart             # Bookmark model
    bookmark_repository.dart  # SharedPreferences-backed persistence
bump_version.sh               # Version bump script
```

## Dependencies

| Package | Purpose |
|---|---|
| `webview_flutter` | Embedded WebView |
| `shared_preferences` | Local bookmark storage |
| `cupertino_icons` | iOS-style icons |

## License

MIT
