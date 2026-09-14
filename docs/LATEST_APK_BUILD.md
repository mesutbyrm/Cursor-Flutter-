# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.486+524` |
| Tarih (UTC) | 2026-09-14 10:04 |
| Commit | [`f4d847518281d6166cbe44af1f37dd27869e2825`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f4d847518281d6166cbe44af1f37dd27869e2825) |
| İş akışı | [Run 34829809442](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34829809442) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.487+525 (2026-09-14) — API parite (bildirim, istatistik, PK, müzik)

- Okunmamış bildirim: `GET /api/notifications?unreadOnly=true` (+ messages yedek); `/api/notifications/unread` kaldırıldı
- Profil istatistik: yalnızca `/api/user/stats` ve `/api/user/statistics` (`/api/users/me/stats` kaldırıldı)
- PK: kullanılmayan `/api/pk/battles/*` sabitleri ve `fetchBattle` kaldırıldı (oda PK korunur)
- Popüler müzik: `/api/chat/music/popular` 404 ise `/api/music/search?q=popüler` yedek
- Oyun geçmişi: mini-scores / profile önce, sonra `/api/games/history`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
