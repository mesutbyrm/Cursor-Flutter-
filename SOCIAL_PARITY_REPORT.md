# Sosyal Parite Raporu

Tarih: 2026-06-10  
Kapsam: Canlifal.com sosyal özellikleri ile Flutter uygulamasının sosyal modülü.

## Özet

Bu parçada uygulama kodunda sosyal hikaye paritesi güçlendirildi. Sosyal akış, beğeni, yorum, takip, takipçi listesi, profil sayfası ve paylaşım oluşturma Flutter tarafında zaten mevcut olduğu için davranışları korunmuştur. Webde olup Flutterda kısmi kalan hikaye grup/detay davranışı mevcut API'lerle geliştirilmiştir.

## Değiştirilen sosyal davranışlar

### 1. Hikaye grupları

- Webde mevcut mu? Evet
- Flutterda önceki durum: Kısmi; story ring sadece tek `previewUrl` ile açılıyordu.
- Yapılan değişiklik:
  - `SocialStoryRingEntity` artık `stories` listesi taşır.
  - `/api/stories` veya `/api/social/stories` yanıtındaki `storyGroups[].stories[]` öğeleri parse edilir.
  - Her story için id, media URL, type, caption ve createdAt alanları okunur.
- Kullanılan API'ler:
  - `GET /api/stories`
  - `GET /api/social/stories`
- Kullanılan socket eventleri: Yok
- Kullanılan veritabanı modelleri:
  - `UserStory`

### 2. Hikaye görüntüleyici

- Webde mevcut mu? Evet
- Flutterda önceki durum: Kısmi; tek görsel önizleme açılıyordu.
- Yapılan değişiklik:
  - `StoryViewerPage` çoklu hikaye gezintisini destekler.
  - Sol tarafa dokununca önceki, sağ tarafa dokununca sonraki story açılır.
  - Hikaye ilerleme çubukları eklendi.
  - Caption gösterimi eklendi.
  - Profil bağlantısı korundu.
- Kullanılan API'ler:
  - Görüntüleyici mevcut story verisini kullanır; ek API çağrısı yapmaz.
- Kullanılan socket eventleri: Yok
- Kullanılan veritabanı modelleri:
  - `UserStory`

### 3. Hikaye oluşturma fallback

- Webde mevcut mu? Evet
- Flutterda önceki durum: `POST /api/stories` deneniyordu.
- Yapılan değişiklik:
  - Hikaye görseli önce `POST /api/stories` endpointine gönderilir.
  - Başarısız olursa web kullanıcı endpointi olan `POST /api/user/story` fallback olarak denenir.
  - Multipart payload içine `image`, `media`, `mediaType=image`, `type=image` alanları eklenir.
- Kullanılan API'ler:
  - `POST /api/stories`
  - `POST /api/user/story`
- Kullanılan socket eventleri: Yok
- Kullanılan veritabanı modelleri:
  - `UserStory`

## Mevcut ve korunan sosyal özellikler

### Akış (Feed)

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `GET /api/social/posts`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `SocialPost`

### Paylaşım oluşturma

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Metin/görsel paylaşım mevcut.
- Kullanılan API'ler:
  - `POST /api/social/posts`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `SocialPost`

### Beğeni

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `POST /api/social/posts/{postId}/likes`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `SocialLike`

### Yorum

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `GET /api/social/posts/{postId}/comments`
  - `POST /api/social/posts/{postId}/comments`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `SocialComment`

### Takip et / takipten çık

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `POST /api/users/{userId}/follow`
  - `POST /api/user/{userId}/follow`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `Follow`

### Takipçi / takip edilen listesi

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `GET /api/users/{userId}/followers`
  - `GET /api/users/{userId}/following`
  - `GET /api/user/followers`
  - `GET /api/user/following`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `Follow`

### Profil sayfası ve profil paylaşımları

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Durum: Mevcut davranış korundu.
- Kullanılan API'ler:
  - `GET /api/users/{userId}`
  - `GET /api/users/lookup/{username}`
  - `GET /api/users/search`
  - `GET /api/social/posts?authorId={userId}`
- Kullanılan socket eventleri: Yok
- Veritabanı modelleri:
  - `User`
  - `ProfileView`
  - `SocialPost`

## Kalan sosyal gap'ler

### 1. Profil ziyaretleri

- Webde mevcut mu? Evet, envanterde `ProfileView` modeli var.
- Flutterda mevcut mu? Kısmen; profil açıldığında kullanıcı bilgisi çekiliyor.
- Eksik kalan:
  - Üretim envanterinde ayrı profil ziyaret API endpointi listelenmemiştir.
  - Bu nedenle yeni API uydurulmadı.
- Not:
  - Eğer webde profil görüntüleme `GET /api/users/{id}` içinde otomatik kaydediliyorsa Flutter zaten bu çağrıyı yapar.
  - Ayrı endpoint varsa dokümante edilince mobil datasource'a eklenmelidir.

### 2. DM realtime

- Webde mevcut mu? Mesaj sistemi mevcut.
- Flutterda mevcut mu? REST tabanlı mevcut.
- Eksik kalan:
  - DM için Socket.IO realtime event sözleşmesi repoda doğrulanamadı.
  - Yeni socket event uydurulmadı.

### 3. Ünlüler / Fan Club sosyal detayları

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik kalan:
  - Ünlü detay, ünlü takip, fan club join, fan club post ve anket detayları tam native değildir.
  - Bu kapsam ayrı bir sosyal alt parite parçası olarak ele alınmalıdır.

## Değişen dosyalar

- `mobile/lib/features/social/domain/entities/social_story_ring_entity.dart`
- `mobile/lib/features/social/data/datasources/social_remote_datasource.dart`
- `mobile/lib/features/social/presentation/pages/story_viewer_page.dart`
- `mobile/lib/core/network/api_endpoints.dart`
- `mobile/pubspec.yaml`
- `mobile/CHANGELOG.md`
- `APK_DOWNLOAD.md`

## Doğrulama planı

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug --dart-define=API_BASE_URL=https://canlifal.com`
