# Backend ↔ Flutter — parity (2026-10-13 güncel)

| Durum | Not |
|-------|-----|
| **Flutter `main`** | Router + istemci sözleşmesi tamam |
| **Backend canlifal** | `cursor/mobile-parity-apis-dfca` — social-accounts, PK me/history|stats, test-push |

Doğrulama (backend clone güncelken):

```bash
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
python3 scripts/backend-method-parity.py canlifal-backend/nextjs_space
```

Deploy: canlifal.com’a backend merge sonrası mobil ek değişiklik gerekmez (782+ router zaten ana site).
