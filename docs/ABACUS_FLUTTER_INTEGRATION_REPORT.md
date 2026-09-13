# Abacus backend ↔ Flutter entegrasyon raporu

> **Tarih:** 2026-09-13 (UTC)  
> **Referans:** `backend-reference/canlifal_flutter_entegrasyon_paketi.zip` → `backend-reference/canlifal_flutter_paketi/` (yerel çıkartma; ZIP yedek olarak repoda)  
> **Kural:** `backend-reference/` içindeki dosyalar **değiştirilmedi** (salt okunur referans).

---

## 1. Değiştirilen dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/core/theme/user_theme_remote_datasource.dart` | Tema güncelleme `POST` → `PATCH /api/user/theme` |
| `mobile/lib/features/gifts/data/gift_reciprocal_guard.dart` | Karşılıklı hediye `GET` → `POST` + `recipientId` |
| `mobile/lib/features/gifts/data/gift_repository.dart` | Aynı sözleşme |
| `mobile/lib/features/games/data/game_remote_datasource.dart` | Liderlik `POST` → `GET` + `period` query |
| `mobile/lib/features/home/data/datasources/home_remote_datasource.dart` | Burç `GET` birincil (`lang`); eski `POST` yedek |
| `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart` | Okundu işareti `POST` (OpenAPI); `PATCH` kaldırıldı |
| `scripts/generate_abacus_flutter_integration_report.py` | OpenAPI tarama betiği |
| `docs/ABACUS_FLUTTER_INTEGRATION_REPORT.md` | Bu rapor |

---

## 2. Neden değiştirildiler

Abacus paketi `openapi.yaml` / `endpoints_index.json` ile `mobile/lib` içindeki `safeGet/safePost/...` çağrıları karşılaştırıldı. **HTTP method** uyuşmazlığı olan ve OpenAPI’de doğrulanmış sözleşmeye göre düzeltme gereken noktalar güncellendi. UI, navigasyon ve tasarım dokunulmadı.

---

## 3. Kullanılan backend endpointleri (Abacus paketi)

Öncelik: `backend-reference/canlifal_flutter_paketi/openapi.yaml`, `endpoints_index.json`, `FLUTTER_BACKEND_INTEGRATION_SPEC.md`, `AUTHENTICATION.md`, `REALTIME.md`, `websocket_events.md`, özellik API `.md` dosyaları.

Mobil üretim tabanı: `https://canlifal.com` (`mobile/lib/core/config/env.dart`).

---

## 4. Doğrulanan endpointler (örnek kritik set)

| Alan | Endpoint | Method | Kaynak |
|------|----------|--------|--------|
| Auth giriş | `/api/auth/mobile-login` | POST | OpenAPI + AUTHENTICATION.md |
| Auth yenile | `/api/auth/mobile-refresh` | POST | OpenAPI |
| Oturum | `/api/me` | GET/PATCH | OpenAPI |
| Cüzdan | `/api/wallet` | GET | OpenAPI (birincil; `user/wallet` yedek — önceki oturum) |
| Fal erişim | `/api/fortune-access/check` | POST | OpenAPI |
| Fal IP durumu | `/api/fortune-access/ip-status` | GET | OpenAPI |
| Referral | `/api/referral` | GET | OpenAPI |
| Sohbet SSE | `/api/chat/rooms/{roomId}/stream` | GET | REALTIME.md + OpenAPI |
| Yayın SSE | `/api/video-streams/{streamId}/stream` | GET | REALTIME.md + OpenAPI |
| Bildirim SSE | `/api/notifications/stream` | GET | REALTIME.md + OpenAPI |
| PK SSE | `/api/pk/{matchId}/stream` | GET | REALTIME.md + OpenAPI |
| Fal seans SSE | `/api/room/{sessionId}/stream` | GET | REALTIME.md + OpenAPI |
| Falcı kuyruk SSE | `/api/fortune-tellers/sessions/stream` | GET | REALTIME.md + OpenAPI |
| TRTC | `/api/trtc/usersig` | POST | REALTIME.md + OpenAPI |
| FCM | `/api/devices/fcm` | POST/DELETE | OpenAPI + checklist |
| Mobil config | `/api/mobile/config` | GET | OpenAPI + checklist |
| Hediye reciprocal | `/api/gifts/check-reciprocal` | POST `{ recipientId }` | OpenAPI (bu oturumda hizalandı) |
| Oyun liderlik | `/api/games/leaderboard` | GET `period` | OpenAPI (bu oturumda hizalandı) |
| Tema | `/api/user/theme` | GET/PATCH | OpenAPI (bu oturumda hizalandı) |
| Bildirim okundu | `/api/notifications` | POST `{ notificationIds }` | OpenAPI (bu oturumda hizalandı) |

---

## 5. Doğrulanamayan endpointler / davranışlar

| Konu | Flutter kullanımı | Durum |
|------|-------------------|--------|
| `POST /api/user/fortunes` (kayıt) | `fortune_remote_datasource.save` | **DOĞRULANAMADI** — OpenAPI yalnız `GET /api/user/fortunes`, `PATCH /api/user/fortunes/{fortuneId}` |
| `PATCH /api/payments/requests` (iptal) | `profile_remote_datasource.cancelPaymentRequest` | **DOĞRULANAMADI** — OpenAPI yalnız `GET` + `POST` |
| Burç seçimi (`zodiacSign`) | `GET /api/horoscope/daily` | **DOĞRULANAMADI** — OpenAPI query yalnız `lang`; eski `POST` yedek bırakıldı |
| ~51 `api_endpoints` sabiti | OpenAPI’de birebir path yok | Yedek/yerel/admin/games host — `docs/FLUTTER_ONLY_ENDPOINT_AUDIT.md` |

---

## 6. Authentication durumu

- Mobil: `Authorization: Bearer <accessToken>` (`AUTHENTICATION.md`, `authentication.md`).
- Uçlar: `POST /api/auth/mobile-login`, `mobile-refresh`, `mobile-register`, sosyal giriş uçları pakette listelenmiş.
- 401 → refresh → logout akışı mevcut (`auth_service.dart`, Dio interceptor).
- **DOĞRULANAMADI (kod tarafı tam denetlenmedi):** `TOKEN_REVOKED`, `logout-all`, `sessions` liste — paket checklist’te var; mobilde kısmi.

---

## 7. WebSocket / SSE durumu

- Paket: **WebSocket sunucusu yok** (`REALTIME.md`); SSE + polling + TRTC.
- Flutter: `base_sse_service.dart`, chat/live/notifications/PK SSE servisleri — path’ler REALTIME tablosu ile uyumlu.
- Reconnect/backoff: kılavuz ve mevcut SSE istemcisi.

---

## 8. Canlı yayın durumu

- API: `video-streams/*`, TRTC token/usersig, media-heartbeat (REALTIME.md, `live_stream_api.md`).
- Flutter: `video_stream_sse_service.dart`, yayın sayfaları — **path doğrulandı**; medya TRTC/LiveKit entegrasyonu mevcut kodda.

---

## 9. Sesli oda durumu

- API: `chat/rooms/*`, presence, voice request olayları (`voice_room_api.md`, `voice-room-events.ts` referans).
- Flutter: `chat_room_sse_service.dart`, voice hub modülü — SSE path doğrulandı.

---

## 10. Hediye durumu

- Gönderim: mevcut gift datasource’lar + `Idempotency-Key` (kısmen `idempotencyKey` body).
- Reciprocal kontrol: **POST** `recipientId` (Abacus OpenAPI — bu oturumda düzeltildi).
- Animasyon/event: SSE `gift_received` (REALTIME.md).

---

## 11. Coin / cüzdan durumu

- `GET /api/wallet` birincil (`economy_wallet_remote_datasource.dart`).
- Jeton/CFC: `/api/jeton`, payment requests `POST /api/payments/requests` — OpenAPI ile uyumlu.
- Ödeme talebi iptali: **DOĞRULANAMADI** (bkz. §5).

---

## 12. PK durumu

- SSE: `GET /api/pk/{matchId}/stream`.
- Games host: `ApiBackendRouter` → `gamesApiBaseUrl` (mevcut; paket REALTIME ile uyumlu).
- `/api/pk/me/*` bazı path’ler ana host’ta yok — games yönlendirme (önceki parity raporu).

---

## 13. Test sonuçları

- `dart analyze` — **0 error** (mevcut info uyarıları devam ediyor).
- `flutter test` (hedefli): economy, fortune_access, referral_entities, api_endpoint_canonical_contract — önceki oturumda geçti; bu diff sonrası analyze temiz.

Komutlar:

```bash
cd mobile && dart analyze
cd mobile && flutter test test/core/network/api_endpoint_canonical_contract_test.dart
python3 scripts/generate_abacus_flutter_integration_report.py
```

---

## 14. Kalan problemler

1. `POST /api/user/fortunes` — kayıt akışı OpenAPI’de yok; fal üretim uçları üzerinden otomatik kayıt mı — **DOĞRULANAMADI**.
2. Ödeme talebi iptali — kanonik method/path pakette yok.
3. Günlük burç — burç bazlı query parametresi pakette yok (`lang` only).
4. Eski `backend-docs/` ile yeni paket path sayımı farklı (612 vs 502 path) — karşılaştırma referansı olarak tutulmalı.
5. CI APK: workflow bazen `skipped` — sürüm ile `apk-latest` gecikmesi.

---

## Referans bütünlüğü

- `backend-reference/canlifal_flutter_entegrasyon_paketi.zip` — **silinmedi**, repoda duruyor.
- `backend-reference/canlifal_flutter_paketi/**` — çıkartıldı; paket dosyalarına **yazılmadı / değiştirilmedi** (yalnızca okuma).
