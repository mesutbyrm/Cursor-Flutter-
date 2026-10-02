# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.681+734` |
| Tarih (UTC) | 2026-10-02 17:12 |
| Commit | [`8071003a6c5b2d2b584452cec22428885925d847`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8071003a6c5b2d2b584452cec22428885925d847) |
| İş akışı | [Run 37036800383](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37036800383) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.681+734 (2026-10-02) — VIP şifre kapısı zorunlu, PK düzeltmeleri, temizlik

- **VIP şifreli oda:** kapı tüm giriş yollarında zorunlu (router'daki doğrudan `push` dahil); oda içeriği şifre geçilmeden oluşturulmuyor; sunucu da mesaj/SSE/durum/koltuk/TRTC uçlarında şifresiz erişimi reddediyor; "Oda Sahibine Bildir" → sahip popup'ı (kimin istediği görünür) → kabul/ret; ret sonrası düğme pasif
- **Sesli oda PK:** sohbet varsayılan açık (yazılanlar görünür); "Destekle" sunucuda bulunduğun odanın tarafına +3 yazar ve iki odada anında görünür; koltuktakiler PK sırasında mikrofonu açıp kapatır; "karşı tarafın sesini kapat"; oda sahipleri arası ses köprüsü (TRTC)
- **Kullanıcı satırları:** seviye ve gerçek çevrimiçi durumu; **canlı yayın:** gerçek "çıkar" (yasaklamadan)
- **Temizlik:** hiçbir yerde kullanılmayan 63 dosya silindi (yinelenen `lib/services/models` dahil)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
