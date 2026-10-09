# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.748+801` |
| Tarih (UTC) | 2026-10-09 11:16 |
| Commit | [`62f38b260f83024fdd5261965d0bc34bb18bd75b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/62f38b260f83024fdd5261965d0bc34bb18bd75b) |
| İş akışı | [Run 37920400345](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37920400345) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.748+801 (2026-10-09) — Teşhis: yakalanmayan hata logu (401 ucu + çözülebilir yığın)

- **Neden:** Canlı falcı seansı bitiminde `Cannot use "ref" after the widget was disposed` ve 2× `401` logda görünüyor ama kaynak bulunamıyordu: `ui.zone` yalnız ilk 3 başlık satırını yazıyordu (çerçeve yok), DioException'da uç yolu yoktu
- **Değişiklik:** `ui.zone` / `ui.flutter` / `ui.platform` → DioException için `YÖNTEM /yol status=…` (sorgu dizesi/başlık yok → token sızmaz); obfuscated yığında `flutter symbolize` için başlık + ilk 12 çerçeve
- Davranış değişikliği yok; bir sonraki cihaz logu hatanın tam yerini gösterecek


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
