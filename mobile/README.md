# Canlifal Social (Flutter)

Modern, TikTok tarzı koyu arayüzlü sosyal medya istemcisi. **Clean Architecture** (domain / data / presentation), **Riverpod** ve **REST + JWT** ile çalışır.

## Çalıştırma

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://senin-api.example.com
```

`API_BASE_URL` verilmezse varsayılan `https://api.canlifal.local` kullanılır (kendi backend adresinizle değiştirin).

## Mimari

- **Domain:** entity + repository arayüzleri  
- **Data:** `RemoteDataSource` (Dio), DTO’lar, repository implementasyonları  
- **Presentation:** Riverpod provider’ları, sayfalar  
- **Core:** tema, Dio + JWT interceptor, güvenli token saklama (`flutter_secure_storage`), router

## JWT

- Giriş / kayıt yanıtında `accessToken` (veya `access_token`) ve isteğe bağlı `refreshToken` beklenir; tokenlar güvenli depoda tutulur.  
- İsteklere `Authorization: Bearer <access>` eklenir.  
- `401` sonrası bir kez `POST /auth/refresh` ile yenileme denenir (`refreshToken` gövdesi).

## Backend ile hizalama

Uç nokta yolları `lib/core/network/api_endpoints.dart` içindedir. Kendi API’nize göre bu dosyayı güncellemeniz yeterlidir. Özet:

| Özellik | HTTP | Yol |
|--------|------|-----|
| Giriş | POST | `/auth/login` |
| Kayıt | POST | `/auth/register` |
| Yenileme | POST | `/auth/refresh` |
| Oturum kullanıcısı | GET | `/auth/me` |
| Akış | GET | `/feed?page=&limit=` |
| Profil | GET | `/users/:id` |
| Takip / çık | POST / DELETE | `/users/:id/follow` |
| Canlı listesi | GET | `/live/streams` |
| Sohbetler | GET | `/messages/conversations` |
| Mesajlar | GET | `/messages/conversations/:id/messages` |
| Mesaj gönder | POST | `/messages/conversations/:id/messages` |
| Bildirimler | GET | `/notifications` |
| Okundu | PATCH | `/notifications/:id/read` |
| Coin | GET | `/wallet` |

DTO’lar yaygın alan adı varyantlarını (`camelCase` / `snake_case`) okumaya çalışır; yanıt şekliniz farklıysa ilgili `*_dto.dart` dosyalarını uyarlayın.

## Özellikler

- Giriş / kayıt, korumalı shell, alt gezinme (Akış, Canlı, Mesaj, Profil)  
- Dikey kart akışı, canlı yayın listesi, konuşmalar ve sohbet, bildirimler, profil + takip, coin bakiyesi  

## Test

```bash
cd mobile && flutter test
```

## APK (telefonda dene)

Bu ortamda Android SDK olmadan APK üretilemez. GitHub’da **Actions → Build release APK** iş akışını çalıştırıp artifact’tan indirin; ayrıntılar için depo kökündeki [`APK_DOWNLOAD.md`](../APK_DOWNLOAD.md).
