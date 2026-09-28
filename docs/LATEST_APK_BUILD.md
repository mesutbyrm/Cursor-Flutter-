# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.622+673` |
| Tarih (UTC) | 2026-09-28 14:23 |
| Commit | [`817e16acf8308422f8d4c36ea278a0183ae105e4`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/817e16acf8308422f8d4c36ea278a0183ae105e4) |
| İş akışı | [Run 36433099374](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36433099374) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.622+673 (2026-09-28) — Backend dokümanlarıyla eşleşme (canlifal PR #1)

- **Takipçi listesi:** başka birinin profilinde takipçi/takip listesi senin listeni gösteriyordu → `/api/user/followers?userId=` ile doğru kullanıcı
- **Yönetici üyelik sayfası:** yanlış yol (`membership_tiers`) yüzünden hiç yüklenmiyordu; kademe aç/kapa 400 dönüyordu; yetenek matrisi hep kapalı görünüyordu → düzeltildi
- **Ajans canlı takip:** üyelerin canlı durumu hep boştu → `/api/agency/live-status`
- **SSE:** falcı seansı ve video yayın akışında bağlantı zaman aşımında üstel geri çekilmeyle yeniden bağlanma
- **Doküman:** `docs/BACKEND_DOCS_ESLESME.md` + `scripts/backend-route-parity.py` (714 backend route ↔ Flutter yol kontrolü)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
