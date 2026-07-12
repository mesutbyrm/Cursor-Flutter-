# Admin Hediye Yönetimi — Kök Neden ve Onarım Raporu

**Tarih:** 12 Temmuz 2026  
**Mobil sürüm:** `1.0.12+16`

## Gerçek neden

Yeni hediye akışındaki sorun tek bir backend hatası değil, create/upload
zincirindeki dört doğrulanmış istemci hatasının birleşimiydi:

1. `Kaydet`, `POST /api/admin/gifts` Future'ını operasyon seviyesinde
   timeout/cancel olmadan bekliyordu. Future sonuçlanmadığında `_saving=true`
   kalıyordu.
2. R2 presign veya PUT başarısız olduğunda `uploadAsset()` hata fırlatmak yerine
   sessizce `null` dönüyordu. Kullanıcı gerçek hatayı göremiyordu.
3. Presign yanıtındaki `publicUrl`, create DTO'daki `imageCloudPath` /
   `thumbnailCloudPath` / `animationCloudPath` / `soundCloudPath` alanlarına
   yazılıyordu. CDN URL'si ile R2 nesne anahtarı birbirine karışıyordu.
4. Başarılı response içindeki kayıt doğrulanmıyor, admin/public katalog
   yenilemeleri beklenmiyor ve HTTP disk cache temizlenmiyordu. Yeni kayıt
   eski katalog cache'i nedeniyle görünmeyebiliyordu.

## Onarım

- Create/update isteklerine 25 saniyelik operasyon timeout'u, `CancelToken`,
  send/receive timeout ve debug request log'u eklendi.
- Create artık yalnızca HTTP `200/201` ve geçerli `gift.id` döndüğünde başarılı
  kabul ediliyor.
- Upload artık eksik presign URL, eksik cloud path ve başarısız PUT için gerçek
  `ApiException` üretiyor.
- Dosya `readAsBytes()` yerine stream ile R2/S3'ye gönderiliyor.
- `AdminGiftUploadedAsset` ile `cloudPath` ve `publicUrl` ayrıldı:
  - DTO'ya yalnız `cloudPath`
  - UI önizlemesine `publicUrl`
- Upload sürerken Kaydet engellendi.
- `finally` ve timeout testiyle loading'in her hata yolunda kapandığı doğrulandı.
- Create sonrası admin katalog, canlı yayın hediye kataloğu ve sesli oda
  hediye kataloğu invalidate ediliyor.
- HTTP memory + disk katalog cache'i temizleniyor.
- Admin katalog reload'u await ediliyor ve kullanıcıya başarı mesajı gösteriliyor.
- Backend 403 mesajı mevcutsa generic hata yerine gerçek mesaj gösteriliyor.

## Canlı API gözlemi

12 Temmuz 2026 UTC ölçümü:

| İstek | Sonuç | Süre |
|---|---:|---:|
| `GET https://canlifalapi.abacusai.app/api/admin/gifts` | 401 (auth zorunlu) | 0.393 sn |
| `POST https://canlifalapi.abacusai.app/api/admin/gifts` (JWT yok) | 401 | 0.118 sn |
| `OPTIONS .../api/admin/gifts` | 204 | 0.404 sn |
| `GET https://canlifalapi.abacusai.app/api/v1/health` | 200; Redis/DB connected | 0.102 sn |
| `GET https://canlifal.com/api/video-streams/gifts?platform=mobile` | 200 JSON | 0.375 sn |

Bu ölçümler doğru hostun ayakta, route'un mevcut, auth'un zorunlu ve public
kataloğun JSON döndürdüğünü doğruluyor.

## Test sonuçları

```text
flutter analyze
0 error / 0 warning

flutter test \
  test/features/gifts/admin_gift_remote_datasource_test.dart \
  test/core/network/api_backend_router_test.dart
12 test passed

npm run typecheck
passed

npm test
1 test passed

flutter build apk --debug
bloklandı: Cloud ortamında Android SDK bulunmuyor
```

Yeni test kapsamı:

- POST create JSON ve `/api/admin/gifts` path'i
- HTTP 201 + geçerli kayıt parse
- Geçersiz 2xx response'un reddedilmesi
- Takılı request timeout/cancel
- Loading state'in kapanması
- Presign → PUT → cloudPath/publicUrl ayrımı
- Eksik R2 cloudPath'in gerçek hata üretmesi

## Veritabanı / R2 / web doğrulama sınırı

Bu repo production `canlifalapi.abacusai.app` admin route kaynak kodunu,
production Prisma şemasını veya R2 credentials'ını içermiyor. Yerel `api/`
yalnız public gift catalog/send mirror'ını içeriyor; `/api/admin/gifts` burada
implement edilmemiş. Yerel PostgreSQL `localhost:5432` çalışmadığı ve Docker
binary'si bulunmadığı için yerel Prisma roundtrip başlatılamadı.

Production admin JWT olmadan production'a test hediyesi yazmak güvenli veya
mümkün değildir. Bu nedenle:

- Production DB'ye test kaydı yazılmadı.
- Production R2'ye test dosyası yüklenmedi.
- Flutter zinciri fake HTTP/R2 adapter'larıyla başarılı create/upload olarak
  doğrulandı.
- Gerçek admin hesabıyla ilk kayıt işleminde `[AdminGift]` logları request,
  HTTP status, gift id, süre, R2 cloud path ve PUT status'u gösterecek.
- Create sonrası public Flutter katalogları cache atlayarak yenilenecek.
- Web görünümü production servisinin aynı DB/cache invalidation davranışına
  bağlıdır; bu repo web admin backend'ini içermediğinden istemci tarafından
  garanti edilemez.
- Android APK derlemesi kod hatası nedeniyle değil, bu Cloud imajında Android
  SDK bulunmadığı için başlatılamadı (`No Android SDK found`).

