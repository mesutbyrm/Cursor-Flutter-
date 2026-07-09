# Google giriş hatası (ApiException 10 / SHA-1) — telefon rehberi

## Neden oluyor?

Play Console’daki SHA-1’leri Firebase’e eklemeniz **doğruydu**.  
Ama GitHub’dan indirdiğiniz APK şu iki nedenle uyuşmuyor:

1. **CI debug imza kullanıyor** — release keystore secret’ları GitHub’da yok
2. **Eski derleme** — `GOOGLE_SERVICES_JSON_BASE64` o derlemede boştu

Yani telefondaki APK’nın imzası ≠ Firebase’deki SHA-1.

## Çözüm — 3 secret + yeni derleme

GitHub → **Settings** → **Secrets and variables** → **Actions**

### Secret 1 — `GOOGLE_SERVICES_JSON_BASE64`

Telefonda indirdiğiniz **güncel** `google-services.json` dosyasının **tüm içeriğini** yapıştırın (`{` ile başlar).

### Secret 2–5 — Release keystore (zorunlu)

| Secret adı | Değer |
|------------|--------|
| `ANDROID_KEYSTORE_BASE64` | `release.keystore` dosyasının base64’ü |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore şifresi |
| `ANDROID_KEY_ALIAS` | `canlifal-upload` |
| `ANDROID_KEY_PASSWORD` | Anahtar şifresi |

Keystore bilgileri: `mobile/android/KEYSTORE_CREDENTIALS.local.txt` (geliştirme ortamında).

### Yeni APK derle

**Actions** → **Build release APK** → **Run workflow** → `main`

Yeşil tikten sonra:  
https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

### Firebase’de olması gereken SHA-1

| Kaynak | SHA-1 |
|--------|--------|
| Release keystore | `45:3B:96:93:AF:D0:A1:7E:6C:06:87:B1:03:67:8A:3C:EB:C2:43:99` |
| Play App Signing | Play Console → Uygulama imzalama |

İkisi de Firebase **Proje ayarları** → Android uygulaması → **Parmak izi ekle** altında olmalı.
