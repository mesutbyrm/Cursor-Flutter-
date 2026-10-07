# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.740+793` |
| Tarih (UTC) | 2026-10-07 22:53 |
| Commit | [`2288a59a91ca833639a29bd9589c57f0fcddeb55`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/2288a59a91ca833639a29bd9589c57f0fcddeb55) |
| İş akışı | [Run 37697092065](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37697092065) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.740+793 (2026-10-07) — Koltuksuz mikrofon TRTC publish engeli

- **Hata:** Koltuktan indikten sonra mic kapat-aç ile TRTC yeniden yayın yapıyordu; `canSpeak` (oda sahibi/admin) veya doğrudan `setMicEnabled(true)` koltuk kontrolünü atlıyordu
- **Düzeltme:** `setMicPublishGate` + `setSelfMicPublishEnabled` — TRTC publish yalnızca `selfOccupiesSeat()` iken; coordinator’da async race için `invalidatePendingMicEnable`
- UI: koltuksuz açma → «Konuşmak için koltuğa oturun»; koltuk düşünce otomatik publish kapatma
- Gerçek cihaz: mic off-seat senaryoları


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
