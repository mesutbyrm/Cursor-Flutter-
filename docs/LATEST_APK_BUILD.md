# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.487+525` |
| Tarih (UTC) | 2026-09-14 10:23 |
| Commit | [`d478cda4a2055252e0723f4584d25b2b6a80cde5`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d478cda4a2055252e0723f4584d25b2b6a80cde5) |
| İş akışı | [Run 34830562714](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34830562714) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.487+525 (2026-09-14) — API parite (bildirim, istatistik, PK, müzik)

- Okunmamış bildirim: `GET /api/notifications?unreadOnly=true` (+ messages yedek); `/api/notifications/unread` kaldırıldı
- Profil istatistik: yalnızca `/api/user/stats` ve `/api/user/statistics` (`/api/users/me/stats` kaldırıldı)
- PK: kullanılmayan `/api/pk/battles/*` sabitleri ve `fetchBattle` kaldırıldı (oda PK korunur)
- Popüler müzik: `/api/chat/music/popular` 404 ise `/api/music/search?q=popüler` yedek
- Oyun geçmişi: mini-scores / profile önce, sonra `/api/games/history`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
