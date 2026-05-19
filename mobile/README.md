# Canlifal Social (Flutter)

Modern, canlifal.com web arayüzüyle uyumlu **kozmik koyu tema**lı sosyal istemci. **Clean Architecture** (domain / data / presentation), **Riverpod** ve **REST + JWT** ile çalışır.

## Çalıştırma

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=https://senin-api.example.com
```

`API_BASE_URL` verilmezse varsayılan `https://canlifal.com` kullanılır (`lib/core/config/env.dart`; kendi backend adresinizle `--dart-define` verin).

## Tema (canlifal.com ile uyum)

Koyu **kozmik mor** zemin, hafif **yıldız** dokusu (`CosmicBackground`), bölüm başlıklarında web’deki gibi **kırmızı dikey çubuk** (`CosmicSectionHeader`), alt gezinmede ortada **pembe–mor gradient FAB** (Canlı sekmesi). Renk sabitleri: `lib/core/theme/app_theme.dart`.

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
| Canlı yayınlar (canlifal) | GET | `/api/video-streams?limit=` |
| Sohbet odaları | GET | `/api/chat/rooms` |
| Oturum profili (canlifal) | GET | `/api/user/profile` |
| Kredi / coin (canlifal) | GET | `/api/user/credits` |
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
- Dikey kart akışı, **canlifal.com sosyal** listesi, canlı yayın listesi, konuşmalar ve sohbet, bildirimler, profil + takip, coin bakiyesi  

## Test

```bash
cd mobile && flutter test
```

## APK (telefonda dene)

**Doğrudan indirme (son `main` derlemesi, `apk-latest`):**  
[canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk)

Uygulama içinde **Giriş** ve **Kayıt** ekranlarının altında da aynı bağlantıya giden **«Android test APK indir»** düğmesi vardır (`lib/core/config/app_links.dart`).

404 alırsanız: GitHub → **Actions** → [**Build release APK**](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) → **Run workflow** → dal **`main`**. Ayrıntılar: depo kökündeki [`APK_DOWNLOAD.md`](../APK_DOWNLOAD.md).

**Görsel özet:** [`docs/`](docs/) klasöründeki `ui-mockup-*.png` dosyaları ve kökteki [`APK_DOWNLOAD.md`](../APK_DOWNLOAD.md) tablosu.
