# M7 — Müzik probe yakalama (üretim)

**Tarih:** 2026-08-19 02:07 UTC  
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
            "thumbnail": "https://i.ytimg.com/vi/cpp69ghR1IM/hq720.jpg?sqp=-oaymwEgCNAFEJQDSFXyq4qpAxIIARUAAIhCGAFwAcABBrgC8xg=&rs=AOn4CLDHxtyAnuJe6RjduONUO1bCujQoZQ",
            "duration": "3:12",
            "channel": "Tarkan",
            "views": 102953174
        },
        {
            "id": "pu9co0YRKHg",
            "title": "Simarik",
            "thumbnail": "https://i.ytimg.com/vi/pu9co0YRKHg/hq720.jpg?sqp=-oaymwEgCNAFEJQDSFXyq4qpAxIIARUAAIhCGAFwAcABBrgC8xg=&rs=AOn4CLAX452ZqlKA0VFpZIPIu1zkmmouCA",
            "duration": "3:13",
            "channel": "Tarkan",
            "views": 17924582
        },
        {
            "id": "c9r1Vfb51X8",
            "title": "Tarkan - \u015e\u0131mar\u0131k (Kiss Kiss) (HQ / HD)",
            "thumbnail": "https://i.ytimg.com/vi/c9r1Vfb51X8/hqdefault.jpg?sqp=-oaymwE6COADEI4CSFXyq4qpAywIARUAAIhCGAFwAcABBvABAfgBzgWAAuADigIMCAAQARh_IFAoIDAPuALzGA==&rs=AOn4CLBdgK7XIENHz9fOlnw7_EDJTndPuw",
            "duration": "3:11",
            "channel": "TiredOfYou",
            "views": 3557154
        },
        {
            "id": "SSMoILdzGDg",
            "title": "TARKAN - \u015eIMARIK (MUAH) - lyrics/s\u00f6zleri",
            "thumbnail": "https://i.ytimg.com/vi/SSMoILdzGDg/hqdefault.jpg?sqp=-oaymwEgCOADEI4CSFXyq4qpAxIIARUAAIhCGAFwAcABBrgC8xg=&rs=AOn4CLDu5p6p0ax9XufP_SiNhmL4mnyxaA",
            "duration": "3:11",
            "channel": "seven7lyrics",
            "views": 8736605
        },
        {
            "id": "M0-joG_2SZY",
            "title": "\u2102\u22c6Tarkan | \u015e\u0131mar\u0131k \"Official Music Video\" Full HD",
            "thumbnail": "https://i.ytimg.com/vi/M0-joG_2SZY/hq720.jpg?sqp=-oaymwEgCNAFEJQDSFXyq4qpAxIIARUAAIhCGAFwAcABBrgC8xg=&rs=AOn4CLCpHvXAxEvwG2AaoQJW3bnhjn1VOw",
            "duration": "4:00",
            "channel": "\u2102\u22c6Tarkanland",
            "views": 407137
        },
        {
            "id": "ARCxyt9GS5o",
            "title": "TARKAN : THE WORLD MUSIC AWARDS IN MONACO 1999",
            "thumbnail": "https://i.ytimg.com/vi/ARCxyt9GS5o/hqdefault.jpg?sqp=-oaymwE6COADEI4CSFXyq4qpAywIARUAAIhCGAFwAcABBvABAfgB_gSAAuADigIMCAAQARhyIEIoNjAPuALzGA==&rs=AOn4CLDW5Rj0VgVJmH_W4Txl55Q9WBWBGw",
            "duration": "3:29",
            "channel": "F6FGrumman",
            "views": 18063561
        },
```
