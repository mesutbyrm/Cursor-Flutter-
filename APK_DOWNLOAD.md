# Canlifal — Android test APK

Bu depoda APK **Git ile birlikte zorunlu taşınmaz**; aşağıdaki bağlantılardan birini kullanın.

## Doğrudan indirme (GitHub Release)

**[Son sürüm — canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/latest/download/canlifal-mobile-release.apk)**

> Bu bağlantı, en az bir kez `v*` etiketiyle Release oluşturulup APK yüklendikten sonra çalışır. Şu an 404 alıyorsanız önce [GitHub Actions](#github-actions) ile bir build alın veya bakımçı `git tag v1.0.0 && git push origin v1.0.0` ile sürüm oluşturulsun.

Belirli sürüm örneği:  
`https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/v1.0.0/canlifal-mobile-release.apk`

## GitHub Actions {#github-actions}

1. **[Build release APK iş akışı](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml)** sayfasını açın  
2. **Run workflow** → dal seçin (`main` veya Flutter kodunun olduğu dal) → çalıştırın  
3. İşlem bitince **Artifacts** → **`canlifal-social-release-apk`** ZIP  
4. ZIP içindeki **`canlifal-mobile-release.apk`** veya **`app-release.apk`** (iş akışı sürümüne göre) dosyasını kurun  

> “Bilinmeyen kaynak” izni gerekebilir; Play Store imzası yoktur, test içindir.

## Kendi bilgisayarında derle

[Flutter](https://docs.flutter.dev/get-started/install) ve Android SDK kurulu olmalı.

```bash
cd mobile
flutter pub get
flutter build apk --release
```

Çıktı: `mobile/build/app/outputs/flutter-apk/app-release.apk`

İsteğe bağlı API tabanı:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

## API

Varsayılan taban: `mobile/lib/core/config/env.dart` (`API_BASE_URL`). Uçlar: `mobile/lib/core/network/api_endpoints.dart`.
