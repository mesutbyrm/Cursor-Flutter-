# Backend reference artifacts (read-only)



> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`../docs/DOCS_RELEASE_INDEX.md`](../docs/DOCS_RELEASE_INDEX.md)

**Kaynak:** Abacus.ai devir paketi — `backend-docs/abacus-current/` (2026-09-10 materialize)  
**Kullanım:** Cursor MCP, OpenAPI parity, Flutter DTO doğrulama — **üretim API değildir**.

| Dosya | Açıklama |
|-------|----------|
| `openapi.json` | OpenAPI 3.0.3 — **502** path |
| `endpoints_index.json` | **780** handler kaydı |
| `schema.prisma` | Üretim Prisma şeması |
| `ENDPOINTS.md` | İnsan okur API listesi |
| `abacus-current/` | Tam Abacus export (priority1–3, flutter) |
| `B1_12_*`, `MCP_INVENTORY.md` | **LEGACY** — kullanmayın |

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
