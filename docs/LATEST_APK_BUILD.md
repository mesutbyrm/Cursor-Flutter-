# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.261+264` |
| Tarih (UTC) | 2026-06-18 11:36 |
| Commit | [`3f4af1cf4de7a9484366570f8634afb9636097b9`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3f4af1cf4de7a9484366570f8634afb9636097b9) |
| İş akışı | [Run 27756080742](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27756080742) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.261+264 (2026-06-18)

### Canlı falcı — backend MD sözleşmesi (canlifal.com/api/download-prompt)

- **Seans oluşturma:** `POST /api/fortune-tellers/session` — body yalnızca `tellerId`, `fortuneType`, `duration`; `creditsCharged` / `maxMinutes` yanıttan okunur
- **Falcı poll:** Öncelik `GET /api/fortune-tellers/sessions?status=pending` (3 sn aralık)
- **Kabul / red / iptal:** `PATCH /api/fortune-tellers/sessions/{id}` `{ action }` birincil yol
- **Çevrimiçi:** `POST /api/fortune-tellers/toggle-online` `{ isOnline: true }`
- **Aktif seans:** Uygulama açılışında `GET /api/user/active-sessions` ile devam
- **Push:** `session_request`, `session_update`, `session_ended` tipleri işlenir; kabulde canlı odaya yönlendirme
- **Danışan bekleme:** Durum poll 3 sn (üretim dokümanı §6–8)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
