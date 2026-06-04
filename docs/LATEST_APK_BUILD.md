# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.125+127` |
| Tarih (UTC) | 2026-06-04 13:20 |
| Commit | [`04f1be76be9b1fc7163ba4779ad502a3b54b02f5`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/04f1be76be9b1fc7163ba4779ad502a3b54b02f5) |
| İş akışı | [Run 26953162322](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26953162322) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.125+127 (2026-05-19)

### WhatsApp jeton ödemesi — zaman aşımı düzeltmesi

- `POST /api/payment/requests`: 22 sn dış zaman aşımı kaldırıldı; istek başına 45 sn `receiveTimeout`
- Gövde artık `Map` olarak gönderiliyor (web ile aynı JSON; çift kodlama riski yok)
- Oturum yoksa anında anlamlı hata; 4xx/5xx sunucu mesajı snackbar’da
- Debug: `[Payment]` logları (URL, method, JWT varlığı, status, süre)
- API: ödeme talebi 201 yanıtı bildirimler tamamlanmadan döner (mobil zaman aşımı önlenir)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
