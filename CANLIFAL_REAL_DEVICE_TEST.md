# CANLIFAL Real Device Test

| Ortam | Durum |
|-------|--------|
| Cloud agent VM | **TEST NOT RUN** — `flutter devices` Android yok |
| Yerel Android | `bash scripts/run-canlifal-diagnostics.sh` |

## Gereksinimler

```bash
export ACCEPTANCE_USER_EMAIL="cursor.test.1786235468@mailinator.com"
export ACCEPTANCE_USER_PASSWORD="CursorTest!1786235468"  # bkz. docs/ACCEPTANCE_TESTS.md
export CANLIFAL_REAL_DEVICE_TEST=true
cd mobile && flutter test integration_test/ -d <device_id> \
  --dart-define=CANLIFAL_REAL_DEVICE_TEST=true \
  --dart-define=CANLIFAL_DIAGNOSTICS=true
```

Production API: `https://canlifal.com` (değiştirilmez).

**Unit test (`flutter test test/core/diagnostics/`) ≠ gerçek cihaz PASS.**
