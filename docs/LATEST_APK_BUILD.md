# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.753+806` |
| Tarih (UTC) | 2026-10-09 17:38 |
| Commit | [`72d7fdfcaa227d83521d79320f74251063808771`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/72d7fdfcaa227d83521d79320f74251063808771) |
| İş akışı | [Run 37965097774](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37965097774) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.753+806 (2026-10-09) — Mistik kutular, Hediye Yolla, alt bar, GirLive, arka plan senkronu, sosyal ve profil

- **Mistik kutu görselleri:** Ana sayfadaki 10 kutu ve «Tüm Özellikler»deki tüm kutular adına uygun mistik amblemle (ör. Jeton Al → altın jeton, Canlı Falcılar → göz)
- **Hediye Yolla (yeni):** Kendi bakiyenden bir kullanıcıya Jeton veya CFC gönder; en az 100, komisyon admin panelinden (`POST /api/wallet/transfer` — **backend deploy gerekli**)
- **Ana sayfa düğmesi:** Ana sayfadayken tekrar dokununca en üste kayar ve sayfa yenilenir
- **Alt bar (kök neden):** `push` ile açılan sayfalarda go_router adresi değişmediği için (ör. Trend Videolar) alt bar gizleniyordu → görünen sayfa eşleşme listesinden okunur; kendi barı olan / tam ekran sayfalarda ve klavye açıkken eklenmez
- **GirLive Bot:** Selam 10 sn sonra kalkar, odaya girince geçmişteki eski selamlar yeniden görünmez; kurallar/duyuru artık popup değil, yalnız girene sohbet içinde 15 sn görünür
- **Sesli oda arka planı (kök neden):** Diğer kullanıcılarda yeni arka plan 450 ms sonra önbellekteki eski arka plana dönüyordu → anında ve kalıcı; varsayılana dönüş de herkese yansır
- **Koltuk değiştirme / koltuğa oturma efekti kaldırıldı**
- **GirLive Sosyal:** Başlıktaki yıldız kaldırıldı; fal kartında yazı görselin üstünde, «daha fazla» metnin tamamını kartta açar; «kaç kişi baktı» + son 5 kişinin avatarı (`GET /api/social/fortune-viewers` — **backend deploy gerekli**, yoksa akıştan)
- **Profil:** Aşağı açılan bölümler (Bakiye & Üyelik, İstatistikler & Sosyal, Yayın & Sesli Oda, Ayarlar & Güvenlik) düğme oldu; hızlı menü kaydırmasız ızgara


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
