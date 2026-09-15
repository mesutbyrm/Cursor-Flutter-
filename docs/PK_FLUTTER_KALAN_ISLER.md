# PK + entegrasyon — Flutter tarafında kalan işler

> **Sürüm referansı:** `mobile/pubspec.yaml` · **Sözleşme:** [`PK_ENTEGRASYON.md`](PK_ENTEGRASYON.md) · **API kılavuz:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md)

## Tamamlanan (agent — 2026-09-15)

- Birleşik `PkService` → `GET/POST /api/live/pk` (canlifal.com yönlendirme)
- Canlı adaylar: `GET /api/video-streams/pk/candidates`
- Sesli adaylar: `GET /api/chat/rooms/pk/candidates` + oda listesi yedek
- Premium PK başlatma sheet (canlı + sesli), `openVoicePkInviteSheet`
- Canlı yayıncı bekleyen davet banner; gelen davet premium diyalog
- Sesli kabul/red önce `/api/live/pk`, yedek oda uçları
- Oda içi PK: `create_user` takım sheet (4+4), koltuktan 1v1
- Tanış Kaynaş kaydırma destesi + `skip` / eşleşme snackbar
- Ana sayfa fal türleri mistik kapak görselleri
- Sosyal feed tam genişlik; sesli admin nick staff hatası düzeltildi

## Kalan — mobil kod / ürün

| Öncelik | İş | Not |
|--------|-----|-----|
| P1 | **PK cihaz senaryoları 1–12** | Split ekran, timeout, red, iptal, ayrılma, SSE senkron, karışık oda↔yayın |
| P1 | **Ödeme / hediye kuyruğu PK** | Spec’teki sıra ve jeton düşümü — cihazda doğrula; kodda ayrı `pk_queue` yok |
| P2 | **`PK_ENABLED` sunucu bayrağı** | Uygulama açılışında kontrol; kapalıysa PK UI gizle |
| P2 | **pause / resume** | Yalnızca `POST /api/chat/rooms/{id}/pk` — UI eksik |
| P2 | **Canlı kontrol merkezi** | PK yalnızca oda içi (kısmen); kontrol merkezinden kaldırma tam cihaz doğrulaması |
| P3 | **Eski diyalog temizliği** | `voice_pk_invite_center_modal` vs `pk_invite_dialog` — tek görsel dil |
| P3 | **Dokümantasyon** | `USER_DEVICE_TEST_LOG.md` PK maddeleri PASS/FAIL |

## Kalan — release (cihaz / mağaza)

Bu liste **`docs/KALAN_ISLER.md`** ile aynı yol haritasıdır; özet:

| # | İş | Durum | Komut |
|---|-----|--------|--------|
| **P0** | Psychic TRTC, 2 telefon (T+5s donma) | ⏳ OPEN | `bash scripts/p0-go.sh` |
| **P1** | Platform 2 telefon (sesli, hediye, PK, müzik) | ⏸ P0 sonrası | `bash scripts/p1-prep-go.sh` |
| **P2** | Play Store, keystore, AAB | ⏸ P0+P1 sonrası | `bash scripts/kullanici-sonraki.sh` |

**RELEASE READY:** `NO` — kullanıcı `Psychic P0 PASS` yazana kadar mobilde yalnızca P0 **FAIL** hotfix.

Canlı durum: `bash scripts/kalan-isler.sh` · `bash scripts/print-release-blockers.sh`

## Test hesapları (P0/P1)

| Rol | E-posta |
|-----|---------|
| Danışan | `cursor.test.1786235468@mailinator.com` |
| Falcı/host | `cursor.host.1786235468@mailinator.com` |

Şifre: `CursorTest!1786235468`

## APK

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
