# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.264+267` |
| Tarih (UTC) | 2026-06-18 14:22 |
| Commit | [`dcfa3439386266593dcda21a9792e2154e6ad43f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/dcfa3439386266593dcda21a9792e2154e6ad43f) |
| İş akışı | [Run 27765377150](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27765377150) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.264+267 (2026-06-18)

### Canlı fal seans SSE (`GET /api/room/{sessionId}/stream`)

- **Servis:** `LiveFortuneRoomSseService` — mesaj, timer, oda durumu, seans sonu olayları
- **Bekleme:** Danışan kabul/red anında SSE ile yönlendirme (3 sn poll yedek)
- **Seans:** Sohbet SSE birincil; poll 20 sn yedek; timer/oda güncellemeleri anlık
- **Test:** `live_fortune_room_sse_mapper_test.dart` — payload ayrıştırma


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
