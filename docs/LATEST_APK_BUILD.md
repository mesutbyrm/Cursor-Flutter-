# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.598+644` |
| Tarih (UTC) | 2026-09-24 21:19 |
| Commit | [`80b9a1f432b7f7ccf8a8aa47c3f7023f4c62bae8`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/80b9a1f432b7f7ccf8a8aa47c3f7023f4c62bae8) |
| İş akışı | [Run 36058644498](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36058644498) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.598+643 (2026-09-23) — Backend PK sözleşmesi hizalama

- **Backend referans (`full-source` / `pk-state.ts`):** `scope: room` sesli PK; `stream1Id/stream2Id` oda kimliği
- **Sesli PK state:** `GET /api/chat/rooms/{id}/pk` slug yedek anahtarı; `me/invites` zarfında `data[]` listesi
- **Davet poll:** Giden pending varken diğer odalar + `me/invites` poll’u kesilmez
- **Kabul/red:** Oda PK ucu 404/400 ise `POST /api/live/pk` birleşik yedek (PK_ENTEGRASYON)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
