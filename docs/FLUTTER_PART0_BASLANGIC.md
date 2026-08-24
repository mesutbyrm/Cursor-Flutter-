# CanlıFal Flutter — Başlangıç Kılavuzu (PART 0)

> **Amaç:** `FLUTTER_PART1` … `FLUTTER_PART12` dosyalarının önerdiği sırayı tek sayfada özetlemek.  
> **2026 Premium şartname:** [`FLUTTER_PREMIUM_2026_SARTNAME.md`](./FLUTTER_PREMIUM_2026_SARTNAME.md) — özellik matrisi ve yayın kontrol listesi.  
> **Bu repoda API tek kaynağı:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](./FLUTTER_ENTegrasyon_KILAVUZU.md) (27 Haziran 2026). PART dosyaları ile çelişkide **kılavuz geçerlidir**.

**Base URL:** `https://canlifal.com`  
**Paket:** `mobile/` → `canlifal_social`

---

## Hızlı özet — 7 adım

| Adım | PART | Ne yapılır? | Bu repodaki karşılık |
|------|------|-------------|----------------------|
| 1 | PART 1 + 10 | ApiClient, JWT, `{success,data}` zarfı, 401 refresh | `lib/core/network/` — `dio_provider.dart`, `ApiClient`, `token_storage.dart` |
| 2 | PART 12 §3 | Mobil giriş + SSO | `features/auth/` — `POST /api/auth/mobile-login`, Google/Apple/TikTok |
| 3 | PART 2 | Tasarım sistemi | `lib/core/theme/`, `core/widgets/`, `core/ui/premium_2026/` |
| 4 | PART 3–7 | Modül modül ekranlar | `profile/`, `voice_hub/`, `live/`, `gifts/`, `fortune/` |
| 5 | PART 12 §4 | Tencent TRTC | `lib/features/trtc/`, `voice_trtc_engine.dart`, `live_broadcast_room_page.dart` |
| 6 | PART 9 + 11 | `mobile/config`, feature flag | `services/config_service.dart`, `mobile_config_providers.dart` |
| 7 | PART 12 §6 | Test + release | `flutter test`, `flutter build apk/appbundle`, CI `build-apk.yml` |

---

## Adım 1 — Temel (PART 1 + PART 10)

**Ne anlatır?** Tüm modüllerin üzerine oturacak HTTP katmanı.

| Konu | Beklenen | Repoda |
|------|----------|--------|
| Base URL | `https://canlifal.com` | `lib/core/config/env.dart` → `Env.apiBaseUrl` |
| Zarf parse | `{ success, data, message, error }` | `dio_provider.dart` → `safeGet` / `safePost`; `json_util.dart` → `pick`, `asJsonMap` |
| JWT Bearer | Her korumalı istekte header | `dio_provider.dart` interceptor |
| 401 refresh | `POST /api/auth/mobile-refresh` → yeniden dene | `auth_token_refresh_coordinator.dart` |
| Token saklama | `flutter_secure_storage` | `token_storage.dart` |
| Retry / cache | Ağ kopması, GET cache | `api_retry_interceptor.dart`, `api_cache_interceptor.dart` |

**Yeni endpoint eklerken:** Path ve body alanları yalnızca kılavuz §9 tablolarından; `api_endpoints.dart` ile hizala.

---

## Adım 2 — Giriş (PART 12 §3)

**Ne anlatır?** Oturum açma, token çifti, sosyal SSO.

| Endpoint | Dosya |
|----------|--------|
| `POST /api/auth/mobile-login` | `features/auth/data/` |
| `POST /api/auth/mobile-refresh` | `dio_provider.dart` |
| Google / Apple / TikTok | `authMobileGoogle`, `authMobileApple`, `authMobileTiktok` |
| `GET /api/me` | Profil bootstrap |

**Akış:** Login → `TokenStorage` → `Api.setToken` → Riverpod `authControllerProvider`.

---

## Adım 3 — Tasarım sistemi (PART 2)

**Ne anlatır?** Ortak renk, tipografi, cam kart, buton, scaffold — ekranlar kopya stil üretmez.

| PART 2 adı | Repodaki eşdeğer |
|------------|------------------|
| `AppColors` | `core/theme/app_colors.dart`, `app_palette.dart`, `app_theme_colors.dart` |
| `AppText` | `core/theme/app_theme.dart`, `google_fonts` |
| `GlassCard` | `ThemedGlassCard`, `DiscoverGlassCard`, `LiquidGlassCard` |
| `PremiumButton` | `core/ui/premium_2026/`, feature-specific FilledButton stilleri |
| `AppScaffold` | `DiscoverSubPage`, `MainAppShell` |
| `FramedAvatar` | `core/widgets/user_avatar.dart`, `VoiceNeonAvatar` |

Yeni ekran: önce `core/` bileşenlerini kullan; ham `Container` + inline renkten kaçın.

---

## Adım 4 — Modüller (PART 3 → 7)

Her PART, bir feature klasörü + kılavuz §9 repository grubuna karşılık gelir.

### PART 3 — Profil
- **Klasör:** `mobile/lib/features/profile/`
- **API:** User, wallet, jeton, takip — kılavuz §9.2
- **Giriş:** `profile_page.dart` → `ProfileHubLayout`

### PART 4 — Sesli oda
- **Klasör:** `mobile/lib/features/voice_hub/`
- **API:** `ChatRoomRepository` — presence, SSE, koltuk, DJ, PK — kılavuz §9.3
- **Gerçek zamanlı:** SSE (`/api/chat/rooms/{id}/stream`), Socket.IO değil
- **Giriş:** `voice_room_rtc_page.dart`, `open_voice_chat_room_flow.dart`

### PART 5 — Canlı yayın
- **Klasör:** `mobile/lib/features/live/`
- **API:** `LiveStreamRepository` — kılavuz §9.4
- **Giriş:** `live_broadcast_room_page.dart`, `open_live_stream.dart`

### PART 6 — Hediye
- **Klasör:** `mobile/lib/features/gifts/`
- **API:** `giftId`, jeton, animasyon — kılavuz + `live_gifts_remote_datasource.dart`
- **Parse:** `totalCoin`, `giftPrice`, `jetonAmount`

### PART 7 — Fal
- **Klasör:** `mobile/lib/features/fortune/`, `live_psychics/`
- **API:** Fortune teller, session, SSE — kılavuz §9.6–9.7

**Sıra önerisi (sıfırdan):** Profil → Sesli oda → Canlı → Hediye → Fal. Bu repo’da hepsi mevcut; yeni iş kılavuz §9’a göre ilgili repository’ye eklenir.

---

## Adım 5 — TRTC (PART 12 §4)

**Ne anlatır?** Tencent TRTC SDK; token **daima backend’den** — istemci üretmez.

| Senaryo | Token uçları | Kod |
|---------|--------------|-----|
| Sesli oda (audio) | `/api/trtc/token` veya `/api/trtc/usersig` | `trtc_room_manager.dart`, `voice_trtc_engine.dart` |
| Canlı yayın | `/api/live/join-room` | `live_broadcast_room_page.dart` |
| Rol | Anchor (yayıncı) / Audience (izleyici) | TRTC `TRTCRole` — host vs seyirci |

**Kural:** Mikrofon/kamera izinleri → join → leave/dispose; PK signaling backend + SSE ile.

---

## Adım 6 — Dinamik modüller (PART 9 + 11)

**Ne anlatır?** Açılışta yapılandırma; feature flag ile modül aç/kapa.

| Konu | Endpoint / dosya |
|------|------------------|
| Config | `GET /api/mobile/config?platform=&version=` |
| Feature flags | `MobileConfig.features` → `mobile_config_gate.dart` |
| Yasal linkler | `config.links.terms`, `links.privacy` |
| Kademeli modüller | shorts, games, agency — flag true ise route/menu göster |

**Örnek:** `mobileConfigProvider` → bakım modu, zorunlu güncelleme, modül listesi.

---

## Adım 7 — Yayın öncesi (PART 12 §6)

**Ne anlatır?** Test matrisi + release build.

| Kontrol | Komut / dosya |
|---------|----------------|
| Lint | `cd mobile && dart analyze` |
| Unit test | `flutter test` |
| Kabul testleri | `scripts/run-acceptance-tests.sh` (CI) |
| Debug APK | `flutter build apk --debug` |
| Release | `flutter build appbundle` / `flutter build ipa` |
| CI APK | `.github/workflows/build-apk.yml` → `apk-latest` |

**Manuel matris (özet):** Giriş, profil, sesli oda giriş/çıkış, canlı yayın, PK, randevu, hediye, bildirim, token refresh, ağ kopması.

---

## PART dosyaları → kılavuz eşlemesi

Repoda `FLUTTER_PART1..12` dosyaları commit edilmemiş olabilir; eşdeğer dokümanlar:

| PART (konsept) | Bu repodaki doküman |
|----------------|---------------------|
| API / network | `FLUTTER_ENTegrasyon_KILAVUZU.md` §1, §7–9 |
| UI / tema | `core/theme/`, mockup prompt’ları `docs/prompts/` |
| Sesli oda | `docs/prompts/FLUTTER_SESLI_SOHBET_PROMPT.md` |
| Canlı yayın | `docs/prompts/FLUTTER_CANLI_YAYIN_PROMPT.md` |
| PK | `docs/PK_SYSTEM_FLUTTER_INTEGRATION.md` |
| Backend uyum | `FLUTTER_BACKEND_UYUMLULUK_RAPORU.md` |

---

## Yeni geliştirici — ilk gün checklist

1. `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9 — ilgili repository tablosunu oku  
2. `mobile/lib/core/network/api_endpoints.dart` — path doğrula  
3. `grep` ile mevcut kullanımı bul; yeni path icat etme  
4. Riverpod + repository katmanına ekle  
5. `dart analyze` + ilgili `flutter test`  
6. `main` push → APK CI (`scripts/wait-apk-build.sh`)

---

## Sürüm ve APK

- Sürüm: `mobile/pubspec.yaml` → `version:`  
- İndir: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

---

*Son güncelleme: Temmuz 2026 — PART 0, mevcut `canlifal_social` monorepo yapısına göre yazılmıştır.*
