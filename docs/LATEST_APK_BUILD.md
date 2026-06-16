# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.221+224` |
| Tarih (UTC) | 2026-06-16 04:58 |
| Commit | [`22691c7770276c5c586e2cfcbacd54689ff3c9c2`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/22691c7770276c5c586e2cfcbacd54689ff3c9c2) |
| İş akışı | [Run 27594868225](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27594868225) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.221+224 (2026-06-14)

### Sesli oda — müzik sistemi (yeniden yazım)

- **!istek:** YouTube API ile arama; her istek **10 jeton** (sunucu doğrulaması, `skipPayment` kaldırıldı)
- **Yetersiz jeton:** Uyarı + «Jeton Yükle» yönlendirmesi
- **Kuyruk:** Oda başına sıra; çalan şarkı kesilmeden ekleme; otomatik sonraki parça (`/music-queue/complete`)
- **Yetki:** Durdur/kapat — isteyen, oda sahibi, admin, süper admin; yetkisizde standart mesaj
- **Oynatıcı:** Kapak, sanatçı, süre, isteyen, sırada N; duraklat / ses / kapat
- **Veritabanı:** `music_queue` + `music_action_logs` (Prisma); işlem günlüğü (istek, jeton, oynatma, yetkisiz)
- **API:** `POST .../music-request-by-query`, `POST .../music-queue/complete`, `canControlMusic` alanı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
