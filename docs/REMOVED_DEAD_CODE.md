# Removed Dead Code

Date: 2026-08-08

## Removed in this pass

No runtime code was deleted in this pass.

Reason: the priority was backend/Flutter contract repair without breaking existing working flows. Several old paths are still used as compatibility fallbacks and require production confirmation before removal.

## Confirmed cleanup candidates

| Candidate | Reason | Removal condition |
|---|---|---|
| Legacy `core/sse_client.dart` | Overlaps with `BaseSseService` and hub | Remove after all callers migrate to domain SSE services |
| Agora wording in `ApiException` and changelog-era labels | No Agora SDK runtime dependency remains | Rename user-facing strings to RTC/TRTC after QA confirms copy |
| Auth datasource overlap | `AuthService` and `AuthRemoteDataSource` share auth/session responsibilities | Keep `AuthService` for auth; move session/admin-only calls to a focused datasource |
| Socket.IO PK/gift fallbacks | SSE is primary target | Remove only after backend proves SSE emits all required gift/PK events |
| Unused `ApiEndpoints` symbols | Registry contains production/admin/future routes not all used by mobile | Remove only when production confirms they are not planned mobile surfaces |

## Do not remove yet

- `/api/trtc/usersig`: required fallback for older/self-hosted backend mirrors.
- Socket.IO package: still used as fallback bridge in live/voice/PK paths.
- LiveKit backend route: local mirror compatibility only; Flutter has no runtime LiveKit client.
- Gift aliases (`giftId`/`giftTypeId`, `recipientId`/`receiverId`): needed while backend payload naming is consolidated.
