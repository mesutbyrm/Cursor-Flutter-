# Kalan işler — canlı takip listesi

**Son güncelleme:** 2026-08-18 17:45 UTC  
**Kural:** Bu dosya her agent oturumunda güncellenir. Tamamlanan maddeler `[x]`, devam eden `[~]`, bekleyen `[ ]`.

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| FAZ 0 Audit | `[~]` DEVAM | OpenAPI/Prisma/B1.12 ✅; SSE şema kısmen; tam MCP eksik |
| P0 !istek / müzik ANR | `[~]` | Kod + testler tamam; **M5 cihaz testi testler bitince** |
| APK `1.0.258+294` | `[x]` | Release APK başarılı (run 32163086275) |
| APK `1.0.259+295` | `[x]` | Release APK başarılı (run 32163545874) |
| APK `1.0.260+296` | `[x]` | Release APK (run 32164943755) |
| APK `1.0.261+297` | `[ ]` | CI bekliyor |
| FAZ 1+ | `[ ]` | FAZ 0 PASS olmadan başlamaz |

---

## P0 — Müzik / !istek (sesli oda)

| # | İş | Durum | Sahip |
|---|-----|--------|-------|
| M1 | Üretimde `music-request-by-query` atla → `song-request` | `[x]` | `1.0.258+294` |
| M2 | Kırık `youtube-audio?url=` proxy kaldır | `[x]` | `1.0.257+293` |
| M3 | SSE grace + oynatma koordinatörü | `[x]` | `1.0.255–256` |
| M4 | Üretimde `youtube_explode` arama yedeğini kapat (ANR) | `[x]` | `1.0.259+295` |
| M8 | Stream resolve: explode/Piped üretimde kapalı | `[x]` | `1.0.260+296` |
| M5 | Oda `cmoohrbr` gerçek cihaz: `!istek` + müzik paneli | `[ ]` | **Tüm otomatik testler bitince** (kullanıcı) |
| M6 | Backend: `music-request-by-query` üretime ekle VEYA resmi “song-request only” dokümanı | `[ ]` | Backend |
| M7 | Gerçek `song-request` + SSE `dj_update` response dump (oda cmoohrbr) | `[ ]` | Backend |

---

## FAZ 0 — Audit / parity

| # | İş | Durum |
|---|-----|--------|
| A1 | `backend-docs/` (OpenAPI, index, Prisma, B1.12) | `[x]` |
| A2 | `BACKEND_FLUTTER_PARITY_AUDIT.md` B1.12 ile güncelle | `[x]` |
| A3 | MCP stub → `endpoints_index` + Prisma | `[x]` |
| A4 | `SSE_EVENTS_FLUTTER_PARSED.md` (koddan türetilmiş) | `[x]` |
| A5 | Tam backend MCP `index.mjs` (SDK, `read_source`) | `[ ]` |
| A6 | `nextjs_space/app/api/**/route.ts` kaynak ağacı | `[ ]` |
| A7 | Resmi SSE şema dokümanı (backend örnek payload) | `[ ]` |
| A8 | Test hesapları (TEST_USER, TEST_ROOM_OWNER, …) | `[ ]` |
| A9 | Android E2E müzik PASS → FAZ 0 kapat | `[ ]` |

---

## B1.12 — Bilinen parity (henüz kodlanmadı)

| # | Konu | Durum | Not |
|---|------|--------|-----|
| B1 | 12× WRONG_HOST `gifts/insights/*`, `gifts/missions*` | `[x]` | Ağu 2026: ana host 200 — sorun giderilmiş |
| B2 | 68× MISSING_BACKEND_ENDPOINT | `[x]` | `docs/MISSING_ENDPOINTS_FLUTTER_ACTIVE.md` |
| B3 | Gift realtime: SSE vs Socket.IO canonical | `[ ]` | Backend onayı |
| B4 | PK state machine dokümanı | `[ ]` | FAZ 7 öncesi |

---

## FAZ 1–13 (bloke)

FAZ 0 **PASS** olmadan başlanmaz. Sıra: `docs/PHASE_PLAN.md`.

---

## Oturum günlüğü

### 2026-08-18

- `1.0.257+293`: backend-docs, 404 yedeği, proxy düzeltmesi
- `1.0.258+294`: doğrudan song-request, MCP backend-docs
- `1.0.259+295`: youtube_explode üretimde kapalı, REMAINING_WORK + SSE parsed doc
- `1.0.260+296`: stream resolve ANR, MUSIC_API_PRODUCTION_PROBE.md
- `1.0.261+297`: DJ player üretim YouTube skip, mock song-request testi, MISSING_ENDPOINTS_FLUTTER_ACTIVE.md
- **Sırada:** M5 cihaz (testler sonrası), backend MCP (A5)

---

## Hızlı komutlar

```bash
bash scripts/print-build-status.sh
bash scripts/wait-apk-build.sh 900
cd mobile && flutter test test/features/voice_hub/
cd mcp-server && node index.mjs --selftest
```
