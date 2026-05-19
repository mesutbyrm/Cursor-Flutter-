# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

Flutter mobile client (Android/iOS) for **Canlifal Social**, a Turkish social media / live-streaming platform. All source lives under `mobile/`. There is no backend code in this repo — the app connects to `https://canlifal.com` by default.

### Key commands (run from `mobile/`)

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint | `dart analyze` |
| Test | `flutter test` |
| Debug APK | `flutter build apk --debug` |
| Release APK | `flutter build apk --release` |
| Custom backend | `flutter run --dart-define=API_BASE_URL=https://your-api.example.com` |

### Environment notes

- **Flutter SDK** is at `/opt/flutter` (v3.41.9 stable, Dart 3.11.5).
- **Android SDK** is at `/opt/android-sdk`. You must export `ANDROID_HOME=/opt/android-sdk` and add `$ANDROID_HOME/cmdline-tools/latest/bin` and `$ANDROID_HOME/platform-tools` to `PATH` before running Gradle-based builds.
- **Java 21** is the system JDK; the project targets Java 17 compatibility in Gradle — this works fine.
- **Web target** does not render correctly because the app uses `path_provider` / `PersistCookieJar` (filesystem-based), which are mobile-only. `flutter build web` compiles but the app fails at runtime on web. Use Android APK builds for verification.
- **No Android emulator** is available in Cloud Agent VMs, so you cannot `flutter run` on device. Build verification (`flutter build apk`) is the primary validation path.
- The first Gradle build downloads NDK 28.2, CMake 3.22.1, and Android Platform 34 automatically — this can take ~3 minutes.
- API endpoints are defined in `lib/core/network/api_endpoints.dart`; configuration in `lib/core/config/env.dart`.
