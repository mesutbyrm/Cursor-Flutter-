# M7 — song-request HTTP 200 yanıt şablonu (bekleyen)

**Durum:** Üretimde henüz yakalanmadı — test hesabı 0 jeton (HTTP 400).  
**Sözleşme:** `docs/MUSIC_SONG_REQUEST_CONTRACT.md`  
**Flutter parse:** `chat_room_remote_datasource.dart` → `requestMusic` / `music.queue.add.ok`

---

## Yakalama komutu (jeton ≥ 10 sonrası)

```bash
# Admin jeton sonrası
MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh
# veya
bash scripts/m5-preflight.sh   # jeton top-up dener (ACCEPTANCE_ADMIN_* gerekli)
```

---

## Beklenen alanlar (Flutter)

| Alan | Tip | Kullanım |
|------|-----|----------|
| `playing` | bool | DJ oynatma durumu |
| `musicUrl` | string | `/api/chat/youtube-stream?videoId=` veya embed URL |
| `item` / `request` / `song` | object | `MusicQueueItem` |
| `queue` / `musicQueue` | array | Kuyruk |
| `newBalance` / `coinBalance` | number | Jeton düşümü sonrası |
| `queuePosition` / `position` | number | Sıra |

---

## Örnek şablon (mock test — `music_request_production_test.dart`)

```json
{
  "playing": true,
  "musicUrl": "/api/chat/youtube-stream?videoId=dQw4w9WgXcQ",
  "item": {
    "id": "req-1",
    "videoId": "dQw4w9WgXcQ",
    "title": "Test Song",
    "youtubeUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  },
  "queue": [],
  "newBalance": 90,
  "queuePosition": 1
}
```

---

## SSE (song-request sonrası)

Aynı oturumda SSE `song_started` veya `dj` / `QUEUE_UPDATED` beklenir. Örnek: `docs/M7_MUSIC_SSE_CAPTURE.md` (`dj` bloğu).

**M7 kapanış:** Bu dosyaya gerçek HTTP 200 JSON eklendiğinde madde `[x]` olur.
