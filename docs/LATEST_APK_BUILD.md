# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.96+98` |
| Tarih (UTC) | 2026-06-01 10:09 |
| Commit | [`7e6289dd092cc2e9e8c6456072475f2c4339b85b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/7e6289dd092cc2e9e8c6456072475f2c4339b85b) |
| İş akışı | [Run 26747502772](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26747502772) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.96+98 (2026-05-31)

### Sesli oda, ödeme, jeton/CFC, sohbet düzeltmeleri

- Bakiye: `GET /api/me` + yedek `GET /api/user/credits` — jeton 0 görünme / oda açılamama
- Oda aç: bakiye yüklenmeden engel kaldırıldı; API jeton kontrolü esas
- Ödeme bildirimi: 22 sn zaman aşımı; belirsiz yanıtta hata; sonsuz dönme giderildi
- Jeton/CFC: `openJetonStore` / `openCfcStore` — sesli odadan güvenilir yönlendirme
- Sohbet: ikinci mesaj kilidi (`sending` + poll pause) kaldırıldı; 10 sn gönderim limiti
- YouTube: `/api/chat/youtube-search` önce, boş sonuçta yedek uç


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
