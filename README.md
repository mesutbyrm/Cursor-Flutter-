# Canlifal — Flutter Sosyal Medya Uygulaması

Modern TikTok tarzı arayüzlü sosyal medya istemcisi. **Clean Architecture**, **Riverpod** state management ve **JWT** ile REST API entegrasyonu.

## Özellikler

| Özellik | Açıklama |
|--------|----------|
| Giriş / Kayıt | E-posta + şifre, JWT access/refresh token |
| Ana akış | Dikey video feed (`trend-videos`) |
| Profiller | Kullanıcı profili, avatar, bio, seviye |
| Takip | `POST/DELETE /users/:id/follow` |
| Canlı yayın | Yayın listesi ve izleme |
| Mesajlaşma | Sohbet odaları ve mesaj geçmişi |
| Bildirimler | Duyurular ve uygulama içi bildirim paneli |
| Coin | Bakiye görüntüleme ve harcama |
| Alt navigasyon | TikTok tarzı glassmorphism bottom bar |

## Mimari

```
lib/
├── app/                 # MaterialApp, router, tema
├── core/                # Config, network, storage, bootstrap
├── domain/              # Entities + repository sözleşmeleri
├── data/                # Datasources, repository implementasyonları
└── presentation/        # Riverpod providers, ekranlar, widget'lar
```

## Kurulum

### Flutter

```bash
flutter pub get
flutter analyze
flutter run
```

### Üretim API (canlifal.com)

```bash
flutter run \
  --dart-define=CANLIFAL_API_URL=https://canlifal.com/api \
  --dart-define=CANLIFAL_WS_URL=wss://canlifal.com/ws
```

### Yerel JWT API

```bash
docker compose up -d
cp api/.env.example api/.env
cd api && npm install && npx prisma migrate deploy && npm run dev
```

```bash
flutter run \
  --dart-define=CANLIFAL_API_URL=http://10.0.2.2:3000/api/v1 \
  --dart-define=CANLIFAL_WS_URL=ws://10.0.2.2:3000/ws
```

> Android emülatörde `localhost` yerine `10.0.2.2` kullanın. iOS simülatörde `http://127.0.0.1:3000/api/v1`.

## JWT akışı

1. `POST /auth/login` veya `/auth/register` → `accessToken` + `refreshToken`
2. Token'lar `flutter_secure_storage` içinde saklanır
3. İsteklerde `Authorization: Bearer <accessToken>`
4. 401 yanıtında otomatik `POST /auth/refresh`

## API uç noktaları

Üretim: `https://canlifal.com/api/...`  
Yerel: `http://localhost:3000/api/v1/...`

Detaylı JWT auth uçları için `api/README` bölümüne bakın. Sosyal uçlar (`trend-videos`, `video-streams`, `chat/rooms`, `coins`, `follow`) yerel API'de seed veri ile çalışır; üretimde canlifal.com public endpoint'leri kullanılır.

## Teknoloji

- Flutter 3.8+ / Dart 3.8+
- Riverpod 3, GoRouter, Dio
- Firebase Auth & FCM (isteğe bağlı)
- LiveKit canlı yayın istemcisi
