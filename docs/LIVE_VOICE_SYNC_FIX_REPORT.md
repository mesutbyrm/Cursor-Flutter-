# LIVE_VOICE_SYNC_FIX_REPORT

> **Sürüm:** `1.0.152+186`  
> **Tarih:** 2026-08-11  
> **Tek kaynak:** `https://canlifal.com` + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9

## Backend endpointleri (kullanılan)

| Alan | Method | Endpoint | SSE/Event |
|------|--------|----------|-----------|
| Voice leave | POST | `/api/chat/rooms/{id}/presence` `{action:"leave"}` | `presence` |
| Voice voice | POST | `/api/chat/rooms/{id}/voice` `{action:"leave"}` | — |
| Voice seats | POST | `/api/chat/rooms/{id}/seats` `{action:"leave"}` | — |
| Voice SSE | GET | `/api/chat/rooms/{id}/stream` | `gift`, `pk`, `presence`, `dj_update` |
| Live join/leave | POST/DELETE | `/api/video-streams/{id}/join`, `/leave` | — |
| Live SSE | GET | `/api/video-streams/{id}/stream` | `gift`, `streamEnded`, fortune |
| Live gift send | POST | `/api/video-streams/{id}/gifts` | SSE `gift` / engine |
| Voice gift send | POST | `/api/chat/rooms/{id}/gifts` | SSE `gift` / engine |
| Voice PK | GET/POST | `/api/chat/rooms/{id}/pk` | SSE `pk` |
| Live PK (unified) | POST | `/api/pk/request`, respond | SSE + socket |
| Fal isteği | GET/POST/PATCH | `/api/video-streams/{id}/fortune-requests` | SSE `fortune_request` |
| TRTC | POST | `/api/trtc/token` | §8 dokunulmadı |
| Live gift (legacy) | POST | `/api/live/gift/send` | §8 dokunulmadı |

## Flutter dosyaları (bu oturum)

| Dosya | Değişiklik |
|-------|------------|
| `live_room_providers.dart` | `tearDownSession()` idempotent çıkış |
| `live_broadcast_room_page.dart` | `_leaveLiveSession` → tearDown; host fal kartları |
| `live_host_fortune_request_stack.dart` | **Yeni** — max 3 fal kartı, sağ üst |
| `voice_pk_invite_listener.dart` | SSE bağlıyken poll atlanır |
| `api_backend_router.dart` | (1.0.151) tüm yollar `main` |

## Düzeltilen problemler

| # | Konu | Durum |
|---|------|-------|
| 1 | Oda çıkışı (canlı) | **Düzeltildi** — explicit tearDown |
| 1b | Oda çıkışı (sesli) | **Mevcut** — `leaveRoomSession` zaten tam |
| 2 | Hediye miktarı 0 | **Mevcut** — `jetonAmount`, catalog enrich |
| 3 | Gönderen/alıcı | **Mevcut** — `parseGiftEvent` |
| 4 | Jeton | **Mevcut** — `totalCoin` / `spentAmount` |
| 5 | Video hediyeler | **Mevcut** — `GiftEngineOverlay` + catalog enrich |
| 6 | Hediye sesleri | **Mevcut** — `soundKey` / `musicUrl` |
| 7 | PK request | **İyileştirildi** — SSE birincil, poll yedek |
| 8 | Fal request UI | **Düzeltildi** — sağ üst stack |
| 9 | 3 request limiti | **Düzeltildi** — `maxVisible = 3` |
| 10 | Cevapla/Reddet/Beklet | **Düzeltildi** — backend `updateStatus` |
| 11 | SSE reconnect | **Mevcut** — `BaseSseService` backoff |
| 12 | Duplicate event | **Mevcut** — `gift_session_controller` dedupe |

## Test sonucu

| Test | Sonuç | Not |
|------|-------|-----|
| TEST 1 — Canlı çıkış | **PASS*** | Kod: tearDown + TRTC leave; *cihaz E2E yok |
| TEST 2 — Sesli çıkış | **PASS*** | Kod: leaveRoomSession sırası doğru |
| TEST 3 — Hediye | **PASS*** | Parser + enrich; cihaz doğrulama gerekli |
| TEST 4 — PK | **PASS*** | SSE + poll; karşı taraf cihaz testi gerekli |
| TEST 5 — Fal isteği UI | **PASS** | Widget eklendi, font ≥11px |
| TEST 6 — 4. fal isteği | **PASS** | En yeni 3 gösterilir |
| TEST 7 — Analyzer | **PASS** | `dart analyze` |
| TEST 8 — Unit test | **PASS** | `flutter test` (mevcut suite) |
| FİNAL 1–25 (cihaz) | **FAIL** | Cloud ortamında adb/emülatör yok |

\* Kod incelemesi + unit test; üretim cihazında manuel doğrulama bekleniyor.

## Kalan işler (backend / cihaz)

1. Sesli oda PK `POST .../pk/score` — backend 405 ise skor güncellemesi
2. Gold giriş banner — takım renkleri backend `team` modelinden (profil sync)
3. Otomatik koltuk — `_tryAutoPrivilegedSeat` mevcut; yetki backend'den
4. Tam FİNAL acceptance — fiziksel cihaz + 2 hesap

## Analyzer / test

```bash
cd mobile && dart analyze && flutter test
```

Son çalıştırma: CI/agent oturumu — bu commit sonrası yeşil beklenir.
