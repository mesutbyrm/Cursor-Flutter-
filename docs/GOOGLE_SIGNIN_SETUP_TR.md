# Google ile giriş — Flutter APK kurulumu

Canlifal mobil uygulaması Google girişinde şu akışı kullanır:

1. Native **Google Sign-In** → `idToken`
2. `POST https://canlifal.com/api/auth/mobile-google` → JWT (`accessToken`, `user`)

APK’da giriş çalışmıyorsa genelde **Web OAuth client ID** derlemeye gömülmemiştir veya Firebase’de **SHA-1** eksiktir.

## Sizden gerekenler

| # | Ne | Nereye |
|---|-----|--------|
| 1 | `google-services.json` (Firebase Android uygulaması) | `mobile/android/app/google-services.json` |
| 2 | OAuth **Web** client ID (`…apps.googleusercontent.com`, `client_type: 3`) | `google-services.json` içinde veya CI secret |
| 3 | Debug + release **SHA-1** parmak izleri | Firebase Console → Android app → SHA certificate fingerprints |
| 4 | (CI) Base64 `google-services.json` | GitHub secret: `GOOGLE_SERVICES_JSON_BASE64` |

### SHA-1 almak

```bash
cd mobile/android && ./gradlew signingReport
```

`Variant: debug` ve release keystore için çıkan **SHA1** değerlerini Firebase’e ekleyin. Google Cloud Console’da Android OAuth istemcisinde de aynı SHA-1 olmalı.

### Web client ID nerede?

Firebase Console → **Authentication** → Sign-in method → **Google** → Web SDK configuration’daki **Web client ID**.

Veya `google-services.json` içinde:

```json
"oauth_client": [
  { "client_id": "….apps.googleusercontent.com", "client_type": 3 }
]
```

## Yerel derleme

```bash
# 1) Dosyayı koyun (site HTML dönerse Firebase’den indirin)
bash scripts/sync-canlifal-config.sh
# veya elle: mobile/android/app/google-services.json

# 2) Dart sabitlerini üretin
bash scripts/generate-firebase-options.sh

# 3) APK (Web client ID otomatik --dart-define olur)
cd mobile
flutter build apk --release $(bash ../scripts/print-firebase-dart-defines.sh)
```

Manuel define:

```bash
flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
```

## GitHub Actions (apk-latest)

Workflow: `.github/workflows/build-apk.yml`

1. Secret **`GOOGLE_SERVICES_JSON_BASE64`**: `base64 -w0 mobile/android/app/google-services.json`
2. Build adımı `print-firebase-dart-defines.sh` ile `GOOGLE_SERVER_CLIENT_ID` ekler.

Secret yoksa APK Firebase/Google olmadan derlenir; uygulama açılır ama **Google ile giriş** yapılandırılmamış hatası verir.

## Sunucu (canlifal.com)

Endpoint hazır: `POST /api/auth/mobile-google` body: `{ "idToken": "…" }`.

Geçersiz token → `401` *Geçersiz Google token*. Ek backend değişikliği gerekmez.

## Site tarafı (öneri)

`https://canlifal.com/google-services.json` şu an HTML dönebiliyor. Next.js `public/google-services.json` olarak statik yayınlayın; böylece `scripts/sync-canlifal-config.sh` otomatik indirir.

## Hata mesajları

| Mesaj | Olası neden |
|-------|-------------|
| Google giriş yapılandırılmamış | `GOOGLE_SERVER_CLIENT_ID` yok, `google-services.json` yok |
| Google kimlik jetonu alınamadı | Web client ID yanlış / eksik |
| SHA-1 / OAuth yapılandırması (kod 10) | Firebase’de SHA-1 yok veya yanlış keystore |
| Geçersiz Google token (401) | Sunucudaki Google client ile mobil Web client uyuşmuyor |

## Kod referansları

- `mobile/lib/core/config/google_auth_config.dart`
- `mobile/lib/features/auth/data/datasources/native_auth_datasource.dart`
- `scripts/print-firebase-dart-defines.sh`
- `scripts/generate-firebase-options.sh`
