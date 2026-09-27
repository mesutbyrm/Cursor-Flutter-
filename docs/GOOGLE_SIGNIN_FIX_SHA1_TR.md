# Google giriş hatası (ApiException 10 / SHA-1) — telefon rehberi


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

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

## Güncelleme (2026-09-27) — 3 parmak izi zorunlu

`mobile/android/app/google-services.json` içinde şu an **yalnızca 1 adet** SHA-1
kayıtlı (`45:3B:96:...:43:99` = upload/release keystore). Bu nedenle Google girişi
**yalnızca** CI'nin ürettiği release APK'da çalışır; aşağıdaki iki kurulum biçiminde
`ApiException 10 / DEVELOPER_ERROR` verir:

| Kurulum biçimi | İmzalayan | Şu an çalışır mı? |
|---|---|---|
| `apk-latest` release APK (CI) | Upload keystore `45:3B:…:43:99` | ✅ Evet |
| Play Store'dan kurulum | **Play App Signing** (Google yeniden imzalar) | ❌ Hayır |
| `flutter run` / `apk-debug-latest` | Debug keystore | ❌ Hayır |

### Yapılması gerekenler

Firebase Console → **Proje ayarları** → Android uygulaması (`com.mesutbyrm.canlifal`)
→ **Parmak izi ekle**. Şu üç SHA-1'in hepsi kayıtlı olmalı:

1. `45:3B:96:93:AF:D0:A1:7E:6C:06:87:B1:03:67:8A:3C:EB:C2:43:99` (upload keystore — zaten var)
2. **Play App Signing SHA-1** → Play Console → Sürüm → Kurulum → **Uygulama imzalama**
3. **Debug SHA-1** → `cd mobile/android && ./gradlew signingReport`

Sonra `google-services.json` dosyasını **yeniden indirip** `GOOGLE_SERVICES_JSON_BASE64`
secret'ını güncelleyin ve **Actions → Build release APK** iş akışını çalıştırın.

### Cihazdaki APK'nın gerçek SHA-1'ini öğrenme

Artık uygulama, Google giriş hatası verdiğinde **kendi imza SHA-1'ini** hata
mesajında gösteriyor (`AppSignature` + `app_signature` MethodChannel). Ekranda
görünen değeri doğrudan Firebase'e ekleyebilirsiniz.

Bilgisayardan kontrol:

```bash
bash scripts/verify-google-signin-config.sh                 # kayıtlı SHA sayısı + uyarılar
bash scripts/verify-google-signin-config.sh /yol/uygulama.apk   # APK'nın imza SHA-1'i
```
