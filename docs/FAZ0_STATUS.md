# FAZ 0 — Durum özeti

**Sonuç:** **INCOMPLETE** — Otomatik iş tamam; **jeton + M5 cihaz** bekleniyor  
**APK:** `1.0.271+307` (`apk-latest`)  
**Sürüm:** `mobile/pubspec.yaml`  
**Tek engel:** Test hesabı jeton=0 — `docs/M5_M7_JETON_BLOCKER.md`

---

## Tamamlanan (otomatik)

| Alan | Kanıt |
|------|--------|
| Backend envanter | `backend-docs/`, `BACKEND_API_ROUTE_INDEX.md` |
| Flutter parity | `BACKEND_FLUTTER_PARITY_AUDIT.md`, B1–B4 |
| MCP | `mcp-server` v1.2.0 |
| !istek / ANR kod | M1–M12 — `1.0.266+302` |
| SSE oda anahtarı | `VOICE_ROOM_KEY_RESOLUTION.md` |
| API müzik fazı | 6/6 PASS — `run-music-acceptance.sh` |
| Faz testleri | 15 PASS — `run-phase-tests.sh` |
| FAZ12 otomatik | 4/4 — `faz12-automated-gates.sh` |
| Jeton UX | `showInsufficientJetonDialog` — basic/RTC/müzik paneli |
| Günlük görevler | Growth Hub API eşlemesi — `1.0.269–271` |
| Otomatik betikler | `faz0-verify`, `probe-jeton-earn`, `admin-jeton-cheatsheet`, `wait-for-jeton` |
| Unit testler | 93× voice_hub + profile daily_task |

---

## Bekleyen (manuel)

| Madde | Durum | Bloker |
|-------|--------|--------|
| **M5** cihaz E2E | `[ ]` | Android — `M5_DEVICE_TEST_CHECKLIST.md` |
| **M7** song-request 200 | `[~]` | jeton ≥10 |
| **A9** FAZ 0 kapat | `[ ]` | M5 PASS |

---

## Hızlı komutlar

```bash
bash scripts/faz0-status.sh
bash scripts/admin-jeton-cheatsheet.sh   # user id + admin adımları
bash scripts/faz0-verify.sh
bash scripts/wait-for-jeton.sh 10 3600
```

---

## Jeton top-up

```bash
bash scripts/admin-jeton-cheatsheet.sh
```

Admin panel → `cursor.test.1786235468@mailinator.com` → **≥50 jeton**  
User ID: `cmsyoxjh80066mo08fo7nv5o6`
