# Canlifal

Flutter sosyal medya ve canlı yayın istemcisi — **https://canlifal.com** API ile çalışır.

| Klasör | Açıklama |
|--------|----------|
| [`mobile/`](mobile/) | Ana Flutter uygulaması (APK buradan derlenir) |
| [`api/`](api/) | İsteğe bağlı yerel JWT REST API (Node.js + Prisma) |

## Android APK indir

| Bağlantı | Açıklama |
|----------|----------|
| **[canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk)** | Her zaman son `main` derlemesi (`apk-latest`) |
| **[Sürüm arşivi](https://github.com/mesutbyrm/Cursor-Flutter-/releases)** | Tüm test APK’ları (**güncel: 1.0.75+77**, `apk-latest`) |

Ayrıntılar: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)

## Hızlı başlangıç

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

Mimari ve uç noktalar: [`mobile/README.md`](mobile/README.md) · Cursor ortamı: [`AGENTS.md`](AGENTS.md)
