# canlifal.com — mobil parity API paketi

**Kaynak:** yerel `canlifal-backend` dal `cursor/mobile-parity-apis-dfca` (commit `0d5fe53+`).

GitHub push bu ortamda **403** (canlifal repo yazma izni yok). Deploy için:

1. `mesutbyrm/canlifal` deposunda dal açın veya `main`’e kopyalayın.
2. Bu klasördeki dosyaları `nextjs_space/` altına aynı yollarla yapıştırın.
3. Deploy sonrası parity:

```bash
git clone https://github.com/mesutbyrm/canlifal canlifal-backend
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
```

## Eklenen uçlar

| Path | Açıklama |
|------|----------|
| `GET /api/social-accounts` | SiteSetting `site.social_accounts_v1` |
| `GET/PUT /api/admin/social-accounts` | Admin (requireFullAdmin) |
| `GET /api/pk/me/history` | Tamamlanan PKBattle |
| `GET /api/pk/me/stats` | Galibiyet/mağlubiyet özeti |
| `GET /api/pk/stats/:userId` | Herkese açık özet |
| `GET /api/pk/me/matches` | Aktif PK oturumları |
| `POST /api/notifications/test-push` | OneSignal test |

Migration **yok** — yalnızca `SiteSetting` JSON.
