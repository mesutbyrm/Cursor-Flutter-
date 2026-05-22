# canlifal.com — anlık push (OneSignal)

Mobil uygulama `OneSignal.login(siteUserId)` kullanır. Sunucudan push için **site kullanıcı id** ile `external_id` eşleşmeli.

## Ortam değişkenleri (sunucu)

```env
ONESIGNAL_APP_ID=578518ed-7b16-46a9-a1e6-7692d3ba55d8
ONESIGNAL_REST_API_KEY=os_v2_app_...
```

## Tetiklenecek olaylar

| Olay | Kime | `type` | `targetPath` |
|------|------|--------|--------------|
| Yeni DM | Alıcı | `message` | `/chat/{conversationId}` |
| Jeton/CFC ödeme talebi | `admin`, `yonetici`, … | `jeton_payment_request` | `/admin` |
| Ödeme onay/red | Talep sahibi | `*_approved` / `*_rejected` | `/jeton-yukle` veya `/cfc-store` |
| Canlı yayın başladı | Takipçiler | `live` | `/live` |

## REST örnek (Node)

```javascript
await fetch('https://api.onesignal.com/notifications', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Key ${process.env.ONESIGNAL_REST_API_KEY}`,
  },
  body: JSON.stringify({
    app_id: process.env.ONESIGNAL_APP_ID,
    target_channel: 'push',
    include_aliases: { external_id: [userId] },
    headings: { en: title, tr: title },
    contents: { en: body, tr: body },
    priority: 10,
    android_channel_id: 'canlifal_urgent',
    data: { type, targetPath, targetId, title, body },
  }),
});
```

## Site uçları (öneri)

- `POST /api/messages/...` sonrası → alıcıya push
- `POST /api/payment/requests` sonrası → staff push
- `POST /api/video-streams` veya yayın başlatma → `POST /api/video-streams/:id/live-started` → takipçilere push

Self-hosted API (`/workspace/api`) bu mantığı zaten içerir; canlifal.com aynı çağrıları eklemelidir.
