# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.675+728` |
| Tarih (UTC) | 2026-10-01 19:23 |
| Commit | [`e02748676ad1efcb0097e90d2f6cdfc126ee56a4`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e02748676ad1efcb0097e90d2f6cdfc126ee56a4) |
| İş akışı | [Run 36911242153](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36911242153) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.675+728 (2026-10-01) — Sesli Odalar Premium 2026 yeniden tasarım

- **Ana ekran:** menü/başlık/arama/liderlik/bildirim üst barı, "Sesinle Daha Yakın Ol" hero, 10 kategori (Tümü, Popüler, Sohbet, Müzik, Aşk, Fal & Astroloji, Oyun, Arkadaşlık, Yardım, Diğer), Odalarım özeti, 2 kolonlu Popüler Sesli Odalar, Günün Öne Çıkan Odası, Trend Konular, En Aktif Konuşmacılar, Öne Çıkan Kategoriler, "Kendi Odanı Aç"
- **Takip Et:** En Aktif Konuşmacılar satırlarında oda sahibini takip etme (`ProfileRepository.follow`); kendi satırında ve kimliği olmayanlarda gösterilmez
- **Yeni ekranlar:** `/voice-rooms/list` (Yakındaki / Yeni / Arkadaşların odaları, arama + kategori filtresi, sayfalı) ve `/voice-rooms/mine` (Odalarım yönetimi)
- **Tek alt navigasyon:** sayfanın kendi alt menüsü kaldırıldı (kabuktaki menüyle çift navigasyon oluyordu)
- **Düzeltmeler:** arama ve liderlik düğmeleri artık çalışıyor (önceden boş `onTap`); Odalarım'da oda başına ayar API çağrısı kaldırıldı (kategori oda listesinden okunur); ana ekrandaki sürekli hareket eden arka plan/parçacıklar ve ağır BackdropFilter kaldırıldı
- "Müsait/Kilitli/Dolu" rozeti oda verisinden; konuşmacılar sahibe göre birleştirilir (dinleyici + oda sayısı)
- Katıl, oda oluşturma, ayarlar, presence, TRTC ve backend çağrıları değişmedi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
