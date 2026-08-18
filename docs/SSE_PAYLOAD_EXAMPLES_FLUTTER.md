# SSE payload örnekleri — Flutter test fixture'larından

**Tarih:** 2026-08-18  
**Uyarı:** Bunlar **resmi backend dump değil**; Flutter unit testlerinde kullanılan ve parser'ların geçtiği örneklerdir. Backend doğrulaması gelene kadar A7 yedeği.

**Stream:** `GET /api/chat/rooms/{roomId}/stream`  
**İlgili:** `docs/SSE_EVENTS_FLUTTER_PARSED.md`, `mobile/test/room_song_bloc_test.dart`

---

## `song_started`

```json
{
  "type": "song_started",
  "currentSong": {
    "videoId": "abc123",
    "title": "Test",
    "elapsedMs": 0,
    "paused": false,
    "serverTime": 1700000000000
  },
  "elapsed": 0
}
```

Ses-only (`musicUrl`):

```json
{
  "type": "song_started",
  "currentSong": {
    "musicUrl": "https://canlifal.com/stream/test",
    "title": "Audio only"
  }
}
```

---

## `dj` / `dj_update`

Üretim örneği (`cmoohrbr` → `cmoohrbrx00a4nt08zlkdjyil`, `docs/M7_MUSIC_SSE_CAPTURE.md`):

```json
{
  "type": "dj",
  "event": "QUEUE_UPDATED",
  "playing": true,
  "nowPlaying": {
    "videoId": "cpp69ghR1IM",
    "title": "TARKAN - Şımarık (Official Music Video)",
    "startedAt": "2026-08-18T14:23:46.802Z",
    "startedAtMs": 1787063026802,
    "elapsedSeconds": 23146,
    "duration": "3:12",
    "embedUrl": "https://www.youtube.com/embed/cpp69ghR1IM?autoplay=1&start=23146&enablejsapi=1&playsinline=1"
  },
  "musicUrl": "https://www.youtube.com/embed/cpp69ghR1IM?autoplay=1&start=23146&enablejsapi=1&playsinline=1",
  "embedUrl": "https://www.youtube.com/embed/cpp69ghR1IM?autoplay=1&start=23146&enablejsapi=1&playsinline=1",
  "musicQueue": [],
  "queue": [],
  "queueLength": 0
}
```

Test fixture:

```json
{
  "type": "dj",
  "playing": true,
  "nowPlaying": {
    "videoId": "abc123",
    "title": "Test",
    "elapsedSeconds": 42
  },
  "musicQueue": [
    { "id": "q1", "videoId": "v1", "title": "A" }
  ]
}
```

Normalize sonrası (`normalizeSongSseForDjPlayback`):

```json
{
  "type": "song_started",
  "playing": true,
  "videoId": "abc123",
  "musicUrl": "https://example.com/stream",
  "nowPlaying": {
    "videoId": "abc123",
    "title": "Test",
    "musicUrl": "https://example.com/stream",
    "withVideo": true
  }
}
```

---

## `queue_updated`

```json
{
  "type": "queue_updated",
  "queue": [
    { "queueId": "q1", "videoId": "v1", "title": "A" }
  ]
}
```

---

## `player_state`

```json
{
  "type": "player_state",
  "playing": true,
  "musicUrl": "/api/chat/youtube-stream?videoId=abc123"
}
```

---

## Üretim probe notu (müzik)

Üretimde `GET /api/chat/youtube-stream?videoId=` → `mode: embed`. Flutter bu durumda **IFrame** oynatır; `just_audio` için doğrudan stream beklenmez.

Backend'den hâlâ istenen: oda `cmoohrbr` üzerinde `!istek` sonrası **gerçek** SSE ham dump (M7).
