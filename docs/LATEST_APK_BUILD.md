# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.516+557` |
| Tarih (UTC) | 2026-09-15 16:42 |
| Commit | [`87e3cc17e3016968c34361ee5a485566e6bc0a15`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/87e3cc17e3016968c34361ee5a485566e6bc0a15) |
| İş akışı | [Run 34995307690](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34995307690) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.517+558 (2026-09-15) — P0–P2 parite + hub API

- backend-parity: admin user hub routes (overview, activity, agency, …) + `360`
- Ajans: `POST /api/agency/wallet/transfer` (ledger + idempotency + audit)
- Referans: `lib/admin-mutation.ts` (P0 guard)
- Mobil: `admin_user_hub_providers`, aktivite timeline API
- `docs/PLATFORM_PRODUCTION_DEPLOY_P0_P2.md`

## Unreleased — Profesyonel platform sprint (mobil katman)

- Admin komuta merkezi: VIP, Ajans, Mod., Rapor sekmeleri + hızlı işlem şeridi
- `AdminUserHubLauncher` — staff uzun basış ile merkezi kullanıcı yönetimi
- Mesafe: `DistanceBand` (yuvarlanmış bant; kesin km gösterimi kaldırıldı)
- Ajans panel: jeton kredisi probe + üyeye transfer sheet (`/api/agency/wallet*`)
- CFC Arena hub rotası `/cfc-arena` (liste probe)
- `docs/PLATFORM_PROFESSIONAL_SOCIAL_MASTER_PLAN.md` — tam sistem analizi ve faz planı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
