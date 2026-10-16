# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.811+867` |
| Tarih (UTC) | 2026-10-16 17:17 |
| Commit | [`017601cfffbf5ac69902d58ed332ca68beccf78b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/017601cfffbf5ac69902d58ed332ca68beccf78b) |
| İş akışı | [Run 38934965661](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38934965661) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.812+868 (2026-10-16) — Yönetim işlemleri sunucuyla uyumlu

Mobil yönetim panelindeki birçok işlem sunucuya yanlış biçimde gidiyor, ya hiç çalışmıyor ya da «kaydedildi» görünüp hiçbir şey yapmıyordu. Düzeltilenler:
- **Ban / ban kaldırma**, yayın açma ve oda açma izinleri, keşfette gizleme ve öncelik: artık gerçekten uygulanır (web panelindeki Kullanıcı 360 işlemleriyle aynı)
- **Rol değiştirme ve üyelik verme:** sunucunun yetki kontrollü işlemleri üzerinden; biyografi alanı (kaydedilmiyordu) kaldırıldı
- **Canlı falcı ekleme** ve **kullanıcı adına sesli oda açma** çalışır
- **CFC Arena:** yarışma oluşturma ve başlat / duraklat / bitir çalışır
- **Sosyal medya hesapları:** kaydetme çalışır (sitede desteklenen 5 platform)
- **Site animasyonları:** ekleme, düzenleme, açma/kapama, kullanıcıya atama / kaldırma ve süreli toplu atama çalışır; hatalar artık «yerelde kaydedildi» gibi gizlenmez
- **Sesli oda gelir ayarları:** sunucunun gerçekten kullandığı ayarlara (site komisyonu, oda sahibi payı, müzik payı, oda kapasiteleri) bağlandı
- **Ödeme onayı:** profil kartından ve bildirim sekmesinden jeton bildirimleri de onaylanır; toplu kapatma CFC taleplerini de kapatır
- **Hediye düzenleme** web'de kapatılan sesli oda / canlı yayın görünürlüğünü artık yeniden açmaz; yüklenen dosyalar doğru klasöre gider
- **Üyelik matrisi:** açma/kapama hücre önceliğini sıfırlamaz
- Sunucuda karşılığı olmayan GirLive Bot oda/yayın anahtarları ve PK Moderasyon girişi kaldırıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
