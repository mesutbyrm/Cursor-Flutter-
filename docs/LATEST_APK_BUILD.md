# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.623+674` |
| Tarih (UTC) | 2026-09-28 14:53 |
| Commit | [`3a918cdcf628733c9d48b8c31b78f93014993fa7`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3a918cdcf628733c9d48b8c31b78f93014993fa7) |
| İş akışı | [Run 36436752063](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36436752063) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.623+674 (2026-09-28) — 7 modül backend uçlarına bağlandı ve menüye eklendi

- **Burç Uyumu** (Fal sekmesi → hızlı erişim): iki burç seç, `POST /api/compatibility` ile aşk/arkadaşlık/iş uyum analizi (uydurma günlük/haftalık skorlar kaldırıldı)
- **Rüya Yarışması** (Fal sekmesi + Rüya Merkezi): aktif yarışmalar, yorumlanacak rüya, yorum gönderme (en az 20 karakter), oy verme/geri alma — `/api/dream-contest/*`
- **Futbol** (Ana sayfa şeridi + `/futbol`): bugünkü/dün/yarın maçları, canlı skor, puan durumu, gol krallığı — `/api/football?action=…` (bahis/tahmin backend'de olmadığı için kaldırıldı). Ana sayfa artık `/futbol` bağlantısında arama yerine futbol sayfasını açar
- **Ajans haftalık görev** (Ajans paneli): kazanç / aktif üye / yeni üye hedefleri ve gerçekleşen, geçmiş 4 hafta — `/api/agency/tasks`. Paneldeki "Görevler" kartı önceden hep boştu
- **Ortak yayın davetleri** (Ayarlar → Canlı Yayın & Ses): bekleyen davetler, kabul et ve katıl / reddet. **Hata düzeltmesi:** backend davet yanıtında `userId` olmadığı için yayın dışındaki davet penceresi hiç açılmıyordu
- **Ses ayarları** (Ayarlar → Canlı Yayın & Ses): ses kalitesi (konuşma/dengeli/müzik), mikrofon seviyesi, yankı, ses değiştirici, kulaklıkta kendini duy — TRTC SDK'ya cihazda uygulanır (backend ucu yok)
- **Kısa video:** kullanılmayan remix katmanı kaldırıldı; kısa videolar mevcut akışta
- Testler: backend JSON biçimleriyle ayrıştırma + sayfa render testleri (390 dp)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
