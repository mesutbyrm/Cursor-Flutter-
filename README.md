# Canlifal Mobile

Canlifal Mobile, [canlifal.com](https://canlifal.com) için Flutter ile hazırlanmış profesyonel Android/iOS uygulamasıdır. Koyu tema ağırlıklı sosyal medya arayüzü, canlı yayın, sohbet, fal, profil, premium/FanClub ve admin/moderasyon yüzeylerini tek modüler uygulamada toplar.

## Teknoloji

- Flutter 3.41.8 / Dart 3.11.5 uyumlu kaynak kodu
- Riverpod state management
- GoRouter navigation
- Dio API client + JWT bearer interceptor
- WebSocket gerçek zamanlı iletişim katmanı
- Firebase Authentication ve Firebase Cloud Messaging entegrasyon noktaları
- Flutter Secure Storage token saklama
- SharedPreferences tabanlı cache katmanı
- LiveKit client entegrasyon servisi
- Android ve iOS platform projeleri

## Uygulama alanları

- Giriş, kayıt ve şifremi unuttum
- Profil, avatar, kapak fotoğrafı, takip, rozet, seviye ve coin
- Premium üyelik ve FanClub aksiyonları
- Sonsuz kaydırmalı ana akış, hikayeler, trendler ve canlı yayın kartları
- TikTok benzeri dikey canlı yayın deneyimi
- Canlı yorum, emoji, hediye ve coin gönderme akışı
- Grup sohbeti, sesli oda, online kullanıcı ve moderasyon aksiyonları
- Kahve falı, tarot, astroloji ve canlı danışman ekranları
- Keşfet, hashtag, beğeni, yorum ve kaydet yüzeyleri
- Admin metrikleri, kullanıcı/yayın/içerik/coin/şikayet yönetimi panelleri

## Kurulum

Android ve iOS platform klasörleri repoya dahil olduğu için yeniden `flutter create` çalıştırmaya gerek yoktur.

```bash
flutter pub get
```

Firebase kullanımı için ortamınıza ait dosyaları ekleyin:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Ortam değişkenleri

Uygulama API ve gerçek zamanlı servis adreslerini `dart-define` ile alır:

```bash
flutter run \
  --dart-define=CANLIFAL_API_URL=https://canlifal.com/api \
  --dart-define=CANLIFAL_WS_URL=wss://canlifal.com/ws \
  --dart-define=CANLIFAL_LIVEKIT_URL=wss://livekit.canlifal.com
```

Firebase için Android tarafında `android/app/google-services.json`, iOS tarafında `ios/Runner/GoogleService-Info.plist` eklenmelidir.

## Geliştirme komutları

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Paket kimliği

- Android applicationId: `com.canlifal.app`
- iOS display name: `Canlifal`
