# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.328+331` |
| Tarih (UTC) | 2026-06-22 18:15 |
| Commit | [`b1e92c0ef3f18ffdd4f2fe8d8065cddd4606d946`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b1e92c0ef3f18ffdd4f2fe8d8065cddd4606d946) |
| İş akışı | [Run 27973173812](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27973173812) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.328+331 (2026-06-22)

### Ana sayfa — gri ekran düzeltmesi

- **HomePage:** `dispose()` içinde `ref.read` kaldırıldı (Riverpod hatası); bridge örneği `initState`'te önbelleğe alınıyor
- **HomeRealtimeBridge:** `_disposed` bayrağı ile sekme değişiminde güvenli timer iptali
- Sekme dışına çıkıp ana sayfaya dönünce widget yeniden oluşturulduğunda çökme/gri ekran giderildi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
