# FAZ 0 — Durum özeti

**Sonuç:** **INCOMPLETE** — Otomatik iş tamam; **jeton + M5 cihaz** bekleniyor  
**APK:** `1.0.280+316` (`apk-latest`)  
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
| Jeton UX | `showInsufficientJetonDialog` + `showJetonAwareError` — oda/müzik/hediye/oyun/üyelik (`1.0.277–281`) |
| Günlük görevler | Growth Hub API eşlemesi — `1.0.269–271` |
| Otomatik betikler | `faz0-verify`, `probe-jeton-earn`, `admin-jeton-cheatsheet`, `wait-for-jeton`, `m5-device-prep` |
| Unit testler | 93× voice_hub + profile daily_task + wallet_navigation |

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
bash scripts/faz0-next.sh          # önerilen
bash scripts/faz0-status.sh
bash scripts/admin-jeton-cheatsheet.sh
bash scripts/m5-device-prep.sh       # jeton sonrası
bash scripts/wait-for-jeton.sh 10 3600
```

---

## Jeton top-up

Admin panel → `cursor.test.1786235468@mailinator.com` → ≥50 jeton.  
Ayrıntı: `docs/M5_M7_JETON_BLOCKER.md`
