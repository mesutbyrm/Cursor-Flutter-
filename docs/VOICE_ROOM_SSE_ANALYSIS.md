# Sesli Oda — SSE Analiz (Socket.IO değil)

**Üretim:** https://canlifal.com  
**Örnek oda id:** `cmokyb9o9007iod09gi6pb1tb` (GET `/api/chat/rooms`)

## Mimari (doğrulanmış)

| Katman | Teknoloji |
|--------|-----------|
| Gerçek zamanlı | **SSE** `GET /api/chat/rooms/{room.id}/stream` |
| Yedek / DJ / mesaj geçmişi | **HTTP polling** (Flutter: 3 sn `refresh`) |
| Odaya kayıt | **POST** `/api/chat/rooms/{room.id}/presence` (+ 20 sn heartbeat) |
| Ses | **TRTC** `voice_room_{room.id}` |
| Socket.IO | **Kullanılmıyor** (üretimde sohbet/presence için) |

## SSE örnek olaylar (üretim, auth’sız bile 200)

```
data: {"type":"connected","roomId":"cmokyb9o9007iod09gi6pb1tb"}

data: {"type":"typing","users":[]}
```

Tüm olaylar `data:` satırında JSON ve **`type`** alanı ile gelir.

## Flutter — 10 soru cevapları

| # | Soru | Durum (önceki) | Durum (düzeltme sonrası) |
|---|------|----------------|---------------------------|
| 1 | SSE açılıyor mu? | Kısmen — 30 sn sonra Dio `receiveTimeout` kesiyordu | Ayrı SSE Dio, `receiveTimeout: zero`, otomatik yeniden bağlanma |
| 2 | SSE URL? | `https://canlifal.com/api/chat/rooms/{room.id}/stream` | Aynı — `VoiceRoomSseService.streamUrlFor()` |
| 3 | EventSource paketi? | Hayır — Dio `ResponseType.stream` | Aynı (yeterli); ayrı `eventsource` paketi yok |
| 4 | Payload log? | Sınırlı | Her `data:` → `[VoiceRoom] sse.payload` (+ preview) |
| 5 | Presence POST başarılı? | Bearer ile evet (401 giriş yoksa) | `api.presence.post` status + count log |
| 6 | DB’ye yazılıyor mu? | İstemciden doğrulanamaz | Sunucu POST sonrası SSE’ye yayınlar; mobil DB erişimi yok |
| 7 | Mobil girince web SSE görür mü? | Socket varsayımı yüzünden tutarsız | POST presence + sunucu SSE push (web dinliyorsa) |
| 8 | Web girince mobil görür mü? | SSE `type` parse edilmiyordu | `type`: presence / userJoined / users vb. parse |
| 9 | Sadece polling? | SSE + Socket paralel, SSE zayıf | **SSE birincil**; Socket sohbet **kapatıldı**; 3 sn poll yedek |
| 10 | Eksik abonelik? | `type` alanı yoktu | `voice_room_sse_event.dart` + tam `type` switch |

## Flutter dosyaları

- `voice_room_sse_service.dart` — birincil SSE
- `chat_room_providers.dart` — `_startSse()`, Socket kaldırıldı
- `voice_room_chat_socket.dart` — deprecated, kullanılmıyor
- `voice_room_gift_realtime_service.dart` — yalnızca REST poll (6 sn)

## Test (debug build)

Logcat / konsol filtresi: `[VoiceRoom]`

1. `api.presence.join` → `api.presence.join.ok`
2. `sse.subscribe` + `sse.stream_open`
3. `sse.connected` (`type: connected`)
4. Başka cihazdan odaya girince `sse.presence` veya `sse.payload` with presence type
