# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.565+608` |
| Tarih (UTC) | 2026-09-19 13:46 |
| Commit | [`8be95b65fc360842644158e6f04be71368934384`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8be95b65fc360842644158e6f04be71368934384) |
| İş akışı | [Run 35445760876](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35445760876) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.565+608 (2026-09-19) — Hediye gösterimi TikTok/Bigo tarzı (alttan ≤%50, tam ekran yok)

- **Hediyeler artık tam ekran açılmıyor.** `GiftEngineOverlay` backend `fullScreen`/`isFullScreen` bayrağını yok sayıp tüm hediyeleri **alttan-hizalı banda** alıyor (koltuk efektleri hariç, onlar küçük/konumlu kalır)
- Hediye animasyonu **ekranın en fazla ~%48'i** ile sınırlı (responsive, sabit px değil); canlı yayın görüntüsü, sesli oda koltukları ve PK skoru üstte açık kalır
- Sahne bandı alttan başlar: `GiftStageMetrics` topInset %50–52, alt chrome (kontroller/giriş) korunur
- Video hediyelerinde **progress bar / seekbar / kontrol yok** (ham `VideoPlayer`, `looping:false`); ses ayrı `playActiveGiftSound` ile çalınır, video muted
- Alttan yukarı yumuşak giriş (fade + slideY + scale)
- Değişmeyen (zaten spec'e uygun): FIFO animasyon kuyruğu, event-bazlı **puan (animasyondan bağımsız)**, ses, duplicate koruması (`CdsFullscreenGiftGate` + `seenEventIds`), oda/PK temizliği, TRTC/SSE/jeton/PK-skor/backend contract


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
