# canlifal.com — FCM push PR (yerel hazır, push sizde)

Agent `mesutbyrm/canlifal` reposuna yazamıyor (403). Aşağıdaki commit yerelde üretildi; siz push/merge edin.

## Dal önerisi

`feat/fcm-only-push-2026-10` → `full-source`

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `nextjs_space/lib/fcm-push.ts` | Firebase Admin multicast |
| `nextjs_space/lib/push.ts` | `PUSH_PROVIDER=fcm` |
| `nextjs_space/lib/push-test.ts` | Tanılama test push |
| `nextjs_space/app/api/notifications/test-push/route.ts` | `provider` alanı |
| `nextjs_space/lib/notify.ts` | `sendPush` (OneSignal doğrudan değil) |

## Deploy env

```bash
PUSH_PROVIDER=fcm
GOOGLE_APPLICATION_CREDENTIALS=/path/to/canlifal-firebase-adminsdk.json
ONESIGNAL_SEND_DISABLED=1   # geçişte çift gönderim önleme
```

## Flutter eşleşmesi

Mobil **1.0.759+** / **760+** — `USE_FCM_ONLY=true` (varsayılan), token `provider: fcm`.

## Yerel commit (VM)

Commit mesajı: `feat(push): FCM provider via PUSH_PROVIDER=fcm; notify uses sendPush; test-push`

Parity kopyası Flutter repo: `backend-parity/nextjs_space/` (aynı içerik).
