# Canlifal uygulamasını çalıştırma (kolay rehber)

Benim (bulut ortamının) sizin telefonunuzda uygulamayı açması mümkün değil. Aşağıdaki yollardan **birini** seçin.

## Yol 1 — Hazır APK (en kolay, bilgisayar bilgisi az)

1. Telefonda **Bilinmeyen kaynaklardan yükleme**ye izin verin.
2. APK indirin (en güncel, **1.0.119+121** — sesli oda + oda komutları + native API):
   - https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk  
   - GitHub **Actions → Build release APK** yeşil olduktan sonra da aynı link güncellenir.
3. Dosyaya dokunup kurun.
4. Uygulamayı açın → Giriş yapın → canlifal.com hesabınızla kullanın.

> En güncel sürüm için GitHub **Actions → Build release APK** işinin bitmesini bekleyin (aşağıdaki Yol 3).

## Yol 2 — Bilgisayarınızda geliştirici modu (Android Studio)

1. [Flutter kurulumu](https://docs.flutter.dev/get-started/install) (Windows/Mac).
2. [Android Studio](https://developer.android.com/studio) + bir emülatör **veya** USB ile telefon (USB hata ayıklama açık).
3. Terminalde:

```bash
cd mobile
chmod +x calistir.sh
./calistir.sh
```

Windows’ta:

```bat
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

## Yol 3 — GitHub’dan otomatik APK (güncel kod)

Depoda `main` veya sesli oda dalı push edildiğinde APK üretilir.  
Sizin için tetiklenmiş iş: **Actions** sekmesi → **Build release APK** → yeşil tik → **Artifacts** veya Release `apk-latest`.

## Sık sorunlar

| Sorun | Çözüm |
|--------|--------|
| `No devices found` | Emülatör açın veya telefonu USB ile bağlayın |
| Giriş olmuyor | İnternet + canlifal.com hesabı; uygulamayı kapatıp açın |
| Sesli oda ses yok | Mikrofon izni; aynı odaya web’den de giriliyorsa güncel APK kullanın |

Sürüm: `pubspec.yaml` içindeki `version` satırına bakın (ör. 1.0.119+121).
