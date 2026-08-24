# FAZ 3 — Social parity

**Durum:** HAZIRLIK — `getUserPosts` kılavuz ucu eklendi (1.0.267)

| Kılavuz §9.10 | Durum |
|---------------|--------|
| getPosts / create / like / comment | ✅ |
| getUserPosts `/api/users/{id}/posts` | ✅ `fetchUserPosts` |
| getStories | 🔄 datasource; repo yüzeyi eksik |
| viewPost | 🔄 datasource only |

**Testler:** 14 dosya (UI/utils) — `bash scripts/run-phase-tests.sh` FAZ3
