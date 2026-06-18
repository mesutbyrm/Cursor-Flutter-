# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.278+281` |
| Tarih (UTC) | 2026-06-18 23:45 |
| Commit | [`e98b8fbeb385d8e96675dd8758d68ca94050f953`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e98b8fbeb385d8e96675dd8758d68ca94050f953) |
| İş akışı | [Run 27795821610](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27795821610) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.278+281 (2026-06-18)

### Jeton — ödeme bildir düzeltmesi

- **Tek dokunuş:** WhatsApp / Papara / Havale'de «Ödeme Bildir» doğrudan talep gönderir (önce yalnızca alt sayfa açılıyordu)
- **API yedekleri:** `POST /api/payment/requests` → `/api/jeton/payment-request` → `/api/payment/request`
- **Yanıt algısı:** `paymentRequest`, `ok`, `created` alanları; 2xx geniş kabul
- **Dekont:** İsteğe bağlı «Dekont ekle» tüm yöntemlerde


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
