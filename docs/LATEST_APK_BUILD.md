# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.735+788` |
| Tarih (UTC) | 2026-10-07 13:39 |
| Commit | [`af8775e63da0524136a7c3f7ca75493bd9fe057c`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/af8775e63da0524136a7c3f7ca75493bd9fe057c) |
| İş akışı | [Run 37627254793](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37627254793) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.735+788 (2026-10-07) — Backend'de olup Flutter'da eksik olan uçlar

- **VIP mesaj sabitleme:** sesli oda mesajına uzun bas → «Sabitle (Premium+)» (`POST /api/chat/rooms/{id}/pin-message`); SSE `VIP_PIN` olayı sohbetin üstünde süreli (TTL) sabit bant gösterir. Yetki/bekleme/saatlik sınır sunucuda
- **Müzik geçmişi:** müzik panelinde yeni «Geçmiş» sekmesi (`GET /api/music/history`); satıra dokunmak şarkıyı arama sekmesine taşır
- **Ödeme bildirimlerim + itiraz:** `GET /api/payments/notify` listesi (durum, admin açıklaması) ve reddedilen/düzeltilen ödeme için «İtiraz et» (`POST /api/payments/notifications/{id}/dispute` → destek talebi). Ödeme Bildirimi sayfasından bağlantı
- **Bildirim rozeti:** önce `GET /api/notifications/unread` (yalnız sayı); eski liste sorgusu yedek
- **Hata düzeltmesi:** yasaklı kelime silme kelimeyi iki kez URL-encode ediyordu (Türkçe karakterli/boşluklu kelime silinemiyordu)
- Gerçek cihaz: **BLOCKED**


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
