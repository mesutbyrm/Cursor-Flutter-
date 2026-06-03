# Sesli Sohbet Odaları — Web ↔ Flutter Senkron Analiz Raporu

**Tarih:** 2026-05-19  
**Kapsam:** Canlifal.com sesli oda API, Socket.IO, TRTC ses katmanı, Flutter `voice_hub`  
**Depo:** Bu rapor `/workspace` kod tabanına dayanır; üretim Next.js web istemcisi bu repoda yoktur.

---

## 1. Özet

Web ve Flutter’ın aynı odada birbirini görmemesinin ana nedenleri **oda kimliği (id vs slug)**, **presence’ın yalnızca REST ile tutulması**, **Socket.IO’da presence olaylarının eksikliği**, **Flutter’ın JWT’siz socket bağlantısı (eski sürüm)** ve **TRTC kanal adı uyumsuzluğu** idi. Mesajların görünüp sesin çalışmaması (veya tersi), sohbet ile sesin **farklı katmanlarda** (REST/Socket vs TRTC) ilerlemesinden kaynaklanır.

Bu dalda (`cursor/voice-web-flutter-sync-7009`) Flutter tarafı güçlendirildi; API aynasına presence socket yayınları eklendi.

---

## 2. Mimari

| Katman | Teknoloji | Rol |
|--------|-----------|-----|
| Oda listesi / mesaj / üye | REST `/api/chat/rooms/*` | Kalıcı durum (in-memory store + Prisma odaları üretimde) |
| Anlık mesaj / hediye | Socket.IO `/socket.io` | `joinRoom` → `room:{roomId}` kanalları |
| Ses | **TRTC** (`POST /api/trtc/usersig`) üretimde | LiveKit üretimde **404** |
| Flutter state | Riverpod (`voiceRoomLiveProvider`) | 3 sn REST poll + socket dinleyicileri |

---

## 3. A — API Analizi

### 3.1 Ortak endpointler (web + mobil aynı host)

| İşlem | Metot | Yol |
|--------|--------|-----|
| Oda listesi | GET | `/api/chat/rooms` |
| Mesajlar | GET | `/api/chat/rooms/:roomId/messages` |
| Mesaj gönder | POST | `/api/chat/rooms/:roomId/messages` |
| Presence oku | GET | `/api/chat/rooms/:roomId/presence` |
| Odaya katıl | POST | `/api/chat/rooms/:roomId/presence` |
| Odadan ayrıl | DELETE | `/api/chat/rooms/:roomId/presence` |
| DJ durumu | GET/POST | `/api/chat/rooms/:roomId/dj` |
| Konuşma isteği | POST/DELETE | `/api/chat/rooms/:roomId/speak-request` |
| TRTC imza | POST | `/api/trtc/usersig` |
| LiveKit (yerel API) | POST | `/api/livekit/token` |

### 3.2 Kritik: `roomId` vs `slug`

`chatRoomStore.resolveRoomId()` tüm haritaları **canonical Prisma `id`** ile anahtarlar. URL’de slug (`sohbet`, `ilhamperisi-xxx`) kullanılsa bile presence/mesajlar aynı `id` altında birleşir.

**Risk:** Socket `joinRoom` yalnızca `room:slug` ile yapılırsa, sunucu mesajı `room:canonicalId`’ye yayınlar → istemci mesaj alamaz.  
**Çözüm:** Hem `id` hem `slug` ile `joinRoom` + `voiceRoomTargets()` ile çift yayın (`giftHub.ts`).

### 3.3 Response modelleri

| Alan (API) | Flutter `ChatRoomPresence` |
|------------|---------------------------|
| `id`, `name`, `nickname`, `image` | ✓ + alias `userId`, `avatarUrl` |
| `chatRole`, `roleSymbol`, `membership` | ✓ |
| `seatIndex`, `isSpeaking` | ✓ |
| `joinedAt` | API’de var; Flutter yok sayar (UI için yeterli) |

Mesajlar: `content`, `createdAt`, `user` — Flutter `body`/`text` alias’larını da okur.

### 3.4 Eşleşmesi gereken token’lar

- **REST:** `Authorization: Bearer <JWT>` — `joinPresence` **401** olursa kullanıcı listede görünmez.
- **Socket:** `auth.token` + `Authorization` header (Flutter `VoiceRoomSocketHelper`).
- **TRTC:** `userId` = uygulama kullanıcı id’si; `roomId` = TRTC oda string’i (id veya slug; ikisi de denenmeli).

---

## 4. B — Socket / WebSocket Analizi

### 4.1 Repoda gerçekten var olan olaylar (`api/src/socket/giftHub.ts`)

**İstemci → sunucu**

| Olay | Payload |
|------|---------|
| `joinRoom` | `{ roomId: string }` |
| `leaveRoom` | `{ roomId: string }` |
| `joinStream` / `leaveStream` | canlı yayın |

**Sunucu → istemci**

| Olay | Açıklama |
|------|----------|
| `chatMessage`, `message`, `roomMessage` | Yeni sohbet satırı |
| `gift`, `giftSent` | Hediye |
| `roomUsers`, `presenceUpdated` | Tam üye listesi (**bu dalda eklendi**) |
| `userJoined`, `userLeft` | Delta presence (**bu dalda eklendi**) |

### 4.2 Kullanıcının listelediği ama repoda **olmayan** olaylar

`userMuted`, `userUnmuted`, `microphoneStatusChanged`, `voiceStateChanged`, `speakerJoined`, `speakerLeft`, `typing`, `roomUpdated` — **bu API aynasında yok**. Mikrofon durumu TRTC SDK içinde; `isSpeaking` yalnızca REST `approveSpeak` ile güncellenir.

### 4.3 Flutter dinleyicileri

| Dosya | Dinlediği olaylar |
|-------|-------------------|
| `voice_room_chat_socket.dart` | `chatMessage`, `message`, `roomMessage`, `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` |
| `voice_room_gift_socket.dart` | `gift`, `giftSent` |

---

## 5. C — Ses Sistemi (TRTC)

- **Üretim:** `POST /api/livekit/token` → 404; `POST /api/trtc/usersig` → 200.
- **Flutter:** `canlifal.com` için doğrudan TRTC (`VoiceRoomAudioCoordinator`).
- **Sahne:** `TRTCAppScene.voiceChatRoom`, `audioOnly: true`.
- **Oda anahtarı:** Önce `apiRoomKey` (id), başarısızsa `apiRoomAlternateKey` (slug).

**Ses var, liste yok:** TRTC kanala girilmiş ama `POST .../presence` başarısız (JWT yok / 401).  
**Liste var, ses yok:** Presence REST OK; TRTC `roomId` yanlış veya mikrofon kapalı.

---

## 6. D — Kullanıcı Listesi Senkronizasyonu

| Olay | Önceki durum | Düzeltme |
|------|--------------|----------|
| Kullanıcı girer | Yalnızca REST; karşı taraf 3 sn poll | Socket `userJoined` + `roomUsers` |
| Kullanıcı çıkar | Aynı | Socket `userLeft` |
| Mikrofon (konuşmacı) | `approveSpeak` REST | Socket presence yenileme (approve sonrası emit) |
| Moderatör ban | REST + sistem mesajı | Mesaj socket; presence leave emit |

Flutter: socket presence + 3 sn `fetchPresence` yedek poll.

---

## 7. E — Flutter Tarafı

| Bileşen | Dosya |
|---------|--------|
| Canlı oda state | `chat_room_providers.dart` → `VoiceRoomLiveController` |
| REST | `chat_room_remote_datasource.dart` |
| Socket sohbet | `voice_room_chat_socket.dart` |
| Socket hediye | `voice_room_gift_socket.dart` |
| Ses | `voice_room_audio_coordinator.dart` + `voice_room_rtc_page.dart` |
| Debug log | `voice_room_debug_log.dart` (debug build) |

State management: **Riverpod** (`AutoDisposeFamilyNotifier`).

---

## 8. F — Veri Modeli

Web TypeScript (`ChatPresenceRow`) ile Flutter `ChatRoomPresence` alanları uyumlu. Ek alias’lar Flutter’da bilinçli (geriye dönük API şekilleri).

---

## 9. G — Log ve Debug

Debug modda `[VoiceRoom]` önekli loglar:

- `api.presence.join` / `join.ok` / `join.fail`
- `socket.connecting` / `connect` / `disconnect` / `chatMessage` / `roomUsers` …
- `audio.trtc.token` / `joined` / `fail`

---

## 10. H — Bulunan Sorunlar, Nedenler, Dosyalar, Çözümler

| # | Sorun | Neden | Etkilenen dosyalar | Çözüm |
|---|--------|--------|---------------------|--------|
| 1 | Web mobil kullanıcıyı görmüyor | Mobil `joinPresence` yok / JWT yok | `chat_room_providers.dart`, auth | Giriş zorunlu; `joinPresence` hata mesajı |
| 2 | Mobil web kullanıcıyı görmüyor | Aynı + slug/id | `voice_room_socket_helper.dart`, `giftHub.ts` | Çift `joinRoom`; canonical id |
| 3 | Mesaj var ses yok | TRTC oda id uyumsuz | `voice_room_audio_coordinator.dart` | id + slug TRTC denemesi |
| 4 | Ses var mesaj yok | Socket yanlış oda kanalı | `giftHub.ts`, `voice_room_chat_socket.dart` | Çift oda emit + çift join |
| 5 | Liste gecikmeli | Presence socket yoktu | `giftHub.ts`, `chat_rooms.ts` | `emitChatRoomPresence` |
| 6 | LiveKit hatası | Üretimde endpoint yok | `env.dart`, coordinator | TRTC önceliği canlifal.com’da |
| 7 | YouTube arama | Üretim API auth ister | `chat_room_remote_datasource.dart` | Önce `/api/youtube/search` |

### Üretim notu

`api/` klasörü yerel aynadır. **canlifal.com** üretim sunucusuna `emitChatRoomPresence` ve çift oda yayını deploy edilmeden, web istemcisi hâlâ yalnızca poll kullanıyorsa liste gecikmesi sürebilir. Flutter socket dinleyicileri üretimde bu olayları yayınlayan backend ile anında senkron olur.

### Web istemcisi (repoda yok)

Üretim web’in şunları yapması gerekir:

1. `POST /api/chat/rooms/:id/presence` (slug değil mümkünse **id**)
2. Socket: JWT + `joinRoom` hem **id** hem **slug**
3. `roomUsers` / `presenceUpdated` dinle veya en az 2–3 sn `GET presence` poll
4. TRTC `roomId` = backend’in döndürdüğü değer (mobil ile aynı)

---

## 11. Uygulanan düzeltmeler (bu dal)

- JWT + çift `joinRoom` (id/slug)
- Mesaj/hediye çift oda emit (`voiceRoomTargets`)
- TRTC id/slug fallback
- Presence socket emit + Flutter dinleyiciler
- `VoiceRoomDebugLog`
- 3 sn presence/mesaj poll (yedek)

---

## 12. Doğrulama checklist

1. İki hesap: biri web, biri APK — aynı oda slug’ı.
2. Her iki tarafta giriş yapılmış olmalı.
3. Flutter log: `api.presence.join.ok`, `audio.trtc.joined`, `socket.connect`.
4. Web kullanıcısı 3 sn içinde mobil listede görünmeli (socket veya poll).
5. Mesaj gönderimi karşıda anında (`chatMessage`).
6. Mikrofon: TRTC kanalında; karşı taraf kulaklık/ses açık.

---

## 13. İlgili PR

https://github.com/mesutbyrm/Cursor-Flutter-/pull/95
