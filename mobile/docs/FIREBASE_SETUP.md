# Firebase (Messaging + Analytics)

Uygulama Firebase’i **isteğe bağlı** başlatır. `google-services.json` veya dart-define olmadan CI ve yerel derleme çalışmaya devam eder.

## Hızlı etkinleştirme

1. [Firebase Console](https://console.firebase.google.com/) → proje oluştur → Android uygulaması ekle (`com.mesutbyrm.canlifal`).
2. `google-services.json` dosyasını `mobile/android/app/` altına kopyalayın.
3. FlutterFire (önerilen):

   ```bash
   cd mobile
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

4. Veya manuel dart-define ile çalıştırma:

   ```bash
   flutter run \
     --dart-define=FIREBASE_PROJECT_ID=your-project \
     --dart-define=FIREBASE_API_KEY=AIza... \
     --dart-define=FIREBASE_APP_ID=1:123:android:abc \
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789
   ```

## Android Gradle

`google-services.json` mevcutsa `com.google.gms.google-services` eklentisi otomatik uygulanır. Dosya yoksa eklenti atlanır (CI).

Örnek dosya: `android/app/google-services.json.example`

## Backend

Oturum açıldığında uygulama `POST /api/devices/fcm` ile token kaydı dener (canlifal.com’da uç yoksa sessizce atlanır). Self-hosted API bu uçu destekler.

## Analytics

`FirebaseBootstrap.logEvent('screen_view', parameters: {...})` — init sonrası çalışır.
