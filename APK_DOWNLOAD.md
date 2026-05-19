# Canlifal — Android test APK

Bu depoda APK **Git ile birlikte taşınmaz**; aşağıdaki yollardan biriyle alıp `downloads/` klasörüne kopyalayabilirsiniz (isteğe bağlı, bkz. [`downloads/README.md`](downloads/README.md)).

## Sabit indirme: GitHub Sürümü (önerilen)

Her `v*` etiketi (ör. `v1.0.0`) ile tetiklenen iş akışı, sürüme **`canlifal-mobile-release.apk`** adıyla dosya ekler. **Son yayınlanan sürüm** için doğrudan indirme:

**[Son sürüm APK — canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/latest/download/canlifal-mobile-release.apk)**

> Henüz hiç GitHub Release yoksa veya bu dosya eklenmemişse bağlantı 404 verir. O zaman aşağıdaki “Etiket ile sürüm oluşturma” adımını bir kez uygulayın.

### Etiket ile sürüm oluşturma (bakımçılar)

```bash
git checkout main
git pull
git tag v1.0.0   # sürüm numarasını güncelleyin
git push origin v1.0.0
```

GitHub Actions (`Build release APK`) etiket push’unda APK üretir ve aynı etiketin **Releases** sayfasına yükler. Belirli bir sürüme sabit bağlantı örneği:

`https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/v1.0.0/canlifal-mobile-release.apk`

İndirdikten sonra yerel yansıma için:

```bash
./scripts/copy-apk-to-downloads.sh /path/to/indirilen/canlifal-mobile-release.apk
```

(kaynak yolu verilmezse varsayılan olarak `mobile/build/.../app-release.apk` kullanılır.)

## GitHub Actions (Artifacts)

1. Repo → **Actions** → **Build release APK**
2. **Run workflow** ile isteğe bağlı çalıştırın veya `main` dalına `mobile/**` değişikliği itin
3. İş bitince **Artifacts** → `canlifal-social-release-apk` ZIP → içindeki APK

## Kendi bilgisayarında derle

[Flutter](https://docs.flutter.dev/get-started/install) ve Android SDK kurulu olmalı.

```bash
cd mobile
flutter pub get
flutter build apk --release
```

Çıktı: `mobile/build/app/outputs/flutter-apk/app-release.apk`

APK’yı `downloads/` altında sabit isimle kopyalamak için (kök dizinden):

```bash
./scripts/copy-apk-to-downloads.sh
```

İsteğe bağlı API tabanı:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

## Güvenlik notu

Test APK’sıdır; Play Store imzası yoktur. İlk kurulumda Android “bilinmeyen kaynak” izni gerekebilir.
