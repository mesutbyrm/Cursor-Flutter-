# Fal & Tarot Parite Raporu

Tarih: 2026-06-10  
Kapsam: Canlifal.com Fal & Tarot sistemi ile Flutter uygulaması.

## Yapılan değişiklikler

### Kahve Falı

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Yapılan:
  - `kahve-fali` akışı artık önce `POST /api/fortunes/kahve-fali` endpointini dener.
  - API geçici hata verirse mevcut hazır/yerel yorum fallback'i korunur.
- Kullanılan API:
  - `POST /api/fortunes/kahve-fali`
  - `POST /api/user/fortunes`
- Socket/SSE:
  - Webde LLM/SSE streaming var; Flutter bu parçada POST API sonucunu kullanır.
- DB modelleri:
  - `Fortune`
  - `FortuneRating`

### Tarot

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Yapılan:
  - `tarot` mobil slug'ı web endpointi olan `tarot-fali` ile eşleştirildi.
  - Fal oturumu önce `POST /api/fortunes/tarot-fali` çağırır.
- Kullanılan API:
  - `POST /api/fortunes/tarot-fali`
  - `POST /api/user/fortunes`
- Socket/SSE:
  - Webde streaming olabilir; Flutter POST sonucunu işler.
- DB modelleri:
  - `Fortune`
  - `FortuneRating`

### Yıldızname

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen vardı
- Yapılan:
  - Flutter katalog başlığı `Yıldızname` olarak güncellendi.
  - `yildizname`, `yildizname-fali`, `yıldızname` alias'ları `yildiz-haritasi` akışına bağlandı.
  - Mobil `yildiz-haritasi` web `burc-yorumu`, `yildizname` web `dogum-haritasi` endpointleriyle eşleştirildi.
- Kullanılan API:
  - `POST /api/fortunes/burc-yorumu`
  - `POST /api/fortunes/dogum-haritasi`
  - `POST /api/user/fortunes`
- Socket/SSE:
  - Yok / POST sonucu
- DB modelleri:
  - `Fortune`

### Hazır Yorumlar

- Webde mevcut mu? Evet, hazır/örnek yorum içerikleri ve AI öneri bölümleri var
- Flutterda mevcut mu? Yeni eklendi
- Yapılan:
  - `/fortune/ready` route'u eklendi.
  - `FortuneReadyReadingsPage` oluşturuldu.
  - Kahve, Tarot, Yıldızname ve Aşk hazır yorum kartları eklendi.
  - Kartlar ilgili fal oturumuna yönlendirir.
- Kullanılan API:
  - Hazır yorum ekranı statik örnek içerik gösterir; fal başlatıldığında ilgili `/api/fortunes/*` endpointi kullanılır.
- Socket/SSE:
  - Yok
- DB modelleri:
  - Yok

### Fal Geçmişi

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Vardı
- Yapılan:
  - Eksik route tamamlandı: `/fortune/history/:id`
  - Sonuç ekranındaki geçmiş detay butonu artık `FortuneDetailPage` ile çalışır.
- Kullanılan API:
  - `GET /api/user/fortunes`
  - `GET /api/user/fortunes/{id}`
  - `POST /api/user/fortunes`
- Socket/SSE:
  - Yok
- DB modelleri:
  - `Fortune`
  - `UserFortune`

### Satın Alma İşlemleri

- Webde mevcut mu? Evet
- Flutterda mevcut mu? Vardı
- Yapılan:
  - Fal API kredi/Jeton yetersizliği döndürürse kullanıcıya satın alma bottom sheet'i gösterilir.
  - Kullanıcı `Jeton yükle` ile `/jeton-store` ekranına yönlendirilir.
  - Kullanıcı `Üyelik avantajlarını gör` ile `/premium-membership` ekranına yönlendirilir.
- Kullanılan API:
  - `GET /api/user/credits`
  - `GET /api/jeton`
  - `GET /api/membership/packages`
  - `POST /api/membership/purchase`
- Socket/SSE:
  - Yok
- DB modelleri:
  - `CreditTransaction`
  - `JetonTransaction`
  - `MembershipPlan`
  - `MembershipPurchase`

## Değişen dosyalar

- `mobile/lib/features/fortune/data/datasources/fortune_remote_datasource.dart`
- `mobile/lib/features/fortune/domain/repositories/fortune_repository.dart`
- `mobile/lib/features/fortune/data/repositories/fortune_repository_impl.dart`
- `mobile/lib/features/fortune/presentation/pages/fortune_session_page.dart`
- `mobile/lib/features/fortune/presentation/data/fortune_catalog.dart`
- `mobile/lib/features/fortune/presentation/pages/fortune_ready_readings_page.dart`
- `mobile/lib/features/fortune/presentation/pages/fortune_tarot_hub_page.dart`
- `mobile/lib/app/router/app_router.dart`
- `mobile/pubspec.yaml`
- `mobile/CHANGELOG.md`
- `APK_DOWNLOAD.md`

## Kalan gap'ler

- Webdeki gerçek SSE token streaming davranışı Flutter'da tam stream UI olarak uygulanmadı; bu parçada mevcut web POST endpointleri bağlandı.
- Görsel kahve fincanı ve el falı fotoğraf analizinde Flutter tarafında dosya yükleme UI'ı ayrı parça olarak ele alınmalı.
- Aura, kurşun dökme ve istihare gibi web fal türleri katalog alias/fallback ile kısmen kapsanır; özel UI'ları ayrı parça gerektirir.
