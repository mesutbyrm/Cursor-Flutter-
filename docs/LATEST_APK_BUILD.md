# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.751+804` |
| Tarih (UTC) | 2026-10-09 15:48 |
| Commit | [`ce4fed04374230034629f4c28d69d808cd51dc16`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ce4fed04374230034629f4c28d69d808cd51dc16) |
| İş akışı | [Run 37952223232](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37952223232) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.751+804 (2026-10-09) — Animasyon pilotu: «Tüm Özellikler»

- **Ortak hareket politikası (`CanlifalMotionPolicy`):** Sistem «hareketi azalt» ayarı veya uygulama performans modu (düşük donanımda varsayılan açık) → dekoratif hareket kapalı, işlev aynı
- **«Tüm Özellikler» pilotu:** Kutular oturumda yalnız ilk açılışta kademeli girer (en çok 5 adım), ikon bir kez zıplar, basınca küçülür + hafif titreşim; sürekli dönen animasyon yok; hareket azaltılmışsa hiçbiri çalışmaz
- Yeni bağımlılık yok (`flutter_animate` mevcut); `animations` eklenmedi, Rive ertelendi
- **Test:** ilk açılış / ikinci açılış / hareketi azalt / performans modu / animasyon ortasında kapanma / dokununca gezinme


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
