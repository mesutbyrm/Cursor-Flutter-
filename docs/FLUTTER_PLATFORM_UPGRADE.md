# Flutter Platform & Performans Yükseltmesi

**Sürüm:** 1.0.122+155  
**Tarih:** 2026-08-03

---

## 1. SDK & Araç Zinciri

| Bileşen | Sürüm |
|---------|--------|
| Flutter (stable) | **3.44.8** — `mobile/.flutter-version` |
| Dart | `3.12.x` (`>=3.8.0 <4.0.0`) |
| Android Gradle Plugin | 8.13.0 |
| Gradle | 8.14 |
| Kotlin | 2.2.21 |
| Java | 17 |
| compileSdk / targetSdk | 36 |
| minSdk | **26** (Android 8.0+) |
| iOS minimum | **15.0** |
| NDK | Flutter SDK ile uyumlu (`flutter.ndkVersion`) |

CI: `.github/workflows/ci.yml`, `build-apk.yml` → `flutter-version: '3.44.8'`

---

## 2. Cihaz Uyumluluğu

### Android
- **API 26–36** desteklenir (Android 8 → Android 16)
- **ABI:** `arm64-v8a` (modern telefonlar), `armeabi-v7a` (eski ARM), `x86_64` (emülatör/tablet)
- Release: `--split-per-abi` — her mimari için ayrı APK (daha küçük indirme)
- `apk-latest` yayını: **arm64-v8a** (çoğu cihaz)

### Tablet & katlanır
- `android:resizeableActivity="true"`
- `supports-screens` — large/xlarge/anyDensity
- `supportsPictureInPicture` — mini oynatıcı / arka plan müzik

### Performans profili
- `DevicePerfTuning.apply()` — düşük çekirdek sayılı cihazlarda image cache 48MB
- Soğuk açılış: bootstrap cap **1 sn** (`StartupPerf.bootstrapCap`)
- Deferred init: Firebase, Crashlytics, OneSignal, AdMob runApp sonrası

---

## 3. Build Optimizasyonu (Release)

| Özellik | Durum |
|---------|--------|
| R8 full mode | `android.enableR8.fullMode=true` |
| ProGuard optimize | `proguard-android-optimize.txt` |
| Resource shrink | `isShrinkResources = true` |
| Code minify | `isMinifyEnabled = true` |
| Tree-shake icons | CI `--tree-shake-icons` |
| Dart obfuscate | CI `--obfuscate` |
| Split ABI | CI `--split-per-abi` |
| AAB split (abi/density/lang) | `bundle { }` blok |

---

## 4. Backend Senkronizasyon (mevcut)

- JWT refresh: `POST /api/auth/mobile-refresh`
- SSE: tek hub, exponential backoff, 45s heartbeat
- Gift Engine SSE + socket yedek
- HTTP retry: kılavuz §7
- Offline: Hive / secure storage / image disk cache

---

## 5. Sesli Oda Müzik (web paritesi)

| Özellik | Flutter |
|---------|---------|
| !istek / sanatçı-şarkı | ✅ |
| YouTube arama | ✅ `MusicSearchPickerSheet` |
| Kuyruk / sıradaki / geç | ✅ DJ API + `VoiceRoomDjPlayer` |
| Duraklat / devam | ✅ |
| Oda sahibi DJ yetkisi | ✅ `VoiceRoomPermissions` |
| Arka plan çalma | ✅ `audio_service` foreground |
| Kilit ekranı kontrolü | ✅ `MediaItem` + notification |
| Kulaklık tuşları | ✅ `MediaButtonReceiver` |
| Mini oynatıcı (oda dışı) | ✅ `VoiceRoomGlobalMusicBar` |
| Videolu / sesli mod | ✅ 1.0.120+ |
| Oda geneli senkron | ✅ SSE `onDjUpdate` / `onSong` |

---

## 6. Crashlytics & Performans Log

- `CrashReportingBootstrap` — Firebase Crashlytics + Sentry
- `AppPerfMetrics` — API/route süre ölçümü
- `VoiceRoomDebugLog` — oda diagnostik

---

## 7. Kalan / Manuel Test

- [ ] `flutter pub upgrade` — CI'da otomatik
- [ ] 3 ABI APK boyutları
- [ ] Android 8 fiziksel cihaz
- [ ] Katlanır (Samsung) layout
- [ ] 120Hz scroll jank profili (DevTools)
- [ ] Kullanılmayan dependency audit (`dart pub deps`)

---

*Backend değiştirilmedi. API: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`*
