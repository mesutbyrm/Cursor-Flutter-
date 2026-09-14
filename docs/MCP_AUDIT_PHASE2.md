# MCP Audit — Phase 2 (2026-09-14)

## Özet

| | |
|--|--|
| Toplam MCP (repo config) | **1** (`canlifal-backend`) |
| Flutter runtime MCP client | **0** (mobil APK içinde MCP yok) |
| Silinen | **0** |

## Kayıtlar

### `canlifal-backend` (development / Cursor)

| Alan | Değer |
|------|--------|
| Config | `.cursor/mcp.json` |
| Entry | `node /workspace/mcp-server/index.mjs` |
| Mobil `lib/` import | Yok |
| Runtime dependency (APK) | Yok |
| Duplicate | Yok |
| Durum | **alive** — agent/dev tooling |

### Diğer dokümantasyon

- `docs/MCP_INTEGRATION_MATRIX.md`, `backend-docs/MCP_*.md` — backend/entegrasyon referansı; mobil derlemeye dahil değil.

## Karar

Belirsiz veya dev-only MCP **silinmedi**. Mobil kodda MCP client eklenmedi/değiştirilmedi.
