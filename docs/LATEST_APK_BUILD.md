# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.816+872` |
| Tarih (UTC) | 2026-10-16 23:34 |
| Commit | [`21076112e01ce3f6a5f2d6edf72b2cad0f67a103`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/21076112e01ce3f6a5f2d6edf72b2cad0f67a103) |
| İş akışı | [Run 38979588290](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38979588290) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.816+872 (2026-10-16) — Canlı yayın kapanışı ve PK

- **Yayın kapatma:**
  - Yayıncı «Kapat» dediğinde kamera, mikrofon ve yayın bağlantısı hemen kapanıyor. Önceden özet penceresi açıkken izleyiciler yayını görmeye devam ediyordu.
  - Sunucu bağlantısı hata verse bile yayıncı odadan çıkıyor; önceden odada takılı kalıyordu.
  - Bitmiş yayın için «yayına devam et» önerisi artık çıkmıyor.
- **İzleyici:**
  - Yayın bittiğinde izleyici ekranı beklemeden kapanıyor.
  - Yayının bitip bitmediği önbellek kullanılmadan 10 sn'de bir kontrol ediliyor. Bu kontrol yayına katılım hata verse bile çalışıyor.
  - Kaydırma akışında ekranda olmayan bir yayın bittiğinde izlenen yayın ve akış artık kapanmıyor.
- **PK:**
  - PK bittiği anda yayıncılar ve izleyiciler doğrudan tekli yayına dönüyor. Önceden ekran 7-8 sn bölünmüş kalıyordu; erken bitişte süre dolunca bölünmüş ekran geri geliyordu.
  - Sohbet ayrı: A'yı izleyen yalnız A'nın sohbetini, B'yi izleyen yalnız B'nin sohbetini görüyor ve oraya yazıyor.
  - İzlerken rakip yayıncının adına ya da fotoğrafına dokununca «… yayınına geçmek istiyor musun?» sorusu çıkıyor; «Evet» ile o yayına geçiliyor.
  - Hediye arkada tam ekran oynuyor; hediye süresince yayıncı panelleri ve sohbet yarı şeffaf oluyor.


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
