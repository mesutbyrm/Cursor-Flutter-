# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.358+396` |
| Tarih (UTC) | 2026-08-24 22:05 |
| Commit | [`e4d80f71`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e4d80f71) |
| İş akışı | [Run 32781903927](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32781903927) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.358+396 (2026-08-24) — Canlı Falcılar bağlantı stabilitesi

- **Oturum başlangıcı:** Oda kimliği backend'den gelene kadar kısa bekleme — erken TRTC join kopması azalır
- **TRTC yeniden bağlanma:** Kanal değişiminde 800ms debounce — gereksiz kopma/yeniden giriş önlenir
- **Oda SSE:** Kopunca otomatik 3 denemeye kadar yeniden bağlanma; uygulama ön plana gelince SSE yenileme
- **Falcı timer:** Oturum açılınca süre otomatik başlar (manuel unutma engeli)
- **Gelen çağrı SSE:** Max reconnect sonrası hızlı HTTP poll + otomatik SSE retry

## 1.0.357+395 (2026-08-24) — Müzik arama sheet geçişi

- **Müzik arama:** Şarkı seçiminden sonra mod seçici sheet'i 150ms gecikmeyle açılır

_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
