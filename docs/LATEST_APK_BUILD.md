# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.679+732` |
| Tarih (UTC) | 2026-10-02 13:36 |
| Commit | [`70d24e13dcf81d8a8bcb3576bca7e1a6a99fc537`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/70d24e13dcf81d8a8bcb3576bca7e1a6a99fc537) |
| İş akışı | [Run 37011869559](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37011869559) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.679+732 (2026-10-02) — PK ekranı, Sosyal, oda/jeton düzeltmeleri, geri tuşu, bildirimler, gelen kutusu

- **PK ekranı:** Duraklat kaldırıldı, "Bitir" küçüldü, alttaki Sohbet yerine sağ üstte sohbet + "sesleri kapat" (TRTC uzak sesler), mesaj alanı hep açık/büyük; hediye animasyonlarında "X → Y'ye … gönderdi" (alıcı avatarı + adı)
- **Sosyal:** başlık "Sosyal"; Tümü/Takip/Falcılar/Ünlüler/Fan Club sekmeleri kaldırıldı; "Ne düşünüyorsun" ve paylaşım kartları tam genişlik/kenarlıksız; metin ekrana sığdığı kadar + "Daha fazla"; fal paylaşımında "X kişi bu fal türüne baktırdı" (fortuneTypeCount)
- **Sesli oda:** ücretsiz odaya "(ödüllerden komisyon alınmaz)"; aktif PK olayı artık oda dışındaki kullanıcıyı kendiliğinden odaya itmiyor; oda arka planı yalnızca ücretli (2500) ve VIP odalarda
- **Jeton/üyelik:** yükleme bonus kademeleri kaldırıldı; "bekleyen ödeme" durumu her açılışta sunucudan; SVIP jeton satın alma hatası yakalanıp loglanır, Türkçe mesaj + kopyalanabilir ayrıntı, gereksiz tekrar denemeler kaldırıldı
- **Geri tuşu:** hiçbir yerde uygulamayı doğrudan kapatmaz (AppBackScope, sekme geçmişi, go→push); ana sayfada "Uygulamadan çıkmak istiyor musunuz?"; sesli odada/canlı yayında çıkış onayı (yayıncı Evet → yayın kapanır)
- **Giriş ekranı:** arka plan 1080×1920 kaynaktan yeniden üretildi (kenar şeridi yok), BoxFit.cover, klavyede ölçeklenmez
- **Bildirimler:** WhatsApp tarzı mesaj bildirimi (MessagingStyle, "Yanıtla"), POST_NOTIFICATIONS isteği, kanal bazlı ayarlar (Mesajlar / Canlı yayın başlatanlar / Günlük fal önerisi / Diğer), yerel bildirimler uygulama içi listede
- **Gelen kutusu:** gönderilen mesajın 3–5 sn sonra kaybolması giderildi (kimliğe göre birleştirme); uzun sohbetlerde yeni mesajlar; sohbet tarihi/sıralama, okunmamış sayacı, gizlenen sohbetin geri gelmesi
- Backend değişmedi (backend notları PR açıklamasında)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
