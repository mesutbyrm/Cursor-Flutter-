# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.787+843` |
| Tarih (UTC) | 2026-10-14 14:58 |
| Commit | [`1ad10025500358f6f20ad89a42b97f719037fe20`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/1ad10025500358f6f20ad89a42b97f719037fe20) |
| İş akışı | [Run 38581496983](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38581496983) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.787+843 (2026-10-14) — Canlı / profil / GirLive / falcı süre

- **Canlı fal isteği:** yayıncı yedek yoklama 5 sn (SSE açıkken 60 sn gecikme giderildi); SSE fal sinyali ayrıştırma genişletildi
- **Misafir yayın:** onaylı misafirde mikrofon/kamera alt çubuğu (yayıncı «Bitir» yalnız host)
- **Yayın kapatma:** sunucu `end` başarısızsa odadan çıkılmaz; kullanıcı tekrar deneyebilir
- **Canlı falcı süre uzatma:** çift süre sayımı kaldırıldı; sunucu/SSE tek kaynak
- **GirLive Bot:** yalnız «hoş geldin» satırı 5 sn geçici; moderasyon/duyuru kalıcı
- **Profil kaydet:** hub invalidate + «Profil kaydedildi» geri bildirimi (**şehir** alanı üretimde `PATCH /api/user/profile` city desteği olmadan kaydedilmez — backend güncellemesi gerekir)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
