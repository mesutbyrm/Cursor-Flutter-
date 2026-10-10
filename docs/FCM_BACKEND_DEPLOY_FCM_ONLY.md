# canlifal.com — FCM-only push deploy (onay gerekir)

Flutter **1.0.759+** varsayılan `USE_FCM_ONLY=true` ile FCM token kaydeder. Üretimde push gelmesi için **bu deploy** şarttır.

## Ortam değişkenleri

| Değişken | Açıklama |
|----------|----------|
| `PUSH_PROVIDER` | `fcm` (varsayılan geçişte `onesignal` kalabilir) |
| `GOOGLE_APPLICATION_CREDENTIALS` | Firebase Admin JSON yolu (asla repoya commit etmeyin) |
| `ONESIGNAL_SEND_DISABLED` | `1` — OneSignal REST çağrılarını no-op (çift kanal önleme) |

## Kod (full-source)

1. `nextjs_space/lib/fcm-push.ts` — şablon: `backend-parity/nextjs_space/lib/fcm-push.ts`
2. `nextjs_space/lib/push.ts` — FCM dalı: `backend-parity/nextjs_space/lib/push.ts`
3. `POST /api/notifications/test-push` — FCM `messageId` / hata gövdesi döndürsün

## Doğrulama

1. Mobil giriş → `POST /api/user/device-token` body `provider: fcm`
2. Admin veya test ucu ile tek kullanıcıya push
3. OneSignal dashboard’da **yeni** kampanya göndermeyin (Flutter artık abone olmuyor)
4. Aynı olay için tek bildirim (notify dedupe + tek provider)

## Geri alma

`PUSH_PROVIDER=onesignal`, Flutter build `--dart-define=USE_FCM_ONLY=false`, eski APK.
