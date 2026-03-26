# wb-cloud-mobile-wrapper

Flutter mobile wrapper for [Wiren Board Cloud](https://wirenboard.cloud) — turns the web UI into a native Android/iOS app with offline bookmarks and navigation controls.

## Features

- Full-screen WebView of `wirenboard.cloud` with JavaScript enabled
- Bottom navigation bar: back, refresh, bookmark, bookmarks list, home
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

## Project structure

```
lib/
  main.dart                   # App entry point, theme setup
  screens/
    main_screen.dart          # WebView + navigation bar
  widgets/
    bookmarks_sheet.dart      # Bottom sheet with bookmark list
  data/
    bookmark.dart             # Bookmark model
    bookmark_repository.dart  # SharedPreferences-backed persistence
```

## Dependencies

| Package | Purpose |
|---|---|
| `webview_flutter` | Embedded WebView |
| `shared_preferences` | Local bookmark storage |
| `cupertino_icons` | iOS-style icons |

## License

MIT
