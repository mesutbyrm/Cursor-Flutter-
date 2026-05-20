# Canlifal — Agent talimatları

## Cursor Cloud specific instructions

### Proje düzeni

- **Ana uygulama:** `mobile/` — `canlifal_social` Flutter paketi; tüm geliştirme ve CI komutları buradan çalıştırılır.
- **Yerel API:** `api/` — Node.js + Express + Prisma JWT API (isteğe bağlı; üretimde `https://canlifal.com` kullanılabilir).

### Ortam

- Flutter SDK: `/opt/flutter/bin` (v3.41.x)
- Node.js: `nvm` — `api/` bağımlılıkları için
- Güncelleme: `.cursor/environment.json` → `bash scripts/cursor-update.sh; exit 0` (betik de her zaman **exit 0**; adımlar zaman aşımıyla atlanabilir)
- Başlangıç: `bash scripts/cursor-start.sh; exit 0`
- Hata görürseniz: yeni agent oturumu başlatın veya **Rebuild environment**
- **Prisma migrate** yalnızca `api/.env` içinde `DATABASE_URL` varsa çalışır

### Android derleme (Cloud Agent)

- `ANDROID_HOME=/opt/android-sdk`; PATH'e `cmdline-tools/latest/bin` ve `platform-tools` ekleyin
- Java 21 sistem JDK; proje Gradle'da Java 17 uyumluluğu
- Emülatör yok — doğrulama: `cd mobile && flutter build apk --debug`
- İlk Gradle derlemesi NDK/platform indirebilir (~3 dk)

### Komutlar (`mobile/`)

| Görev | Komut |
|-------|--------|
| Bağımlılık | `flutter pub get` |
| Lint | `dart analyze` |
| Test | `flutter test` |
| Debug APK | `flutter build apk --debug` |
| Özel API | `flutter run --dart-define=API_BASE_URL=https://your-api.example.com` |

### Web hedefi

`path_provider` / `PersistCookieJar` nedeniyle web'de tam çalışmaz; mobil/APK doğrulaması tercih edin.

### API yapılandırması

- Üretim varsayılanı: `https://canlifal.com` (`mobile/lib/core/config/env.dart`)
- Uç noktalar: `mobile/lib/core/network/api_endpoints.dart`
- Yerel JWT API: `API_BASE_URL=http://127.0.0.1:3000/api/v1` (emülatörde `10.0.2.2`)

### Dikkat

- Firebase yapılandırma dosyaları repoda yok; uygulama eksikliği tolere eder
- `api/node_modules/` commit edilmez

### APK — her yanıtın sonunda (kullanıcı isteği)

Kullanıcı mesajlarına cevap verirken **en sonda** şu sabit indirme bağlantısını ekle; sürümü `mobile/pubspec.yaml` → `version:` satırından yaz:

- **İndir:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
- **404 / eski build:** [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) → `main` → `apk-latest` güncellenir
- Ayrıntı: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)
