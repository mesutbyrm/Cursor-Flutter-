# CanlıFal — Gerçek Zamanlı Katman (Flutter Sözleşmesi)

Sistemde **WebSocket sunucusu yoktur.** Gerçek zamanlılık üç mekanizma ile sağlanır:

1. **SSE (Server-Sent Events)** — sunucudan istemciye tek yönlü akış
2. **Kısa aralıklı polling** — `?since=` imleçli olay kuyrukları
3. **TRTC / WebRTC** — ses-görüntü medya katmanı

---

## 1. SSE kanalları (`Content-Type: text/event-stream`)

| Kanal | Path | Amaç |
|---|---|---|
| Sohbet odası | `GET /api/chat/rooms/[roomId]/stream` | Mesaj, hediye, koltuk, mikrofon, moderasyon olayları |
| Sesli/görüntülü oda | `GET /api/room/[sessionId]/stream` | Seans içi olaylar |
| Canlı yayın | `GET /api/video-streams/[streamId]/stream` | Yayın olayları, izleyici, hediye |
| PK düellosu | `GET /api/pk/[matchId]/stream` | `match_update` skoru |
| Falcı seansları | `GET /api/fortune-tellers/sessions/stream` | Sıra/seans durumu |
| Bildirimler | `GET /api/notifications/stream` | Kullanıcı bildirimleri |

Ayrıca **fal üretim endpoint’leri** yanıtı SSE ile parça parça akıtır (LLM token akışı):
`/api/fortunes/{kahve-fali, kahve-fali-image, tarot-fali, ruya-yorumu, el-fali, burc-yorumu, dogum-haritasi, numeroloji, katina, melek-kartlari, istihare, evet-hayir, aura-analizi, ask-uyumu}` — hepsi **POST** + SSE gövdesi.

> Flutter: `http` paketiyle `StreamedResponse` veya `dio` `ResponseType.stream` kullanın; `flutter_client_sse` de uygundur. Bearer başlığı SSE isteklerinde de gereklidir.

## 2. Olay adları (event payload `event` alanı)

`lib/chat-events.ts`, `lib/room-events.ts`, `lib/voice-room-events.ts`, `lib/stream-events.ts`

| Grup | Olaylar |
|---|---|
| Oda üyeliği | `user_joined`, `user_left`, `room_closed`, `owner_changed`, `host_changed` |
| Koltuk / mikrofon | `seat_changed`, `mic_changed` |
| Söz isteği | `voice_request`, `voice_request_accepted`, `voice_request_rejected`, `voice_request_cancelled`, `voice_request_blocked`, `voice_request_unblocked`, `hand_raised` |
| Konuk | `guest_invited`, `guest_rejected` |
| Hediye | `gift_received` |
| PK | `pk_invite`, `pk_requested`, `match_update` |
| Moderasyon | `USER_BANNED`, `USER_KICKED`, `USER_MUTED`, `USER_UNMUTED`, `ROOM_MUTED`, `ROOM_UNMUTED`, `CHAT_CLEARED`, `ANNOUNCEMENT` |
| Yayın | `STREAM_ENDED`, `QUEUE_UPDATED`, `impression` |

Yayıcı fonksiyonlar: `emitChatEvent`, `emitRoomEvent`, `emitTellerEvent`, `emitStreamEvent`, `emitUserJoined`, `emitUserLeft`, `emitMicChanged`, `emitSeatChanged`, `emitHostChanged`, `emitOwnerChanged`, `emitRoomClosed`, `emitPkInvite`, `emitPkToBothSides`, `emitVoiceRequest*`.

## 3. Polling kanalları

| Path | Aralık | Not |
|---|---|---|
| `GET /api/presence/online-events?since=<ts>` | **8 sn** | Gold kullanıcı giriş kartları; `id` ile tekilleştirin |
| `GET /api/chat/rooms/[roomId]/...` durum uçları | 3–10 sn | Oda durumu senkronizasyonu |
| `GET /api/video-streams/[streamId]/viewers` | 10 sn | İzleyici sayacı |
| `POST /api/video-streams/[streamId]/media-heartbeat` | 15–30 sn | Yayın canlılık sinyali; kesilirse yayın otomatik kapanır (`lib/stream-auto-close.ts`) |

## 4. WebRTC sinyalizasyonu

| Method | Path | Amaç |
|---|---|---|
| GET / POST / DELETE | `/api/room/signal` | Oda içi peer sinyalleşmesi (offer/answer/ICE) |
| GET / POST / DELETE | `/api/video-streams/signal` | Yayın sinyalleşmesi |
| GET / POST / DELETE | `/api/video-streams/[streamId]/signal` | Yayına özel sinyalleşme |

ICE/TURN yapılandırması: `lib/webrtc-config.ts` (`ICE_SERVERS`, `getRTCConfiguration`, `BITRATE_PRESETS`, `SIMULCAST_ENCODINGS`).

## 5. TRTC (Tencent RTC) — mobil için önerilen medya yolu

| Method | Path | Amaç |
|---|---|---|
| POST | `/api/trtc/usersig` | `{ userId, roomId }` → UserSig üretimi |
| GET/POST | `/api/trtc/token` | Oda token’ı |
| POST | `/api/trtc/webhook` | Tencent olay geri bildirimi (sunucu-sunucu) |
| POST | `/api/tencent/webhook` | Tencent olay geri bildirimi (sunucu-sunucu) |
| POST | `/api/live/create-room` | Canlı oda oluştur |
| POST | `/api/live/join-room` | Canlı odaya katıl |

Yardımcılar: `lib/trtc-client.ts` (`fetchTRTCCredentials`, `enterRoom`, `startLocalVideo/Audio`, roller), `lib/trtc-room.ts` (`voiceTrtcRoomId`, `userIdToNumericUid`).

**Flutter:** `tencent_trtc_cloud` paketi ile `/api/trtc/usersig`’ten alınan UserSig kullanılarak odaya girilir. WebRTC sinyalizasyon uçları tarayıcı içindir; mobilde TRTC yolu tercih edilmelidir.

## 6. Push bildirimleri

`lib/push.ts`, `lib/onesignal.ts`, `lib/notify.ts`

- Sağlayıcı: **OneSignal** (`PUSH_PROVIDER`), `sendPush` / `sendPushBulk`.
- Bildirim oluşturma + push: `createNotificationWithPush`, `createBulkNotificationsWithPush`.
- Derin bağlantı: `lib/deeplink.ts` → `DEEPLINK_SCHEME`, `buildDeepLink`, `resolveDeepLink`. Flutter tarafında aynı şema ile yönlendirme yapılmalıdır.
- Tekilleştirme: `buildNotificationDedupeKey` + `DEFAULT_DEDUPE_WINDOW_SECONDS`.
