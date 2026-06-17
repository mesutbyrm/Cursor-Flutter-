# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.244+247` |
| Tarih (UTC) | 2026-06-17 13:20 |
| Commit | [`02f125319f4b1e7306b97b442b8f0a8421fb2b2b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/02f125319f4b1e7306b97b442b8f0a8421fb2b2b) |
| İş akışı | [Run 27691307997](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27691307997) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.244+247 (2026-06-12)

### Canlı Falcılar — kabul ekranı + bildirim + hız

- **Kabul ekranı:** Üretim `GET /fortune-tellers/sessions` ayrıştırması genişletildi; falcı uygulama açılışında `toggle-online` (web ile aynı çevrimiçi)
- **Poll:** Davet kontrolü 2 sn; 4 sn başlangıç gecikmesi kaldırıldı; uygulama ön plana gelince anında yenileme
- **Push:** Token kaydı `POST /api/auth/mobile/device-token` + yedek uçlar; girişte bildirim izni isteği
- **Performans:** Ana sayfa bölümleri kademeli yükleme (`HomeDeferredSection`); arka plan poll 60 sn


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
