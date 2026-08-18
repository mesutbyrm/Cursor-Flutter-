# Müzik API — Üretim Probe Raporu

**Tarih:** 2026-08-18  
**Host:** `https://canlifal.com`  
**Yöntem:** Anonim HTTP probe (auth yok)

---

## Sonuç tablosu

| Endpoint | Metod | HTTP | Flutter kullanımı | Aksiyon |
|----------|-------|------|-------------------|---------|
| `…/music-request-by-query` | POST | **404** | `!istek` (eski) | Flutter `1.0.258+` atlıyor → `song-request` |
| `…/song-request` | POST | 401 | Şarkı kuyruğu | ✅ Canonical üretim yolu |
| `/api/chat/youtube-stream?videoId=` | GET | 200 | Stream resolve | `mode: embed` döner |
| `/api/chat/youtube-audio?videoId=` | GET | 200 | — | JSON/embed; `just_audio` için uygun değil |
| `/api/chat/youtube-audio?url=` | GET | **400** | Eski Android proxy | Flutter kaldırdı (`1.0.257+`) |
| `/api/chat/music/popular` | GET | **404** | Popüler liste | Yerel fallback kullanılıyor |
| `/api/youtube/search?q=` | GET | 401 | Arama | Auth ile çalışır |
| `/api/music/search?q=` | GET | 401 | Arama yedeği | Auth ile çalışır |

---

## Flutter üretim akışı (`!istek`)

1. `POST …/song-request` (sunucu arama sonrası `videoId` + `title`)
2. SSE: `dj_update` / `song_started` / `queue_updated`
3. Oynatma: `musicUrl` yoksa veya embed ise → gizli YouTube IFrame; googlevideo varsa doğrudan CDN

---

## Backend'den istenen (M6–M7)

1. **Seçenek A:** `POST …/music-request-by-query` üretime deploy (web ile parity)
2. **Seçenek B:** Resmi doküman: mobil yalnızca `song-request` + `youtube-stream` kullanır
3. Oda `cmoohrbr` için örnek:
   - `POST song-request` request/response JSON
   - Ardından gelen SSE `dj_update` ham payload

Bkz. `docs/BACKEND_REQUIREMENTS_TO_REQUEST.md` Eksik #6.
