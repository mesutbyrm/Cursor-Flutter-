# GIFT + PK Flutter Sync Report

> **Tarih:** 2026-08-12  
> **Sürüm (dal):** `1.0.161+196` (planlı)  
> **API:** `https://canlifal.com`  
> **Tek kontrat:** `docs/BACKEND_API_REFERENCE.md`

## 1. Kullanılan gerçek endpointler

| Alan | Method | Path | Backend |
|------|--------|------|---------|
| Global hediye ayarları | GET | `/api/gifts/display-settings` | ANA |
| Global hediye ayarları (admin) | PATCH | `/api/gifts/display-settings` | ANA |
| Hediye akışı (poll) | GET | `/api/gifts/insights/feed` | ANA |
| Bildirim SSE | GET | `/api/notifications/stream` | ANA |
| Sesli oda PK | GET/POST | `/api/chat/rooms/{roomId}/pk` | ANA |
| Sesli PK yanıt | POST | `/api/chat/rooms/{roomId}/pk/{inviteId}/respond` | ANA |
| Canlı PK (birincil) | POST | `/api/video-streams/{streamId}/pk-battle` | ANA |
| Canlı PK (toplu) | GET/POST | `/api/video-streams/pk` | ANA |
| Canlı PK liste | GET | `/api/video-streams/pk/list` | ANA |

**Kaldırılan / kullanılmayan (ana backend'de 404):** `POST /api/pk/request`, `GET /api/pk/me/invites` — Flutter artık canlı PK davetinde bunlara fallback yapmıyor.

## 2. HTTP methodları

- Hediye ayarları: GET (public/dual), PATCH (admin)
- PK davet: POST `action: create`
- PK kabul/red: POST `action: accept|reject` + `battleId` veya `.../respond`
- PK skor: POST `/api/video-streams/pk/score` veya oda `/pk/score` (mevcut)

## 3. Request body örnekleri

### Sesli oda PK davet
```json
{
  "action": "create",
  "opponentRoomId": "room_opponent_id",
  "targetRoomId": "room_opponent_id",
  "durationSeconds": 180,
  "guestUserId": "target_user_id"
}
```

### Canlı yayın PK davet (birincil)
```json
{
  "action": "create",
  "opponentStreamId": "stream_b_id",
  "durationSeconds": 180
}
```

### Hediye display settings (admin PATCH)
```json
{
  "durationMs": 3000,
  "position": "topCenter",
  "size": "small",
  "maxQueue": 10,
  "showReceiver": false
}
```

## 4. Response body örnekleri

### GET `/api/gifts/display-settings`
```json
{
  "settings": {
    "enabled": true,
    "durationMs": 3000,
    "position": "topCenter",
    "size": "small",
    "maxQueue": 10,
    "showSender": true,
    "showGiftName": true,
    "showAmount": true
  }
}
```

### POST PK create (başarılı)
```json
{
  "battle": {
    "id": "pk_...",
    "status": "pending",
    "challengerId": "...",
    "opponentId": "...",
    "liveStreamId": "...",
    "opponentLiveStreamId": "..."
  },
  "pk": { }
}
```

## 5. SSE / event isimleri

| Event | Kanal | Hedef |
|-------|-------|-------|
| `gift` / `gift_received` | oda/yayın SSE | GlobalGiftOverlay + GiftEngine |
| `pk` / `pk:invite` | video-stream SSE / socket | hedef yayıncı |
| `PK_INVITATION` (normalize) | `RoomRealtimeEventParser` | davet dialog |
| `PK_ACCEPTED` / `PK_REJECTED` | SSE/socket | gönderen |
| `PK_STARTED` / `PK_SCORE_UPDATE` / `PK_ENDED` | SSE | iki taraf |

## 6. Gift config yapısı

Flutter: `GiftDisplaySettings` — tüm süre/konum/boyut admin'den; hard-code `3000` yok (yalnızca API erişilemezse varsayılan entity).

## 7. PK state machine (backend)

`pending` → `accepted` → `started` / `active` → `ended`  
`pending` → `rejected` | `cancelled` | `expired`

Flutter `PkBattleRemote.status` backend değerini aynen kullanır.

## 8. PK invitation akışı

1. Yayıncı A → POST PK create  
2. Backend `pending` battle + SSE/socket → yalnızca hedef (B)  
3. B → dialog Kabul/Reddet  
4. POST accept → `active` + PK UI  
5. Reddet → `rejected` + A'ya bildirim  

## 9. PK score akışı

Backend hediye/jeton transaction sonrası skor günceller → SSE `PK_SCORE_UPDATE` → `pkBattleRemoteProvider.ingestSseBattle` — tam sayfa refresh yok.

## 10. Değiştirilen backend dosyaları (mirror + deploy stub)

| Dosya | Değişiklik |
|-------|------------|
| `api/src/routes/gifts.ts` | `GET/PATCH /display-settings` |
| `api/src/routes/chat_rooms.ts` | `/pk` alias |
| `api/src/routes/video_streams.ts` | `GET/POST /pk`, `/pk/list` |
| `docs/BACKEND_API_REFERENCE.md` | gift display + PK kontrat güncellemesi |

## 11. Değiştirilen Flutter dosyaları

| Dosya | Değişiklik |
|-------|------------|
| `global_gift_overlay.dart` | Küçük toast UI |
| `global_gift_queue.dart` | Kuyruk + eventId dedupe |
| `global_gift_event_bridge.dart` | SSE bildirim + insights poll |
| `gift_display_settings*.dart` | Admin ayar fetch |
| `main_app_shell.dart` | Global overlay host |
| `gift_event_listener.dart` | Marquee yerine global overlay |
| `staff_entrance_marquee_provider.dart` | Hediye duyurusu devre dışı |
| `pk_battle_remote_datasource.dart` | `opponentStreamId` / `opponentRoomId` öncelik |
| `live_pk_invite_listener.dart` | Ana backend poll (owned streams) |
| `live_pk_invite_page.dart` | `/api/pk/request` fallback kaldırıldı |
| `pk_event_log.dart` | `api_failure` teşhis logu |

## 12. Gerçek cihaz testleri

| Test | Sonuç |
|------|-------|
| Tüm gift/PK checklist | **BLOCKED** — Cloud ortamında adb yok |

Statik: `dart analyze` yeni modüllerde 0 error.

## 13. Kalan hata / risk

- Üretim Next.js `app/api/**` bu workspace'te yok — `api/` mirror + `docs/nextjs/` stub deploy edilmeli.
- `/api/gifts/display-settings` canlifal.com'da henüz yoksa Flutter varsayılan ayarlarla çalışır (TTL 2 dk poll).

## 14. 405 hatasının gerçek nedeni ve çözüm

| Neden | Çözüm |
|-------|--------|
| Flutter `POST /api/pk/request` (ikinci backend, main'de 404/405) | Fallback kaldırıldı |
| Canlı PK body `targetStreamId` önce, backend `opponentStreamId` bekliyor | Body sırası düzeltildi; `pk-battle` path öncelikli |
| Sesli PK `targetRoomId` gönderiliyor, handler `opponentRoomId` | Her iki alan gönderiliyor |
| `/pk` vs `/pk-battle` path drift | API mirror'da `/pk` alias eklendi |

Teşhis: `PkEventLog.api_failure` — method, url, status, roomId, targetUserId, response body (token yok).
