# FAZ 5 — Live stream parity


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Durum:** HAZIRLIK — `features/live/` + TRTC

| Kılavuz §9.4 | Durum |
|--------------|--------|
| Streams CRUD/lifecycle | ✅ |
| Viewers, like, messages | ✅ |
| PK, co-broadcast | ✅ |
| getComments `/video-streams/.../comments` | ❌ messages kullanılıyor |
| LiveStreamRepository arayüzü | 🔄 datasource dağılımı |

**Testler:** 36 case (`test/features/live/`)
