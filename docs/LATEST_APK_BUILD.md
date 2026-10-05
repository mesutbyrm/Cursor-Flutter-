# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.713+766` |
| Tarih (UTC) | 2026-10-05 08:10 |
| Commit | [`7be00aeb0e9ebdfedbc523617f8d06234247a662`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/7be00aeb0e9ebdfedbc523617f8d06234247a662) |
| İş akışı | [Run 37279865463](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37279865463) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.713+766 (2026-10-05) — Hediye kombo/ses · sesli oda sol menü · 100 renk arka plan · profil donması

- **Profil kaydetme donması:** düzenleme alanı sheet'i kapanırken controller hemen dispose ediliyordu (kullanım-sonrası hata → uygulama kilitleniyordu); aynı hata hesap silme, takma ad, oda şifresi ve klip başlığı diyaloglarında da düzeltildi
- **Hediye sesi:** hediye videoları varsayılan olarak sessiz oynatılıyordu → videonun kendi sesi artık çalıyor
- **Kombo:** 3 adet seçilen hediye 3 kez, 10 adet 10 kez gösterilir (en fazla 30); ön-yükleme beklemesi kısaltıldı (iki telefon arası zaman farkı azaldı)
- **Hediye yazısı:** sesli odada «X → hediye» yazısı artık üstte «Popüler Oda» arkasında değil, alıcının koltuğu altında çıkar ve kaybolur
- **Sesli oda:** Müzik/PK/İstek/Daha Fazla düğmeleri sol kenardaki açılır menüye alındı; mesaj satırı klavyeye tam oturur (dock yüksekliği hesabı düzeltildi)
- **Oda arka planı:** 100 renk (gri tonlar + 9×10 renk tablosu); oda sahibi/admin seçtiği rengi arka plan yapar (PNG olarak yüklenir, web'de de aynı görünür)
- **Falcı seansı sonu:** alınan hediye/bahşiş toplamı her zaman gösterilir
- `docs/ADMOB_KURULUM.md` eklendi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
