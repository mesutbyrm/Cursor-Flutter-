# CURRENT BACKEND SOURCE SET — Abacus.ai + Canlı Kod Envanteri

> **Güncelleme:** 2026-09-10  
> **Kural:** Entegrasyon yalnızca **CURRENT** satırlardan yapılır. `LEGACY_IGNORE` ve Sep 8 ZIP arşivleri kaynak değildir.

## Kaynak seçim kriteri

| Kaynak | Tarih | Karar | Gerekçe |
|--------|-------|-------|---------|
| `_zip_analysis/00_OKU_BENI.md` + `ENDPOINTS.md` + `DATA_MODELS.md` + `AUTHENTICATION.md` + `REALTIME.md` + `SERVICES.md` + `*.ts` referans | **2026-09-10** | **CURRENT** | Canlı kod taraması — **852** endpoint, **231** model, §90 checkpoint |
| `backend-docs/abacus-current/` + `openapi.json` + `endpoints_index.json` | 2026-09-10 (zip 2026-09-08) | **CURRENT** | OpenAPI **502** path, index **780** handler, Postman, realtime/music dok. |
| `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` | 2026-09-08 | **FLUTTER CANON** | Mobil path/body/SSE tek referansı |
| `_zip_analysis/canlifal_cursor_paketi (2).zip` | 2026-09-08 | **ARCHIVE** | Ham arşiv; materialize: `backend-docs/abacus-current/` |
| `_zip_analysis/output_canlifal_cursor_paketi_01_mcp-server.zip` | 2026-09-08 | **LEGACY** | MCP alt kümesi — tam paket yeterli |
| `backend-docs/B1_12_*`, `MCP_INVENTORY.md` | 2026-08 | **LEGACY** | Abacus paketi hariç tutuyor |

## CURRENT — öncelik sırası (çelişkide)

1. **Gerçek backend davranışı** (`https://canlifal.com` probe)
2. **`_zip_analysis` Sep 10 envanter** (852 endpoint — en güncel sayım)
3. **`backend-docs/openapi.json`** (502 path — şema detayı)
4. **`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`** (mobil sözleşme)
5. Postman / README

## Materialize yollar

```
_zip_analysis/                    ← Sep 10 canlı kod envanteri (CURRENT)
├── 00_OKU_BENI.md
├── ENDPOINTS.md                  (852 endpoint gruplu)
├── DATA_MODELS.md                (231 model)
├── AUTHENTICATION.md
├── REALTIME.md
├── SERVICES.md
├── FLUTTER_ENTEGRASYON_REHBERI.md
├── MCP_VE_ENTEGRASYONLAR.md      (MCP: yok — dev-only mcp-server repoda)
└── *.ts                          (referans lib kaynakları)

backend-docs/
├── openapi.json                  (502 paths)
├── endpoints_index.json          (780 handlers)
├── schema.prisma
├── ENDPOINTS.md
├── DATABASE_REFERENCE.md
└── abacus-current/               (priority1/2/3 + flutter/)

mcp-server/                       ← Cursor geliştirici aracı (Flutter runtime DEĞİL)
docs/FLUTTER_ENTegrasyon_KILAVUZU.md
```

## LEGACY / IGNORE

- `LEGACY_IGNORE/output_canlifal_cursor_paketi_01_mcp-server.zip.README`
- Ham ZIP dosyaları — açılmış kopya kullan
- Eski 438-path openapi (superseded)

## Çelişki notları

| Konu | Açıklama |
|------|----------|
| 852 vs 780 vs 502 | Sep10 index handler/route sayımı > Abacus index > OpenAPI gruplu path |
| MCP | `_zip_analysis`: üretimde MCP yok; repodaki `mcp-server/` yalnızca Cursor |
| PK skor | İstemci skor göndermez — hediye sonrası sunucu hesaplar (`00_OKU_BENI` §8) |
| Müzik | Kanonik: `POST /api/chat/rooms/{roomId}/song-request` |

## MCP (Flutter)

**GEREKMEZ** — REST + SSE + TRTC/Agora token uçları yeterli.
