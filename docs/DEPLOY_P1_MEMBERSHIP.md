# P1 Deploy — Premium Üyelik Paketleri

Parite raporu **#5**.

## Durum

| Katman | Durum |
|--------|--------|
| Flutter | `GET /api/membership/packages` + yerel fallback katalog |
| API mirror | ✅ `api/src/routes/wallet.ts` |
| Prod | ❌ **404** |

## Deploy

1. `docs/nextjs/app-api-membership-packages-route.ts` → `app/api/membership/packages/route.ts`
2. Satın alma: `POST /api/membership/purchase` — `wallet.ts` satır 679+ referans
3. JWT zorunlu

## Doğrulama

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  https://canlifal.com/api/membership/packages
# Deploy + JWT: 200

curl -s https://canlifal.com/api/membership/packages \
  -H "Authorization: Bearer $CANLIFAL_JWT" | head -c 400
```

Flutter `membership_catalog_fallback.dart` API 404/boş dönerse devreye girer.
