# P1 Deploy — FCM / Push Token Kaydı

Parite raporu **#3**.

## Durum

| Katman | Durum |
|--------|--------|
| Flutter | `POST /api/devices/fcm` — 404’te sessiz atlar (`push_registrar.dart`) |
| API mirror | ✅ `api/src/routes/devices.ts` |
| Prod | ❌ **404** |

## Deploy (canlifal.com web reposu)

1. Prisma’da `DevicePushToken` modeli yoksa ekleyin (`api/prisma/schema.prisma` referans).
2. `docs/nextjs/app-api-devices-fcm-route.ts` → `app/api/devices/fcm/route.ts`
3. `verifyApiAuth.ts` mobil JWT ile çalışmalı.
4. `npx prisma migrate deploy`

## İstek sözleşmesi

```http
POST /api/devices/fcm
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "token": "<OneSignal veya FCM token>",
  "fcmToken": "<aynı token — geriye dönük>",
  "platform": "android",
  "provider": "onesignal"
}
```

Başarı: `{ "success": true, "registered": true }`

## Doğrulama

```bash
# Oturumsuz — 401 (route deploy edildiyse) veya 404 (henüz yok)
curl -s -o /dev/null -w "%{http_code}\n" -X POST \
  https://canlifal.com/api/devices/fcm \
  -H "Content-Type: application/json" \
  -d '{"token":"x"}'

# JWT ile
curl -s -X POST https://canlifal.com/api/devices/fcm \
  -H "Authorization: Bearer $CANLIFAL_JWT" \
  -H "Content-Type: application/json" \
  -d '{"token":"<gerçek_token>","platform":"android","provider":"onesignal"}'
```

Sıradaki: [DEPLOY_P1_PK.md](./DEPLOY_P1_PK.md)
