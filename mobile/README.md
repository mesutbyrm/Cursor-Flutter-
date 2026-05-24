# Canlifal Social (Flutter)

Modern, TikTok tarzı koyu arayüzlü sosyal medya istemcisi. **Clean Architecture** (domain / data / presentation), **Riverpod** ve **REST + JWT** ile çalışır.

## Çalıştırma

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://senin-api.example.com
```

`API_BASE_URL` verilmezse varsayılan `https://canlifal.com` kullanılır (`lib/core/config/env.dart`; kendi backend adresinizle `--dart-define` verin).

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
| Akış (hikâyeler) | GET | `/api/stories?page=&limit=` |
| Sosyal paylaşımlar | GET | `/api/social/posts?page=&limit=` |
| Sosyal paylaşım oluştur | POST | `/api/social/posts` (JSON veya multipart `image`) |
| Canlı yayınlar (canlifal) | GET | `/api/video-streams?limit=` |
| Sohbet odaları | GET | `/api/chat/rooms` |
| Oturum profili (canlifal) | GET | `/api/user/profile` |
| Kredi / coin (canlifal) | GET | `/api/user/credits` |
| Jeton paketleri (canlifal) | GET | `/api/jeton` |
| Arkadaş daveti (canlifal) | GET | `/api/referral` |
| Canlı (diğer API) | GET | `/api/live?page=&limit=` |
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

- Giriş / kayıt, korumalı shell, alt gezinme (Akış, Sosyal, Canlı, Mesaj, Profil)  
- **Shell üst çubuğu:** Akış, Sosyal, Canlı ve Mesaj’da profil (→ Profil sekmesi), bildirimler ve jeton; **Profil** sekmesinde sol üst **Ana akış** (`/feed`), bildirimler ve jeton  
- Ana sayfa ve **Sosyal / Canlı (yayınlar) / Mesajlar / Profil** için tema uyumlu **Hızlı işlemler**; Canlı **Sohbet** sekmesinde ek panel + odalar ızgarasında üst boşluk düzeltmesi
- Dikey kart akışı, **canlifal.com sosyal** listesi, canlı yayın listesi, konuşmalar ve sohbet, bildirimler, profil + takip, coin bakiyesi  

## Sürüm

| Sürüm | Build | Özet |
|-------|-------|------|
| **1.0.6** | 7 | Ana sayfa: jeton→mağaza, profil→profil; 3 canlı; tüm hızlı işlemler ve sohbet odaları; 14 fal (5’li grid); hızlı yenileme |
| 1.0.5 | 6 | Sesli oda neon UI, TRTC, hediye, shell jeton/davet |
| 1.0.4 | 5 | Sesli oda API, hediye/çıkış düzeltmeleri |

Güncel: `pubspec.yaml` → `version: 1.0.75+77`

## Test

```bash
cd mobile && flutter test
```

## APK (telefonda dene)

Bu ortamda Android SDK olmadan APK üretilemez. GitHub’da **Actions → Build release APK** iş akışını çalıştırıp artifact’tan indirin; ayrıntılar için depo kökündeki [`APK_DOWNLOAD.md`](../APK_DOWNLOAD.md).
