# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.676+729` |
| Tarih (UTC) | 2026-10-01 20:09 |
| Commit | [`f223f19d7fd23a8aef23dca32f57fd9bcea60a87`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f223f19d7fd23a8aef23dca32f57fd9bcea60a87) |
| İş akışı | [Run 36917077585](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36917077585) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.676+729 (2026-10-01) — Fal & Tarot Premium 2026 yeniden tasarım

- **Ortak tasarım sistemi** (`widgets/fortune_hub_2026/fortune_hub_kit.dart`): renk, gradient, radius, tipografi (Playfair başlık), cam kart (blur'suz), bölüm başlığı, kategori kartı, altın düğme, boş/hata/yükleme durumları
- **Hub sırası referansa göre:** başlık (menü, geçmiş, bildirim, CFC/Jeton) → hero "Kaderin Bugün Sana Ne Söylüyor?" + Falına Bak → Enerjin/Ay Evresi → "N fal kaydın var" → arama → hızlı erişim 3×2 → Günlük Kehanet → Son Fallarım → Popüler Fal Türleri (2 sütun) → Sana Özel → Tüm Fal Türleri (3 sütun) → Canlı Falcılar → Kısa Videolar → Hazır Yorumlar → Bana Özel → Hatırlatıcı
- **Gerçek veri:** fal geçmişi, günlük içgörü, fal türleri vitrini, canlı falcılar (müsaitlik, puan, Jeton/dk), kısa videolar, Bana Özel ve cüzdan mevcut sağlayıcılardan; uydurma içerik yok. Veri gelmezse yükleniyor/boş/hata durumu gösterilir
- **Performans:** sürekli dönen kristal/parçacık/bulanıklık arka planı kaldırıldı (statik gradient); alt bölümler yalnızca görününce kurulur ve veri ister
- **Tüm Fal Türleri sayfası** aynı kartlarla yenilendi; arama hub'daki tür listelerini süzer
- Backend, API yolu, JWT, CFC/Jeton, fal akışı değişmedi. Hub'dan kaldırılanlar: eski burç/doğum kartı ve günlük görev şeridi (doğum bilgisi istemi korunuyor)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
