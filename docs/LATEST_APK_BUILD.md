# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.302+305` |
| Tarih (UTC) | 2026-06-19 22:57 |
| Commit | [`322eb1f429dc53c5aac1748d8e4e648ce03dc9ae`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/322eb1f429dc53c5aac1748d8e4e648ce03dc9ae) |
| İş akışı | [Run 27851764995](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27851764995) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.302+305 (2026-06-19)

### Canlı Falcılar — fortuneTeller.id ≠ authUser.id (kök neden düzeltmesi)

- **Tek kaynak:** `resolveFortuneTellerProfile()` — my-profile → liste (userId) → /api/me → `fortune-tellers/{tellerId}`
- **Kaldırıldı:** `GET /api/fortune-tellers/{authUser.id}` (404 kök nedeni)
- **Tüm akışlar:** `approvedPsychicProvider`, `RolePanelResolver`, `PsychicIncomingHost._ensureTellerProfile`
- **Teşhis:** `[TellerDebug]` — profileFound, fortuneTellerId, authUserId, isUsable, isApprovedTeller, isFortuneTeller


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
