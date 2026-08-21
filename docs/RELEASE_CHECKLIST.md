# Canlifal — Release Checklist (Aşama 12)

Sürüm hedefi: **1.0.331+367**  
Tarih: **2026-08-21**  
Dal: `cursor/final-production-audit-5ac6`

## Otomatik CI

| Kontrol | Durum | Not |
|---------|-------|-----|
| `dart analyze` | ✅ PASS | 0 error |
| `flutter test` | ⚠️ 907 pass, 1 fail, 2 skip | `bana_ozel_hub_section_test` — önceden var (P2) |
| `flutter build apk --release` | ⏳ CI / local | Cloud agent release build |

## Fonksiyonel checklist

| Alan | Durum | Not |
|------|-------|-----|
| Auth | ✅ | JWT refresh, logout SSE teardown eklendi |
| Home | ✅ | Lazy section load, paralel bootstrap |
| Live | ⚠️ | TRTC singleton guard eklendi; çift cihaz test gerekli |
| Voice | ⚠️ | PiP ensureActiveSession SSE guard; 2-device test gerekli |
| Tencent RTC | ✅ fix | `_activeSession` — çoklu manager engeli |
| Participant | ⚠️ | Backend canonical; manuel test |
| Seat | ⚠️ | Auto-seat backend kuralı; manuel test |
| Heartbeat | ✅ | 15s presence; leave/logout stop |
| Gift | ✅ | SSE + canonical refresh |
| PK | ⚠️ | SSE + 4s poll overlap (P2) |
| Music | ✅ | Leave → player stop + SSE release |
| Social | ✅ | Pagination, cache invalidation |
| Shorts | ⚠️ | Controller pool; 50 swipe memory test cihazda |
| Stories | ✅ | Timer dispose OK |
| Fortune | ✅ | SSE streaming ayrı |
| Wallet | ✅ | No stale cache on purchase paths |
| Profile | ✅ | Hub refresh guarded |
| Messages | ✅ | DM poll scope daraltıldı |
| Notifications | ✅ | SSE + list; logout clear |
| Games | ✅ | Repository pattern |
| Logout | ✅ | SSE hub dispose + provider invalidation |

## Multi-device (manuel — release öncesi zorunlu)

- [ ] Device A + B voice room join/leave/rejoin
- [ ] Seat sync owner/viewer
- [ ] Gift amount + wallet + ranking
- [ ] PK request/accept/score
- [ ] Music room switch (eski şarkı durur)
- [ ] DM + notification unread
- [ ] User A logout → User B login (cache isolation)

## Release gate

**RELEASE READY: NO** — P0 TRTC fix uygulandı; P1 manuel 2-cihaz acceptance + 1 pre-existing test fail kapatılmalı.

P0/P1 kapatıldıktan sonra `RELEASE READY: YES` işaretlenebilir.
