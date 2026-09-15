# FAZ 0 — Otomatik doğrulama raporu

**Tarih:** 2026-09-15 19:19 UTC  
**APK:** `1.0.524+565`  
**Sonuç:** **INCOMPLETE**

| Geçti | Uyarı | Başarısız |
|-------|-------|-----------|
| 4 | 0 | 1 |

## Kapılar

| Kapı | Durum | Detay |
|------|--------|-------|
| API müzik (6/6 + M7 probe) | PASS | run-music-acceptance.sh |
| API voice seat | PASS | run-voice-seat-acceptance.sh |
| voice_hub unit | PASS | 93 tests |
| MCP selftest | FAIL | log: /tmp/faz0-mcp.log |
| Jeton bakiyesi | PASS | cursor.test.1786235468@mailinator.com jeton=85164 |

## Manuel bekleyen

| Madde | Açıklama |
|-------|----------|
| **M5** | Android cihaz — `docs/M5_DEVICE_TEST_CHECKLIST.md` |
| **M7** | song-request HTTP 200 (jeton ≥10) |
| **Jeton** | `docs/M5_M7_JETON_BLOCKER.md` |
| **A9** | M5 PASS → FAZ 0 kapat |

## Komutlar

```bash
bash scripts/faz0-next.sh
bash scripts/faz0-verify.sh
bash scripts/m5-preflight.sh
bash scripts/run-music-acceptance.sh
bash scripts/run-voice-seat-acceptance.sh
```
