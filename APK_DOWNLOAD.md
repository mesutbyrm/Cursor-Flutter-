# Canlifal — test APK

Bu depoda **hazır bir APK dosyası** tutulmaz (her build imza ve sürümle değişir). Aşağıdaki yollardan biriyle APK alıp telefonda test edebilirsiniz.

## 1) GitHub Actions ile indir (önerilen)

1. GitHub’da bu repo → **Actions**
2. Sol menüden **“Build release APK”** iş akışını seçin
3. **Run workflow** → dal olarak `main` veya güncel Flutter kodunun olduğu dalı seçin → **Run workflow**
4. İşlem bitince sayfadaki **Artifacts** bölümünden **`canlifal-social-release-apk`** ZIP’ini indirin
5. ZIP içindeki **`app-release.apk`** dosyasını Android’e aktarıp kurun

> Not: İlk kez yüklüyorsanız “Bilinmeyen kaynak” için yükleme izni vermeniz gerekebilir. Play Store imzası yoktur; yalnızca test içindir.

## 2) Kendi bilgisayarında derle

[Flutter](https://docs.flutter.dev/get-started/install) ve **Android Studio** (SDK + lisanslar) kurulu olmalı.

```bash
cd mobile
flutter pub get
flutter build apk --release
```

Çıktı dosyası:

`mobile/build/app/outputs/flutter-apk/app-release.apk`

İsteğe bağlı API adresi:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.senin-domain.com
```

## API

Uygulama varsayılan olarak `lib/core/config/env.dart` içindeki tabanı kullanır; production için `API_BASE_URL` ile kendi backend’inizi verin. Uç yollar: `mobile/lib/core/network/api_endpoints.dart`.
