# websocket_events.md — CanlıFal Gerçek Zamanlı Olay Sözleşmesi

> ## ÖNCE BUNU OKU
> **Bu backend'de WebSocket / Socket.IO sunucusu YOKTUR.** Kaynak taramasında `ws`, `socket.io` veya `WebSocketServer` tabanlı hiçbir sunucu bulunmadı.
> Gerçek zamanlı katman üç parçadan oluşur:
> 1. **SSE (Server-Sent Events)** — `text/event-stream` döndüren **6 kalıcı kanal** (+ yapay zekâ metin akışı için 14 POST ucu).
> 2. **Polling** — `?since=<ISO>` parametreli kısa aralıklı sorgular.
> 3. **TRTC / WebRTC** — ses ve video medya taşıması; sinyalleşme HTTP üzerinden.
>
> Flutter tarafında `web_socket_channel` kullanılmaz. SSE için `http` paketiyle stream okuma veya bir SSE istemcisi kullanılır.
> Bu belgedeki olay adlarının tamamı kaynak koddan çıkarılmıştır. Yeni olay adı uydurulmamıştır.

---

## 1. Kalıcı SSE kanalları (6)

| # | Kanal | Amaç | Alıcı |
|---|---|---|---|
| 1 | `GET /api/chat/rooms/[roomId]/stream` | Sesli sohbet odası | Odadaki herkes |
| 2 | `GET /api/room/[sessionId]/stream` | Falcı 1:1 görüşme odası | Seans tarafları |
| 3 | `GET /api/video-streams/[streamId]/stream` | Canlı yayın | Yayın izleyicileri |
| 4 | `GET /api/pk/[matchId]/stream` | PK maçı | Her iki taraf + izleyiciler |
| 5 | `GET /api/fortune-tellers/sessions/stream` | Falcı seans kuyruğu | Falcı |
| 6 | `GET /api/notifications/stream` | Kullanıcı bildirimleri | Tek kullanıcı |

Bağlanma:

```
GET /api/chat/rooms/{roomId}/stream
Authorization: Bearer <accessToken>
Accept: text/event-stream
```

Kare biçimi: standart SSE — `event: <ad>` satırı + `data: <json>` satırı + boş satır.

---

## 2. Olay kataloğu (kaynaktan doğrulanmış 32 olay adı)

Yön: **S→C** sunucudan istemciye (SSE). SSE tek yönlüdür; istemci bir olayı HTTP POST/PATCH çağrısıyla **tetikler** (C→S sütunu bu çağrıyı gösterir).

### 2.1 Oda yaşam döngüsü (kanal 1 ve 2)

| EVENT NAME | TİP | PAYLOAD (gözlemlenen) | TETİKLEYEN | ALICI |
|---|---|---|---|---|
| `user_joined` | S→C | userId, name, image | `emitUserJoined` — odaya katılma çağrısı | Odadaki herkes |
| `user_left` | S→C | userId | `emitUserLeft` — ayrılma / kopma | Odadaki herkes |
| `room_closed` | S→C | roomId, reason | `emitRoomClosed` — sahip kapatır ya da oda boşalır | Odadaki herkes |
| `owner_changed` | S→C | ownerId | `emitOwnerChanged` | Odadaki herkes |
| `host_changed` | S→C | hostId | `emitHostChanged` | Odadaki herkes |
| `seat_changed` | S→C | seatIndex, userId veya null | `emitSeatChanged` — oturma/kalkma/kilit | Odadaki herkes |
| `mic_changed` | S→C | userId, micOn | `emitMicChanged` | Odadaki herkes |
| `message` | S→C | oda sohbet mesajı | Oda mesaj gönderme ucu | Odadaki herkes |

### 2.2 Söz alma (mikrofon isteği)

| EVENT NAME | TİP | TETİKLEYEN | ALICI |
|---|---|---|---|
| `voice_request` | S→C | `emitVoiceRequest` | Oda yöneticileri |
| `voice_request_accepted` | S→C | `emitVoiceRequestAccepted` | İstek sahibi + oda |
| `voice_request_rejected` | S→C | `emitVoiceRequestRejected` | İstek sahibi |
| `voice_request_cancelled` | S→C | `emitVoiceRequestCancelled` | Oda yöneticileri |
| `voice_request_blocked` | S→C | `emitVoiceRequestBlocked` | İlgili kullanıcı |
| `voice_request_unblocked` | S→C | `emitVoiceRequestUnblocked` | İlgili kullanıcı |
| `hand_raised` | S→C | El kaldırma çağrısı | Oda yöneticileri |
| `guest_invited` | S→C | Konuk daveti | Davet edilen |
| `guest_rejected` | S→C | Davet reddi | Davet eden |

### 2.3 Hediye ve PK

| EVENT NAME | TİP | PAYLOAD | TETİKLEYEN | ALICI |
|---|---|---|---|---|
| `gift_received` | S→C | gönderen, alıcı, hediye tipi, adet, animasyon | Hediye gönderme ucu (sunucu hesapladıktan sonra) | Oda / yayın izleyicileri |
| `pk_invite` | S→C | matchId, from, to | `emitPkInvite` | Davet edilen taraf |
| `pk_requested` | S→C | matchId | `emitPkToBothSides` | Her iki taraf |
| `match_update` | S→C | matchId, skorlar, durum | Hediyeyle skor değişimi (`applyGiftPkScore`) veya durum geçişi | PK kanalı aboneleri |

### 2.4 Moderasyon ve yayın (büyük harfli aile)

| EVENT NAME | TİP | TETİKLEYEN | ALICI |
|---|---|---|---|
| `USER_BANNED` | S→C | Yayın/oda ban ucu | İlgili kullanıcı + oda |
| `USER_KICKED` | S→C | Atma ucu | İlgili kullanıcı + oda |
| `USER_MUTED` / `USER_UNMUTED` | S→C | Susturma ucu | İlgili kullanıcı + oda |
| `ROOM_MUTED` / `ROOM_UNMUTED` | S→C | Oda geneli susturma | Odadaki herkes |
| `CHAT_CLEARED` | S→C | Sohbet temizleme | Odadaki herkes |
| `ANNOUNCEMENT` | S→C | Yönetici duyurusu | Hedef kitle |
| `STREAM_ENDED` | S→C | Yayın bitişi veya `media-heartbeat` kesilmesi (`lib/stream-auto-close.ts`) | İzleyiciler |
| `QUEUE_UPDATED` | S→C | Müzik / söz kuyruğu değişimi | Odadaki herkes |
| `session_cancelled` | S→C | Falcı seansı iptali | Seans tarafları |
| `streamMessage` | S→C | Yayın sohbet mesajı | İzleyiciler |
| `impression` | S→C | Görüntülenme sayacı | İlgili istemci |
| `not_found` | S→C | Abone olunan kaynak yok | Abone |

### 2.5 Sunucu tarafı yayıcı fonksiyonlar (19)

`emitChatEvent`, `emitRoomEvent`, `emitTellerEvent`, `emitStreamEvent`, `emitUserJoined`, `emitUserLeft`, `emitMicChanged`, `emitSeatChanged`, `emitHostChanged`, `emitOwnerChanged`, `emitRoomClosed`, `emitPkInvite`, `emitPkToBothSides`, `emitVoiceRequest`, `emitVoiceRequestAccepted`, `emitVoiceRequestRejected`, `emitVoiceRequestCancelled`, `emitVoiceRequestBlocked`, `emitVoiceRequestUnblocked`, ayrıca `emitDjUpdate`.

Kaynak: `lib/chat-events.ts`, `lib/room-events.ts`, `lib/voice-room-events.ts`, `lib/stream-events.ts`, `lib/chat-dj-events.ts`.

---

## 3. Polling kanalları

| Endpoint | Önerilen aralık | Not |
|---|---|---|
| `GET /api/presence/online-events?since=<ISO>` | 8 sn | Web'de online giriş kartları bu aralıkta çalışıyor |
| `GET /api/presence` | 15–30 sn | Genel varlık durumu |
| `GET /api/chat/rooms/[roomId]/presence` | 10–15 sn | Oda katılımcı sayacı |
| `POST /api/video-streams/[streamId]/media-heartbeat` | Yayıncı için zorunlu | Kesilirse yayın otomatik kapanır (`lib/stream-auto-close.ts`) |

---

## 4. Medya taşıma (TRTC / WebRTC)

Sinyalleşme HTTP üzerinden yapılır (WebSocket değil):
`GET|POST|DELETE /api/room/signal` · `GET|POST|DELETE /api/video-streams/signal` · `GET|POST|DELETE /api/video-streams/[streamId]/signal`

TRTC uçları: `POST /api/trtc/usersig` (gövde: `userId`, `roomId`), `/api/trtc/token`, `/api/trtc/webhook`, `/api/tencent/webhook`, `/api/live/create-room`, `/api/live/join-room`.
Kütüphaneler: `lib/trtc-client.ts`, `lib/trtc-room.ts` (`voiceTrtcRoomId`, `userIdToNumericUid`), `lib/webrtc-config.ts` (`ICE_SERVERS`, `getRTCConfiguration`, `BITRATE_PRESETS`, `SIMULCAST_ENCODINGS`).

Flutter tarafında TRTC SDK kullanılmalı; `usersig` **sunucudan** alınır, istemcide üretilmez.

---

## 5. Flutter bağlantı kuralları

1. **Yeniden bağlanma:** SSE koptuğunda üstel geri çekilme (1s → 2s → 4s → en fazla 30s) ile yeniden aç.
2. **Arka plan:** Android'de uygulama arka plana alınınca SSE bağlantısını kapat; öne gelince yeniden aç ve kaçırılan durumu REST/`?since=` ile telafi et.
3. **`Last-Event-ID` tabanlı yeniden oynatma DOĞRULANMADI** — güvenli yol, yeniden bağlanınca durumu REST ile baştan çekmektir.
4. **Tek bağlantı ilkesi:** Aynı anda en fazla 2 kalıcı SSE (oda + bildirim).
5. **Olay adlarını sabitle:** Yukarıdaki adları Dart sabiti olarak tanımla; bilinmeyen olay gelirse sessizce yok say.

---

## 6. Tüm SSE uçları (taramadan)

> Toplam **20** endpoint (path+method). Kaynak: üretim kodu taraması, 2026-09-12.

| METHOD | ENDPOINT | AUTH | ÖZELLİK | QUERY | BODY ALANLARI | KAYNAK DOSYA |
|---|---|---|---|---|---|---|
| `GET` | `/api/chat/rooms/[roomId]/stream` | mobil JWT + web oturum | ADMIN, SSE | lastEventId | — | `app/api/chat/rooms/[roomId]/stream/route.ts` |
| `GET` | `/api/fortune-tellers/sessions/stream` | mobil JWT + web oturum | SSE | — | — | `app/api/fortune-tellers/sessions/stream/route.ts` |
| `POST` | `/api/fortunes/ask-uyumu` | mobil JWT | SSE | — | — | `app/api/fortunes/ask-uyumu/route.ts` |
| `POST` | `/api/fortunes/aura-analizi` | mobil JWT | SSE | — | — | `app/api/fortunes/aura-analizi/route.ts` |
| `POST` | `/api/fortunes/burc-yorumu` | mobil JWT | SSE | — | — | `app/api/fortunes/burc-yorumu/route.ts` |
| `POST` | `/api/fortunes/dogum-haritasi` | mobil JWT | SSE | — | — | `app/api/fortunes/dogum-haritasi/route.ts` |
| `POST` | `/api/fortunes/el-fali` | mobil JWT | SSE | — | — | `app/api/fortunes/el-fali/route.ts` |
| `POST` | `/api/fortunes/evet-hayir` | mobil JWT | SSE | — | — | `app/api/fortunes/evet-hayir/route.ts` |
| `POST` | `/api/fortunes/istihare` | mobil JWT | SSE | — | — | `app/api/fortunes/istihare/route.ts` |
| `POST` | `/api/fortunes/kahve-fali` | mobil JWT | SSE | — | — | `app/api/fortunes/kahve-fali/route.ts` |
| `POST` | `/api/fortunes/kahve-fali-image` | mobil JWT | SSE | — | — | `app/api/fortunes/kahve-fali-image/route.ts` |
| `POST` | `/api/fortunes/katina` | mobil JWT | SSE | — | — | `app/api/fortunes/katina/route.ts` |
| `POST` | `/api/fortunes/melek-kartlari` | mobil JWT | SSE | — | — | `app/api/fortunes/melek-kartlari/route.ts` |
| `POST` | `/api/fortunes/numeroloji` | mobil JWT | SSE | — | — | `app/api/fortunes/numeroloji/route.ts` |
| `POST` | `/api/fortunes/ruya-yorumu` | mobil JWT | SSE | — | — | `app/api/fortunes/ruya-yorumu/route.ts` |
| `POST` | `/api/fortunes/tarot-fali` | mobil JWT | SSE | — | — | `app/api/fortunes/tarot-fali/route.ts` |
| `GET` | `/api/notifications/stream` | mobil JWT | SSE | — | — | `app/api/notifications/stream/route.ts` |
| `GET` | `/api/pk/[matchId]/stream` | public | SSE | — | — | `app/api/pk/[matchId]/stream/route.ts` |
| `GET` | `/api/room/[sessionId]/stream` | mobil JWT + web oturum | SSE | — | — | `app/api/room/[sessionId]/stream/route.ts` |
| `GET` | `/api/video-streams/[streamId]/stream` | mobil JWT | SSE | — | — | `app/api/video-streams/[streamId]/stream/route.ts` |

---

## GÜNCELLEME 2026-09-12 — SSE Yeniden Bağlanma Sözleşmesi (GERÇEK KOD)

WebSocket **yoktur**. Gerçek zamanlı kanal = Server-Sent Events (20 uç) + yoklama (`?since=`) + TRTC/WebRTC.

`lib/sse-resume.ts` ortak yardımcıları eklendi: `parseLastEventId`, `resumeCursor`, `newestTimestamp`, `sseIdLine`.

### Sözleşme

1. Sunucu her olaydan sonra `id: <epoch_ms>` satırı yayar.
2. İstemci bağlantı koparsa **`Last-Event-ID` başlığı** ile yeniden bağlanır (Dart `EventSource` paketleri bunu otomatik yapar; el ile `http` kullanılıyorsa başlık elle eklenmelidir).
3. Sunucu `Last-Event-ID` yoksa `?since=<epoch_ms>` sorgu parametresine düşer; o da yoksa "şu andan itibaren" başlar.
4. İstemci **kendi tarafında yinelenen olay ayıklaması (dedupe)** yapmalıdır: olay `id`'lerini bir `Set` içinde tutun (500 kayıtta kırpın). Aynı olayın iki kez gelmesi normaldir.
5. Yeniden bağlanma aralığı: 1 sn → 2 → 4 → 8, üst sınır 30 sn (üstel geri çekilme + jitter).

### Kanallar

| Kanal | Last-Event-ID | Tekrar oynatma (replay) |
|---|---|---|
| `/api/chat/rooms/[roomId]/stream` | ✅ | bellek içi olay tamponu |
| `/api/notifications/stream` | ✅ | **veritabanından gerçek tekrar oynatma**, en fazla 24 saat geriye, tek seferde 50 kayıt |
| `/api/room/[sessionId]/stream` | ✅ | imleçten sonraki olaylar |
| `/api/video-streams/[streamId]/stream` | ✅ | imleçten sonraki olaylar |
| `/api/fortune-tellers/sessions/stream` | ✅ | imleçten sonraki olaylar |
| `/api/pk/[matchId]/stream` | ✅ (yalnız `id` yayar) | gerekmez — her olay tam anlık görüntüdür |
| diğer 14 SSE ucu | ❌ | durum anlık görüntüsü / düşük kritiklik |

### Bilinen sınır
Olay veriyolu **süreç içidir**. Çok örnekli (multi-instance) dağıtımda süreçler arası garantili tekrar oynatma yalnız veritabanı destekli `notifications` kanalında vardır. Kritik veri asla yalnızca SSE'ye dayanmamalı; istemci ekrana girişte REST ile durumu tazelemelidir.

---

## BÖLÜM 22 olayları

Tam payload örnekleri: **BOLUM22_MULTIGUEST_PK_GIFTBOX.md** (§5).

- Misafir (`type: "guest"`): guest_request_created, guest_request_accepted, guest_request_rejected, guest_request_cancelled, guest_invited, guest_joined, guest_left, guest_removed, guest_muted, guest_camera_off, guest_position_changed, guest_updated, guest_grid_changed
- PK (`eventType`): PK_STARTING, PK_STARTED, PK_SCORE, PK_PAUSED, PK_RESUMED, PK_ENDED, PK_REQUEST_REJECTED, PK_REQUEST_CANCELLED, PK_EXPIRED
- Hediye kutusu (`type: "gift_box"`): gift_box_created, gift_box_started, gift_box_joined, gift_box_task_verified, gift_box_winner, gift_box_reward_distributed, gift_box_finished, gift_box_expired, gift_box_cancelled
