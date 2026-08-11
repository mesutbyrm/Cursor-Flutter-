# Canlifal Flutter — Master Sync Audit (2026-08-11)

> **Sürüm:** `1.0.154+189`  
> **Backend tek kaynak:** `https://canlifal.com`  
> **Entegrasyon kılavuzu:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9

## A. Düzeltilen problemler (bu oturum + önceki faz)

| # | Problem | Eski durum | Kök neden | Flutter değişiklik | Backend endpoint |
|---|---------|------------|-----------|-------------------|------------------|
| 1 | Sesli oda çıkış — kullanıcı listede kalıyor | Music PiP sonrası presence yeniden join | `refresh()` `_sessionActive` kontrol etmeden `_joinPresence()` | `chat_room_providers.dart` guard | `POST .../presence` `{action:leave}` |
| 2 | Basic oda çıkış — backend gecikmesi | `awaitBackend: false` | Navigasyon leave'den önce | `voice_room_basic_page.dart` `awaitBackend: true` | aynı |
| 3 | Swipe canlı — arka plan TRTC/SSE | ±1 sayfa TRTC bağlı kalıyor | `active` yalnızca sesi kısıyordu | `suspendForSwipe` / `resumeFromSwipe` | `DELETE .../join`, SSE release |
| 4 | Canlı çıkış kaynak sızıntısı | Eski session listener | tearDown eksikti | `tearDownSession()` (1.0.152) | `leaveVideoStream` |
| 5 | Gold banner takım renkleri | Hardcoded altın/mor | `favoriteTeam` / `team` parse yoktu | `EntranceTheme`, `userRoomProfileProvider` | `PATCH /api/me` |
| 6 | CodeQL derleme | Import path hatası | Relative import derinlik hatası | package import (1.0.153+188) | — |
| 7 | Google giriş | Kullanıcı "aktif değil" algısı | SHA-1 / Firebase uyumsuzluğu (dev build) | Kod hazır; `NativeAuthDataSource` + login UI | `POST /api/auth/mobile-google` |

## B. Eklenen / güncellenen modüller

- `EntranceTheme` / `TeamCatalog` — VIP giriş renkleri
- `userRoomProfileProvider` — üyelik + takım tek kaynak
- `LiveHostFortuneRequestStack` — yayıncı fal kartları (max 3)
- `suspendForSwipe` / `resumeFromSwipe` — swipe feed TRTC/SSE lifecycle
- Release signing CI preflight betikleri

## C. Silinen / obsolete (Agora)

- Agora SDK **yok** (`pubspec.yaml` yalnızca `tencent_rtc_sdk`)
- Kalan: yorumlar, `agoraUid` JSON alias, `VoiceAgoraException` typedef, stale Android ProGuard
- `/api/agora/*` mobilde **yok** — token: `POST /api/trtc/token`

## D. Backend'de yapılması gerekenler (Flutter workaround yok)

| Konu | Durum | Not |
|------|-------|-----|
| PK request karşı tarafa delivery | Backend/SSE | Mobil: SSE birincil + poll yedek |
| `POST .../pk/score` 405 | Backend | Skor hediye+SSE; client POST eklenmedi |
| Presence stale cleanup | Backend cron | Flutter optimistic leave + heartbeat stop |
| Video thumbnail ffmpeg | Backend upload | Flutter DB `thumbnailUrl` kullanmalı |
| Fal viewer count | API response | Flutter tahmin etmiyor |
| Bot permissions | Backend role | Flutter bot aksiyon UI gizleme (kısmi) |
| Google OAuth | Firebase SHA-1 + `GOOGLE_CLIENT_ID` | Mobil kod tamam |

## E. Flutter mimari (mevcut)

| Katman | Konum |
|--------|--------|
| HTTP | `dio_provider.dart` + interceptors (auth refresh, retry, cache) |
| Auth | `AuthService`, `NativeAuthDataSource`, `TokenStorage` |
| SSE | `BaseSseService`, `sse_connection_hub.dart` (ref-count) |
| Voice RTC | `VoiceTrtcEngine`, `voice_room_audio_coordinator.dart` |
| Live RTC | `TrtcLiveRoomCoordinator`, `TrtcRoomManager` |
| Room state | `voiceRoomLiveProvider`, `liveRoomProvider` |
| Gifts | `gift_session_controller`, SSE dedupe |

**Hedef birleşik katman:** `RoomRealtimeManager` — kısmen `sse_connection_hub` + provider mixin'ler; tam birleşim backlog.

## F. API contract

- **Tek router:** `ApiBackendRouter.resolve()` → her zaman `main` (`canlifal.com`)
- **§8 korunan:** `/api/live/gift/send`, `/api/trtc/token`, `/api/trtc/usersig`
- **Auth:** `/api/auth/mobile-login`, `mobile-refresh`, `mobile-google`, `/api/me`

## G. Performance (hedef vs mevcut)

| Metrik | Hedef | Mevcut | Not |
|--------|-------|--------|-----|
| Startup | <2.5s | ~3–4s (cihaz) | `StartupPerf` lazy init var |
| Navigation | <300ms | Değişken | Optimistic UI kısmen |
| Feed scroll | 60 FPS | Lazy list var | Video autoplay sınırlı |
| Room entry | <1.5s | TRTC token + join | `VoiceRoomEntryPerf` |
| Swipe live CPU | Düşük | **İyileştirildi** suspend | Eski: 3 eşzamanlı TRTC |

## H. Thermal optimization

| Kaynak | Azaltma |
|--------|---------|
| Swipe feed TRTC | `suspendForSwipe` — inactive sayfa leave |
| Heartbeat | `_sessionActive` guard; leave'de cancel |
| SSE poll | SSE bağlıyken poll atlanır |
| Gift audio | `GiftAudioPool` (mevcut) |
| Backlog | SSE stack birleştirme, discover SSE ref-count review |

## I. Acceptance test (Cloud agent — gerçek sonuç)

| Alan | Sonuç | Not |
|------|-------|-----|
| AUTH username login | **PASS*** | Kod + unit; prod credentials gerekli |
| AUTH Google | **PASS*** kod / **FAIL*** cihaz | SHA-1 Firebase gerekli |
| Token storage / refresh | **PASS** | `AuthTokenRefreshCoordinator` |
| Voice leave | **PASS*** | P0 guard bu oturum |
| Live leave / swipe | **PASS*** | suspend/resume eklendi |
| Gifts jeton/animasyon | **PASS*** | Parser mevcut; cihaz E2E gerekli |
| PK A→B delivery | **FAIL*** | Backend SSE; 2 cihaz test |
| Social feed pagination | **Kısmi** | `PagedResult` var; tam audit backlog |
| Fal türleri (15) | **Kısmi** | Çoğu modül var; gap analiz backlog |
| Bot kısıt | **Kısmi** | Backend role; UI guard backlog |
| FİNAL 1–25 cihaz | **FAIL** | adb/emülatör yok |

\* Kod + unit test; üretim cihazında manuel doğrulama bekleniyor.

## J. Kalan sorunlar (öncelik sırası)

1. **PK karşı taraf delivery** — backend SSE/event + 2 cihaz doğrulama
2. **Social feed** — otomatik fal post pagination / viewer count API parity
3. **Video thumbnail** — backend ffmpeg pipeline (Flutter yalnızca URL gösterir)
4. **Bot UI guards** — role/type ile aksiyon gizleme (tüm ekranlar)
5. **SSE stack birleştirme** — 4+ paralel implementasyon → `BaseSseService`
6. **RoomRealtimeManager** — tek event parser katmanı
7. **Eksik fal UI** — envanter vs `FortuneRepository` gap listesi
8. **Performance profiling** — startup/thermal cihaz ölçümü
9. **Google SHA-1** — Firebase Console debug+release fingerprint

## Google ile giriş

- **UI:** Aktif — login/register birincil CTA (`AuthSocialSection`)
- **API:** `POST /api/auth/mobile-google` `{idToken}`
- **Yapılandırma:** `google-services.json` + Web client ID (`GoogleAuthConfig.isConfigured`)
- **Başarısızlık (dev):** SHA-1 uyumsuz → `bash scripts/verify-google-signin-config.sh`
- **Backend:** `GOOGLE_CLIENT_ID` = Web OAuth client ID (`docs/GOOGLE_SIGNIN_SETUP_TR.md`)

## Sonraki faz sırası (master task §31)

```
AUDIT ✓ (bu dosya)
→ P0 leave/sync ✓ (bu oturum)
→ PK delivery test (backend + 2 cihaz)
→ Social/fal parity
→ Bot guards
→ Performance/thermal measure
→ UI polish backlog
→ Full acceptance device run
```
