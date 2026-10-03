# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.702+755` |
| Tarih (UTC) | 2026-10-03 16:20 |
| Commit | [`266d4a0a5d5270dd1598a20a78c4f60805d7776e`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/266d4a0a5d5270dd1598a20a78c4f60805d7776e) |
| İş akışı | [Run 37135173964](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37135173964) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.702+755 (2026-10-03) — Mockup'a birebir arayüz: profil, admin profil, ayarlar, yönetim

- **Ortak görsel dil (`mock_ui_kit.dart`):** ortalanmış başlıklı üst çubuk, mor tonlu koyu kartlar, düz renkli ikon kareleri, mor anahtarlı satırlar
- **Ayarlar:** hero kartı kalktı; 14 kategori kompakt satır (renkli ikon karesi · başlık · alt başlık · ok), sağ üstte çalışan arama. **Cüzdanım:** Jeton / CFC bakiye kartları + «Satın Al», İşlem Geçmişi, Hediye Geçmişi, Kazançlarım. **Bildirimler:** mor anahtarlı satırlar (4 gerçek kanal). **Gizlilik ve Güvenlik:** Engellenenler (`GET/POST /api/user/block`, yeni ekran), Şifre, Giriş Cihazları, VIP gizlilik, **Hesabı Sil** (`POST /api/user/account/delete`, onay + şifre). **Profil Düzenle:** satır tabanlı alanlar (Ad, Kullanıcı Adı, Biyografi, Konum…), dokununca alt sayfada düzenlenir
- **Normal profil:** logo + paylaş/ayar · ortalanmış halkalı avatar (Çevrimiçi/VIP rozeti) · @kullanıcı adı · Gönderi/Takipçi/Takip/Beğeni · biyografi/konum · Profili Düzenle + Paylaş · Jeton/CFC satırı · sekmeler (Gönderiler, Videolar, Hikâyeler, Fal Aktiviteleri, ⋮ menüsü: Beğeniler, Kaydedilen, Canlı Yayınlarım, İzlediklerim, Favoriler, Taslaklar). Mevcut üyelik/istatistik/ayar bölümleri sekmelerin altında korunur
- **Admin profil (ayrı sayfa):** taçlı altın halkalı avatar, ADMIN rozeti, rol etiketi, 4 gerçek sayaç, altın «Yönetim Merkezi» + Profil Düzenle, 4 bilgi kartı, Hızlı İşlemler (yetkiye göre)
- **Yönetim Merkezi:** mockup'taki 10 kart (Güvenlik ve Yayın İstatistikleri kartları kalktı; istatistik sağ üstteki grafik simgesinden), Acil Durum kırmızı
- **Canlı Yayın İstatistikleri:** dönem seçici (7/14/30 gün), 4 kart, gradyanlı çizgi grafik. İstemci `GET /api/admin/live-stats?days=` ucunu çağırır; uç yoksa mevcut sayaçlara düşer ve grafik boş-durum gösterir (sahte veri yok)
- **Kullanıcı Yönetimi:** mockup'taki arama + pil filtreler + satır (ad, @kullanıcı adı, VIP/rol rozeti, Aktif/Pasif/Banlı, ⋮)
- Mockup'ta olup **eklenmeyenler** (sunucu karşılığı yok): İki Adımlı Doğrulama, Verilerimi İndir, Hesabı Dondur, Hesabım Kimler Görebilir / Mesaj İstekleri (sunucuda yalnızca VIP gizlilik anahtarları var), Hediye/PK/Oda/Sistem bildirim anahtarları (yalnızca 4 kanal gerçek), «Aktif Kullanıcı» sayacı, istatistik kartlarındaki % değişim


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
