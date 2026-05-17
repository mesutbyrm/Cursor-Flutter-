# VivaLive Flutter App

VivaLive, canlı yayın, sesli sohbet odaları, sosyal paylaşım akışı, hikayeler, hediye/jeton sistemi, FunClub, oyunlar, gold üyelik, davet sistemi, trendler ve keşfet sayfası olan native Flutter uygulama önizlemesidir.

Bu sürüm WebView kullanmaz. Tüm ekranlar Flutter bileşenleriyle çizilir ve API bilgileri geldiğinde gerçek site verilerine bağlanacak şekilde hazırlanmıştır.

## Özellikler

- Akılda kalıcı logo ve gradient açılış ekranı.
- TikTok benzeri canlı yayın sahnesi, izleyici rozeti, sohbet ve hediye aksiyonları.
- Sesli sohbet odaları, konuşmacı/dinleyici görünümü ve oda açma aksiyonu.
- Facebook tarzı sosyal akış kartları, beğeni, yorum, paylaşım ve hediye butonları.
- Hikaye ekleme ve hikaye listesi.
- Keşfet/trend sayfası, oyunlar, günlük görevler ve 12 fal/yorum türü.
- Instagram/TikTok benzeri profil, takipçi istatistikleri, gold üyelik ve jeton cüzdanı.
- Bildirim ve mesaj giriş noktaları.
- API bağlantıları için hazır aksiyon noktaları ve placeholder veri yapısı.
- TikTok benzeri tam ekran canlı yayın modu.
- Tencent RTC SDK (`tencent_rtc_sdk`) ile UserSig alıp TRTC odasına girme iskeleti.

## API bağlamak için gerekli bilgiler

Uygulamayı gerçek veriye bağlamak için şu bilgileri gönderin:

1. Base API URL
2. Giriş/kayıt endpointleri ve auth tipi: token, JWT, session vb.
3. Kullanıcı profil endpointi
4. Sosyal akış endpointi
5. Canlı yayın listeleme, yayın açma ve yayın detay endpointleri
6. Sesli oda listeleme, oda açma ve oda detay endpointleri
7. Mesajlaşma endpointleri veya websocket bilgisi
8. Bildirim endpointleri veya push notification bilgisi
9. Hediye listesi, hediye gönderme ve jeton satın alma endpointleri
10. Gold üyelik, FunClub, davet sistemi ve oyun endpointleri
11. 12 fal/yorum türü için endpointler
12. Örnek JSON cevapları ve gerekiyorsa API anahtarı

## Canlı API ile build alma

Uygulama varsayılan olarak `https://canlifal.com` API adresine istek atar. Farklı ortam için `API_BASE_URL` Dart define değeri verilebilir.

```bash
flutter run --dart-define=API_BASE_URL=https://staging.example.com
flutter build apk --release --dart-define=API_BASE_URL=https://staging.example.com
```

Şu endpointler için servis katmanı hazırdır:

- `POST /api/auth/mobile-login`
- `POST /api/auth/mobile-register`
- `POST /api/auth/mobile-refresh`
- `POST /api/trtc/usersig`
- `GET /api/social/posts?page=1&limit=20`
- `GET /api/video-streams`
- `GET /api/chat/rooms?withCounts=true`
- `GET /api/gifts/types`
- `POST /api/gifts/send`
- `POST /api/video-streams/{streamId}/gifts`
- `GET /api/user/profile`
- `GET /api/jeton`
- `POST /api/video-streams`
- `POST /api/video-streams/{streamId}/join`
- `DELETE /api/video-streams/{streamId}/join?viewerId=...`
- `POST /api/chat/rooms/{roomId}/gifts`

Tencent RTC için UserSig `POST /api/trtc/usersig` endpointinden `userId + roomId` ile alınır. `TrtcService`, `tencent_rtc_sdk` üzerinden `TRTCCloud.enterRoom`, yayıncı için kamera/mikrofon açma ve izleyici için remote video başlatma akışını hazırlar.

Android build sırasında şu izinler manifest'e eklenmelidir:

- `android.permission.INTERNET`
- `android.permission.CAMERA`
- `android.permission.RECORD_AUDIO`
- `android.permission.MODIFY_AUDIO_SETTINGS`
- `android.permission.BLUETOOTH`
- `android.permission.BLUETOOTH_CONNECT`

Tam API dokümanı repoda `docs/FLUTTER_API_DOKUMANTASYONU.md` altında tutulur.

## Kurulum

Yeni bir makinede platform klasörlerini üretmek için:

```bash
flutter create --platforms=android,ios --project-name canlifal_mobile .
flutter pub get
flutter run
```

## Geliştirme komutları

```bash
flutter pub get
dart format lib/main.dart
flutter analyze
flutter build apk --release
```
