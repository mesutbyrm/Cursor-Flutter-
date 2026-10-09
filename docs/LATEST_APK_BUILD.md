# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.755+808` |
| Tarih (UTC) | 2026-10-09 21:32 |
| Commit | [`40c64679bdd968019a18014ad7ed2e51a8e9c164`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/40c64679bdd968019a18014ad7ed2e51a8e9c164) |
| İş akışı | [Run 37991886815](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37991886815) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.755+808 (2026-10-09) — Ajans yönetimi: keşif, performans, vaatler, hedefler, yayıncı paneli

- **Ajanslar (`/ajanslar`, yeni):** Ajansları sırala/ara (önerilen, yayın saati, yayıncı sayısı, hedef başarısı, seviye, en yeni). İstatistikler gerçek veriden: son 30 gün doğrulanmış video yayını, son 90 gün hedef başarısı (veri yoksa «Hedef verisi yok»)
- **Ajans detayı:** Yönetici onaylı vaatler (hedef, bonus, ölçüm yöntemi, geçerlilik), yayıncılar, **ajansa başvur** / başvuruyu geri çek
- **Yayıncı Paneli (`/ajans/yayinci`, yeni):** Ajans ve üyelik, bugün/hafta/ay doğrulanmış yayın süresi, hedef ilerlemesi ve kalan süre, vaatleri **açık onayla kabul** (sürüm kaydı), kabul geçmişi, bonus/hak edişler, duyurular, ajans geçmişi, başvuru/davet geçmişi, kurallar, destek/itiraz, ayrılma talebi
- **Ajans paneli araçları:** Performans (yayıncı bazında saat, gün, kesinti, hediye, hedef durumu) ve yayıncı ayrıntısı (günlük dağılım, oturumlar, hedef ata, hak ediş öde/iptal, üyelik geçmişi, moderasyon kayıtları); katılma başvuruları; vaatler (taslak → yönetici onayı, yeni sürüm, geri çek, arşivle); duyurular; hak edişler (dönem kapat); çalışan yetkileri
- **Düzeltme:** Metin girişli pencereler kapanırken denetleyici erken dispose ediliyordu (hata ekranı riski)
- **Backend deploy + `prisma db push` gerekli** (yalnız yeni tablolar)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
