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

## Faz 1 durumu

| Tür | Dosya sayısı | Açıklama |
|-----|--------------|----------|
| Re-export | 6 | `users/me/*`, cihaz token alias |
| Yeni handler | 3 | `notifications/unread`, `payment`, `[id]/read` |
| Sonraki (Faz 1b) | 10 | DM conversations, `user/*` görevler, `auth/mobile-sessions` |

Kaynak şema/lib: `backend-reference/canlifal_flutter_paketi/kaynak/`.
