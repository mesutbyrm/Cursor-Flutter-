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

1. `/api/gifts` is a page route in production probe; Flutter must use JSON endpoints such as `/api/gifts/types`, `/api/gifts/catalog` where auth permits, or context send/list endpoints.
2. Uploaded docs mark removed old paths: `/api/payment/*` -> `/api/payments/*`, `/api/membership/packages` -> `/api/memberships/packages`, old `/api/rooms/{id}/music/*` -> `/api/chat/rooms/{roomId}/music*`.
3. Music canonical flow: `POST/GET /api/chat/rooms/{roomId}/song-request`, `GET/POST/DELETE /api/chat/rooms/{roomId}/music`, `GET /api/chat/rooms/{roomId}/music-queue`, `GET /api/youtube/search?q=`.
4. TRTC canonical token endpoint remains `/api/trtc/token`; Flutter must not bypass with tokenless `/usersig` in production.
5. Error format is mixed: `{error}` and `{success:false,error:{code,message}}`; Flutter must parse per endpoint and reject HTML API responses.

## Counts

| Metric | Count |
|---|---:|
| Backend handlers | 690 |
| Backend unique paths | 438 |
| Flutter normalized paths | 441 |
| Connected normalized paths | 251 |
| Flutter-only normalized paths | 190 |
| Mobile-relevant backend handlers sampled | 302 |

## Highest priority mismatches

- `/api/payment/config`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/payment/requests`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/payment-methods`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/membership/packages`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/video-streams/gifts/catalog`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/gifts`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/youtube/search`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/chat/rooms/{param}/skip`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/chat/rooms/{param}/pause`: verify or migrate to backend-documented canonical path before relying on it.
- `/api/chat/rooms/{param}/resume`: verify or migrate to backend-documented canonical path before relying on it.

## Duplicate / deprecated risks

- Legacy auth paths `/api/auth/login`, `/api/auth/register`, `/api/auth/refresh`, `/api/auth/me` appear in Flutter constants but uploaded docs define mobile JWT as `/api/auth/mobile-*` and `/api/me`.
- Payment constants still include singular `/api/payment/*`; uploaded docs require plural `/api/payments/*`.
- Some music helpers use skip/pause/resume aliases; uploaded MUSIC API canonicalizes `DELETE /api/chat/rooms/{roomId}/music` and `POST /api/chat/rooms/{roomId}/music/stop`.

## Next code actions

1. Replace singular payment endpoints with `/api/payments/*`.
2. Remove or isolate legacy auth constants from production flows.
3. Align music queue/skip/stop methods with `MUSIC_API`.
4. Continue analyzer cleanup without weakening rules.
5. Add endpoint contract tests for high-risk migrated paths.
