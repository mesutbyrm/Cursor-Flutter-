# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.256+259` |
| Tarih (UTC) | 2026-06-17 22:13 |
| Commit | [`f8c77065b5839d0cab9ab9166b97bbbfcedb329d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f8c77065b5839d0cab9ab9166b97bbbfcedb329d) |
| İş akışı | [Run 27722496843](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27722496843) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.256+259 (2026-06-17)

### Canlı falcı — baştan yazılmış akış

- **Randevu:** Süre seç → Randevu Al → `POST /api/fortune-tellers/session` → bekleme ekranı
- **Bekleme:** Admin reklamı (`GET /api/banners`); falcıya popup (Kabul / Beklet / Reddet)
- **Kabul sonrası:** Danışana reklam geçişi (3 sn) → aktif seans
- **Kapatma:** Danışan ve falcı iptal/kapat dediğinde onay + API `end` + güvenli çıkış
- **Router:** `/canli-falcilar/:id/waiting` bekleme rotası eklendi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
