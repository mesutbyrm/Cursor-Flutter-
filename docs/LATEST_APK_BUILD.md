# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.598+644` |
| Tarih (UTC) | 2026-09-24 21:37 |
| Commit | [`88a238f60f93964fef0e73f390b363f97d32973d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/88a238f60f93964fef0e73f390b363f97d32973d) |
| İş akışı | [Run 36060440886](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36060440886) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.598+643 (2026-09-23) — Backend PK sözleşmesi hizalama

- **Backend referans (`full-source` / `pk-state.ts`):** `scope: room` sesli PK; `stream1Id/stream2Id` oda kimliği
- **Sesli PK state:** `GET /api/chat/rooms/{id}/pk` slug yedek anahtarı; `me/invites` zarfında `data[]` listesi
- **Davet poll:** Giden pending varken diğer odalar + `me/invites` poll’u kesilmez
- **Kabul/red:** Oda PK ucu 404/400 ise `POST /api/live/pk` birleşik yedek (PK_ENTEGRASYON)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
