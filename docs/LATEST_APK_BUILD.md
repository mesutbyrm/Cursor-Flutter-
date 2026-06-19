# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.302+305` |
| Tarih (UTC) | 2026-06-19 22:59 |
| Commit | [`06d09525835aecf1a4ffee322b1786d4c848319f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/06d09525835aecf1a4ffee322b1786d4c848319f) |
| İş akışı | [Run 27851845518](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27851845518) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.302+305 (2026-06-19)

### Canlı Falcılar — fortuneTeller.id ≠ authUser.id (kök neden düzeltmesi)

- **Tek kaynak:** `resolveFortuneTellerProfile()` — my-profile → liste (userId) → /api/me → `fortune-tellers/{tellerId}`
- **Kaldırıldı:** `GET /api/fortune-tellers/{authUser.id}` (404 kök nedeni)
- **Tüm akışlar:** `approvedPsychicProvider`, `RolePanelResolver`, `PsychicIncomingHost._ensureTellerProfile`
- **Teşhis:** `[TellerDebug]` — profileFound, fortuneTellerId, authUserId, isUsable, isApprovedTeller, isFortuneTeller


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
