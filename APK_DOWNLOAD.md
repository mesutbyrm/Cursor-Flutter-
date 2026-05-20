# Canlifal — Android APK indirme

## Doğrudan indirme (önerilen)

**Son `main` derlemesi (sabit bağlantı):**

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

> 404 alırsanız: [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) → **Run workflow** → dal **`main`** → işlem bitince `apk-latest` güncellenir.

## Öne çıkan sürümler

| Sürüm | İndirme |
|-------|---------|
| **apk-latest** (otomatik, `main` son derleme) | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |
| **Kaynak sürüm (dal)** | `mobile/pubspec.yaml` → `version:` (ör. **1.0.7+8** sesli oda native) |
| **v1.0.6** (ana sayfa + navbar) | [Releases](https://github.com/mesutbyrm/Cursor-Flutter-/releases) |
| v1.0.5 | [Releases](https://github.com/mesutbyrm/Cursor-Flutter-/releases/tag/v1.0.5) |
| v1.0.4 sesli oda (neon UI) | [canlifal-v104-voice-7009.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-v104-voice-7009/canlifal-v104-voice-7009.apk) |

Tüm sürümler: https://github.com/mesutbyrm/Cursor-Flutter-/releases

## Kurulum

1. APK’yı Android cihazınıza indirin.
2. **Bilinmeyen kaynaklardan yükleme**ye izin verin.
3. Uygulamayı açın ve **canlifal.com** ile giriş yapın (oturum API için gerekli).

## GitHub Actions (artifact)

1. [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml)
2. **Run workflow** → dal seçin
3. **Artifacts** → `canlifal-social-release-apk` → ZIP içindeki `canlifal-mobile-release.apk`

## Yerelde derleme

```bash
cd mobile
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

Çıktı: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## API yapılandırması

- Varsayılan: `https://canlifal.com` — `mobile/lib/core/config/env.dart`
- Uçlar: `mobile/lib/core/network/api_endpoints.dart`
