# M7 — Müzik probe yakalama (üretim)

**Tarih:** 2026-08-18 22:53 UTC  
**Oda slug:** `cmoohrbr`  
**Oda id (SSE):** `cmoohrbrx00a4nt08zlkdjyil`  
**Hesap:** `cursor.test.1786235468@mailinator.com` — jeton=0  
**Üretim:** `https://canlifal.com`

> Otomatik: `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`  
> **Not:** SSE yalnızca tam cuid ile çalışır; slug ile `Room not found`. Flutter `1.0.264+` düzeltmesi.

---

## POST song-request (slug `cmoohrbr`) → HTTP 400

```json
{
    "error": "Yetersiz jeton. 10 jeton gerekiyor."
}
```

---

## GET youtube-stream?videoId=cpp69ghR1IM

```json
{
    "success": true,
    "videoId": "cpp69ghR1IM",
    "embedUrl": "https://www.youtube.com/embed/cpp69ghR1IM?autoplay=1&start=0&enablejsapi=1&playsinline=1",
    "streamUrl": "https://www.youtube.com/embed/cpp69ghR1IM?autoplay=1&start=0&enablejsapi=1&playsinline=1",
    "youtubeUrl": "https://www.youtube.com/watch?v=cpp69ghR1IM",
    "title": "TARKAN - \u015e\u0131mar\u0131k (Official Music Video)",
    "thumbnail": "https://i.ytimg.com/vi/cpp69ghR1IM/hqdefault.jpg",
    "author": "Tarkan",
    "mode": "embed"
}
```

---

## SSE stream `cmoohrbrx00a4nt08zlkdjyil` (ilk 24KB)

```
data: {"type":"connected","roomId":"cmoohrbrx00a4nt08zlkdjyil"}

data: {"type":"dj","event":"QUEUE_UPDATED","playing":false,"nowPlaying":null,"musicUrl":null,"embedUrl":null,"musicQueue":[],"queue":[],"queueLength":0}

data: {"type":"presence","users":[]}
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
            "views": 559148
        },
        {
            "id": "M0-joG_2SZY",
            "title": "\u2102\u22c6Tarkan | \u015e\u0131mar\u0131k \"Official Music Video\" Full HD",
            "thumbnail": "https://i.ytimg.com/vi/M0-joG_2SZY/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLAvD7ytb3m6NOzHLxmHEXI7Ibjy5Q",
            "duration": "4:00",
            "channel": "\u2102\u22c6Tarkanland",
            "views": 406990
        },
```
