# M7 — Müzik probe yakalama (üretim)

**Tarih:** 2026-09-21 21:30 UTC  
**Oda slug:** `cmoohrbr`  
**Oda id (SSE):** `cmoohrbr`  
**Hesap:** `cursor.test.1786235468@mailinator.com` — jeton 950→950 (admin top-up)  
**Üretim:** `https://canlifal.com`

> Otomatik: `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`  
> **Not:** SSE yalnızca tam cuid ile çalışır; slug ile `Room not found`. Flutter `1.0.264+` düzeltmesi.

---

## POST song-request (id `cmoohrbr`, slug `cmoohrbr`) → HTTP 500

```json
{
    "error": "\u015eark\u0131 iste\u011fi g\u00f6nderilemedi"
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

## SSE stream `cmoohrbr` (ilk 24KB)

```
Room not found
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
            "views": 104904671
        },
        {
            "id": "pu9co0YRKHg",
            "title": "Simarik",
            "thumbnail": "https://i.ytimg.com/vi/pu9co0YRKHg/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDEavpd5f0hzpOfThiOFcHocOYnUQ",
            "duration": "3:13",
            "channel": "Tarkan",
            "views": 18164275
        },
        {
            "id": "SSMoILdzGDg",
            "title": "TARKAN - \u015eIMARIK (MUAH) - lyrics/s\u00f6zleri",
            "thumbnail": "https://i.ytimg.com/vi/SSMoILdzGDg/hqdefault.jpg?sqp=-oaymwEcCOADEI4CSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDTldu0uezSMjvlVItdp6sie7z0Fw",
            "duration": "3:11",
            "channel": "seven7lyrics",
            "views": 9160436
        },
        {
            "id": "OG4ggvY_8p0",
            "title": "Tarkan - \u015e\u0131mar\u0131k (Audio)",
            "thumbnail": "https://i.ytimg.com/vi/OG4ggvY_8p0/hq720.jpg?sqp=-oaymwE2CNAFEJQDSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgBzgWAAtAFigIMCAAQARhyIFkoOTAP&rs=AOn4CLDZ5W2IHvOd4XA9sMjSsheWz46IUQ",
            "duration": "3:56",
            "channel": "M\u00fczik A\u015f\u0131\u011f\u0131",
            "views": 579128
        },
        {
            "id": "9UAwX1slv8g",
            "title": "TARKAN - \u015e\u0131mar\u0131k",
            "thumbnail": "https://i.ytimg.com/vi/9UAwX1slv8g/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgB3gOAAugCigIMCAAQARhlIGUoZTAP&rs=AOn4CLCPafc5F1jXaTW05vd-GFgbJKChtA",
            "duration": "4:00",
            "channel": "\u0130STANBUL PLAK",
            "views": 9558503
        },
        {
            "id": "ARCxyt9GS5o",
            "title": "TARKAN : THE WORLD MUSIC AWARDS IN MONACO 1999",
            "thumbnail": "https://i.ytimg.com/vi/ARCxyt9GS5o/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgB_gSAAuADigIMCAAQARhyIEIoNjAP&rs=AOn4CLCQyOzBDTLZB1PY2PjZXzOwci-wRA",
            "duration": "3:29",
            "channel": "F6FGrumman",
            "views": 18231984
        },
{"videos":[{"id":"cpp69ghR1IM","title":"TARKAN - Şımarık (Official Music Video)","thumbnail":"https://i.ytimg.com/vi/cpp69ghR1IM/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLAFL20hyg2MZSmMLkic82LMnae-Lg","duration":"3:12","channel":"Tarkan","views":104904671},{"id":"pu9co0YRKHg","title":"Simarik","thumbnail":"https://i.ytimg.com/vi/pu9co0YRKHg/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDEavpd5f0hzpOfThiOFcHocOYnUQ","duration":"3:13","channel":"Tarkan","views":18164275},{"id":"SSMoILdzGDg","title":"TARKAN - ŞIMARIK (MUAH) - lyrics/sözleri","thumbnail":"https://i.ytimg.com/vi/SSMoILdzGDg/hqdefault.jpg?sqp=-oaymwEcCOADEI4CSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLDTldu0uezSMjvlVItdp6sie7z0Fw","duration":"3:11","channel":"seven7lyrics","views":9160436},{"id":"OG4ggvY_8p0","title":"Tarkan - Şımarık (Audio)","thumbnail":"https://i.ytimg.com/vi/OG4ggvY_8p0/hq720.jpg?sqp=-oaymwE2CNAFEJQDSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgBzgWAAtAFigIMCAAQARhyIFkoOTAP&rs=AOn4CLDZ5W2IHvOd4XA9sMjSsheWz46IUQ","duration":"3:56","channel":"Müzik Aşığı","views":579128},{"id":"9UAwX1slv8g","title":"TARKAN - Şımarık","thumbnail":"https://i.ytimg.com/vi/9UAwX1slv8g/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgB3gOAAugCigIMCAAQARhlIGUoZTAP&rs=AOn4CLCPafc5F1jXaTW05vd-GFgbJKChtA","duration":"4:00","channel":"İSTANBUL PLAK","views":9558503},{"id":"ARCxyt9GS5o","title":"TARKAN : THE WORLD MUSIC AWARDS IN MONACO 1999","thumbnail":"https://i.ytimg.com/vi/ARCxyt9GS5o/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgB_gSAAuADigIMCAAQARhyIEIoNjAP&rs=AOn4CLCQyOzBDTLZB1PY2PjZXzOwci-wRA","duration":"3:29","channel":"F6FGrumman","views":18231984},{"id":"dVGRRCzYxeM","title":"ℂ⋆Tarkan | Şımarık 99' (Universal Version)","thumbnail":"https://i.ytimg.com/vi/dVGRRCzYxeM/hq720.jpg?sqp=-oaymwEcCNAFEJQDSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLBn0iVVvlLJXCk8kN0I7TyXkj6GoA","duration":"3:13","channel":"ℂ⋆Tarkanland","views":2102159},{"id":"3w_zsI2xOD0","title":"TARKAN: \"Şımarık\" - De Muziekdoos, Belgian TV Channel \"één\", 1998","thumbnail":"https://i.ytimg.com/vi/3w_zsI2xOD0/hq720.jpg?sqp=-oaymwE2CNAFEJQDSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgBvgeAAtAFigIMCAAQARh_IDYoODAP&rs=AOn4CLCrxjzxAWOvj73Un0ThLc3qBGJChA","duration":"3:00","channel":"Marleen TARKANclub","views":3374689},{"id":"REwYextipFI","title":"TARKAN - Simarik With Lyrics","thumbnail":"https://i.ytimg.com/vi/REwYextipFI/hqdefault.jpg?sqp=-oaymwE2COADEI4CSFXyq4qpAygIARUAAIhCGAFwAcABBvABAfgB_gKAAqACigIMCAAQARgTICMofzAP&rs=AOn4CLAUnR3vPk0BkkELWuhL6S2feLQRHA","duration":"3:14","channel":"StarCRN10","views":1505599},{"id":"6sxIxU5b2rg","title":"Simarik / Tarkan (kiss kiss) / Zumba","thumbnail":"https://i.ytimg.com/vi/6sxIxU5b2rg/hqdefault.jpg?sqp=-oaymwEcCOADEI4CSFXyq4qpAw4IARUAAIhCGAFwAcABBg==&rs=AOn4CLA9Wz5kXC0D7Vq-ae2ALjeoItNTXw","duration":"3:49","channel":"Zumba Suzy","views":676392}]}
```
