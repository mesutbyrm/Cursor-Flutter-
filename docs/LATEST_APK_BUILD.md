# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.223+226` |
| Tarih (UTC) | 2026-06-16 08:25 |
| Commit | [`ef896f97b1ae1527025ed38616b92efb45a75738`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ef896f97b1ae1527025ed38616b92efb45a75738) |
| İş akışı | [Run 27603855086](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27603855086) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.223+226 (2026-06-16)

### Sesli oda — YouTube çalma + DJ üretim uyumu

- **Müzik:** Üretimdeki gibi YouTube watch URL (`musicUrl`) Piped/Explode ile çözülür; ilk hata sonrası oynatma durumu korunur
- **!istek:** İstek sonrası videoId/watch URL ön yükleme ve otomatik çalma
- **DJ ekleme:** Üretimde `POST /dj/:id` yok — `!dj @kullanıcı` sohbet komutu yedeği (eski hatalı `/dj` POST kaldırıldı)
- **DJ listesi:** `room.djUserIds` + presence ile `djUsers` zenginleştirilir; DJ 1/5 sayacı güncellenir
- **Moderasyon:** Oda sahibi / admin / moderatör DJ atayabilir (yerel API)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
