# Canlifal — Agent talimatları


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`docs/DOCS_RELEASE_INDEX.md`](docs/DOCS_RELEASE_INDEX.md)

## Flutter entegrasyon kılavuzu (tek kaynak — zorunlu)

Tüm mobil API entegrasyonu **yalnızca** [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](docs/FLUTTER_ENTegrasyon_KILAVUZU.md) dosyasına göre yapılır. Bu kılavuz dışına çıkma: endpoint path, HTTP metodu, JSON body alanları, auth/SSE/retry kuralları buradan gelir.

- **Base URL:** `https://canlifal.com` — **Auth:** JWT Bearer (`/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `/api/me`)
- **Repository grupları:** kılavuz §9 (Auth, User, ChatRoom, LiveStream, Fortune, …)
- **SSE:** kılavuz §5–6 (5 endpoint, reconnect backoff)
- **Eski dokümanlar** (`sesli-sohbet-api-dokumantasyonu.md`, `FLUTTER_API_DOCS.md` vb.) yalnızca arka plan; **çelişkide bu kılavuz geçerlidir**

## Git iş akışı (zorunlu)

- **PR otomatik açma** — Agent'lar Pull Request oluşturmaz.
- **Review isteği yok** — Otomatik review / onay beklenmez.
- **Doğrudan commit** — Değişiklikler aktif geliştirme dalına (`main`) commit edilir.
- **Doğrudan push** — Başarılı değişikliklerden sonra `git push origin main`.
- **Dal temizliği** — Birleşmiş `cursor/*` dalları haftalık `github-cleanup.yml` ile silinir; manuel PR birikimine izin verilmez.
- **Temizlik betiği** — `bash scripts/github-cleanup.sh` (CI: Actions → GitHub cleanup).

## Üretim envanteri (canlifal.com)

Bu repo, **canlifal.com** (Next.js 14 + Prisma + PostgreSQL) platformunun **Flutter mobil istemcisidir**. Yeni özellik, hata düzeltmesi veya refactor öncesi ilgili sistemin üretim sözleşmesine uy; mevcut akışları kırma.

| Katman | Üretim | Bu repo |
|--------|--------|---------|
| Web + API | Next.js App Router, **384** API, **149** Prisma model | `mobile/` → JWT `Bearer`, `https://canlifal.com` |
| Yerel mirror | — | `api/` (Express; üretimin tam kopyası değil) |

**Mobil dokunulan başlıca sistemler (rapor §3):**

- **Sohbet / sesli oda:** kılavuz §9.3 `ChatRoomRepository` — SSE `GET /api/chat/rooms/{id}/stream`, presence `{action: join|leave}`, voice `{action: join}`, Agora token `/api/agora/token`
- **Auth (§3 + §7.5):** NextAuth (web) + **mobil JWT** (`/api/auth/mobile/*`, `/api/me`); `sub` ≠ kullanıcı anahtarı — `realCid` / `gcid`
- **Kredi / jeton (§3.12):** CFC + Jeton; mobil cüzdan uçları
- **Video / TRTC (§3.5):** LiveKit/TRTC token uçları; PK, hediye
- **Fal, sosyal, bildirim, oyun** vb.: rapordaki endpoint listesi; mobilde `api_endpoints.dart` + feature modülleri

**Gerçek zamanlı:** kılavuz §5 — SSE (Socket.IO değil). Fal streaming ayrı SSE.

**Değişiklik yaparken:**

1. Önce `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9 ilgili repository tablosunu oku
2. Mobil path/body için `grep` ile mevcut kullanımı doğrula; kılavuzla hizala
3. `api/` mirror üretimde yoksa yalnızca mobil-safe fallback veya dokümantasyon
4. Admin / Stripe / reklam gibi **web-only** sistemlere mobilde gereksiz bağımlılık ekleme

Güncel envanter metni (dış kaynak): https://canlifal.com/canlifal-envanter-raporu.txt

## Cursor Cloud specific instructions

### Proje düzeni

- **Ana uygulama:** `mobile/` — `canlifal_social` Flutter paketi; tüm geliştirme ve CI komutları buradan çalıştırılır.
- **Yerel API:** `api/` — Node.js + Express + Prisma JWT API (isteğe bağlı; üretimde `https://canlifal.com` kullanılabilir).

### Ortam

- Flutter SDK: `/opt/flutter/bin` (stable **3.44.x** — `mobile/.flutter-version`)
- Node.js: `nvm` — `api/` bağımlılıkları için
- Güncelleme: `.cursor/environment.json` → `bash scripts/cursor-update.sh; exit 0` (betik de her zaman **exit 0**; adımlar zaman aşımıyla atlanabilir)
- Başlangıç: `bash scripts/cursor-start.sh; exit 0`
- Hata görürseniz: yeni agent oturumu başlatın veya **Rebuild environment**
- **Prisma migrate** yalnızca `api/.env` içinde `DATABASE_URL` varsa çalışır

### Android derleme (Cloud Agent)

- `ANDROID_HOME=/opt/android-sdk`; PATH'e `cmdline-tools/latest/bin` ve `platform-tools` ekleyin
- Java 21 sistem JDK; proje Gradle'da Java 17 uyumluluğu
- Emülatör yok — doğrulama: `cd mobile && flutter build apk --debug`
- İlk Gradle derlemesi NDK/platform indirebilir (~3 dk)

### Kullanıcı testi (paralel mod — 2026-09-07)

**Cihaz testi sonucu sonra** — agent **P1/P2 hazırlığına** devam eder. Mobil kod değiştirme yalnızca **`Psychic P0 FAIL`** hotfix ile.

| Görev | Komut |
|-------|--------|
| **Agent paralel (şimdi)** | `bash scripts/kalan-isler-agent.sh` |
| **Devam et** | `bash scripts/devam-et.sh` |
| **Paralel mod özet** | `bash scripts/print-paralel-mod.sh` |
| **RELEASE READY engelleri** | `bash scripts/print-release-blockers.sh` |
| **GO komut indeks** | `bash scripts/print-go-commands.sh` |
| **Play Target audience + ads** | `bash scripts/print-play-target-audience-summary.sh` |
| **P1 prep GO** | `bash scripts/p1-prep-go.sh` |
| **Cihaz (sonra)** | `bash scripts/cihaz-sonra.sh` |
| **P2 prep GO** | `bash scripts/p2-prep-go.sh` |
| **P2 Play Store prep (tam)** | `bash scripts/p2-prep-all.sh` |
| **P2 Play Store özet** | `bash scripts/p2-prep-now.sh` |
| **Play FGS metni** | `bash scripts/print-play-foreground-service-declaration.sh` |
| **Play Data safety özeti** | `bash scripts/print-play-data-safety-summary.sh` |
| **Play Console prep indeks** | `bash scripts/print-play-console-prep-index.sh` |
| **Play Content rating (IARC)** | `bash scripts/print-play-content-rating-summary.sh` |
| **Play Store listing taslak** | `bash scripts/print-play-store-listing.sh` |
| **CI AAB adımları** | `bash scripts/print-ci-aab-steps.sh` |
| **AAB readiness** | `bash scripts/play-aab-readiness.sh` |
| **Play Console checklist** | `bash scripts/play-store-checklist.sh` |
| **Keystore secret rehberi** | `bash scripts/play-keystore-secrets-cheatsheet.sh` |
| **Play Console App access** | `bash scripts/print-play-console-app-access.sh` |
| **P1 checklist ön** | `bash scripts/p1-prep-now.sh` |
| **Tek komut başlangıç** | `bash scripts/basla.sh` |
| **Kalan işler** | `bash scripts/kalan-isler.sh` |
| **P0 GO** | `bash scripts/p0-go.sh` |
| **Cihaz testi menü** | `bash scripts/user-test-start.sh` |
| Cihaz öncesi doğrulama | `bash scripts/validate-pre-device-handoff.sh` |
| P0 akış (checklist) | `bash scripts/user-test-start.sh p0` |
| P1 GO (P0 sonrası) | `bash scripts/p1-go.sh` |
| Falcı doğrula | `bash scripts/probe-psychic-teller.sh` |
| Özet handoff | `bash scripts/basla.sh` |
| Sonuç kaydı | `bash scripts/record-user-test-result.sh p0 PASS` |
| Önkoşul (APK, giriş, jeton) | `bash scripts/psychic-p0-prereqs.sh` |
| Admin jeton | `bash scripts/admin-jeton-cheatsheet.sh` |
| Derleme durumu | `bash scripts/print-build-status.sh` |

Rehber: [`docs/KALAN_ISLER.md`](docs/KALAN_ISLER.md) · [`docs/PSYCHIC_P0_START.md`](docs/PSYCHIC_P0_START.md)

Kullanıcı **`Psychic P0 PASS`** yazana kadar `RELEASE READY: NO`. PASS → checklist güncelle; FAIL → freeze hotfix.

### Komutlar (`mobile/`)

| Görev | Komut |
|-------|--------|
| Bağımlılık | `flutter pub get` |
| Lint | `dart analyze` |
| Test | `flutter test` |
| Debug APK | `flutter build apk --debug` |
| Özel API | `flutter run --dart-define=API_BASE_URL=https://your-api.example.com` |

### Web hedefi

`path_provider` / `PersistCookieJar` nedeniyle web'de tam çalışmaz; mobil/APK doğrulaması tercih edin.

### API yapılandırması

- Üretim varsayılanı: `https://canlifal.com` (`mobile/lib/core/config/env.dart`)
- Uç noktalar: `mobile/lib/core/network/api_endpoints.dart`
- Yerel JWT API: `API_BASE_URL=http://127.0.0.1:3000/api/v1` (emülatörde `10.0.2.2`)

### Dikkat

- Firebase yapılandırma dosyaları repoda yok; uygulama eksikliği tolere eder
- `api/node_modules/` commit edilmez

### APK — her yanıtın sonunda (kullanıcı isteği)

Kullanıcı mesajlarına cevap verirken **en sonda** şu sabit indirme bağlantısını ekle; sürümü `mobile/pubspec.yaml` → `version:` satırından yaz:

- **İndir:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
- **404 / eski build:** [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) → `main` → `apk-latest` güncellenir
- Ayrıntı: [`APK_DOWNLOAD.md`](APK_DOWNLOAD.md)

### Release acceptance testleri

`main` push sonrası APK derlenmeden önce `scripts/run-acceptance-tests.sh` (20 madde) çalışır. Başarısızsa APK oluşturulmaz. Gerekli GitHub Secrets: `docs/ACCEPTANCE_TESTS.md`.

### Kullanıcı bildirimi — APK bitti + özellikler

`main`’e mobil değişiklik push ettiysen oturum sonunda kullanıcıyı bilgilendir:

1. `bash scripts/wait-apk-build.sh 900` (mümkünse derlemenin bitmesini bekle)
2. `bash scripts/print-build-status.sh` + CHANGELOG üst madde
3. Yanıtta **📢 Derleme ve özellikler** bölümü: sürüm, madde madde özellikler, derleme durumu, APK linki
4. CI `docs/LATEST_APK_BUILD.md` dosyasını günceller — kullanıcıya bu yolu da söyle

Kullanıcı GitHub’da **Watch → Releases** ile e-posta alabilir.

### Release handoff

Güncel sürüm ve kalan iş: [`docs/DOCS_RELEASE_INDEX.md`](docs/DOCS_RELEASE_INDEX.md) · P0: `bash scripts/p0-go.sh` · Rehber: [`docs/PSYCHIC_P0_START.md`](docs/PSYCHIC_P0_START.md) · `[skip ci]` push CI/APK atlar.
