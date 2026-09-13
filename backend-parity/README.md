# Backend API parite — uygulama paketi

Flutter `fl_ref/extra_main.json` içindeki eksik uçlar için `nextjs_space/app/api/**/route.ts` dosyaları.

## Kurulum

```bash
cd fortune_telling_platform
bash ../Cursor-Flutter-/scripts/apply-backend-parity-to-nextjs.sh
# veya bu repo kökünden:
bash scripts/apply-backend-parity-to-nextjs.sh /path/to/fortune_telling_platform/nextjs_space
```

Sonra:

```bash
cd nextjs_space && yarn tsc --noEmit && yarn run build
python3 ../Cursor-Flutter-/scripts/check-extra-main-api-routes.py
```

## Faz 1 durumu (tamam)

| Tür | Adet | Açıklama |
|-----|------|----------|
| Re-export | 9 | `users/me/*`, cihaz token, `daily-tasks`, `story` |
| Proxy / yeni | 10 | bildirimler, DM, oturum revoke, fal pin/rate, favoriler |
| **Toplam** | **19** | `extra_main` Faz 1 kapsamı |

`lib/dm-typing-state.ts`, `lib/parity-route-params.ts` — `nextjs_space/lib/` altına kopyalanır.

Kaynak şema/lib: `backend-reference/canlifal_flutter_paketi/kaynak/`.
