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

## Kullanıcı testi — agent prep ✅ tamam

Agent P2 prep bitti. Kalan: **cihaz P0→P1**, **keystore/AAB**, **Play Console**. Jeton ✅ · host falcı ✅

```bash
bash scripts/kullanici-sonraki.sh           # ★ kalan adımlar
bash scripts/agent-bitti.sh               # agent ✅ bitti (hızlı durum)
bash scripts/agent-prep-tamam.sh            # prep doğrula
bash scripts/cihaz-sonra.sh                 # cihaz (sonra)
bash scripts/basla.sh                       # canlı durum + devir teslim
bash scripts/kalan-isler.sh                 # durum tablosu
bash scripts/print-release-blockers.sh      # engeller
bash scripts/p0-go.sh
bash scripts/user-test-start.sh p0
```

Rehber: [`docs/RELEASE_USER_NEXT_STEPS.md`](docs/RELEASE_USER_NEXT_STEPS.md)

## Hızlı başlangıç (geliştirici)

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://canlifal.com
```

Mimari ve uç noktalar: [`mobile/README.md`](mobile/README.md) · Cursor ortamı: [`AGENTS.md`](AGENTS.md)
