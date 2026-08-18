# Müzik API — Üretim sözleşmesi (song-request only)

**Tarih:** 2026-08-18  
**Durum:** Flutter resmi üretim yolu (M6 — Seçenek B)  
**Probe:** `docs/MUSIC_API_PRODUCTION_PROBE.md`

---

## Canonical mobil akış (`!istek` / müzik paneli)

Üretimde (`canlifal.com`) Flutter **yalnızca** aşağıdaki yolu kullanır:

| Adım | Endpoint | Not |
|------|----------|-----|
| 1 | `GET /api/youtube/search?q=` | Sunucu YouTube arama (JWT) |
| 2 | `POST /api/chat/rooms/{roomId}/song-request` | `title`, `youtubeUrl`, `videoId`, `priority` |
| 3 | `GET /api/chat/rooms/{roomId}/stream` (SSE) | `song_started`, `dj`, `queue_updated` |
| 4 | Oynatma | `musicUrl` embed → IFrame; googlevideo → CDN |

**Kullanılmıyor (üretim):**

- `POST …/music-request-by-query` — **404** (atlanır, `1.0.258+`)
- `GET /api/chat/youtube-audio?url=` — **400** (kaldırıldı)
- İstemci `youtube_explode` — kapalı (`1.0.259+`)
- Piped/Invidious resolve — kapalı (`1.0.260+`)

---

## `song-request` gövdesi (Flutter)

```json
{
  "title": "Artist - Song",
  "youtubeUrl": "https://www.youtube.com/watch?v=VIDEO_ID",
  "videoId": "VIDEO_ID",
  "thumbUrl": "https://...",
  "duration": "3:45",
  "priority": true
}
```

---

## Beklenen yanıt alanları

Flutter parse: `item`, `queue`, `musicUrl`, `playing`, `newBalance`, `queuePosition`

Örnek:

```json
{
  "playing": true,
  "musicUrl": "/api/chat/youtube-stream?videoId=VIDEO_ID",
  "item": { "title": "...", "videoId": "VIDEO_ID" },
  "queue": []
}
```

---

## Backend onayı

Bu doküman Flutter tarafının resmi üretim sözleşmesidir. Backend ekibi:

1. `music-request-by-query` deploy etmeyecekse bu dokümanı web/mobile kılavuzuna eklesin
2. M7 için gerçek SSE dump sağlasın (`cmoohrbr`)
