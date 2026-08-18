# FAZ 0 — Durum özeti (2026-08-18)

**Sonuç:** **INCOMPLETE** — P0 müzik cihaz testi (M5) bekleniyor  
**APK:** `1.0.266+302` (`apk-latest`)

---

## Tamamlanan (otomatik)

| Alan | Kanıt |
|------|--------|
| Backend envanter | `backend-docs/`, `BACKEND_API_ROUTE_INDEX.md` |
| Flutter parity | `BACKEND_FLUTTER_PARITY_AUDIT.md`, B1–B4 |
| MCP | `mcp-server` v1.2.0 (`read_source`, `search_source`) |
| !istek / ANR kod | M1–M4, M8–M9 — `1.0.257–263` |
| SSE oda anahtarı | M10–M12 — `1.0.264–266`, `VOICE_ROOM_KEY_RESOLUTION.md` |
| SSE üretim payload | M7 kısmi — `dj`, `connected` (`M7_MUSIC_SSE_CAPTURE.md`) |
| API müzik fazı | 6/6 PASS — `API_MUSIC_PHASE_REPORT.md`, `run-music-acceptance.sh` |
| Unit testler | 93× `test/features/voice_hub/` |

---

## Kısmi / bekleyen

| Madde | Durum | Bloker |
|-------|--------|--------|
| **M5** cihaz E2E | `[ ]` | Kullanıcı — `M5_DEVICE_TEST_CHECKLIST.md` |
| **M7** song-request 200 | `[~]` | Test jetonu 0 — `M5_M7_JETON_BLOCKER.md` |
| **A6** route.ts ağacı | `[~]` | `BACKEND_API_ROUTE_INDEX.md` yedeği |
| **A7** resmi SSE şema | `[~]` | Üretim `dj`/`connected`; backend doc yok |
| **A8** test hesapları | `[~]` | `TEST_ACCOUNTS.md`; admin secret eksik |
| **A9** FAZ 0 kapat | `[ ]` | M5 PASS |

---

## Doğrulama komutları

```bash
# Hızlı durum (test çalıştırmaz)
bash scripts/faz0-status.sh

# Tüm otomatik FAZ 0 kapıları (M5 hariç)
bash scripts/faz0-verify.sh

# M5 cihaz testi öncesi (API + jeton + unit)
bash scripts/m5-preflight.sh

# API müzik fazı (secret olmadan varsayılan test hesabı)
MUSIC_PROBE_ROOM=cmoohrbr bash scripts/acceptance-tests/api-music-phase.sh

# M7 probe + SSE dump
MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh

# Flutter unit
cd mobile && flutter test test/features/voice_hub/

# MCP
cd mcp-server && node index.mjs --selftest
```

---

## FAZ 0 → FAZ 1 geçiş kriteri

1. Android cihazda `cmoohrbr` + `!istek Tarkan - Şımarık` — ANR yok, müzik gelir
2. (Opsiyonel) M7 song-request 200 yanıt dump'ı — jeton + admin

**FAZ 1** başlamaz: `docs/PHASE_PLAN.md`
