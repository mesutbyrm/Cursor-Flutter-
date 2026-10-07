# CANLIFAL Real Device Test

| Ortam | Durum | Güncelleme (UTC) |
|-------|--------|------------------|
| Cloud agent VM (2026-10-07) | **TEST NOT RUN** — Flutter SDK yok, `adb`/Android cihaz yok | Denetim raporu: `CANLIFAL_TEST_REPORT.md` |
| Redmi Telefon A (kullanıcı) | **Kısmi** — Diagnostic ZIP `DIAG-20261007-032621-E0BF` analiz edildi | Log kanıtı raporlarda |
| Yerel Android | `bash scripts/run-canlifal-diagnostics.sh` | — |

## Gereksinimler

```bash
export ACCEPTANCE_USER_EMAIL="..."  # docs/ACCEPTANCE_TESTS.md
export ACCEPTANCE_USER_PASSWORD="..."
export CANLIFAL_REAL_DEVICE_TEST=true
cd mobile && flutter test integration_test/ -d <device_id> \
  --dart-define=CANLIFAL_REAL_DEVICE_TEST=true \
  --dart-define=CANLIFAL_DIAGNOSTICS=true
```

Production API: `https://canlifal.com` (değiştirilmez).

**Unit test (`flutter test test/`) ≠ gerçek cihaz PASS.**

## Üretilen raporlar (2026-10-07)

- `CANLIFAL_TEST_REPORT.md` — ana özet  
- `CANLIFAL_CRITICAL_ERRORS.md` — P0–P3  
- `CANLIFAL_PERFORMANCE_REPORT.md`  
- `CANLIFAL_API_COMPATIBILITY.md`  
- `CANLIFAL_TRTC_SSE_REPORT.md`
