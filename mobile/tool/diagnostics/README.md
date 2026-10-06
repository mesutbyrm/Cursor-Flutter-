# Canlifal — gerçek cihaz diagnostic

Uygulama kodu: `mobile/lib/core/diagnostics/scenarios/`

| İstenen yol | Gerçek paket yolu |
|-------------|-------------------|
| `live_fortune_diagnostic.dart` | `package:canlifal_social/core/diagnostics/scenarios/live_fortune_diagnostic.dart` |
| `live_stream_diagnostic.dart` | `.../live_stream_diagnostic.dart` |
| `voice_room_diagnostic.dart` | `.../voice_room_diagnostic.dart` |
| `app_global_diagnostic.dart` | `.../app_global_diagnostic.dart` |

## Çalıştırma (Android cihaz)

```bash
export ACCEPTANCE_USER_EMAIL="..."
export ACCEPTANCE_USER_PASSWORD="..."
bash scripts/run-canlifal-diagnostics.sh
```

Cihaz yoksa raporlar **TEST NOT RUN** — PASS yazılmaz.
