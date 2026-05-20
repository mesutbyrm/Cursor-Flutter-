# Canlifal — Android APK İndirme

## ⚠️ Önemli: Private Repo

Bu repo **private** olduğu için `releases/download/...` linkleri doğrudan tarayıcıdan **çalışmaz** (404 verir). İndirmek için aşağıdaki yöntemlerden birini kullanın.

---

## 📱 Yöntem 1: GitHub Actions Artifact (Önerilen)

En kolay yöntem — GitHub'a giriş yaptıktan sonra:

1. **[Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml)** sayfasına gidin
2. En son **başarılı** (✅) çalışmaya tıklayın
3. Sayfanın altındaki **Artifacts** bölümünden `canlifal-social-release-apk` ZIP'i indirin
4. ZIP'i açın → `canlifal-mobile-release.apk`

> İlk kez mi? **Run workflow** → `main` dalını seçin → çalışmasını bekleyin.

---

## 📱 Yöntem 2: GitHub Releases (Giriş yapılı)

GitHub'a giriş yaptıysanız release sayfasından indirebilirsiniz:

**[Releases sayfası](https://github.com/mesutbyrm/Cursor-Flutter-/releases)**

- **apk-latest** → her zaman son `main` derlemesi
- **v1.1.0-build.{N}** → versiyonlu arşiv sürümleri

---

## 📱 Yöntem 3: gh CLI ile indirme

```bash
# Son sürümü indir
gh release download apk-latest --repo mesutbyrm/Cursor-Flutter- --pattern "*.apk"

# Belirli sürümü indir
gh release download v1.0.5 --repo mesutbyrm/Cursor-Flutter- --pattern "*.apk"
```

---

## 📱 Yöntem 4: Repo'yu public yap

Repo'yu public yaparsanız indirme linkleri doğrudan çalışır:

```
https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
```

GitHub → Settings → Danger Zone → Change visibility → Public

---

## Versiyon sistemi

| Alan | Açıklama | Örnek |
|------|----------|-------|
| `version` | Semantic versioning (pubspec.yaml) | `1.1.0` |
| `build_number` | GitHub Actions run_number (otomatik artan) | `42` |
| `full_version` | `{version}-build.{build_number}` | `1.1.0-build.42` |

Her `main` push'unda CI otomatik olarak:
1. **`apk-latest`** release'ini günceller (her zaman son APK)
2. **`v{version}-build.{N}`** versiyonlu release oluşturur (arşiv)

### Versiyon geçmişi

| Sürüm | Değişiklik |
|-------|-----------|
| 1.1.0 | Premium ana sayfa, cosmic tema, FAB navigasyon, hızlı işlemler, fal & tarot |
| 1.0.5 | Saat kronolojisi, doküman düzenlemeleri |
| 1.0.0 | İlk sürüm — giriş, akış, sosyal, canlı yayın, mesajlar, profil |

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
