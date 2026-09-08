# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.398+436` |
| Tarih (UTC) | 2026-09-08 19:37 |
| Commit | [`dc9a80681c17b6cc6a66ccb699c6776dd50e9352`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/dc9a80681c17b6cc6a66ccb699c6776dd50e9352) |
| İş akışı | [Run 34266937452](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34266937452) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.401+439 (2026-09-08) — PK davet + misafir ortak yayın düzeltmeleri

- Canlı yayın: `invited` PK durumu kabul ekranında tanınır (`isPkInvitePendingStatus`)
- `LivePkInviteListener`: `/api/pk/me/invites` + birleşik davet poll; 4 sn yedek
- Video SSE: `pk_invite` / `pk_request` ve misafir davet alias'ları
- Sesli oda: bekleyen PK SSE kullanıcı ID eşleşmesi (`guestUserId` vb.)
- Global `LiveCoBroadcastInviteListener` — ortak yayın daveti her ekranda


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
