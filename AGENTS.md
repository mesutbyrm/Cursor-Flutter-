# Canlifal — Agent talimatları

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

- **Sohbet / sesli oda (§3.3–3.4):** `room.id` (cuid), SSE `GET /api/chat/rooms/{id}/stream`, presence **20s**, TRTC `voice_room_{id}`, IRC rolleri, DJ + YouTube müzik, `!istek` komutu
- **Auth (§3 + §7.5):** NextAuth (web) + **mobil JWT** (`/api/auth/mobile/*`, `/api/me`); `sub` ≠ kullanıcı anahtarı — `realCid` / `gcid`
- **Kredi / jeton (§3.12):** CFC + Jeton; mobil cüzdan uçları
- **Video / TRTC (§3.5):** LiveKit/TRTC token uçları; PK, hediye
- **Fal, sosyal, bildirim, oyun** vb.: rapordaki endpoint listesi; mobilde `api_endpoints.dart` + feature modülleri

**Gerçek zamanlı (§6):** Sohbet = **SSE + polling** (Socket.IO değil). Fal = SSE streaming. Presence heartbeat 20s.

**Değişiklik yaparken:**

1. Rapordaki ilgili bölümü (sayfa / API / model) kontrol et
2. Üretim uçlarını değiştirmeden önce mobilin zaten hangi path’i kullandığını `grep` ile doğrula
3. `api/` mirror’a eklenen davranış, canlifal.com’da yoksa dokümante et veya yalnızca mobil-safe fallback kullan
4. Admin / Stripe / reklam gibi **web-only** sistemlere mobilde gereksiz bağımlılık ekleme

Güncel envanter metni (dış kaynak): https://canlifal.com/canlifal-envanter-raporu.txt

## Cursor Cloud specific instructions

### Proje düzeni

- **Ana uygulama:** `mobile/` — `canlifal_social` Flutter paketi; tüm geliştirme ve CI komutları buradan çalıştırılır.
- **Yerel API:** `api/` — Node.js + Express + Prisma JWT API (isteğe bağlı; üretimde `https://canlifal.com` kullanılabilir).

### Ortam

- Flutter SDK: `/opt/flutter/bin` (v3.41.x)
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

### Kullanıcı bildirimi — APK bitti + özellikler

`main`’e mobil değişiklik push ettiysen oturum sonunda kullanıcıyı bilgilendir:

1. `bash scripts/wait-apk-build.sh 900` (mümkünse derlemenin bitmesini bekle)
2. `bash scripts/print-build-status.sh` + CHANGELOG üst madde
3. Yanıtta **📢 Derleme ve özellikler** bölümü: sürüm, madde madde özellikler, derleme durumu, APK linki
4. CI `docs/LATEST_APK_BUILD.md` dosyasını günceller — kullanıcıya bu yolu da söyle

Kullanıcı GitHub’da **Watch → Releases** ile e-posta alabilir.
