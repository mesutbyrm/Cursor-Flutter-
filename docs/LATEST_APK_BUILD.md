# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.716+769` |
| Tarih (UTC) | 2026-10-05 18:56 |
| Commit | [`22d445091969be47f12ac4e36e86f41acef24d4b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/22d445091969be47f12ac4e36e86f41acef24d4b) |
| İş akışı | [Run 37356998354](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37356998354) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.716+769 (2026-10-05) — Odadan çıkınca ses, profil kaydı, admin ayrıcalıkları

- **Sesli odadan çıkış:** TRTC bağlantısı ve uzak ses artık REST `voice leave` beklenmeden ilk adımda kesilir (yavaş ağda çıktıktan sonra da odada duyuluyor/duyuluyordu)
- **Profil tamamlama:** Şehir/burç/takım kaydı hata yutmuyor; backend `city` alanını kaydediyor ve geri döndürüyor (daha önce «Kaydet» başarılı görünüp şehir boş kalıyordu)
- **Profil ekranı:** Paylaş/Ayarlar çubuğu durum çubuğunun (pil/Wi‑Fi) altında kalmıyor
- **Admin:** oda açarken jeton/bakiye sorusu yok (sunucu da ücret almaz); admin korumalı: admine sustur/at/yasakla girişiminde ilk seferde sesli uyarı, tekrarında girişimi yapanın kendisine uygulanır
- **Bildirimler:** uygulama açıkken gelen bildirim sesli (+ titreşim)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
