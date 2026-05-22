# OneSignal push bildirimleri

## Uygulama kimliği (App ID)

| Alan | Değer |
|------|--------|
| **OneSignal App ID** | `578518ed-7b16-46a9-a1e6-7692d3ba55d8` |
| **Android paket adı** | `com.mesutbyrm.canlifal` |

Kodda varsayılan olarak bu App ID kullanılır. Farklı bir ortam için:

```bash
flutter run --dart-define=ONESIGNAL_APP_ID=başka-uuid
```

## Firebase (Android zorunlu)

OneSignal Android’de teslimat için **Firebase Cloud Messaging** kullanır.

1. Firebase Console’da `com.mesutbyrm.canlifal` ile proje + `google-services.json`
2. OneSignal Dashboard → **Settings → Platforms → Google Android (FCM)**
3. Firebase **Service Account** veya **Server key** ile FCM’i OneSignal’e bağlayın
4. `google-services.json` → `mobile/android/app/`

## Oturum eşlemesi

Kullanıcı giriş yaptığında SDK `OneSignal.login(userId)` çağırır; panelden kullanıcıya hedefli bildirim gönderebilirsiniz.

Push token sunucuya `POST /api/devices/fcm` ile kaydedilir (`provider: onesignal`).

## Test

1. Uygulamayı fiziksel cihazda açın, bildirim izni verin
2. OneSignal → **Audience** → cihazın **Subscribed** olduğunu kontrol edin
3. **Messages → New Push** ile test gönderin
