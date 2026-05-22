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

## Sunucu (API) — REST API Key

| Ortam değişkeni | Açıklama |
|----------------|----------|
| `ONESIGNAL_APP_ID` | `578518ed-7b16-46a9-a1e6-7692d3ba55d8` |
| `ONESIGNAL_REST_API_KEY` | Dashboard → **Settings → Keys & IDs** → App API Key |

**Önemli:** REST API Key yalnızca `api/.env` veya canlifal.com sunucu ortamında tutulur; Flutter APK içine veya GitHub’a eklenmez.

Ödeme onayı / uygulama içi bildirim oluşturulunca API, aynı `userId` ile OneSignal push dener (`OneSignal.login` ile aynı id).

`api/.env.example` dosyasını kopyalayıp anahtarları doldurun; API’yi yeniden başlatın.

## Test

1. Uygulamayı fiziksel cihazda açın, bildirim izni verin, giriş yapın
2. OneSignal → **Audience** → **Subscribed** + **External ID** = site kullanıcı id
3. Panelden test push veya API üzerinden ödeme onayı bildirimi
