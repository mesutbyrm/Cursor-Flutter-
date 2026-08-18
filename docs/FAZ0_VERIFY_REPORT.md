# FAZ 0 — Otomatik doğrulama raporu

**Tarih:** 2026-08-18 23:42 UTC  
**APK:** `1.0.266+302`  
**Sonuç:** **AUTOMATED_PASS (M5 cihaz bekliyor)**

| Geçti | Uyarı | Başarısız |
|-------|-------|-----------|
| 3 | 1 | 0 |

## Kapılar

| Kapı | Durum | Detay |
|------|--------|-------|
| API müzik (6/6 + M7 probe) | PASS | run-music-acceptance.sh |
| voice_hub unit | PASS | 93 tests |
| MCP selftest | PASS | v1.2.0 read_source |
| Jeton | WARN | cursor.test.1786235468@mailinator.com jeton=0 — M5/M7 için ≥10 gerekli |

## Manuel bekleyen

| Madde | Açıklama |
|-------|----------|
| **M5** | Android cihaz — `docs/M5_DEVICE_TEST_CHECKLIST.md` |
| **M7** | song-request HTTP 200 (jeton ≥10) |
| **Jeton** | `docs/M5_M7_JETON_BLOCKER.md` |
| **A9** | M5 PASS → FAZ 0 kapat |

## Komutlar

```bash
bash scripts/faz0-verify.sh
bash scripts/m5-preflight.sh
bash scripts/run-music-acceptance.sh
```
