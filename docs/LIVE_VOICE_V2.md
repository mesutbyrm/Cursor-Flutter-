# LIVE + VOICE V2

Canlifal Flutter — Canlı Yayın + Sesli Sohbet Odaları (Aşama 7)

## Tencent RTC

- SDK: `tencent_rtc_sdk` (Agora kullanılmaz)
- Token: `POST /api/trtc/token` → `TrtcRemoteDataSource.fetchToken()`
- Yedek: `POST /api/trtc/usersig`
- Sesli oda: `VoiceTrtcEngine.joinVoice()` — TRTC bilgisi `GET /state` snapshot `roomTrtc`
- Canlı yayın: `TrtcLiveRoomCoordinator` — `POST /api/live/join-room` compound join + token

## Join Flow

### Sesli oda
1. Auth kontrolü (`openVoiceRoomWithVipGate`)
2. `prepareVoiceRoomSwitch` — önceki oda LEAVE
3. `_beginRoomSession`: presence join → state + seats → SSE → poll
4. Sayfa: `backendSyncReady` + `roomTrtc` → `VoiceRoomAudioCoordinator.join()` → TRTC

### Canlı yayın
1. `TrtcLiveRoomCoordinator.join()` — join-room + TRTC enter
2. `LiveRoomController` — video-stream SSE + chat

## Leave Flow

`leaveRoomSession()` sırası:
1. Timer iptal (poll, heartbeat, SSE debounce)
2. Optimistic presence düşür
3. Backend leave + seat clear
4. TRTC/audio leave
5. Local state + SSE release + gift/PK temizliği

`RoomLeaveCoordinator` — idempotent çıkış

## Room State

- **Tek kaynak:** `voiceRoomLiveProvider` (`VoiceRoomLiveController`)
- Fragment selectors: `room_fragment_providers.dart`
- State: presence, seats, ownerId, roomTrtc, hubOnlineCount, PK, DJ, messages

## Participants

- Merge: `_mergePresenceStable()` + `dedupePresencesById()`
- Canonical ID: `userId` > `id` (`presence_canonical.dart`)
- Server reconciliation: authoritative kaynaklarda boş liste = gerçekten boş
- Optimistic self: `_seedOptimisticSelfPresence()` — server ile reconcile

## Presence

- REST: `PATCH/POST /api/chat/rooms/{id}/presence` `{ action: join|leave|heartbeat }`
- SSE: `GET /api/chat/rooms/{id}/stream` — presence, join, leave events
- Hub sayaç: `voiceRoomsPresenceProvider.patchRoomCount`

## Heartbeat

| Katman | Interval | Endpoint |
|--------|----------|----------|
| Voice presence | 15s | chat room presence heartbeat |
| Live TRTC | 10s | `POST /api/live/heartbeat` |

- Tek timer: `_presenceHeartbeat` / `TrtcLiveRoomCoordinator._heartbeat`
- Leave/dispose: `_cancelSessionTimers()` / `_heartbeat?.cancel()`
- SSE sağlıklıyken voice heartbeat no-op (<45s)

## Seats

- API: `POST/PATCH /api/chat/rooms/{id}/seats` — `{ action: take|leave|swap|kick }`
- **Not:** Voice odalar `/api/live/seats` kullanmaz (chat seats)
- Refresh: `_refreshSeatsFromBackend()` after SSE/seat events

## Owner Auto Seat

- `_tryAutoPrivilegedSeat()` after presence join
- Priority: owner → founder → admin → mod → DJ
- Backend onay + `_refreshSeatsFromBackend()` — optimistic kalıcı değil

## Live Streams

- `GET /api/live/streams` — `liveStreamsListNotifierProvider`
- Kart: gerçek thumbnail, izleyici, liveStreamId
- Fake yayın listesi yok (discover mock yalnızca API boşsa — ayrı konu)

## Gifts

- Voice: `LiveFieldGiftApi` → `POST /api/live/gift/send` (`roomType: voice`)
- Fallback: `POST /api/chat/rooms/{id}/gifts`
- Realtime: SSE + `voice_room_gift_realtime_service`
- Jeton: `walletBalancesProvider` refresh after send

## PK

- Voice: `GET/POST /api/chat/rooms/{id}/pk`
- Live field: `GET/POST /api/live/pk`
- UI: `pkBattleRemoteProvider` + SSE ingest
- Timer: `pkBattleProvider` — single dispose lifecycle

## Room Isolation

- SSE connection per room via `sseConnectionHubProvider.attachVoiceRoom(roomKey)`
- `roomEventMatchesActiveRoom()` — payload roomId mismatch → ignore
- PK remote provider — roomId scope checks
- Oda geçişi: `teardownVoiceRoomBeforeSwitch()` before new room

## Network Recovery

- TRTC: `TrtcLiveRoomCoordinator.reconnect()` on heartbeat fail
- SSE: exponential backoff (`base_sse_service.dart`)
- Voice: poll fallback when SSE drops; presence heartbeat resumes

## App Lifecycle

- Background: mevcut RTC/SSE davranışı korunur
- Foreground: `refresh()` / `_refreshHubOnlineCountFromServer()` reconcile

## Performance

- `room_fragment_providers` — isolated rebuilds
- `RepaintBoundary` on premium stage widgets
- Lazy sections on live broadcast

## Tests

- `test/features/voice_hub/presence_canonical_test.dart`
- `test/features/voice_hub/pk_battle_timer_test.dart`
- Mevcut: `chat_room_presence_test`, `voice_room_leave_flow_test`, `trtc_live_room_test`, PK suite

## Multi Device Tests

Cloud ortamında emüktör yok — gerçek 2 cihazda doğrulanmalı:

| Test | Beklenen |
|------|----------|
| A+B aynı oda | Her iki cihazda aynı online sayı |
| B çıkar | A'da sayı düşer, B odada değil |
| A→B geçiş | A'da B görünmez |
| Owner girer | Otomatik koltuk (yetkili) |
| Hediye | Doğru jeton + ranking |
| PK | Karşı cihazda invite |

## Backend Eksikleri

1. Voice odalar TRTC token'ı `/api/live/join-room` yerine state snapshot'tan — backend her zaman `roomTrtc` dönmeli
2. Canlı yayın dual lifecycle (video-stream join + live join-room) — tek coordinator hedefi
3. Discover API boşken mock oda listesi (`VoiceRoomsMockData`) — production empty state tercih edilmeli

## Fake/Hardcoded Veri

- In-room session: gerçek API (mock yok)
- TRTC: token backend'den; hardcoded sdkAppId/roomId yok
- Discover hub: `voice_rooms_mock_data.dart` yalnızca API fallback (in-room etkilenmez)
- Jeton maliyetleri: `PlatformVoiceRoomSettings` API + fallback sabitleri

## Değişen Dosyalar

- `mobile/lib/features/voice_hub/domain/presence_canonical.dart`
- `mobile/lib/features/voice_hub/domain/room_event_scope.dart`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_presence.dart`
- `mobile/lib/features/voice_hub/presentation/providers/pk_battle_provider.dart`
- `mobile/test/features/voice_hub/presence_canonical_test.dart`
- `mobile/test/features/voice_hub/pk_battle_timer_test.dart`
- `mobile/pubspec.yaml`, `mobile/CHANGELOG.md`
