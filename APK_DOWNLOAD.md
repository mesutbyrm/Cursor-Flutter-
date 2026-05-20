# Canlifal — Android APK İndirme

## 📱 Sabit indirme linki (her zaman son sürüm)

Aşağıdaki link **her zaman** `main` dalındaki en son başarılı derlemeyi gösterir:

**[⬇️ canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk)**

> 404 alıyorsanız: GitHub → **Actions** → **Build release APK** → **Run workflow** → `main` seçin → bitsin.

---

## 🏷️ Versiyonlu sürümler

Her başarılı build otomatik olarak versiyonlu bir release oluşturur:

```
https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/v1.1.0-build.{N}/canlifal-mobile-v1.1.0-build.{N}.apk
```

`{N}` = GitHub Actions build numarası (her çalışmada +1 artar).

**Tüm sürümler:** [Releases sayfası](https://github.com/mesutbyrm/Cursor-Flutter-/releases)

---

## Versiyon sistemi

| Alan | Açıklama | Örnek |
|------|----------|-------|
| `version` | Semantic versioning (pubspec.yaml) | `1.1.0` |
| `build_number` | GitHub Actions run_number (otomatik artan) | `42` |
| `full_version` | `{version}-build.{build_number}` | `1.1.0-build.42` |

- `pubspec.yaml` içindeki `version:` alanı manuel güncellenir (yeni özellik = minor bump, büyük değişiklik = major bump)
- Build numarası CI'da otomatik artar, her commit'te yeni numara alır
- APK dosya adı: `canlifal-mobile-v{full_version}.apk`

### Versiyon geçmişi

| Sürüm | Değişiklik |
|-------|-----------|
| 1.1.0 | Premium ana sayfa, cosmic tema, FAB navigasyon, hızlı işlemler, fal & tarot |
| 1.0.0 | İlk sürüm — giriş, akış, sosyal, canlı yayın, mesajlar, profil |

---

## Manuel etiketli sürüm

```bash
git tag v1.1.0 && git push origin v1.1.0
```

İndirme:
`https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/v1.1.0/canlifal-mobile-release.apk`

---

## GitHub Actions artifact (ZIP)

1. [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml)
2. **Run workflow** → dal seçin
3. **Artifacts** → `canlifal-social-release-apk` → ZIP içinden APK

---

## Yerelde derle

```bash
cd mobile
flutter pub get
flutter build apk --release
```

Çıktı: `mobile/build/app/outputs/flutter-apk/app-release.apk`

Özel API:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://canlifal.com
```

## API

`mobile/lib/core/config/env.dart`, uçlar: `mobile/lib/core/network/api_endpoints.dart`.
