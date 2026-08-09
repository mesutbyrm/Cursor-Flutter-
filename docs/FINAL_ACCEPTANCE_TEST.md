# Final Acceptance Test

Date: 2026-08-08

This is the current repository acceptance matrix after the backend/Flutter sync pass. Items marked `PENDING DEVICE` require a real Android device/emulator with camera/microphone and production credentials. They are not claimed as passed.

## Automated validation

| Check | Status | Evidence |
|---|---|---|
| Backend TypeScript typecheck | PASS | `cd api && npm run typecheck` |
| Backend unit tests | PASS | `cd api && npm test` |
| Backend production build | PASS | `cd api && npm run build` |
| Flutter SDK bootstrap | PASS | Installed Flutter `3.44.8` from the repo version tag for this run |
| Flutter dependencies | PASS | `cd mobile && flutter pub get` |
| Flutter analyze | FAIL | `cd mobile && dart analyze` reports 297 existing warnings/infos; no new compile error from this pass was observed |
| Flutter test | PASS | `cd mobile && flutter test` -> 374 passed, 2 skipped |
| APK build | PASS | `cd mobile && flutter build apk --release` -> `build/app/outputs/flutter-apk/app-release.apk` (258.5MB) |

## Functional acceptance

| Item | Status | Notes |
|---|---|---|
| Login successful | PENDING DEVICE | Requires valid production account |
| Token persist | CODE READY | `TokenStorage` + session cache present |
| Protected API with token | CODE READY | Main Dio Bearer interceptor |
| Profile opens fast | PARTIAL | Cache/session restore present; device measurement pending |
| Home avoids unnecessary API calls | PARTIAL | Cache exists; login invalidation burst still a risk |
| SSE connects | CODE READY | Shared SSE infrastructure present |
| SSE reconnect | CODE READY | Backoff + heartbeat watchdog present |
| Voice room opens | CODE READY | `/api/live/join-room` mirror adapter + existing voice endpoints |
| Voice room leave immediate | CODE READY | `/api/live/leave-room` mirror adapter + existing cleanup |
| User not left in old room | PARTIAL | Leave adapter calls presence cleanup; device test pending |
| TRTC audio | PENDING DEVICE | Backend token path fixed; SDK runtime needs device |
| TRTC video | PENDING DEVICE | Backend token path fixed; SDK runtime needs device |
| Live broadcast create | CODE READY | `/api/live/create-room` mirror adapter |
| Live stream join | CODE READY | `/api/live/join-room` stream path |
| Live fortune request | PARTIAL | Existing aliases remain; full production test pending |
| Live fortune accept | PARTIAL | Existing aliases remain; full production test pending |
| Two users same RTC session | PENDING DEVICE | Needs two-account device test |
| Seat take/leave | PARTIAL | Basic adapter present; full `swap/force` contract needs backend confirmation |
| PK request | CODE READY | `/api/live/pk` uses Prisma PK service |
| PK accept/reject | CODE READY | `/api/live/pk` adapter uses PK service |
| PK state equal on both sides | PENDING DEVICE | Needs realtime two-client test |
| Gift send | CODE READY | `/api/live/gift/send` delegates to existing transaction logic |
| Jeton deducted by backend | CODE READY | Gift functions decrement user coins server-side |
| Gift amount display | PARTIAL | Depends on production event payload |
| Gift animation/sound | PENDING DEVICE | UI/media playback test required |
| `!istek` backend sync | PARTIAL | Existing song-request/music APIs present; production queue test pending |
| Social feed | CODE READY | page/limit API and Flutter datasource present |
| Shorts | CODE READY | cursor pagination and media storage present |
| CDN usage | PARTIAL | R2/local fallback present; production CDN policy required |
| Pagination | CODE READY | social/video/shorts support pagination |
| Cache reduces calls | PARTIAL | Cache policy present; runtime hit ratio pending |
| Critical memory leak | PENDING DEVICE | Static risk list exists; runtime profiling pending |
| Critical RTC resource leak | PENDING DEVICE | Leave paths present; runtime profiling pending |

## Backend data needed before 100% sign-off

1. Production API route dump with exact method/path/body/response for live, voice, seat, PK, gift, song, notification.
2. SSE event payload samples for every stream.
3. Production TRTC token response sample.
4. Production CDN/R2 URL conventions.
5. Two test accounts with wallet/jeton balance for safe gift/PK tests.

## Analyze blocker

The Cloud image initially had no Flutter or Android SDK. Flutter `3.44.8` and Android SDK commandline tools were installed inside this run, allowing tests and release APK build to pass.

Standard `dart analyze` still fails because the existing repository has 297 warnings/infos, mostly unused imports, deprecated APIs, null-aware cleanup warnings, and pre-existing analyzer hygiene issues. These are tracked as a separate cleanup task; analyzer settings were not weakened to hide them.
