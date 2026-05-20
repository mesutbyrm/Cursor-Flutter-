# Canlifal

Flutter sosyal medya ve canlı yayın istemcisi — **https://canlifal.com** API ile çalışır.

| Klasör | Açıklama |
|--------|----------|
| [`mobile/`](mobile/) | Ana Flutter uygulaması (APK buradan derlenir) |
| [`api/`](api/) | İsteğe bağlı yerel JWT REST API (Node.js + Prisma) |

## 📱 APK İndirme

| Yöntem | Link |
|--------|------|
| **Actions artifact** (önerilen) | [Build release APK → Artifacts](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) |
| **Releases sayfası** | [Tüm sürümler](https://github.com/mesutbyrm/Cursor-Flutter-/releases) |
| **gh CLI** | `gh release download apk-latest --repo mesutbyrm/Cursor-Flutter- --pattern "*.apk"` |

> ⚠️ Repo private olduğu için doğrudan indirme linkleri çalışmaz. Detaylar: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)

## Hızlı başlangıç

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

Mimari ve uç noktalar: [`mobile/README.md`](mobile/README.md) · Cursor ortamı: [`AGENTS.md`](AGENTS.md)
