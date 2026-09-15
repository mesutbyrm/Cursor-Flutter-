# Üretim deploy — P0–P2 (canlifal.com / fortune_telling_platform)

## 1. Parite paketini kopyala

```bash
bash scripts/apply-backend-parity-to-nextjs.sh /path/to/fortune_telling_platform/nextjs_space
```

Yeni dosyalar (özet):

- `app/api/admin/users/[userId]/360|overview|activity|earnings|spending|agency|moderation|reports/route.ts`
- `app/api/agency/wallet/route.ts`, `wallet/transfer/route.ts`
- `lib/admin-user-hub-handlers.ts`, `lib/agency-wallet-handlers.ts`, `lib/social-distance.ts`, `lib/hub-date-range.ts`
- `app/api/cfc-arena/join`, `cfc-arena/[contestId]`, `agency/wallet/transactions`

## 2. P0 — RBAC + audit + idempotency

`backend-reference/canlifal_flutter_paketi/kaynak/lib/admin-mutation.ts` dosyasını üretim `lib/admin-mutation.ts` olarak ekleyin.

Jeton/CFC/ban/VIP POST route’larında:

```ts
const guard = await guardAdminMutation(req, {
  permission: 'finance.jeton.adjust',
  action: 'admin.jeton.adjust',
  targetType: 'user',
  targetId: userId,
})
if (guard instanceof NextResponse) return guard
// ... işlem ...
return completeAdminMutation({ req, actor: guard.actor, ... }, { newBalance })
```

## 3. P1 — Admin User Hub

Deploy sonrası mobil komuta merkezi otomatik `GET /api/admin/users/:id/overview` vb. doldurur.

## 4. P2 — Ajans cüzdanı

- Prisma: `agency_wallets`, `agency_wallet_transactions` migrate edilmiş olmalı.
- `POST /api/agency/wallet/transfer` — `idempotencyKey` zorunlu önerilir.
- Nakit çekim endpoint’i **eklenmez** (§14).

## 5. Doğrulama

```bash
# Admin overview (staff JWT)
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" \
  "https://canlifal.com/api/admin/users/$USER_ID/overview" | jq .

# Ajans wallet (ajans sahibi JWT)
curl -s -H "Authorization: Bearer $OWNER_TOKEN" \
  "https://canlifal.com/api/agency/wallet" | jq .
```

## 6. P3–P6

`docs/PLATFORM_PROFESSIONAL_SOCIAL_MASTER_PLAN.md` faz tablosu.
