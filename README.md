# Canlifal


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`docs/DOCS_RELEASE_INDEX.md`](docs/DOCS_RELEASE_INDEX.md)

Flutter sosyal medya ve canlı yayın istemcisi — **https://canlifal.com** API ile çalışır.

| Klasör | Açıklama |
|--------|----------|
| [`mobile/`](mobile/) | Ana Flutter uygulaması (APK buradan derlenir) |
| [`api/`](api/) | İsteğe bağlı yerel JWT REST API (Node.js + Prisma) |

## Android APK indir

| Bağlantı | Açıklama |
|----------|----------|
| **[canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk)** | Her zaman son `main` derlemesi (`apk-latest`) |
| **[Sürüm arşivi](https://github.com/mesutbyrm/Cursor-Flutter-/releases)** | Tüm test APK’ları (**güncel: 1.0.371+409**, `apk-latest`) |

Ayrıntılar: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)

## CI durumu (`main` üzerindeki kırmızı X)

Kod hatası değilse, GitHub **faturalandırma / harcama limiti** yüzünden Actions başlamıyor olabilir (özel repo). Adımlar: [`docs/GITHUB_ACTIONS_CI.md`](docs/GITHUB_ACTIONS_CI.md) · yerel kontrol: `bash scripts/ci-local.sh`

## Kullanıcı testi (Psychic P0 — öncelik)

Agent işi bitti. Jeton ✅ · **Onaylı falcı hesabı** gerekir (host listede değil):

```bash
bash scripts/user-test-start.sh        # Tek menü girişi
bash scripts/record-user-test-result.sh p0 PASS   # sonuç kaydı
```

Rehber: [`docs/PSYCHIC_P0_START.md`](docs/PSYCHIC_P0_START.md) · Falcı: [`docs/PSYCHIC_TELLER_STATUS.md`](docs/PSYCHIC_TELLER_STATUS.md)

## Hızlı başlangıç (geliştirici)

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

Mimari ve uç noktalar: [`mobile/README.md`](mobile/README.md) · Cursor ortamı: [`AGENTS.md`](AGENTS.md)
