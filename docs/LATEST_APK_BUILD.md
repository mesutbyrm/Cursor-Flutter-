# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.756+809` |
| Tarih (UTC) | 2026-10-10 01:46 |
| Commit | [`c6365cb57da8be2931b795feb30e51de55f9ee14`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/c6365cb57da8be2931b795feb30e51de55f9ee14) |
| İş akışı | [Run 38013286987](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38013286987) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.757+810 (2026-10-10) — WhatsApp tarzı gelen kutusu, sistem mesajları okundu, ana sayfa kutuları

- **Gelen kutusu:** Büyük, renkli halkalı avatar; yalnız sunucu «çevrimiçi» dediğinde yeşil nokta; kalın isim, altında son mesaj, sağ üstte saat, yeşil yuvarlak okunmamış rozeti. «Tümü» ve «Mesajlar» aynı satırı kullanır
- **Gerçek son görülme:** «çevrimiçi» / «son görülme bugün 14:05 · dün · 2 Mar». Veri yoksa veya kullanıcı gizlediyse hiçbir şey yazılmaz (uydurma metin yok). Çevrimiçi durumu önbellekten geri gelmez (bayat yeşil nokta yok)
- **Çevrimiçi kök neden düzeltmesi:** Mobil heartbeat `visitorId` göndermediği için sunucu 400 dönüyordu; mobil kullanıcılar hiç çevrimiçi görünmüyor, son aktiflik güncellenmiyordu. Arka plana geçince `leave` kaydı hemen siler
- **Sohbet balonları:** Benim mesajım sağda yeşil, karşı tarafınki solda nötr gri (açık temada koyu yazı); küçük saat ve gönderildi/iletildi/okundu tikleri sağ altta. Başlıkta halkalı avatar + son görülme. Tüm mesaj türleri (sesli not, yanıt, iletilen, davet kartları) korunur
- **Sistem Mesajları:** Ekran açılınca yalnız **sistem** bildirimleri sunucuda okundu yapılır (`POST /api/notifications {notificationIds}`); DM/sohbet bildirimleri etkilenmez. Sunucu onaylamadan öğeler okunmuş gösterilmez; hata olursa «Tekrar dene». «Tümünü oku» da artık yalnız sistem bildirimlerini okur
- **Ana sayfa 10 kutu:** Amblemler kendi renginde (Gold Üyelik ve Jeton Al altın); görsel kırpılmadan, üstüne karartma binmeden tam görünür, etiket görselin altında
- **Backend deploy gerekli** (`mesutbyrm/canlifal` — şema değişikliği yok): `/api/messages` yanıtına `isOnline`/`lastSeenAt` (gizlilik kurallarıyla), `/api/presence` `action: leave`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
