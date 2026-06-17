# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.243+246` |
| Tarih (UTC) | 2026-06-17 10:45 |
| Commit | [`20581c4b453d7ad5c2f34e0b3ea6a4d0624d1480`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/20581c4b453d7ad5c2f34e0b3ea6a4d0624d1480) |
| İş akışı | [Run 27682807875](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27682807875) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.243+246 (2026-06-12)

### Canlı Falcılar — web ile oturum senkronu

- **Gelen istekler:** Üretim API `GET /api/fortune-tellers/sessions` (web ile aynı); yerel ayna yedek
- **Kabul/red:** `PATCH /api/fortune-tellers/sessions/{id}` + eski `respond` yedek
- **Danışan bekleme:** Oturum durumu üretim listesinden poll; kabulde TRTC oda bilgisi güncellenir
- **Sohbet:** `GET/POST /api/teller-chat/{sessionId}` — web ↔ uygulama metin iletişimi
- **Bildirim:** Canlı fal bildirimleri `/canli-falcilar` sayfasına yönlendirilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
