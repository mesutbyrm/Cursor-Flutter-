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

Uygulama `API_BASE_URL` Dart define değeri verilirse gerçek endpointlere istek atar. Verilmezse demo verilerle çalışır.

```bash
flutter run --dart-define=API_BASE_URL=https://example.com
flutter build apk --release --dart-define=API_BASE_URL=https://example.com
```

Şu endpointler için servis katmanı hazırdır:

- `POST /api/auth/mobile-login`
- `POST /api/auth/mobile-register`
- `POST /api/auth/mobile-refresh`
- `POST /api/trtc/usersig`
- `GET /api/social/feed`
- `GET /api/video-streams`
- `GET /api/audio-rooms`
- `GET /api/gifts/types`
- `POST /api/gifts/send`
- `POST /api/video-streams/{streamId}/gifts`

Tencent RTC için UserSig backend'den alınacak şekilde `TrtcService` iskeleti eklendi. Gerçek Tencent Flutter SDK/plugin bilgisi netleşince `enterRoom`, `exitRoom`, kamera/mikrofon ve rol geçişleri bu servise bağlanacak.

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
