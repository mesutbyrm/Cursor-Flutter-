# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.224+227` |
| Tarih (UTC) | 2026-06-16 10:20 |
| Commit | [`09b2060452573cf74de6bbe4ae992a23f776f4c3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/09b2060452573cf74de6bbe4ae992a23f776f4c3) |
| İş akışı | [Run 27610198187](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27610198187) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.224+227 (2026-06-12)

### Sesli oda — canlifal.com üretim API uyumu

- **DJ:** `POST /dj` ile `{ action: add_dj|remove_dj, userId }` (birincil); yerel `/dj/:id` ve `!dj` yedeği
- **Müzik:** `GET/POST/DELETE /music` birincil (`videoId`, `title`, `duration`); `song-request` / `music-queue` yedeği
- **Moderasyon:** `POST /moderation` (`ban_user`, `kick_user`, `mute_user`, `set_role`) birincil
- **Presence:** `DELETE /presence?leave=1`; koltuk atama için `POST /presence { seatIndex }` yedeği
- **Roller:** `%` admin (5) > `~` founder (4) > `&` sop (3) > `@` op (2) > `+` voice (1) hiyerarşisi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
