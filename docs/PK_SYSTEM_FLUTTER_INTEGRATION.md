# PK Sistemi — Flutter Entegrasyon Dokümantasyonu

**Sürüm:** 1.0.492+496  
**Backend:** `https://canlifalapi.abacusai.app` (birleşik PK Faz 1–3)  
**Ana site:** `https://canlifal.com` (auth, yayın listesi, hediye kataloğu)

---

## 1. Mimari Özet

| Katman | Konum | Görev |
|--------|-------|-------|
| API yönlendirme | `api_backend_router.dart` | `/api/pk/*` → games backend |
| Remote datasource | `pk_room_remote_datasource.dart` | Faz 1–3 REST |
| SSE | `pk_match_sse_service.dart` | `GET /api/pk/{id}/stream` |
| Bridge | `pk_unified_bridge.dart` | `PkRoomMatch` ↔ eski battle map |
| Providers | `pk_room_providers.dart` | Riverpod + SSE + poll |
| Canlı 1v1 | `live_video_pk_provider.dart` | Birleşik API öncelikli |
| Çoklu misafir UI | `pk_room_live_section.dart` | Guest/team overlay |
| Liderlik / geçmiş | `pk_leaderboard_page.dart`, `pk_room_history_page.dart` | Faz 3 |

**Geriye dönük:** Sesli oda PK (`/api/chat/rooms/{id}/pk`) ve eski video-stream PK (`/api/video-streams/:id/pk-battle`) bozulmadı; birleşik API başarısız olursa fallback devreye girer.

---

## 2. API Endpoint Listesi

Tüm uçlar `ApiEndpoints` içinde tanımlıdır. İstekler `BackendRoutingInterceptor` ile `canlifalapi.abacusai.app`'e yönlendirilir.

### Faz 1 — 1v1 Davet

| Metod | Path | Body | Açıklama |
|-------|------|------|----------|
| POST | `/api/pk/request` | `hostStreamId`, `opponentStreamId`, `durationSec`, `mode` | PK daveti |
| POST | `/api/pk/{id}/respond` | `action`: `accept` \| `reject` | Yanıt |
| POST | `/api/pk/{id}/cancel` | — | Bekleyen daveti iptal |
| POST | `/api/pk/{id}/end` | — | Maçı bitir |
| GET | `/api/pk/{id}` | — | Maç durumu |
| GET | `/api/pk/active` | — | Aktif maçlar |
| GET | `/api/pk/me/invites` | — | Bekleyen davetlerim |
| GET | `/api/pk/me/matches` | — | Aktif maçlarım |
| GET | `/api/pk/{id}/stream` | — | SSE (skor, süre, koltuk) |

### Faz 2 — Misafir / Takım

| Metod | Path | Body |
|-------|------|------|
| POST | `/api/pk/room` | `hostStreamId`, `mode`, `seatCount`, `durationSec?` |
| POST | `/api/pk/{id}/start` | — |
| POST | `/api/pk/{id}/seats/join` | `team?`, `seatIndex?`, `streamId?` |
| POST | `/api/pk/{id}/seats/leave` | — |
| POST | `/api/pk/{id}/seats/kick` | `userId` |

`mode`: `1v1` | `guest` | `team`  
`seatCount`: 2, 4, 6, 9 (misafir grid)

### Faz 3 — Liderlik, İstatistik, Premium

| Metod | Path | Query |
|-------|------|-------|
| GET | `/api/pk/leaderboard` | `period`, `metric`, `limit` |
| GET | `/api/pk/me/stats` | JWT |
| GET | `/api/pk/stats/{userId}` | — |
| GET | `/api/pk/me/history` | `page`, `limit` |
| POST | `/api/pk/{id}/events` | `type`, `multiplier?`, `durationSec?` |
| GET | `/api/pk/{id}/events` | — |

**Premium etkinlik türleri:** `lucky_gift` (x2/30s), `golden_minute` (x3/60s), `double_score` (x2/60s), `final_frenzy` (x5/30s)

### Moderasyon (admin)

| Metod | Path |
|-------|------|
| POST | `/api/pk/admin/ban` |
| POST | `/api/pk/admin/unban/{userId}` |
| GET | `/api/pk/admin/bans` |
| POST | `/api/pk/admin/{matchId}/force-end` |
| POST | `/api/pk/admin/{matchId}/force-kick/{userId}` |

---

## 3. SSE Olay Listesi

Bağlantı: `GET /api/pk/{matchId}/stream`  
Auth: `Authorization: Bearer <accessToken>`  
Reconnect: `SseReconnectPolicy` — exponential backoff, max 20 deneme, 401 → refresh.

| `type` | Açıklama |
|--------|----------|
| `match_update` / `score_update` | Skor, süre, koltuk güncellemesi |
| `pk_event` / `multiplier` | Premium çarpan başladı/bitti |
| `ended` / `completed` | Maç bitti |
| `connected` | Bağlantı onayı |

Payload: `{ "type": "...", "match": { ... }, "pkEvent": { ... } }`

---

## 4. Redis Anahtar Yapısı (Backend referans)

Mobil istemci Redis'e doğrudan erişmez; SSE/REST üzerinden canlı durum alır.

| Anahtar deseni | TTL | İçerik |
|----------------|-----|--------|
| `pk:match:{id}` | maç süresi + 60s | Canlı maç JSON |
| `pk:match:{id}:scores` | maç süresi | Sol/sağ anlık puan |
| `pk:stream:{streamId}:active` | 1s cache | Aktif maç id |
| `pk:leaderboard:{period}:{metric}` | 60s | Liderlik snapshot |
| `pk:ban:{userId}` | ban süresi | Yasak durumu |
| `pk:event:{matchId}:active` | etkinlik süresi | Aktif çarpan |

---

## 5. Flutter Dosya / Klasör Yapısı

```
mobile/lib/features/live/
├── data/pk/
│   ├── pk_room_remote_datasource.dart   # REST Faz 1–3
│   └── pk_match_sse_service.dart        # SSE
├── domain/pk/
│   ├── pk_room_models.dart              # PkRoomMatch, PkSeat, PkHistoryEntry
│   ├── pk_event_models.dart             # PkEventType, PkMatchEvent
│   ├── pk_leaderboard_models.dart       # PkLeaderboardEntry, PkStats
│   └── pk_unified_bridge.dart           # Model dönüşümleri
├── presentation/
│   ├── providers/
│   │   ├── pk_room_providers.dart       # pkRoomProvider, SSE, liderlik
│   │   └── live_video_pk_provider.dart  # Canlı 1v1 (birleşik öncelikli)
│   ├── pages/
│   │   ├── live_pk_invite_page.dart
│   │   ├── live_pk_battle_page.dart
│   │   ├── pk_leaderboard_page.dart
│   │   ├── pk_room_history_page.dart
│   │   └── pk_moderation_page.dart
│   └── widgets/pk/
│       ├── pk_room_live_section.dart
│       ├── pk_room_score_overlay.dart
│       ├── pk_room_control_bar.dart
│       └── pk_event_banner.dart
```

Sesli oda PK (ayrı akış): `mobile/lib/features/voice_hub/`

---

## 6. Riverpod Provider Yapısı

| Provider | Tip | Açıklama |
|----------|-----|----------|
| `pkRoomRemoteProvider` | `Provider` | REST datasource |
| `pkMatchSseServiceProvider` | `Provider` | SSE servisi (auto-dispose) |
| `pkRoomProvider(id)` | `Family` | Maç canlı state (SSE + 8s poll) |
| `pkActiveEventProvider(id)` | `Family` | Aktif premium çarpan |
| `activePkRoomProvider(streamId)` | `Family` | Guest/team keşif |
| `activePk1v1Provider(streamId)` | `Family` | 1v1 keşif |
| `pkUnifiedInviteProvider` | `Provider` | Davet/yanıt/bitir aksiyonları |
| `pkLeaderboardProvider(key)` | `Family` | Liderlik tablosu |
| `pkStatsProvider(userId?)` | `Family` | İstatistikler |
| `pkRoomHistoryProvider` | `FutureProvider` | PK geçmişi |
| `liveVideoPkProvider(streamId)` | `Family` | Yayın odası 1v1 overlay |

---

## 7. Hediye Entegrasyonu

`LiveGiftsRemoteDataSource.sendGift` body alanları:

- `pkMatchId` — PK sırasında puanın doğru maça yazılması
- `toUserId` — Misafir koltuğuna hedefli hediye (Faz 2)

Combo: `LiveGiftController` 4 sn pencerede aynı gönderen+hediye → x2/x5/x10/x20 çarpan (UI).

---

## 8. Güvenlik

- JWT Bearer tüm PK uçlarında zorunlu (401 oturumsuz)
- Admin moderasyon: site admin rolü (`staffAccessProvider`)
- Rate limit / flood: backend Redis lock (mobil: `_busy` guard butonlarda)
- SSE: token refresh sonrası yeniden bağlanma (`BaseSseService`)
- PK ban: yasaklı kullanıcı davet/koltuk kullanamaz (backend 403)

---

## 9. Ölçeklenebilirlik

- Canlı durum 1 sn Redis cache → SSE yükünde DB korunur
- Poll yedek: 8 sn (guest/team), 3 sn (1v1 video PK legacy)
- SSE birincil kanal — 50k+ eşzamanlı için backend horizontal scale
- Lazy loading: liderlik/geçmiş sayfalı (`page`, `limit`)
- Image cache: avatar URL'leri `canlifalImageProvider`

---

## 10. Performans (Flutter)

- `RepaintBoundary` hediye animasyonlarında (`live_gift_animation_stack`)
- Final Sprint: son 30 sn `TweenAnimationBuilder` (hafif scale)
- SSE + poll hibrit: ağ kesintisinde poll devam eder
- `AutoDispose` provider'lar — oda kapanınca bellek temizlenir
- 60 FPS hedefi: particle/confetti sınırlı eşzamanlı sayı

---

## 11. Test

```bash
# Birim
flutter test test/core/network/api_backend_router_test.dart
flutter test test/features/live/pk_unified_bridge_test.dart

# API smoke (production PK backend)
bash scripts/verify-pk-endpoints.sh
```

---

## 12. Rotalar (GoRouter)

| Path | Ekran |
|------|-------|
| `/live/pk-invite` | Rakip seç + süre |
| `/live/pk` | 1v1 split-screen savaş |
| `/pk/leaderboard` | Liderlik tabloları |
| `/pk/room-history` | PK geçmişi (birleşik) |
| `/pk/moderation` | Admin ban/zorla bitir |

---

## 13. Yapılan Değişiklikler (1.0.492)

1. `/api/pk/*` istekleri `canlifalapi.abacusai.app`'e yönlendirildi
2. Faz 1 `request` / `respond` / `me/invites` eklendi
3. PK SSE servisi (`/api/pk/{id}/stream`) — skor/süre canlı
4. `live_pk_invite_page` birleşik API + legacy fallback
5. `live_video_pk_provider` birleşik 1v1 öncelikli
6. `pk_unified_bridge` — model uyumluluğu
7. `verify-pk-endpoints.sh` güncellendi
8. Birim testler eklendi

---

## 14. Bilinen Sınırlar

- `canlifal.com` üzerinde `/api/pk/*` henüz 404 — routing games backend'e çözer
- Sesli oda PK ayrı sözleşme (`chat_room_providers` SSE `pk` event)
- TRTC/Agora split-screen cihaz testi gerektirir
