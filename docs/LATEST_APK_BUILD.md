# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.736+789` |
| Tarih (UTC) | 2026-10-07 14:44 |
| Commit | [`e1af6fea87838a0c3d330608e132e8cbb1fbea16`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e1af6fea87838a0c3d330608e132e8cbb1fbea16) |
| İş akışı | [Run 37636135276](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37636135276) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.736+789 (2026-10-07) — İçerik detayları, oyun tahtası düzeltmesi, arka plan SSE

- **Blog yazısı (yeni sayfa `/blog/{slug}`):** `GET /api/blog?slug=` tam metin; beğeni/kaydet (`POST /api/blog/like`, `/favorite`, durum `GET /api/blog/interactions`); ilgili yazılar (`GET /api/blog/related`). Daha önce `/blog/...` bağlantıları blog merkezine geri dönüyordu
- **Burç yazıları (`/blog/burclar`):** `GET /api/blog/zodiac` burç sekmeleri + seçili burcun yazıları
- **Rüya sözlüğü sembolü (`/ruya-sozlugu/{slug}`):** `GET /api/dream-symbols/{slug}` anlam + ilgili semboller; Rüya Merkezi sözlük satırları artık buraya açılır (eskiden rüya yorumu fal ekranına gidiyordu)
- **TikTok videoları (`/tiktok`, `/tiktok/{id}`):** `GET /api/tiktok-videos` + detay/benzerler; izleme TikTok'ta (yalnız https bağlantı)
- **Oyun odası oluşturma (hata):** ilk istek `POST /api/games/room {gameType}` — eskiden `/api/games/rooms` (yalnız GET, 405) ve `gameType`'sız gövde denendiği için sunucu «Geçersiz oyun tipi» dönüyordu
- **XOX tahtası (hata):** sunucu `state` alanını JSON metni olarak döndürüyor; Flutter okumadığı için tahta hep boş görünüyordu. Metin çözülür; 6×6/8×8/10×10 tahta kare hücreyle çizilir (`state.size`)
- **XOX tahta boyutu:** oda açarken `GET /api/games/grid-settings` listesinden seçim → `gridSize`
- **Masaya geri dön:** bağlantı kopup masayı yapay zekâ devraldıysa «masaya geri dön» (`POST /api/games/room/{id}/replace-ai`)
- **BG-002 (Flutter tarafı):** sesli oda `room_event {event: room_updated, backgroundImage}` arka planı anında günceller (backend PR mesutbyrm/canlifal#23 ile gelir)
- Gerçek cihaz: **BLOCKED**


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
