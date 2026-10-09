# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.754+807` |
| Tarih (UTC) | 2026-10-09 20:49 |
| Commit | [`55889e8c1c30b68547f7926f51fa6196a78226d3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/55889e8c1c30b68547f7926f51fa6196a78226d3) |
| İş akışı | [Run 37987006938](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37987006938) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.754+807 (2026-10-09) — Ajans Jeton cüzdanı, toplu alım, talep iptali

- **Ajans Cüzdanı (`/ajans/cuzdan`, yeni):** Ajans panelindeki cüzdan kartından açılır
  - **Kullanıcıya Yükle:** Herhangi bir kullanıcıyı ara, Jeton miktarı gir, onayla; miktar ajans bakiyesinden aynen düşer (komisyon yok). Bakiye yetmezse «N jeton eksik» der. Çift dokunma çift yükleme yapmaz (idempotency)
  - **Toplu Jeton Al:** Sunucunun hesapladığı normal fiyat, ajans indirimi ve ödenecek tutar; havale/Papara/WhatsApp ile ödeme bildirimi; yönetici onaylayınca Jeton ajans cüzdanına geçer; bekleyen sipariş iptal edilebilir
- **Düzeltme:** Üye satırındaki Jeton gönderme yanlış alan (`userId`) gönderdiği için çalışmıyordu → `targetUserId`
- **Talep iptali:** Bekleyen para çekme talebi, ödeme bildirimi ve CFC ödeme talebi kullanıcı tarafından iptal edilebilir (önceden CFC iptali «desteklenmiyor» hatası veriyordu)
- **Backend deploy gerekli** (`mesutbyrm/canlifal` — şema değişikliği yok)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
