# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.572+615` |
| Tarih (UTC) | 2026-09-19 21:00 |
| Commit | [`f11b73e774455d9f57d4e6ae90fb43ca12176e0b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f11b73e774455d9f57d4e6ae90fb43ca12176e0b) |
| İş akışı | [Run 35467441652](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35467441652) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.574+617 (2026-09-19) — Bildirim/mesaj birleşik + uygulama içi banner

- **Alt menü:** "Mesaj/Fal" sekmesi **"Fal & Tarot"** oldu ve üzerindeki bildirim rozeti kaldırıldı (bildirim/mesaj artık yalnızca Gelen Kutusu'nda)
- **Gelen Kutusu üst kartları:** "Tümü" görünümüne iki kart eklendi — **Mesajlar** (okunmamış mesaj sayısı) ve **Sistem Bildirimleri** (okunmamış sistem sayısı); her karta dokununca ilgili bölüm açılır. Mesajlar ve sistem bildirimleri tek yerde, ayrı bölümlerde
- **Uygulama içi banner (yeni):** mesaj veya sistem bildirimi geldiğinde kullanıcı **hangi ekranda olursa olsun** ekranın üstünden düşen banner gösterilir; dokununca ilgili sohbet/bildirim açılır, yukarı kaydırınca kapanır, 4 sn sonra otomatik kaybolur. Açık olan DM için o kişinin mesaj banner'ı bastırılır
- Banner, bildirim SSE'sinden (`NotificationsRealtimeListener`) beslenir; yinelenen bildirim iki kez düşmez
- **Not (mesaj iletimi):** istemci DM'i kılavuzda **belgelenmemiş** `POST /api/messages/{peerId}` `{content}` ucuna gönderiyor; conversation id sunucu peer nesnesini döndürdüğünde peer userId'ye çözülüyor. "Karşıya ulaşmıyor" sorunu bu uç/gövde doğru olduğunda **sunucu iletimine** bağlıdır — körlemesine uç değişimi tüm DM'leri kırma riski taşıdığından yapılmadı; sunucu sözleşmesi netleşince hizalanır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
