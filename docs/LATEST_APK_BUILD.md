# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.718+771` |
| Tarih (UTC) | 2026-10-05 22:05 |
| Commit | [`563667ad18b5bd9fb8d1e66480463dca10200080`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/563667ad18b5bd9fb8d1e66480463dca10200080) |
| İş akışı | [Run 37377890147](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37377890147) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.718+771 (2026-10-05) — Sesli odada ses kesme, fal paylaşım görselleri, bildirim tanılama

- **Sesli oda (koltuktan inince / çıkınca):** TRTC ses kesme artık işlem kapısını beklemiyor (uzak ses kapatılır, yerel yayın durur, `exitRoom` her durumda gönderilir); çıkış sırasında sürmekte olan yeniden bağlanma/katılma odaya GERİ girmiyor; koltuktan inen kişinin mikrofonu kapanıyor
- **Sosyal fal paylaşımı:** backend fal türleri (askuyumu, gunluk-burc, 3-kart-tarot, yildizname… ) türüne uygun görsele eşlendi; bilinmeyen tür artık Tarot yerine genel fal görseli; medya yer tutucusu da türe uygun; «birlikte bakan» son **5** kişi
- **Canlı falcı isteği:** mevcut seans kontrolü 12 sn, seans oluşturma 25 sn zaman aşımına bağlandı (sunucu yanıtı gelmezse ekran donmaz, mesaj gösterilir)
- **Bildirim tanılama:** «Sunucudan test bildirimi gönder» — sunucu OneSignal'e istek atar, ham yanıtı (anahtar eksik / abone cihaz yok) ekranda gösterir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
