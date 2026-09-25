# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.599+647` |
| Tarih (UTC) | 2026-09-25 10:26 |
| Commit | [`5b0923b7fccd56ac952f3977e918f9b1905502fd`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/5b0923b7fccd56ac952f3977e918f9b1905502fd) |
| İş akışı | [Run 36120765066](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36120765066) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.599+646 (2026-09-25) — Birleşik release (PK + sesli oda oturumu)

**PK (594–645, backend hizalı)**
- Sesli PK: `POST/GET /api/chat/rooms/{id}/pk`, adaylar, `me/invites`, SSE `pk_invite`
- `stream1Id/stream2Id` oda kimliği; davet poll; kabul/red `/api/live/pk` yedek
- `serverNow` ile geri sayım; slug yedek anahtarı; oda içi `create_user` PK

**Sesli oda (Claude / RoomSessionManager)**
- Merkezi `RoomSessionManager` — join/presence/SSE senkronu, yarış koşulu korumaları
- PK oturumu yalnızca aktif oda controller varken oda olaylarına bağlanır (gereksiz join yok)
- Dispose sonrası event stream korumaları; presence/koltuk hızlı düzeltmeleri

**Canlı fal / diğer**
- Falcı kabul popup ve senkron iyileştirmeleri (önceki 593 dalı)
- CI test düzeltmeleri (`pk_session_keep_alive`, entegrasyon testleri)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
