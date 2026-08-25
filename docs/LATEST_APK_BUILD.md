# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.359+397` |
| Tarih (UTC) | 2026-08-24 22:55 |
| Commit | [`e1e9e343`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e1e9e34303bdc035909a431cf1de60c1cebd4b3d) |
| İş akışı | [Run 32785528630](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32785528630) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.359+397 (2026-08-24) — Canlı Falcılar TRTC + bekleme

- **TRTC kopma:** Koordinatör `onConnectionLost` / `onReconnected` UI ile senkron — otomatik yeniden bağlanma görünür
- **Bekleme ekranı:** Durum poll 2 sn; uygulama ön plana gelince anında kabul kontrolü

## 1.0.358+396 (2026-08-24) — Canlı Falcılar bağlantı stabilitesi

- **Oturum başlangıcı:** Oda kimliği backend'den gelene kadar kısa bekleme
- **TRTC yeniden bağlanma:** Kanal değişiminde 800ms debounce
- **Oda SSE:** Kopunca otomatik yeniden bağlanma; resume'da SSE yenileme
- **Falcı timer:** Oturum açılınca süre otomatik başlar
- **Gelen çağrı SSE:** Max reconnect sonrası hızlı poll + retry

## 1.0.356+394 (2026-08-24) — Müzik isteği ANR düzeltmesi

- Sheet gecikmesi, flash/chat ayrımı, WebView gecikmesi

_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
