# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.335+338` |
| Tarih (UTC) | 2026-06-23 11:02 |
| Commit | [`20659f028d183cb8eb41dc1e254f738ca97443b6`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/20659f028d183cb8eb41dc1e254f738ca97443b6) |
| İş akışı | [Run 28020528379](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/28020528379) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.335+338 (2026-06-22)

### Canlı Falcılar — randevu bildirimi regresyonu

- **Kök neden:** Push/API gövdesindeki `userId` yanlışlıkla `clientId` sayılıyordu; falcı kendi isteğinin danışanı sanılıp bildirim/dialog filtreleniyordu
- `clientId` yalnızca açık `clientId` / `client_id` alanlarından okunuyor
- Onaylı falcıda minimal push (clientId boş) yine gösteriliyor; danışanda gösterilmiyor
- Bildirim listesinde falcı olmayan kullanıcı yine ilgili sayfaya yönlendiriliyor


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
