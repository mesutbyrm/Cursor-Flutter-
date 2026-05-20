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
- **Java 21** is the system JDK; the project targets Java 17 compatibility in Gradle — this works fine.
- **Web target** does not render correctly because the app uses `path_provider` / `PersistCookieJar` (filesystem-based), which are mobile-only. `flutter build web` compiles but the app fails at runtime on web. Use Android APK builds for verification.
- **No Android emulator** is available in Cloud Agent VMs, so you cannot `flutter run` on device. Build verification (`flutter build apk`) is the primary validation path.
- API endpoints are defined in `lib/core/network/api_endpoints.dart`; configuration in `lib/core/config/env.dart`.

### Android SDK setup (one-time, per session)

The Android SDK is **not** pre-installed. If you need APK builds, install it:

```bash
sudo mkdir -p /opt/android-sdk && sudo chown $(whoami) /opt/android-sdk
cd /tmp && curl -sL -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q -o cmdline-tools.zip -d /opt/android-sdk/cmdline-tools-tmp
mkdir -p /opt/android-sdk/cmdline-tools/latest
mv /opt/android-sdk/cmdline-tools-tmp/cmdline-tools/* /opt/android-sdk/cmdline-tools/latest/
rm -rf /opt/android-sdk/cmdline-tools-tmp cmdline-tools.zip

export ANDROID_HOME=/opt/android-sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
yes | sdkmanager --licenses
sdkmanager "platforms;android-36" "build-tools;36.0.0" "platform-tools"
flutter config --android-sdk=/opt/android-sdk
```

The first `flutter build apk` will additionally auto-download NDK 28.2, CMake 3.22.1, and Android Platform 34 (~3 min).
