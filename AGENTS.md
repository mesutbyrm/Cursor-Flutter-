# Canlifal Mobile

## Cursor Cloud specific instructions

### Environment

- Flutter SDK is installed at `/opt/flutter`. The PATH is configured in `~/.bashrc`.
- Dart SDK constraint: `>=3.8.0 <4.0.0` (Flutter 3.41.x stable satisfies this).
- No backend services or databases are required; the app uses seed/mock data (`CanlifalSeed` class) for all features and gracefully falls back to it if API calls fail.

### Development commands

Standard commands are documented in `README.md`. Quick reference:

```bash
flutter pub get        # Install dependencies
flutter analyze        # Lint / static analysis
flutter test           # Run widget/unit tests
flutter build web      # Build web release
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0  # Run web dev server
```

### Key caveats

- The project imports screen files from `lib/src/screens/`. These must be present for analysis and builds to pass.
- Android/iOS platform directories are on the `cursor/canlifal-flutter-app-1c13` branch but not on `main`. For mobile builds, checkout those platform dirs or use web builds for development validation.
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are not included in the repo. The app handles their absence gracefully via try/catch in `AppBootstrap.initialize()`.
- External API/WebSocket URLs are configured via `--dart-define` flags (see README). Without them, the app defaults to seed data.
- The `flutter run -d web-server` command serves the app in debug mode with hot reload. Use port 8080 for consistency.
