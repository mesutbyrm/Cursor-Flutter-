# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.454+492` |
| Tarih (UTC) | 2026-09-09 14:12 |
| Commit | [`7940a66dc1d6e5d089864c1ca4b0443f367479bc`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/7940a66dc1d6e5d089864c1ca4b0443f367479bc) |
| İş akışı | [Run 34360136209](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34360136209) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.455+493 (2026-09-09) — Final release hardening (kod denetimi)

### PK
- Canlı PK: dialog timeout sonrası otomatik reject kaldırıldı (backend pending korunur)
- Canlı oda: `pkPendingInvitesProvider` / unified invites kaldırıldı; yalnızca `liveVideoPkProvider` + SSE
- Sesli PK: SSE bağlı olsa bile REST poll devam eder; SSE callback null ile handler silme engellendi

### Misafir / TRTC
- Ortak `isApprovedCoGuestStatus` — boş status artık onaylı sayılmaz
- Host approve: tam approved list sync; boş coBroadcast grid temizliği
- TRTC `onRemoteUserLeaveRoom`: viewId/video map temizliği

### Presence / oturum
- Background: heartbeat durur + leave; foreground yeniden bootstrap
- Logout: presence heartbeat atlanır; fortune prefs temizlenir; hesap değişiminde realtime teardown

### Bildirim / push
- OneSignal init Firebase'den önce (race azaltma)
- Bildirim SSE kullanıcı değişiminde yeniden bağlanır

### Gold/VIP
- RTC oda giriş efekti: `entranceEffectAllowedProvider` gate (basic ile hizalı)
- Staff marquee canlı yayın odasında gizlenir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
