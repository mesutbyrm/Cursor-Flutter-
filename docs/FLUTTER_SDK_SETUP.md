# Flutter SDK Cloud Environment Setup

**For:** Running tests in cloud environment (CI/CD or agent sessions)  
**Last Updated:** 2026-09-24

---

## Quick Start

### Option 1: Automatic Setup (Recommended)
```bash
# Flutter SDK otomatik yüklenecek
bash scripts/cursor-update.sh

# Sonra testleri çalıştır
bash scripts/run-flutter-tests.sh
```

### Option 2: Manual Setup
```bash
# 1. Flutter SDK klonla
git clone -b stable --depth 1 https://github.com/flutter/flutter.git ~/flutter

# 2. PATH'e ekle
export PATH="$HOME/flutter/bin:$PATH"

# 3. Dependencies yükle
cd mobile && flutter pub get

# 4. Testleri çalıştır
bash scripts/run-flutter-tests.sh
```

---

## What Gets Installed

### Flutter SDK
- **Location:** `$HOME/flutter` (or `/opt/flutter` if available)
- **Version:** From `mobile/.flutter-version` (currently stable 3.44.x)
- **Size:** ~1.5 GB (includes Dart SDK, tools)

### Dart Tools
- Dart compiler
- Pub package manager
- Analysis tools
- Test runner

### Dependencies
```bash
cd mobile && flutter pub get
# Installs 100+ packages from pubspec.yaml
```

---

## Environment Variables

### Automatic (via cursor-update.sh)
```bash
# These are set automatically
export PATH="$HOME/flutter/bin:$PATH"
export FLUTTER_ROOT="$HOME/flutter"
```

### Manual (if needed)
```bash
export FLUTTER_ROOT="$HOME/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export FLUTTER_CHANNEL="stable"
export FLUTTER_VERSION="3.44.x"
```

---

## Running Tests

### All Tests
```bash
bash scripts/run-flutter-tests.sh
```
Runs:
- Phase 4: Unit tests (16 cases)
- Phase 4: Integration tests (7 cases)
- Phase 5: PK integration tests (8 cases)

### Single Test File
```bash
cd mobile
flutter test test/features/voice_hub/room_session_manager_test.dart
```

### With Output Filtering
```bash
# Show only test names, not individual cases
flutter test --reporter=compact

# Verbose output with timing
flutter test --reporter=expanded --verbose

# JSON output for parsing
flutter test --reporter=json > test-results.json
```

---

## CI Integration (GitHub Actions)

### Example: .github/workflows/test.yml
```yaml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter SDK
        run: |
          git clone -b stable --depth 1 https://github.com/flutter/flutter.git ~/flutter
          echo "$HOME/flutter/bin" >> $GITHUB_PATH
      
      - name: Install dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Run tests
        run: bash scripts/run-flutter-tests.sh
      
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: mobile/test-results.json
```

---

## Troubleshooting

### Issue: "flutter: command not found"

**Solution 1:** Run cursor-update
```bash
bash scripts/cursor-update.sh
```

**Solution 2:** Add to PATH manually
```bash
export PATH="$HOME/flutter/bin:$PATH"
which flutter
```

**Solution 3:** Check Flutter installation
```bash
git clone -b stable --depth 1 https://github.com/flutter/flutter.git ~/flutter
~/flutter/bin/flutter --version
```

### Issue: "Pub cache not writable"

**Solution:** Grant permissions
```bash
mkdir -p ~/.pub-cache
chmod -R 755 ~/.pub-cache
```

### Issue: "pubspec.yaml not found"

**Solution:** Run from correct directory
```bash
cd /path/to/Cursor-Flutter-/mobile
flutter pub get
```

### Issue: "Test file not found"

**Solution:** Check file path
```bash
ls -la test/features/voice_hub/room_session_manager_test.dart
flutter test test/features/voice_hub/room_session_manager_test.dart
```

### Issue: "SDK version mismatch"

**Solution:** Update Flutter to correct version
```bash
cd ~/flutter
git fetch
git checkout stable  # or specific version from mobile/.flutter-version
flutter pub get
```

---

## Performance Notes

### First Run
- Flutter SDK clone: 2-3 minutes
- Dependencies: 1-2 minutes
- Tests: 2-3 minutes
- **Total:** 5-8 minutes

### Subsequent Runs
- Tests only: 1-2 minutes
- No download needed

### Memory Requirements
- Flutter SDK: ~1.5 GB
- Dart cache: ~500 MB
- Gradle cache: ~1 GB
- **Total:** ~3 GB disk space

### Network
- Initial clone: 200-400 MB
- Pub packages: 50-100 MB
- Subsequent runs: Minimal

---

## Verification Steps

### 1. Flutter SDK Installed
```bash
flutter --version
# Expected: Flutter X.X.X • channel stable
```

### 2. Dart SDK Available
```bash
dart --version
# Expected: Dart SDK version X.X.X
```

### 3. Pub Works
```bash
pub --version
# Expected: Pub X.X.X
```

### 4. Project Dependencies
```bash
cd mobile
flutter pub get
# Expected: all packages listed in pubspec.yaml installed
```

### 5. Tests Discoverable
```bash
find mobile/test -name "*_test.dart" | wc -l
# Expected: 60+ test files (including Phase 4-6)
```

### 6. Run Sample Test
```bash
cd mobile
flutter test test/features/voice_hub/room_session_manager_test.dart
# Expected: 16 test cases pass
```

---

## Post-Setup Checklist

- [ ] Flutter SDK installed (`flutter --version` works)
- [ ] Dart available (`dart --version` works)
- [ ] Dependencies installed (`flutter pub get` succeeds)
- [ ] Tests discoverable (`find test -name *_test.dart`)
- [ ] Sample test passes (`flutter test room_session_manager_test.dart`)
- [ ] All tests pass (`bash scripts/run-flutter-tests.sh`)

---

## Cleanup

### Remove Flutter SDK (if needed)
```bash
rm -rf ~/flutter
unset FLUTTER_ROOT
# Remove from PATH
```

### Clear Cache
```bash
rm -rf ~/.pub-cache
rm -rf ~/.flutter
rm -rf ~/.dart
```

### Clean Build Artifacts
```bash
cd mobile
flutter clean
rm -rf build/
```

---

## Documentation Links

- [Flutter Official Docs](https://flutter.dev/docs)
- [Flutter CI/CD](https://flutter.dev/docs/deployment/cd)
- [Dart Testing](https://dart.dev/guides/testing)
- [Project Tests](../docs/PHASE_6_VALIDATION.md#1-test-coverage-summary)

---

**Status:** ✅ Ready for cloud environment setup  
**Last Verified:** 2026-09-24

