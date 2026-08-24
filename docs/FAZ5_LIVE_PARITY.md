# FAZ 5 — Live stream parity

**Durum:** HAZIRLIK — `features/live/` + TRTC

| Kılavuz §9.4 | Durum |
|--------------|--------|
| Streams CRUD/lifecycle | ✅ |
| Viewers, like, messages | ✅ |
| PK, co-broadcast | ✅ |
| getComments `/video-streams/.../comments` | ❌ messages kullanılıyor |
| LiveStreamRepository arayüzü | 🔄 datasource dağılımı |

**Testler:** 36 case (`test/features/live/`)
