# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.609+660` |
| Tarih (UTC) | 2026-09-27 01:11 |
| Commit | [`9c73fbeaf4a6e813205beea6d5ca9b74c96db9e9`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/9c73fbeaf4a6e813205beea6d5ca9b74c96db9e9) |
| İş akışı | [Run 36282959068](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36282959068) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.609+660 (2026-09-27) — UI yenileme Aşama 4: fal türleri + fal sonuç ekranları

- **Çalışmayan buton:** kahve/el falında fotoğraf eklenmemişken "Falını Aç" ve üstteki ✦ hiçbir şey yapmıyordu → artık fotoğraf ekleme sayfasını açıyor, fotoğraflar tamamlanınca falı açıyor
- **Taşma:** kahve falı fotoğraf kutucuklarının başlığı ~390 dp ekranlarda 33 px taşıyordu
- **Sonuç başlıkları:** tarot vb. bölümlerde sunucu başlığı ("Geçmiş/Şimdi/Gelecek") yerine hepsine "Yorum" yazılıyordu
- **Açık tema:** fal bölümü her temada koyu mistik zemin çiziyor; içindeki kartlar/başlıklar açık tema rengi alıp çakışıyordu → fal bölümüne koyu tema kapsamı (koyu/AMOLED kullanıcıda değişiklik yok)
- **Kart çevirme:** kehanet kartı çevrilirken kalkıyor, gölgesi büyüyor, yüzeyinden ışık geçiyor; "animasyonları azalt"ta anında
- **Görsel önbelleği:** disk boyutlandırma parametreleri desteklenmeyen önbellek yöneticisiyle kullanılıyordu (release'de yok sayılıyor, debug'da hata) → kaldırıldı; ön-yükleme bellek boyutlandırması `ResizeImage` ile
- **Ölü kod:** hiçbir yerden açılmayan 17 fal "ekranı" + 17 sağlayıcı + 3 model silindi (6.901 satır, sahte butonlar içeriyordu)
- **Yükleme:** "Son Falların" şeridi dönen simge yerine iskelet kartlar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
