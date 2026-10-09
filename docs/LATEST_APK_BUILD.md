# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.750+803` |
| Tarih (UTC) | 2026-10-09 14:46 |
| Commit | [`df1218bd389e47291576c6b41f9b9ee85a4893c6`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/df1218bd389e47291576c6b41f9b9ee85a4893c6) |
| İş akışı | [Run 37943952414](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37943952414) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.750+803 (2026-10-09) — Hediye videoları, ana sayfa kutuları, video düzenleme, Tanış Kaynaş, sosyal medya

- **Canlı yayın hediye videoları (kök neden):** Kuyruk pompası kalan listeyi ön yükleme beklemesinden (videoda 1,2 sn) önce alıp sonra eziyordu → bu sürede gelen hediyeler hiç oynamıyordu. Ayrıca sunucunun `gift_finished` olayı henüz oynamamış hediyeyi kuyruktan siliyordu; aynı hediye 4 sn içinde tekrar gönderilince parmak izi süzgeci ikincisini düşürüyordu; PK panelinden gönderen kendi videosunu görmüyordu → dördü düzeltildi
- **Gold Üyelikler:** Ana sayfa bölümü kademe yerine sunucu cuid'i ile süzdüğü için boş kalıyordu → kademe ile; Premium görseli Diamond ile aynıydı → zümrüt
- **Ana sayfa:** İkinci sıra 5 kutu — Falcı Panelim/Falcı Ol, Ajansım/Ajans Ol, Yayıncı Paneli/Yayıncı Ol, Jeton Al, Hediye Yolla; tüm kutular görselli; ilk sırada Canlı Falcılar; futbol kaldırıldı
- **Tüm Özellikler:** Lamba Cini ve Futbol kaldırıldı; 20 yeni giriş; görselli kutular
- **Trend / kısa video düzenleme:** Sahibi veya admin, video izlerken «Düzenle» ile kapak (galeri ya da videodan kare), açıklama, konum, görünürlük, yorum ve düet ayarlarını değiştirir (`PATCH /api/short-videos/:id`)
- **Video yükleme:** Önceden imzalı yükleme her seferinde 400 alıyordu (`videoKey` gönderiliyordu); yedek yol görünürlük/yorum/düet göndermiyordu ve «Sadece ben» sunucuda herkese açık sayılıyordu → düzeltildi
- **Tanış Kaynaş:** Seni beğenen / eşleşme / gönderdiğin sayaçları, günün buz kırıcı sorusu, görselli «Keşfet & Eğlen» kutuları
- **Sosyal medya:** Yönetim Merkezi → Sosyal Medya (ve web admin ayarlar) ile resmi hesaplar düzenlenir; ana sayfa altında gösterilir (`/api/social-accounts`)
- **Backend (canlifal):** `PATCH /api/short-videos/:id`, `GET /api/social-accounts`, `GET|PUT /api/admin/social-accounts` (migration yok — `SiteSetting`)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
