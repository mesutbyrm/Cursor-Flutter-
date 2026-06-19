# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.302+305` |
| Tarih (UTC) | 2026-06-19 23:37 |
| Commit | [`11f41eb775bab613a094c6f5f22b2f31f2e9664c`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/11f41eb775bab613a094c6f5f22b2f31f2e9664c) |
| İş akışı | [Run 27852819725](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27852819725) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.302+305 (2026-06-19)

### Canlı Falcılar — fortuneTeller.id ≠ authUser.id (kök neden düzeltmesi)

- **Tek kaynak:** `resolveFortuneTellerProfile()` — my-profile → liste (userId) → /api/me → `fortune-tellers/{tellerId}`
- **Kaldırıldı:** `GET /api/fortune-tellers/{authUser.id}` (404 kök nedeni)
- **Tüm akışlar:** `approvedPsychicProvider`, `RolePanelResolver`, `PsychicIncomingHost._ensureTellerProfile`
- **Teşhis:** `[TellerDebug]` — profileFound, fortuneTellerId, authUserId, isUsable, isApprovedTeller, isFortuneTeller


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
