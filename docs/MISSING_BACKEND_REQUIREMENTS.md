# Backend'den İstenmesi Gerekenler — Eksik Özet

**Tarih:** 2026-08-18  
**FAZ:** 0 (Audit)  
**Durum:** Bu dosya `BACKEND_REQUIREMENTS_TO_REQUEST.md` özetidir.

---

## Kritik eksiklik (P0)

Backend MCP'nin çalışması ve Flutter parity doğrulaması için **canlı backend kaynak dosyaları** Flutter reposunda yok.

| # | Eksik | Neden kritik |
|---|-------|--------------|
| 1 | Tam `mcp-server/index.mjs` (SDK'lı) | Repodaki stub yalnızca matrix okur |
| 2 | `openapi.json` | Endpoint request/response şeması |
| 3 | `endpoints_index.json` | Auth, method, tag metadata |
| 4 | `prisma/schema.prisma` (üretim) | Model alan adları |
| 5 | `nextjs_space/app/api/**/route.ts` | Gerçek handler kaynağı |
| 6 | `backend-docs/*.md` | MCP resource URI'leri |
| 7 | SSE event şema dokümanı | Event adı/body uydurma riski |
| 8 | Müzik API response örnekleri | `musicUrl`, `queue`, `playing` alanları |

---

## MCP dosya karşılaştırması

| Dosya | Sizden gelen | Flutter repo | Durum |
|-------|--------------|--------------|-------|
| `README.md` | ✅ Yüklendi | Eski/stub README yok | Backend sürümü daha kapsamlı |
| `package.json` | ✅ (`@modelcontextprotocol/sdk`) | Stub (SDK yok) | Güncellenmeli |
| `cursor-mcp.example` | ✅ | `.cursor/mcp.json` mevcut | Path düzeltilmeli |
| `index.mjs` | ❌ **Gelmedi** | Stub (~220 satır) | **Eksik #1** |

---

## Alan bazlı eksikler

| Alan | Eksik bilgi | Öncelik |
|------|-------------|---------|
| Voice / Music | `music-request-by-query` tam response JSON, SSE `dj_update` şeması | P0 |
| Voice / Seats | Koltuk sync edge-case API yanıtları | P1 |
| Live / PK | PK state machine event listesi | P1 |
| Gifts | SSE vs Socket.IO — hangisi canonical? | P1 |
| TRTC | Token response alanları, roomId mapping | P1 |
| Shorts | Pagination + preload contract | P2 |
| Test hesapları | TEST_USER, TEST_ROOM_OWNER, TEST_ADMIN | P1 |

---

## Ne yapılmamalı

- Endpoint uydurma ❌
- Response alanı uydurma ❌
- SSE event adı uydurma ❌
- FAZ 1'e geçiş (backend eksikleri varken) ❌

---

## Sonraki adım

`docs/BACKEND_REQUIREMENTS_TO_REQUEST.md` dosyasındaki numaralı talepleri backend'den karşılayın. Her dosya geldikçe parity audit güncellenir ve ilgili faz başlatılabilir.
