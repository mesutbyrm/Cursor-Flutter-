# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.638+689` |
| Tarih (UTC) | 2026-09-29 18:40 |
| Commit | [`a829195c2620e8e7c62a9b5acd353db759f0d415`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a829195c2620e8e7c62a9b5acd353db759f0d415) |
| İş akışı | [Run 36611208341](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36611208341) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.642+693 (2026-09-29) — Canlı PK REST yükü (davet + hediye skor)

- **liveVideoPkProvider.refresh:** `GET /api/pk/me/invites` yedek çağrısı kaldırıldı (davet: `LivePkInviteListener` + SSE)
- **PK skor yoklama:** hediye/beğeni sonrası `refreshScoresIfStale` — son SSE ingest 8 sn içindeyse REST atlanır
- **Canlı PK davet poll:** yayıncıdayken `/pk/me/invites` en az 8 sn aralık
- Backend değişikliği yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
