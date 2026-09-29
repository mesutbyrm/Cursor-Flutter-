# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.653+704` |
| Tarih (UTC) | 2026-09-29 23:48 |
| Commit | [`974d77229f561eda73ef63558fba6bbb166c9758`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/974d77229f561eda73ef63558fba6bbb166c9758) |
| İş akışı | [Run 36645320386](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36645320386) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.653+704 (2026-09-29) — Backend (mesutbyrm/canlifal) sözleşme denetimi

Mobilin çağırdığı 475 uç backend kaynağıyla (yol, metot, gövde, eylem adı) karşılaştırıldı. Backend değişikliği yok.

- **Canlı yayın misafir:** yayıncı daveti asıl misafir sistemine (`/api/live/guest` `invite`) taşındı; izleyici daveti `respond` + `inviteId` ile kabul/red ediyor (önceden 400/403). Onay gelince izleyici hemen misafir yayınına geçiyor (önceden 60 sn'ye kadar bekliyordu)
- **Canlı yayın PK (video uçları):** `action`, `targetStreamId`, `duration` alanları backend'e uygun
- **Sosyal:** gönderi JSON ile; görsel önce yüklenip `imageUrl` olarak gidiyor (multipart gönderim sunucuda başarısızdı). Video paylaşımı Kısa Videolar'a yönlendiriliyor
- **E-posta doğrulama:** backend'de olmayan uçlar yerine `/api/auth/email/send-verification` ve `/api/auth/email/verify`
- Sesli oda, canlı falcı, profil, fal & tarot: yol/metot/gövde uyumlu bulundu


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
