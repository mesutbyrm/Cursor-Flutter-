# Release APK imzalama — GitHub Actions

Release APK **yalnızca upload keystore** ile imzalanır. Debug imza veya secret eksikliğinde derleme **kasıtlı olarak durur**.

## Zorunlu GitHub Secrets

Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Açıklama |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | `release.keystore` dosyasının base64 (tek satır, boşluksuz) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore şifresi |
| `ANDROID_KEY_ALIAS` | Genelde `canlifal-upload` |
| `ANDROID_KEY_PASSWORD` | Anahtar şifresi |

İsteğe bağlı (Google Sign-In):

| Secret | Açıklama |
|--------|----------|
| `GOOGLE_SERVICES_JSON_BASE64` | `google-services.json` ham içerik veya base64 |

## Keystore base64 oluşturma (yerel)

```bash
bash scripts/encode-android-keystore-secret.sh mobile/android/app/release.keystore
```

Çıkan tek satırı `ANDROID_KEYSTORE_BASE64` secret'ına yapıştırın.

**Keystore dosyasını ve `key.properties` dosyasını repoya commit etmeyin.**

## Firebase SHA-1

Release keystore SHA-1, `google-services.json` içindeki `certificate_hash` ile eşleşmeli.

Beklenen (upload keystore):

`45:3B:96:93:AF:D0:A1:7E:6C:06:87:B1:03:67:8A:3C:EB:C2:43:99`

Firebase Console → Proje ayarları → Android uygulaması → **SHA sertifika parmak izleri** → bu SHA-1 ekli olmalı.

CI, keystore oluşturulduktan sonra bu eşleşmeyi doğrular (`GOOGLE_SERVICES_JSON_BASE64` set ise).

## Workflow adımları

1. `ci-release-signing-preflight.sh` — dört secret var mı
2. Release gate (analyze, test, API)
3. `google-services.json` (secret varsa)
4. `ci-setup-release-keystore.sh` — decode, `key.properties`, `keytool` doğrulama, SHA-1 kontrolü
5. `flutter build apk --release`
6. `verify-release-apk-signature.sh` — debug imza reddi

## Yerel release derleme

```bash
export ANDROID_KEYSTORE_BASE64="$(base64 -w0 mobile/android/app/release.keystore)"
export ANDROID_KEYSTORE_PASSWORD='...'
export ANDROID_KEY_ALIAS='canlifal-upload'
export ANDROID_KEY_PASSWORD='...'
bash scripts/ci-setup-release-keystore.sh
cd mobile && flutter build apk --release
bash ../scripts/verify-release-apk-signature.sh build/app/outputs/flutter-apk/app-release.apk
```
