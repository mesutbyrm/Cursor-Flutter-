# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.633+684` |
| Tarih (UTC) | 2026-09-29 11:47 |
| Commit | [`b746a3e650eeec34ecfce57a51c82c029aefbbea`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b746a3e650eeec34ecfce57a51c82c029aefbbea) |
| İş akışı | [Run 36561990440](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36561990440) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.633+684 (2026-09-29) — PK bitişi, PK daveti teslimi, SSE ve hız

- **Canlı yayın PK:** süre dolunca istemci sunucuya yeniden sorar ve bitişi tetikler; PK artık "0:00"da asılı kalmaz
- **Sesli oda PK daveti:** oda listesinden boş odaları eleyen filtre kaldırıldı (sahip tek başınayken karşı oda bulunamıyor, "Odalarım" boş kalıyordu); boş oda filtresi yalnızca keşfetteki "Yakındakiler"de
- **Önbellek:** `/pk`, `/state`, `/sync`, `/seats`, `/speak-request` uçları HTTP önbelleğinden çıkarıldı (davet/bitiş 12–20 sn bayat okunuyordu)
- **Hız:** PK davet yoklaması 2 sn → 3 sn ve yalnızca odadayken veya oda sahibiyken; aktif PK yoklaması 1 sn → 3 sn (SSE zaten canlı skor gönderiyor)
- **Backend (canlifal, ayrı PR):** SSE akışı PK durumunu veritabanından senkronlar (çoklu sunucu örneğinde de davet/bitiş ulaşır); `/api/live/pk` süresi dolan PK'yı kapatır; global PK taraması 3 sn'de bir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
