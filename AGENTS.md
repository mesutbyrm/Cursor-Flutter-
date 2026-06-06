## Cursor Cloud specific instructions

### Project overview

Flutter mobile app (WebView wrapper for canlifal.com). Single-file app in `lib/main.dart`. See `README.md` for development commands.

### Environment

- Flutter SDK 3.32.2 (Dart 3.8.1) is installed at `/opt/flutter/bin`; it's on `PATH` via `~/.bashrc`.
- Platform folders (`web/`, `android/`, `ios/`) are not committed. Run `flutter create --platforms=web --project-name canlifal_mobile .` to generate them before building.

### Key gotchas

- **`webview_flutter` does not support web platform.** The app is designed for Android/iOS. To demo on a headless Linux VM, add web platform support via iframes or use `flutter build web` (which compiles but the WebView widget won't render on web without code changes).
- **Auto-generated test file:** `flutter create` generates `test/widget_test.dart` referencing `MyApp`. The committed test uses a `FakeWebViewPlatform` to mock the WebView in unit tests since no real platform is available in the test runner.
- **`webview_flutter_platform_interface`** is listed as a dev dependency for test mocking.

### Commands

```bash
flutter pub get       # install deps
flutter analyze       # lint
flutter test          # run tests
flutter build web     # build for web
flutter run -d chrome # run in Chrome (needs web platform code changes)
```
