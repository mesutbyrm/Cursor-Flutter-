# Canlifal Web ↔ Flutter Socket / Realtime Parity Report

Tarih: 2026-06-09

## Kaynaklar

- Uretim envanteri: `https://canlifal.com/canlifal-envanter-raporu.txt`
- Yerel Socket.IO aynasi: `api/src/socket/giftHub.ts`
- Sesli oda SSE route'u: `api/src/routes/chat_rooms.ts`
- Flutter sesli oda SSE/socket: `mobile/lib/features/voice_hub/data/services/`
- Flutter canli yayin socket: `mobile/lib/features/live/data/services/live_gift_socket_bridge.dart`
- Flutter PK socket: `mobile/lib/features/voice_hub/data/services/pk_battle_socket_service.dart`
- Flutter TRTC: `mobile/lib/features/trtc/`, `mobile/lib/features/voice_hub/presentation/audio/`

Not: Gercek Next.js web kaynak kodu bu repoda yoktur. Bu rapor uretim
envanteri, yerel API/socket mirror ve Flutter koduna dayanir.

## Socket.IO / SSE / TRTC sozlesmesi

| Alan | Web / API eventleri | Flutter onceki durum | Bu turda yapilan | Durum |
|---|---|---|---|---|
| Sesli oda join/leave | Client emit: `joinRoom`, `leaveRoom` | `joinRoom` vardi; disconnect sadece dispose ediyordu | `disconnect()` artik tum join keyleri icin `leaveRoom` emit eder | Esitlendi |
| Sesli oda hediyeleri | Server: `gift`, `giftSent` | Var | Korundu | Esitlendi |
| Sesli oda mesajlari | Server: `chatMessage`, `message`, `roomMessage` | SSE ile vardi, Socket.IO listener eksikti | Socket listener eklendi; mesaj ID ile dedupe edilip state'e yaziliyor | Esitlendi |
| Sesli oda presence | Server: `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` | SSE ile vardi, Socket.IO listener eksikti | Socket listener eklendi; yalnizca tam `users/presence/members` listesi geldiginde state guncellenir | Esitlendi |
| Sesli oda DJ/muzik | Server: `dj`, `music`, `QUEUE_UPDATED`, `CURRENT_SONG_CHANGED`; SSE `type: dj` | Var | Korundu | Esitlendi |
| Sesli oda reconnect | Socket reconnect sonrasi joinRoom | Rejoin vardi | Connection diagnostic callback eklendi | Esitlendi |
| Canli yayin join/leave | Client emit: `joinStream`, `leaveStream` | Join + disconnect leave vardi | Reconnect sonrasi `joinStream` tekrar emit edilir | Esitlendi |
| Canli yayin hediyeleri | Server: `gift`, `giftSent` | Var | Korundu | Esitlendi |
| Canli yayin chat | Server: `streamMessage`, `chatMessage`, `message` | Var | Korundu | Esitlendi |
| Canli yayin izleyici | Server: `viewerCount`, `viewerCountUpdated` | Var | Korundu | Esitlendi |
| Canli yayin bitis | Server: `streamEnded`, `STREAM_ENDED` | Var | Korundu | Esitlendi |
| PK socket | Client emit: `joinRoom`, `joinStream`, `joinPk`, `leaveRoom`, `leaveStream`, `leavePk`; Server: `pk:*`, `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` | Join/reconnect vardi, leave emitleri eksikti | Disconnect artik `leaveRoom`, `leaveStream`, `leavePk` emit eder | Esitlendi |
| TRTC ses/yayin | API: `POST /api/trtc/usersig`; SDK events: `onEnterRoom`, `onRemoteUserEnterRoom`, `onRemoteUserLeaveRoom`, `onUserAudioAvailable`, `onUserVideoAvailable`, `onError` | Var | Kod degisikligi gerekmedi | Esitlendi |
| SSE reconnect | `GET /api/chat/rooms/:id/stream` | Backoff reconnect vardi | Kod degisikligi gerekmedi | Esitlendi |

## Uygulanan Flutter dosyalari

| Dosya | Degisiklik |
|---|---|
| `mobile/lib/features/voice_hub/data/services/voice_room_gift_socket.dart` | Sesli oda `chatMessage`, `message`, `roomMessage`, `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` listenerlari eklendi; `leaveRoom` emitli disconnect ve connection callback eklendi |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` | Socket mesaj/presence eventleri state'e baglandi; diagnostic socket/presence state guncellendi |
| `mobile/lib/features/live/data/services/live_gift_socket_bridge.dart` | Reconnect sonrasi `joinStream` tekrar emit edilir |
| `mobile/lib/features/voice_hub/data/services/pk_battle_socket_service.dart` | Disconnect sirasinda `leaveRoom`, `leaveStream`, `leavePk` emitleri eklendi |
| `mobile/CHANGELOG.md` | Socket parity surum notu eklendi |

## Flutter tarafinda dinlenen eventler

### Sesli oda

- `gift`
- `giftSent`
- `chatMessage`
- `message`
- `roomMessage`
- `roomUsers`
- `presenceUpdated`
- `userJoined`
- `userLeft`
- `dj`
- `music`
- `QUEUE_UPDATED`
- `CURRENT_SONG_CHANGED`

### Canli yayin

- `gift`
- `giftSent`
- `streamMessage`
- `chatMessage`
- `message`
- `viewerCount`
- `viewerCountUpdated`
- `streamEnded`
- `STREAM_ENDED`
- `pkBattle`
- `pkBattleUpdated`
- `PK_UPDATED`
- `pk:score-update`
- `pk:end`
- `pk:winner`

### PK

- `pk:invite`
- `pk:accept`
- `pk:reject`
- `pk:start`
- `pk:score-update`
- `pk:gift`
- `pk:end`
- `pk:winner`
- `pkBattle`
- `pkBattleUpdated`
- `PK_UPDATED`

### SSE

- `connected`
- `presence`
- `userJoined`
- `userLeft`
- `message`
- `gift` (no-op)
- `dj`
- Unknown payload fallback: `musicUrl` veya `playing` varsa DJ update kabul edilir

## Token / reconnect / disconnect durumu

| Alan | Durum |
|---|---|
| Socket auth token | `VoiceRoomSocketHelper.baseOptions(bearerToken)` ile Authorization/auth token aktariliyor |
| Voice room reconnect | `onReconnect` yeniden `joinRoom` emit eder |
| Live stream reconnect | Bu turda `onReconnect` yeniden `joinStream` emit eder |
| PK reconnect | `onReconnect` yeniden `joinRoom`, `joinStream`, `joinPk` emit eder |
| Voice room disconnect | Bu turda `leaveRoom` emit eder |
| Live stream disconnect | `leaveStream` emit eder |
| PK disconnect | Bu turda `leaveRoom`, `leaveStream`, `leavePk` emit eder |
| SSE reconnect | Exponential-ish backoff: 2s, 4s, ... max 12s |

## Kalan riskler

1. Gercek Next.js web socket kaynak kodu bu repoda yok; yerel `giftHub.ts`
   mirror sozlesmesi esas alindi.
2. Production'da sesli oda icin ana kanal dokumanlara gore SSE + polling'dir;
   Socket.IO listenerlari eklenmis olsa da production server bu eventleri
   yaymazsa SSE yine ana kaynak olarak calisir.
3. `userJoined` / `userLeft` tekil payload yerine tam `users` listesi
   gondermezse Flutter presence listesini bozmamak icin event yok sayilir.
4. TRTC SDK eventleri loglanir; tum cihazlarda runtime medya izinleri manuel
   test gerektirir.

## Test plani

1. Iki cihazla ayni sesli odaya gir:
   - Web kullanicisi mesaj gonderir -> Flutter socket/SSE chat gorur.
   - Flutter kullanicisi mesaj gonderir -> Web gorur.
2. Presence:
   - Web kullanicisi girer/cikar -> Flutter liste guncellenir.
   - Flutter kullanicisi girer/cikar -> Web liste guncellenir.
3. Muzik:
   - Web DJ sarki degistirir -> Flutter mini player ve kuyruk guncellenir.
   - Flutter sarki istegi -> Web kuyruk guncellenir.
4. Hediye:
   - Web/Flutter hediye gonderir -> iki tarafta animasyon/listeler guncellenir.
5. Live:
   - Web/Flutter yayin mesaj/gift/viewer eventleri cift yonlu dogrulanir.
6. PK:
   - Invite, accept, score, gift, end eventleri iki tarafta dogrulanir.
7. TRTC:
   - Sesli oda ve live yayinda `onEnterRoom`, remote audio/video available
     eventleri cihaz loglarinda izlenir.

## Sonuc

Flutter tarafinda yerel web/socket mirror sozlesmesine gore eksik olan sesli oda
message/presence listenerlari, live reconnect join ve PK/voice disconnect leave
emitleri tamamlandi. Yeni backend, yeni API veya yeni database tablosu
olusturulmadi.

