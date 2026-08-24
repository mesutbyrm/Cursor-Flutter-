# Backend ↔ Flutter API Parity Audit

**Tarih:** 2026-07-17  
**Kaynak:** `api/src/**` (yerel mirror), `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9 (üretim sözleşmesi), `mobile/lib/**`

---

## Özet

| Metrik | Değer |
|--------|-------|
| Yerel mirror HTTP route (PK+Live+Voice+TRTC+Gift+SSE) | ~95 |
| Flutter `api_endpoints.dart` tanımlı path | ~180+ |
| Üretim (canlifal.com) toplam API | ~384 |
| Games backend (`canlifalapi.abacusai.app`) PK/live oyun uçları | ~25 |
| Bu oturumda düzeltilen kritik uyumsuzluk | 8 |

**Kural:** Flutter yalnızca kılavuz §9 ve backend kodunda doğrulanmış uçları kullanır. Tahmin yok.

---

## Mimari: İki backend

| Backend | Base URL | Kullanım |
|---------|----------|----------|
| **Ana** | `https://canlifal.com` | Auth, chat odaları (mesaj/presence/SSE), video-streams, TRTC token, hediye katalog |
| **Games** | `https://canlifalapi.abacusai.app` | `/api/pk/*`, `/api/chat/rooms/{id}/pk`, `/api/live/pk/*`, `/api/live/guest/*` |

Yönlendirme: `mobile/lib/core/network/api_backend_router.dart`

---

## Endpoint envanteri (PK / Voice / Live / TRTC)

### PK — Games backend (kılavuz §9.3)

| HTTP | Path | Body | Flutter |
|------|------|------|---------|
| GET | `/api/chat/rooms/{roomId}/pk` | — | `PkBattleRemoteDataSource.fetchRoomBattle` ✅ |
| POST | `/api/chat/rooms/{roomId}/pk` | `{guestUserId, durationSec}` | `inviteVoiceRoom` ✅ |
| POST | `/api/chat/rooms/{roomId}/pk/{inviteId}/respond` | `{action: accept\|reject}` | `acceptBattle` / `rejectBattle` ✅ |
| POST | `/api/chat/rooms/{roomId}/pk/{battleId}/end` | — | `endBattle` ✅ |
| GET | `/api/pk/battles/{id}` | — | `fetchBattle` ✅ |
| GET | `/api/pk/history` | `?battleType&limit` | `fetchHistory` ✅ |
| POST | `/api/pk/request` | `{hostStreamId, opponentStreamId, durationSec, mode}` | `PkRoomRemoteDataSource.request` (unified) ✅ |
| POST | `/api/pk/{id}/respond` | `{action}` | unified PK ✅ |
| GET | `/api/pk/{id}/stream` | SSE | `PkMatchSseService` ✅ |

### PK — Ana site (video stream)

| HTTP | Path | Body (kılavuz) | Flutter |
|------|------|----------------|---------|
| POST | `/api/video-streams/{streamId}/pk-battle` | `{opponentStreamId, durationMinutes?}` | `streamPkAction` — **düzeltildi** (önce kılavuz body, sonra action fallback) |
| GET | `/api/video-streams/{streamId}/pk-battle` | — | `fetchStreamBattle` ✅ |

### Voice Room — Ana site

| HTTP | Path | Body (kılavuz §9.3) | Flutter |
|------|------|---------------------|---------|
| POST | `/api/chat/rooms/{id}/presence` | `{action: join, nickname?}` | `joinPresence` ✅ |
| PATCH | `/api/chat/rooms/{id}/presence` | heartbeat | `presenceHeartbeat` — **düzeltildi** (PATCH) |
| DELETE | `/api/chat/rooms/{id}/presence` | leave | `leavePresence` ✅ |
| POST | `/api/chat/rooms/{id}/voice` | `{action: join}` | `joinVoiceSession` — **düzeltildi** (`type` kaldırıldı) |
| GET | `/api/chat/rooms/{id}/stream` | SSE | `ChatRoomSseService` ✅ |
| POST | `/api/chat/rooms/{id}/gifts` | `{giftId, receiverUserId, quantity?}` | `ChatRoomGiftsRemoteDataSource` — **düzeltildi** (çift alan adı) |
| POST | `/api/chat/rooms/{id}/seats` | `{action: take, seatIndex}` | `assignSeat` ✅ (fallback zinciri var) |

### Live Stream — Ana site

| HTTP | Path | Body (kılavuz §9.4) | Flutter |
|------|------|---------------------|---------|
| POST | `/api/video-streams/{id}/join` | `{nickname?}` | `joinVideoStream` — **düzeltildi** |
| POST | `/api/video-streams/{id}/leave` | — | `leaveVideoStream` ✅ |
| POST | `/api/video-streams/{id}/end` | — | `endVideoStream` ✅ |
| GET | `/api/video-streams/{id}/stream` | SSE | `VideoStreamSseService` ✅ |
| POST | `/api/video-streams/{id}/co-broadcast/invite` | `{userId}` | `inviteCoBroadcast` (inviteeId alias) |

### TRTC

| HTTP | Path | Body | Flutter |
|------|------|------|---------|
| POST | `/api/trtc/token` | `{roomId, role}` | `TrtcRemoteDataSource.fetchToken` ✅ (birincil) |
| POST | `/api/trtc/usersig` | `{userId, roomId}` | fallback ✅ |

Agora (`/api/agora/token`) runtime'da devre dışı — TRTC-only (v1.0.44+56).

### SSE (kılavuz §5 — 5 endpoint)

1. `GET /api/chat/rooms/{id}/stream` ✅  
2. `GET /api/video-streams/{id}/stream` ✅  
3. `GET /api/fortune-tellers/sessions/stream` ✅  
4. `GET /api/pk/{id}/stream` ✅ (games)  
5. Fal streaming (FortuneRepository) ✅  

---

## PK analizi — neden çalışmıyordu?

| # | Kök neden | Durum |
|---|-----------|-------|
| 1 | **Yanlış backend** — PK voice uçları games'e gitmeli; ana site stub/null döner | `ApiBackendRouter` doğru yönlendiriyor ✅ |
| 2 | **ownerId boş** — PK daveti `guestUserId` gerektirir; oda listesinde `ownerId` parse edilemezse davet hiç gitmez | `ownerId` alias genişletildi ✅ |
| 3 | **Çift PK kontratı** — `ChatService.pkAction` `action` gönderiyordu; kılavuz yalnızca `{guestUserId, durationSec}` | `ChatService` düzeltildi ✅ |
| 4 | **Video PK body** — `action` multiplexer kılavuzdan farklı; `{opponentStreamId, durationMinutes}` önce denenmeli | `streamPkAction` + `live_stream_extras` düzeltildi ✅ |
| 5 | **SSE/Socket dinlenmemesi** — Davet sonrası `pk:invite` SSE veya Socket.IO | `PkBattleSocketService` + `ChatRoomSseService` pk event ✅ |
| 6 | **roomId vs slug** — API yalnızca Prisma `id` kabul eder | `apiRoomKey` = `id` ✅ |
| 7 | **JWT games isteğinde** — Bearer eksikse 401 | `dio_provider` tüm isteklere JWT ekler ✅ |
| 8 | **Stale PK** — Önceki savaş bitmeden yeni davet | `prepareRoomForInvite` ✅ |

### Eksik / riskli (devam eden)

- Unified PK (`/api/pk/request`) games'te; voice PK (`/chat/rooms/.../pk`) ayrı stack — ikisi paralel çalışıyor.
- `POST /api/pk/battles` (local mirror) ile games `/api/chat/rooms/{id}/pk` farklı path — Flutter games path kullanıyor.
- Socket.IO (`pk_battle_socket_service`) ana site origin'e bağlanıyor; games SSE yedek.

---

## Sesli oda analizi

| Sorun | Neden | Düzeltme |
|-------|-------|----------|
| Bağlanmıyor | TRTC token / presence sırası | `joinPresence` → TRTC `enterRoom`; Agora kaldırıldı |
| Kullanıcı görünmüyor | Heartbeat boş POST, reconnect'te join eksik | PATCH heartbeat; `joinPresence` reconnect'te tekrar |
| Reconnect olmuyor | SSE backoff + presence yenileme | `ChatRoomSseService` exponential backoff max 20 |
| Koltuk kaybı | `action: take` eksik fallback | `assignSeat` zinciri mevcut |

---

## Canlı yayın analizi

| Sorun | Neden | Düzeltme |
|-------|-------|----------|
| Davet gitmiyor | co-broadcast `inviteeId` vs `userId` | alias mevcut |
| Yayın görünmüyor | `createStream` body fazla alan | `LiveRemoteDataSource.createVideoStream` |
| İzleyici sayısı | join body boş | `joinVideoStream(nickname)` düzeltildi |
| Token | Agora → TRTC geçişi | `POST /api/trtc/token` `{roomId, role}` |

---

## Flutter katman özeti

| Katman | Dosya | Durum |
|--------|-------|-------|
| ApiClient | `dio_provider.dart` | JWT, 401 refresh, retry, timing, cache ✅ |
| Endpoint sabitleri | `api_endpoints.dart` | Hardcode URL yok ✅ |
| Backend router | `api_backend_router.dart` | PK → games ✅ |
| Voice repository | `ChatRoomRemoteDataSource` | Düzeltildi |
| PK repository | `PkBattleRemoteDataSource` | Kılavuz uyumlu |
| Live repository | `LiveRemoteDataSource` | Düzeltildi |
| TRTC | `TrtcRemoteDataSource` | token + usersig fallback ✅ |
| Log | `VoiceRoomApiLogInterceptor`, `ApiTimingInterceptor` | Tüm istekler ✅ |

---

## Eksik endpoint / repository (öncelik sırası)

| Öncelik | Endpoint | Not |
|---------|----------|-----|
| Düşük | `POST /api/pk/battles` (local mirror) | Games `/chat/rooms/.../pk` kullanılıyor |
| Orta | `GET /api/video-streams/{id}/comments` | Flutter `messages` kullanıyor (üretim alias) |
| Orta | `POST /api/chat/rooms/{id}/moderation` | Dağınık ban/mute uçları var |
| Düşük | Socket.IO PK | SSE birincil; socket yedek |

---

## Bu oturumda yapılan kod düzeltmeleri

1. `presenceHeartbeat` → PATCH (boş POST kaldırıldı)
2. `enterPresence` → `joinPresence` (action: join)
3. `joinVoiceSession` / `leaveVoiceSession` → yalnızca `action` (type kaldırıldı)
4. `joinVideoStream` → `{nickname?}` body
5. `ownerId` parse → `ownerUserId`, `hostUserId`, `createdBy`, `userId`, `owner.id`
6. Voice gift → `giftId` + `receiverUserId` alias
7. Video PK create → kılavuz `{opponentStreamId, durationMinutes}` önce
8. `ChatService.pkAction` invite → `action` kaldırıldı

---

## Son kontrol listesi

- [x] PK voice daveti kılavuz body (`guestUserId`, `durationSec`)
- [x] PK games backend yönlendirmesi
- [x] Presence join/heartbeat kılavuz uyumu
- [x] TRTC token birincil; Agora runtime kapalı
- [x] SSE 5 endpoint tanımlı
- [ ] Tüm 384 üretim API için otomatik test (kapsam dışı — acceptance 20 madde CI'da)
- [ ] Unified PK ile voice PK tek stack'e indirgeme (gelecek refactor)

---

## Referanslar

- Tek kaynak kılavuz: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`
- Yerel mirror route hub: `api/src/index.ts`
- Önceki rapor: `API_PARITY_REPORT.md`
