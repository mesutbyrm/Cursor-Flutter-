# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.696+749` |
| Tarih (UTC) | 2026-10-02 20:19 |
| Commit | [`b3e4fe33c804d2be7938ae4d34c76613659d520d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b3e4fe33c804d2be7938ae4d34c76613659d520d) |
| İş akışı | [Run 37058071492](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37058071492) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.696+749 (2026-10-02) — Canlı falcı hata düzeltmeleri

- **Oturum kaybı:** ağ hatası artık «seans yok» sayılmıyor — açılışta durum alınamazsa kayıtlı seans silinmez; aktif seans listesi alınamazsa yeni rezervasyon açılmaz («Bağlantı sorunu» uyarısı)
- **Falcı rota koruması:** onaylı falcı, tek bir ağ hatası yüzünden kalıcı olarak «Falcı ol» sayfasına atılmıyor; eş zamanlı doğrulamalar tek istekte birleşti
- **Bekleme ekranı:** turda 3 yerine 1 istek (yedek sorgular 5 turda bir); 180 sn geri sayım duvar saatinden hesaplanır (arka planda uzamaz); sunucu seansı bilmiyorsa 3 turda çıkış; süre dolarken son saniye kabul edilmişse iptal edilmez
- **Düzeltme:** oturum devam ettirmede toplam jeton dakika fiyatı olarak yazılıyordu, fal türü 'general'e düşüyordu
- **Sahte ekranlar kaldırıldı:** sabit/sahte veriyle çalışan 45 falcı paneli ekranı (sahte kazanç, sahte banka hesabı, hiçbir şey göndermeden «Çekim talebi gönderildi») silindi; Seans geçmişi ve Yorumlar gerçek API verisine bağlandı; Kazanç/para çekme cüzdana yönlendirilir. Profil düzenleme ve müsaitlik için sunucu ucu olmadığından kaldırıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
