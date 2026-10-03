# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.701+754` |
| Tarih (UTC) | 2026-10-03 14:31 |
| Commit | [`927b22d2e7308bd68bf305db66fb81f5347a9a97`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/927b22d2e7308bd68bf305db66fb81f5347a9a97) |
| İş akışı | [Run 37128679400](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37128679400) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.701+754 (2026-10-03) — Profil sekmeleri, admin profil, kullanıcı yönetimi, yayın istatistikleri

- **Profil içerik sekmeleri:** kaymayan 5 ana sekme — Gönderiler (kullanıcının sosyal paylaşımları, 3 kolon ızgara) · Videolar · Hikâyeler (oturum kullanıcısının aktif hikâyeleri, dokununca görüntüleyici) · Beğeniler · Fal Aktiviteleri; eski sekmeler (Kaydedilen, Canlı Yayınlarım, İzlediklerim, Favoriler, Taslaklar) «diğer» çipleriyle korunur. Profil eylemleri: Profili Düzenle · Paylaş (profil bağlantısı) · QR · Ayarlar
- **Admin profil:** ADMIN rozeti + yetki seviyesi + gerçek sayaçlar (yönetici işlemi, bekleyen ödeme, aktif yayın, aktif oda; veri yoksa «—»); normal kullanıcıda çizilmez
- **Kullanıcı yönetimi:** sayfalı kullanıcı dizini (`GET /api/admin/users`) — arama + Tümü/Aktif/Pasif/Banlı/Yayıncı/Admin filtreleri; satırda avatar, ad, rol, çevrimiçi, VIP, durum, işlem menüsü (Profil, Ban/Unban, Mute, Rol, Şikâyetler, Aktiviteler)
- **Canlı Yayın İstatistikleri (`/admin/live-stats`):** Aktif yayın, toplam izleyici, hediye geliri (toplam), aktif yayıncı; Yönetim Merkezi'ne kart eklendi. Son 7 gün grafiği sunucuda zaman serisi ucu olmadığından boş-durum gösterir (sahte veri yok)
- **Backend gereksinimleri:** `docs/BACKEND_PROMPT_ADMIN_2026-10-03.md` (Bearer JWT'yi kabul etmeyen 110 admin rotası, ban/mute alanları ve filtre, canlı yayın zaman serisi, auth denetimi)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
