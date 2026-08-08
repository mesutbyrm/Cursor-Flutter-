# API Integration Audit

Date: 2026-08-08

## Sources

- Uploaded backend `ENDPOINTS`, `openapi`, `endpoints_index`, `MUSIC_API`, MCP README/config.
- Flutter `mobile/lib/core/network/api_endpoints.dart` and feature repositories/datasources.

## Backend inventory summary

- Backend docs report 690 endpoint handlers, 438 unique paths, 148 categories.
- OpenAPI `openapi__2__605a.json`: 438 paths.
- Production base URL: `https://canlifal.com`; canonical prefix: `/api`; uploaded prompt explicitly says no `/api/v1`/`v2` split.
- MCP server is read-only developer tooling; Flutter runtime must not use MCP for app operations.

## Critical verified findings

1. `/api/gifts` is a page route in production probe; Flutter now uses `/api/gifts/types` for public JSON fallback.
2. Uploaded docs mark removed old paths: `/api/payment/*` -> `/api/payments/*`, `/api/membership/packages` -> `/api/memberships/packages`, old `/api/rooms/{id}/music/*` -> `/api/chat/rooms/{roomId}/music*`.
3. Music canonical flow: `POST/GET /api/chat/rooms/{roomId}/song-request`, `GET/POST/DELETE /api/chat/rooms/{roomId}/music`, `GET /api/chat/rooms/{roomId}/music-queue`, `GET /api/youtube/search?q=`.
4. TRTC canonical token endpoint remains `/api/trtc/token`; Flutter must not bypass with tokenless `/usersig` in production.
5. Error format is mixed: `{error}` and `{success:false,error:{code,message}}`; Flutter must parse per endpoint and reject HTML API responses.

## Counts

| Metric | Count |
|---|---:|
| Backend handlers | 690 |
| Backend unique paths | 438 |
| Flutter normalized paths | 437 |
| Backend ↔ Flutter connected | 256 |
| Flutter-only normalized paths | 181 |
| MCP tools | 10 |
| Flutter runtime MCP | 0 |

## Fixed after audit

- Payment production constants now use `/api/payments/config`, `/api/payments/methods`, `/api/payments/requests`.
- Membership package/purchase constants now use `/api/memberships/packages`, `/api/memberships/purchase`.
- Gift catalog fallback now uses `/api/gifts/types`, not page route `/api/gifts`.
- Music skip now uses canonical `DELETE /api/chat/rooms/{roomId}/music`; stop constant is `/api/chat/rooms/{roomId}/music/stop`.
- Health/warmup check now uses backend-indexed `/api/warmup`, not `/api/v1/health`.

## Remaining high-priority review

- Legacy auth constants remain for non-production compatibility but must not be used in mobile production auth flow.
- `/api/video-streams/gifts/catalog` is not in backend docs and should remain unused.
- Backend has many admin/session-only endpoints; mobile runtime should not add MCP or session-only admin calls unless product explicitly requires them.
