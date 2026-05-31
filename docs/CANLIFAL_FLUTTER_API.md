# Canlifal — Flutter API kullanımı

Kaynak: canlifal.com sitesinden alınan Flutter entegrasyon dokümanı.

## İstek başlıkları

Tüm korumalı uçlar için:

```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
}
```

Mobil uygulamada `lib/core/network/dio_provider.dart` bu başlıkları otomatik ekler (JWT veya oturum çerezi).

## Uçlar

| Açıklama | Metot | Yol |
|----------|--------|-----|
| Kullanıcı adı ile profil | GET | `/api/users/lookup/{username}` |
| Yayın geçmişi | GET | `/api/user/broadcast-history?page=1&limit=20&status=ended` |
| Okunmamış aktivite | GET | `/api/user/activity?unread=true` |
| Tüm aktiviteleri okundu işaretle | PATCH | `/api/user/activity` — gövde: `{"markAllRead": true}` |

### Örnek URL’ler (canlifal.com)

- `https://canlifal.com/api/users/lookup/mesut_byrm`
- `https://canlifal.com/api/user/broadcast-history?page=1&limit=20&status=ended`
- `https://canlifal.com/api/user/activity?unread=true`
- `https://canlifal.com/api/user/activity` (PATCH)

## Mobil kod eşlemesi

| API | Dosya |
|-----|--------|
| Uç sabitleri | `mobile/lib/core/network/api_endpoints.dart` |
| HTTP istemcisi | `mobile/lib/core/network/dio_provider.dart` |
| Lookup / yayın / aktivite | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart` |
| Bildirimler (aktivite) | `mobile/lib/features/notifications/data/repositories/notifications_repository_impl.dart` |
| Yayın geçmişi ekranı | `mobile/lib/features/profile/presentation/pages/profile_broadcast_history_page.dart` |

Site dokümanı yolları (`/api/user/...`) başarısız olursa uygulama `/api/users/me/...` yollarını dener.

## Güncel doküman

| Kaynak | Konum |
|--------|--------|
| Repo (önerilen) | `docs/canlifal-flutter-api-docs.txt` |
| Site (statik yayın gerekir) | https://canlifal.com/canlifal-flutter-api-docs.txt |

Site kökündeki `.txt` URL’si Next.js’te `[customSlug]` yüzünden **404 HTML** dönebilir. Dosyayı canlifal.com projesinde `public/canlifal-flutter-api-docs.txt` olarak ekleyin. API uçları (`/api/user/...`, `/api/users/lookup/...`) JSON ile çalışır; 401 oturum, 404 kullanıcı yok anlamına gelir.

## Uyarı

Dokümandaki bazı URL’ler ortamda 401 (oturum gerekli) veya 404 (kullanıcı yok) dönebilir — bu, uçların geçersiz olduğu anlamına gelmez; Bearer token veya site oturumu gerekir.
