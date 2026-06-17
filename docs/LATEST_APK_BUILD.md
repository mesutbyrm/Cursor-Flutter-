# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.248+251` |
| Tarih (UTC) | 2026-06-17 16:45 |
| Commit | [`1dcbac64bbd79624120a3fb397ac3b79885aea10`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/1dcbac64bbd79624120a3fb397ac3b79885aea10) |
| İş akışı | [Run 27704338918](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27704338918) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.248+251 (2026-06-12)

### Canlı fal istekleri + sesli oda / PK

- **Canlı fal:** `GET /api/live-fal/pending` (5 sn poll) + `POST …/accept|reject`
- **SSE:** `fal_request`, `live_fal_request`, `fortune_request`, `private_fal_request` — otomatik `FortuneRequestDialog`
- **Falcı SSE:** Oda sahibi odasına SSE; arka plandan dönüşte yeniden bağlanma; kopunca reconnect
- **Sesli oda:** `apiRoomKey` boşken liste yenileme ile giriş düzeltmesi
- **PK:** Bitmiş PK kaydı temizleme; «zaten aktif PK» hatasında sonlandırma / anlaşılır mesaj


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
