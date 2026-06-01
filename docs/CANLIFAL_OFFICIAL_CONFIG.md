# canlifal.com — resmi Flutter / Firebase yapılandırması

## İndirme bağlantıları

| Dosya | URL | Hedef (repo) |
|-------|-----|----------------|
| Flutter API dokümantasyonu | https://canlifal.com/canlifal-flutter-api-docs.txt | `docs/canlifal-flutter-api-docs.txt` |
| Android `google-services.json` | https://canlifal.com/google-services.json | `mobile/android/app/google-services.json` |
| Firebase Admin SDK | https://canlifal.com/canlifal-firebase-adminsdk.json | `api/canlifal-firebase-adminsdk.json` |

## Otomatik kurulum

```bash
bash scripts/sync-canlifal-config.sh
```

Başarılı olursa Firebase Dart seçenekleri üretilir ve APK derlemesinde FCM etkinleşir.

## Site notu

`canlifal-flutter-api-docs.txt` kök URL’si canlıda **düz metin** döner (güncellemek için site `public/` veya repo `docs/` + `scripts/sync-canlifal-config.sh`).

`google-services.json` gibi diğer kök dosyalar hâlâ HTML dönebilir; o zaman Firebase Console’dan indirip `mobile/android/app/` altına kopyalayın.

## Sunucu (API)

`api/.env` (repoya yazılmaz):

```env
GOOGLE_APPLICATION_CREDENTIALS=./canlifal-firebase-adminsdk.json
ONESIGNAL_APP_ID=578518ed-7b16-46a9-a1e6-7692d3ba55d8
ONESIGNAL_REST_API_KEY=os_v2_app_...
```

Admin SDK JSON’u **asla** mobil uygulamaya veya GitHub’a eklemeyin.

## CI / GitHub Actions

İsteğe bağlı secret: `GOOGLE_SERVICES_JSON_BASE64` — `google-services.json` içeriğinin base64’ü.

Build APK iş akışı secret varsa dosyayı yazar ve `--dart-define` ile derler.

## Push (OneSignal + FCM)

1. `google-services.json` → `mobile/android/app/`
2. OneSignal panel → Android FCM → aynı Firebase projesi, paket `com.mesutbyrm.canlifal`
3. Uygulama Kimliği: `578518ed-7b16-46a9-a1e6-7692d3ba55d8` (mobil varsayılan)

Ayrıntı: `mobile/docs/ONESIGNAL_SETUP.md`, `mobile/docs/FIREBASE_SETUP.md`
