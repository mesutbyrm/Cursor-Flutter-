# Kalan işler — canlı takip listesi

**Son güncelleme:** 2026-08-18 22:25 UTC  
**Kural:** Bu dosya her agent oturumunda güncellenir. Tamamlanan maddeler `[x]`, devam eden `[~]`, bekleyen `[ ]`.

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| FAZ 0 Audit | `[~]` DEVAM | Route index + SSE örnekleri + test hesapları eklendi |
| P0 !istek / müzik ANR | `[~]` | Kod + testler tamam; **M5 cihaz testi testler bitince** |
| APK `1.0.258+294` | `[x]` | Release APK başarılı (run 32163086275) |
| APK `1.0.259+295` | `[x]` | Release APK başarılı (run 32163545874) |
| APK `1.0.260+296` | `[x]` | Release APK (run 32164943755) |
| APK `1.0.261+297` | `[x]` | Release APK (run 32167217259) |
| APK `1.0.262+298` | `[x]` | Release APK (run 32181631541) |
| APK `1.0.263+299` | `[x]` | Release APK başarılı |
| APK `1.0.264+300` | `[x]` | Release APK başarılı (run 32184630561) |
| APK `1.0.265+301` | `[x]` | Release APK başarılı |
| APK `1.0.266+302` | `[x]` | Release APK başarılı (run 32191120566) |
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
| M9 | DJ player youtube-stream API üretim skip | `[x]` | `1.0.263+299` |
| M10 | SSE kısmi cuid→tam id çözümleme (oda listesi öneği) | `[x]` | `1.0.264+300` |
| M11 | SSE giriş: oda kataloğu bekle + key upgrade reconnect | `[x]` | `1.0.265+301` |
| M12 | SSE geç katalog listener + basic `_effectiveRoom` önek | `[x]` | `1.0.266+302` |
| M5 | Oda `cmoohrbr` gerçek cihaz: `!istek` + müzik paneli | `[ ]` | **Tüm otomatik testler bitince** (kullanıcı) |
| M6 | Backend: `music-request-by-query` üretime ekle VEYA resmi “song-request only” dokümanı | `[x]` | `docs/MUSIC_SONG_REQUEST_CONTRACT.md` (Flutter resmi) |
| M7 | Gerçek `song-request` + SSE `dj_update` response dump (oda cmoohrbr) | `[~]` | SSE ✅; song-request 400 jeton (acceptance PASS); 200 yanıt jeton bekliyor |

---

## FAZ 0 — Audit / parity

| # | İş | Durum |
|---|-----|--------|
| A1 | `backend-docs/` (OpenAPI, index, Prisma, B1.12) | `[x]` |
| A2 | `BACKEND_FLUTTER_PARITY_AUDIT.md` B1.12 ile güncelle | `[x]` |
| A3 | MCP stub → `endpoints_index` + Prisma | `[x]` |
| A4 | `SSE_EVENTS_FLUTTER_PARSED.md` (koddan türetilmiş) | `[x]` |
| A5 | Tam backend MCP `index.mjs` (SDK, `read_source`) | `[x]` | v1.2.0: read_source, search_source, list_services |
| A6 | `nextjs_space/app/api/**/route.ts` kaynak ağacı | `[~]` | `docs/BACKEND_API_ROUTE_INDEX.md` (690 uç yedeği) |
| A7 | Resmi SSE şema dokümanı (backend örnek payload) | `[~]` | `SSE_PAYLOAD_EXAMPLES` + M7 + `API_MUSIC_PHASE_REPORT` (6/6 PASS) |
| A8 | Test hesapları (TEST_USER, TEST_ROOM_OWNER, …) | `[~]` | `TEST_ACCOUNTS.md` + `VOICE_ROOM_KEY_RESOLUTION.md` |
| A9 | Android E2E müzik PASS → FAZ 0 kapat | `[ ]` |

---

## B1.12 — Bilinen parity (henüz kodlanmadı)

| # | Konu | Durum | Not |
|---|------|--------|-----|
| B1 | 12× WRONG_HOST `gifts/insights/*`, `gifts/missions*` | `[x]` | Ağu 2026: ana host 200 — sorun giderilmiş |
| B2 | 68× MISSING_BACKEND_ENDPOINT | `[x]` | `docs/MISSING_ENDPOINTS_FLUTTER_ACTIVE.md` |
| B3 | Gift realtime: SSE vs Socket.IO canonical | `[x]` | `docs/GIFT_REALTIME_SSE_VS_SOCKET.md` (Flutter ref.) |
| B4 | PK state machine dokümanı | `[x]` | `docs/PK_STATE_MACHINE_FLUTTER.md` |

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
- `1.0.262+298`: MCP read_source/search_source, GIFT_REALTIME + PK_STATE_MACHINE docs
- FAZ 0: BACKEND_API_ROUTE_INDEX, SSE_PAYLOAD_EXAMPLES, TEST_ACCOUNTS, MUSIC_SONG_REQUEST_CONTRACT
- `1.0.263+299`: DJ youtube-stream skip, M7 probe, M5 checklist
- `1.0.264+300`: SSE kısmi cuid→tam id (`VoiceRoomKeyResolver` önek), M7 probe önek çözümleme
- `1.0.265+301`: SSE katalog bekleme + canonical key upgrade reconnect
- `1.0.266+302`: SSE geç katalog listener, VOICE_ROOM_KEY_RESOLUTION doc
- API müzik fazı: `api-music-phase.sh` varsayılan hesap + önek çözümleme (6/6 PASS)
- `FAZ0_STATUS.md`, `run-music-acceptance.sh`, `m5-preflight.sh`, `M7_SONG_REQUEST_200_TEMPLATE.md`
- **Sırada:** M5 cihaz (`m5-preflight.sh` → checklist), M7 song-request 200 (jeton)

---

## Hızlı komutlar

```bash
bash scripts/run-music-acceptance.sh
bash scripts/print-build-status.sh
bash scripts/wait-apk-build.sh 900
cd mobile && flutter test test/features/voice_hub/
cd mcp-server && node index.mjs --selftest
```
