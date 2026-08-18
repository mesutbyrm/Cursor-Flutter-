# Backend reference artifacts (read-only)

**Kaynak:** Backend MCP export — 11 Ağustos 2026 (B1.12 denetimi)  
**Kullanım:** FAZ 0 parity audit, Cursor MCP, Flutter DTO doğrulama — **üretim API değildir**.

| Dosya | Açıklama |
|-------|----------|
| `openapi.json` | OpenAPI 3.0.3 — ~690 endpoint |
| `endpoints_index.json` | Method, auth, tag metadata |
| `schema.prisma` | Üretim Prisma şeması |
| `B1_12_API_MCP_FLUTTER_PARITY.md` | Tam parity denetim raporu |
| `MCP_REGISTRY.md` | MCP araç listesi |
| `MCP_INVENTORY.md` | MCP envanter |
| `MCP_CLEANUP_REPORT.md` | MCP temizlik notları |

## Canlı probe notları (18 Ağustos 2026)

| Endpoint | Üretim (`canlifal.com`) | OpenAPI / B1.12 |
|----------|-------------------------|-----------------|
| `POST .../music-request-by-query` | **404** | Yok |
| `POST .../song-request` | 401 (var) | Var |
| `GET /api/chat/youtube-stream?videoId=` | 200 (embed mode) | Var |
| `GET /api/chat/youtube-audio?videoId=` | 200 (embed JSON) | B1.12: eksik sayıldı |
| `GET /api/chat/youtube-audio?url=` | **400** | Flutter eski sözleşme |
| `GET /api/chat/music/popular` | **404** | B1.12: eksik |

Flutter `!istek` üretimde `song-request` yedeğine düşmeli (`music-request-by-query` 404).

## Eksik (hâlâ backend'den istenmeli)

- Tam `mcp-server/index.mjs` (SDK'lı)
- `nextjs_space/app/api/**/route.ts` kaynak ağacı
- SSE event şema dokümanı
- Test hesapları

Bkz. `docs/BACKEND_REQUIREMENTS_TO_REQUEST.md`.
