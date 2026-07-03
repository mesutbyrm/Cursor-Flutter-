# Ana sayfa & Kısa video performans raporu

**Sürüm:** 1.0.477+481  
**Tarih:** 2026-07-03 (UTC)

## Özet

Ana sayfa kritik API'leri artık **paralel bootstrap** ile yükleniyor; alt bölümler lazy delay ile kademeli açılıyor. Kısa videolarda **sonraki 3 video** öncelikli preload + disk cache genişletildi.

---

## API yükleme süreleri (canlifal.com — curl, tek istek)

| Modül | Endpoint | Süre (ms) |
|-------|----------|-----------|
| Banner | `GET /api/banners` | 407 |
| Fal kartları | `GET /api/homepage-fortune-cards` | 329 |
| Sosyal | `GET /api/social/posts` | 498 |
| Shorts feed | `GET /api/short-videos?limit=12&tab=foryou` | 330 |
| Shorts explore | `GET /api/short-videos/explore?limit=12` | 112 |
| Canlı yayın | `GET /api/video-streams` | 113 |
| Sesli oda | `GET /api/chat/rooms` | 110 |
| Falcılar | `GET /api/fortune-tellers` | 111 |
| Hikayeler | `GET /api/stories?page=1&limit=30` | 108 |
| Oyun kataloğu | `GET /api/games` | 108 |

**Darboğaz (önce):** Banner + sosyal ~400–500 ms; trend videolar 900 ms gecikmeyle başlıyordu.  
**Darboğaz (sonra):** 6 kritik istek `homeBootstrapProvider` ile T=0 paralel; HTTP cache + keepAlive ile tekrar ziyarette ~0 ms (bellek/disk).

Yeniden ölçüm: `bash scripts/measure-home-shorts-api.sh`

---

## Yapılan optimizasyonlar

### Ana sayfa

1. **`homeBootstrapProvider`** — banner, trend, canlı, sesli oda, fal kartları, hikayeler **paralel** prefetch
2. **Lazy delay kısaltıldı** — trend/canlı T=0; alt bölümler 80–800 ms (önce 150–1350 ms)
3. **Pull-to-refresh sadeleştirildi** — yalnızca ekrandaki 6 bölüm (shorts/psychics/games kaldırıldı)
4. **`ref.keepAlive()`** — kritik home provider'ları sekme değişiminde yeniden fetch etmez
5. **Shell prefetch** — çift mesaj listesi isteği kaldırıldı
6. **Canlı önizleme** — eager HLS 5 → **2** kart (bant genişliği)
7. **Trend API sırası** — `/api/short-videos` önce (explore yedek)

### Kısa videolar

1. **Pool 5 → 6** controller; warm sırası **+1,+2,+3 önce** (TikTok tarzı)
2. **Disk preload** — sonraki **4** video arka planda indirilir
3. **UI penceresi ±2 → ±3** tam tile
4. **Video disk cache** 48 → **64** obje
5. **Play retry** 6 → 4 (gereksiz gecikme azaltıldı)

### Debug

- `AppPerfMetrics.formatApiReport()` — API süre özeti
- `homeApiTimings()` — ana sayfa bootstrap etiketleri (`home.banners`, vb.)

---

## Beklenen kullanıcı etkisi

| Alan | Önce | Sonra |
|------|------|-------|
| Ana sayfa ilk içerik | ~900 ms+ (kademeli) | ~max(API) paralel (~500 ms) |
| Trend bölümü | 900 ms gecikme | T=0 (bootstrap) |
| Pull-to-refresh | 12 istek | 6 istek |
| Shorts kaydırma | Sonraki video soğuk start | +1/+2/+3 hazır |
| Canlı kart bant genişliği | 5 HLS | 2 HLS |

---

_Bu dosya agent oturumu tarafından güncellenir; CI otomatik yazmaz._
