# Canlifal — Flutter API (mobil)

**Tam doküman (canlifal.com):** https://canlifal.com/canlifal-flutter-api-docs.txt  
**Repo kopyası:** [`canlifal-flutter-api-docs.txt`](canlifal-flutter-api-docs.txt) — `scripts/sync-canlifal-config.sh` ile güncellenir.

## İstek başlıkları

```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
}
```

`mobile/lib/core/network/dio_provider.dart` Bearer + JSON başlıklarını otomatik ekler.

## Özet (mobil uygulamada kullanılan uçlar)

| # | Açıklama | Metot | Yol |
|---|----------|--------|-----|
| — | Kayıt | POST | `/api/auth/mobile-register` |
| — | Giriş | POST | `/api/auth/mobile-login` |
| — | Google | POST | `/api/auth/mobile-google` |
| — | TikTok | POST | `/api/auth/mobile-tiktok` |
| — | Token yenile | POST | `/api/auth/mobile-refresh` |
| 6 | Profil | GET/PATCH | `/api/me` |
| 8–12 | DM | GET/POST | `/api/messages`, `/api/messages/{userId}` |
| 14 | Kullanıcı lookup | GET | `/api/users/lookup/{username}` |
| 16 | Takip (toggle) | POST | `/api/user/{userId}/follow` |
| 35 | Yayın geçmişi | GET | `/api/user/broadcast-history?page=1&limit=20&status=ended` |
| 36 | Aktivite | GET | `/api/user/activity?page=1&limit=30&unread=true` |
| 37 | Okundu | PATCH | `/api/user/activity` → `{"markAllRead": true}` |

Yanıt örnekleri (broadcast `broadcasts[]`, activity `notifications[]`) tam metinde.

## Mobil kod

| API | Dosya |
|-----|--------|
| Uç sabitleri | `mobile/lib/core/network/api_endpoints.dart` |
| HTTP + 401 refresh | `mobile/lib/core/network/dio_provider.dart` |
| Lookup / yayın / aktivite | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart` |
| Takip | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart` |
| Bildirimler | `mobile/lib/features/notifications/data/repositories/notifications_repository_impl.dart` |

Site yolu (`/api/user/...`) başarısız olursa yedek: `/api/users/me/broadcast-history`, `/api/users/me/activity`.

## OneSignal

App ID: `578518ed-7b16-46a9-a1e6-7692d3ba55d8` — giriş sonrası `OneSignal.login(user.id)`.
