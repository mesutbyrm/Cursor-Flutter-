# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.301+304` |
| Tarih (UTC) | 2026-06-19 21:51 |
| Commit | [`0433e1766e14650ce674741ebd057c0fb9d81c9d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/0433e1766e14650ce674741ebd057c0fb9d81c9d) |
| İş akışı | [Run 27849596303](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27849596303) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.301+304 (2026-06-19)

### Canlı Falcılar — falcı rolü doğrulama (kök neden düzeltmesi)

- **Kök neden:** `approvedPsychicProvider` yalnızca `GET /my-profile` kullanıyordu; `RolePanelResolver` (liste, `/api/me`, `user.role`) devre dışıydı
- **Sonsuz loading:** `AsyncNotifier` + `goRouter` watch — başvuru ekranı her refresh'te sıfırlanıyordu; ajans modeline geçildi
- **Alan eşlemesi:** `fortuneTeller`, `isActive`, `isVerified`, `approvedAt` → `applicationStatus: approved`
- **Üretim listesi:** `displayName`, `applicationStatus`, `userId` (cuid) doğru parse
- **Teşhis logu:** `[TellerRole]` — userId, role, isFortuneTeller, tellerId, approvalStatus, resolveSource, ham my-profile
- **Panel:** `isUsable` ile açılır (`isApproved` tek başına yetmezdi)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
