# Oda müzik sistemi (SongQueueService)

TikTok/Bigo benzeri sesli oda müzik kuyruğu — **yalnızca** YouTube Data API v3 (arama) ve YouTube IFrame Player API (Flutter oynatma).

## Backend (`api/`)

- **Servis:** `src/lib/songQueueService.ts`
- **SSE push:** `src/lib/songQueueSse.ts` — anlık `song_*` olayları
- **Tablolar:** `room_song_queue`, `room_current_song`, `room_song_history`

### API

| Metot | Path | Açıklama |
|--------|------|----------|
| POST | `/api/chat/rooms/:id/song-request` | `{ videoId, title, thumbUrl?, duration?, artist? }` |
| GET | `/api/chat/rooms/:id/current-song` | `currentSong` + `serverTime` + `elapsedMs` |
| GET | `/api/chat/rooms/:id/queue` | FIFO kuyruk |
| POST | `/api/chat/rooms/:id/skip` | Moderasyon |
| POST | `/api/chat/rooms/:id/pause` | Moderasyon |
| POST | `/api/chat/rooms/:id/resume` | Moderasyon |
| DELETE | `/api/chat/rooms/:id/song/:queueId` | Sahip veya moderasyon |
| DELETE | `/api/chat/rooms/:id/queue` | Kuyruk temizleme (moderasyon) |

### SSE olayları

`song_started`, `song_paused`, `song_resumed`, `song_finished`, `queue_updated`, `song_removed`

Her payload `serverTime` (ms) içerir. Flutter 500 ms üzeri sapmada seek yapar.

### Jeton

- `VoiceRoomSettings.musicRequestCost` — admin ayarı
- VIP odalarda istek ücretsiz (`roomType === VIP`)

## Flutter (`mobile/`)

- **Bloc:** `features/voice_hub/music/presentation/bloc/`
- **Mini player:** `room_song_mini_player.dart` — `youtube_player_iframe`
- **SSE:** `ChatRoomSseService` → `RoomSongBloc.eventFromSse`
- **Odaya giriş:** `GET current-song` (`RoomSongJoinSync`)

## Hediye düzeltmesi

- Video hediyeler prefetch beklemeden `activeAnimation` atanır
- MP4/WebM tam ekran zorlanır
- Yükleme sırasında 🎁 yerine thumbnail gösterilir

## Performans

- Kuyruk bellek + Redis (`music_queue:{roomId}`)
- DB yalnızca kalıcı kayıt ve geçmiş
- Bloc + `RepaintBoundary` gereksiz rebuild azaltır
