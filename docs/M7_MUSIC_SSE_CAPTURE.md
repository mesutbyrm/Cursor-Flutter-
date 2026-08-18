# M7 — Müzik probe yakalama (üretim)

**Tarih:** 2026-08-18 20:39 UTC  
**Oda:** `cmoohrbr`  
**Hesap:** `cursor.test.1786235468@mailinator.com` (acceptance test)  
**Üretim:** `https://canlifal.com`

> Otomatik üretildi: `bash scripts/probe-music-room.sh`

---

## POST song-request → HTTP 400

```json
{
    "error": "Yetersiz jeton. 10 jeton gerekiyor."
}
```

---

## GET youtube-stream?videoId=dQw4w9WgXcQ

```json
{
    "success": true,
    "videoId": "dQw4w9WgXcQ",
    "embedUrl": "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&start=0&enablejsapi=1&playsinline=1",
    "streamUrl": "https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&start=0&enablejsapi=1&playsinline=1",
    "youtubeUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "title": "Rick Astley - Never Gonna Give You Up (Official Video) (4K Remaster)",
    "thumbnail": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg",
    "author": "Rick Astley",
    "mode": "embed"
}
```

---

## SSE stream (ilk 16KB)

```
\`Room not found
```

---

## Arama (youtube/search)

```json
{
    "videos": [
        {
            "id": "cpp69ghR1IM",
            "title": "TARKAN - \u015e\u0131mar\u0131k (Official Music Video)",
            "thumbnail": "https://i.ytimg.com/vi/cpp69ghR1IM/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLAFL20hyg2MZSmMLkic82LMnae-Lg",
            "duration": "3:12",
            "channel": "Tarkan",
            "views": 102939922
        },
        {
            "id": "pu9co0YRKHg",
            "title": "Simarik",
            "thumbnail": "https://i.ytimg.com/vi/pu9co0YRKHg/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDEavpd5f0hzpOfThiOFcHocOYnUQ",
            "duration": "3:13",
            "channel": "Tarkan",
            "views": 17922799
        },
        {
            "id": "c9r1Vfb51X8",
            "title": "Tarkan - \u015e\u0131mar\u0131k (Kiss Kiss) (HQ / HD)",
            "thumbnail": "https://i.ytimg.com/vi/c9r1Vfb51X8/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgBzgWAAuADigIMCAAQARh_IFAoIDAP&rs=AOn4CLD0qIgxN_NPCqUYekSJ5PpIFK1Y3A",
            "duration": "3:11",
            "channel": "TiredOfYou",
            "views": 3555473
        },
        {
            "id": "SSMoILdzGDg",
            "title": "TARKAN - \u015eIMARIK (MUAH) - lyrics/s\u00f6zleri",
            "thumbnail": "https://i.ytimg.com/vi/SSMoILdzGDg/hqdefault.jpg?sqp=-oaymwEcCOADEI4CSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDTldu0uezSMjvlVItdp6sie7z0Fw",
            "duration": "3:11",
            "channel": "seven7lyrics",
            "views": 8734267
        },
        {
            "id": "OG4ggvY_8p0",
            "title": "Tarkan - \u015e\u0131mar\u0131k (Audio)",
            "thumbnail": "https://i.ytimg.com/vi/OG4ggvY_8p0/hq720.jpg?sqp=-oaymwE2CNAFEJQDSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgBzgWAAtAFigIMCAAQARhyIFkoOTAP&rs=AOn4CLDZ5W2IHvOd4XA9sMjSsheWz46IUQ",
            "duration": "3:56",
            "channel": "M\u00fczik A\u015f\u0131\u011f\u0131",
```
