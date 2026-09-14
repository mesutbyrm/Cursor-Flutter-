# Cursor Prompt — CanlıFal Flutter PK (Battle) Entegrasyonu

Aşağıdaki metni **olduğu gibi** Cursor'a (Agent / Composer modu) yapıştırın.
Aynı klasördeki `PK_ENTEGRASYON.md`, `dart/pk_models.dart` ve `dart/pk_service.dart` dosyalarını da projeye ekleyip Cursor'a bağlam olarak verin.

---

## 📋 KOPYALA-YAPIŞTIR PROMPT

```
Sen bu Flutter projesinde çalışan kıdemli bir mobil geliştiricisin. Görevin: CanlıFal uygulamasına PK (kapışma / battle) özelliğini HEM sesli sohbet odaları HEM de canlı yayınlar için eksiksiz entegre etmek.

## Bağlam dosyaları
- `docs/PK_ENTEGRASYON.md` — backend API sözleşmesi (TEK DOĞRULUK KAYNAĞI). Endpoint, istek/yanıt gövdeleri, tüm hata kodları, durum makinesi, SSE olayları burada.
- `lib/features/pk/data/pk_models.dart` — hazır veri modelleri (verildi, gerekirse genişlet).
- `lib/features/pk/data/pk_service.dart` — hazır API istemcisi (verildi, gerekirse genişlet).

Bu dosyalardaki endpoint yolları, alan adları ve hata kodlarını ASLA tahminle değiştirme. Sözleşmede olmayan bir alan uydurma.

## Temel kurallar
1. Backend: https://canlifal.com — tüm PK uçları `Authorization: Bearer <accessToken>` ister.
2. Mobilde TERCİH EDİLEN uç `/api/live/pk`'dır: oda ve yayın ayrımını backend çözer, yanıt `{success, data}` zarflıdır.
   Yalnız şu iki durumda `/api/chat/rooms/{roomId}/pk` kullan:
   - oda içi kullanıcı-vs-kullanıcı PK (`action: "create_user"`)
   - `start` / `pause` / `resume` kontrolleri
3. `/api/video-streams/pk` ve `/api/chat/rooms/{roomId}/pk` yanıtları ZARFSIZ döner (doğrudan nesne, hatada `{"error": "..."}`). İki farklı yanıt şeklini de doğru parse et.
4. PK durumları: pending, starting, active, paused, completed, cancelled, rejected, expired.
   `pending` bir PK `end` ile BİTİRİLEMEZ → gönderen `cancel`, alıcı `reject` kullanır.
5. Davet zaman aşımı 60 saniye. Geri sayımı `endsAt`/`expiresAt` eksi `serverNow` farkından hesapla — cihaz saatine ASLA güvenme.
6. Skor hediyelerle otomatik artar; uygulama skor endpoint'ini ÇAĞIRMAZ (admin'e özeldir, 403 döner).
7. PK başlatma butonu SADECE oda sahibi / yayıncıya gösterilir. Misafir veya co-host'ta gizle.

## Yapılacaklar

### 1. Veri katmanı
- `pk_models.dart` ve `pk_service.dart` dosyalarını `lib/features/pk/data/` altına yerleştir.
- Projedeki mevcut HTTP istemcisine (Dio/http wrapper) ve token yenileme (interceptor) mekanizmasına bağla. Servisin kendi `http` çağrısını projenin ortak istemcisiyle değiştir.
- `ApiEndpoints` sınıfı varsa PK sabitlerini oraya taşı, sözleşmedeki yollarla birebir aynı tut.

### 2. State yönetimi
- Projede hangi çözüm kullanılıyorsa (Riverpod / Bloc / Provider) ona uygun bir `PkController` yaz.
- Tutulacak state: `PkBattle? battle`, `List<PkCandidate> candidates`, `bool loading`, `String? error`, `Duration remaining`, `bool selfBusy`.
- Metotlar: `loadState(contextId)`, `loadCandidates()`, `create(targetId, duration)`, `accept()`, `reject()`, `cancel()`, `end()`, `startCountdown()`, `dispose()`.
- Sunucu-istemci saat farkını `serverNow` ile bir kez hesapla (`clockSkew`) ve tüm geri sayımlarda uygula.

### 3. SSE dinleme
- Oda ve yayın SSE akışlarında olay adı `pk` olan mesajları dinle; gövdeyi `PkEvent.fromJson` ile parse et.
- Oda kanalındaki `pk_invite` tipli `room_event` ile davet modalini aç.
- Bağlantı koparsa: yeniden bağlan + `GET /api/live/pk?roomId=...` ile tam senkron yap. `data == null` ise yerel PK state'ini temizle.

### 4. UI bileşenleri (`lib/features/pk/presentation/`)
- `pk_start_sheet.dart` — aday listesi (avatar, ad, izleyici/oda bilgisi), süre seçici (60–600 sn, varsayılan 180), "PK Gönder" butonu. `selfBusy` ise buton pasif; liste boşsa "Şu an PK yapılabilecek kimse yok".
- `pk_invite_dialog.dart` — gelen davet: rakip avatarı + adı, 60 sn dairesel geri sayım, Kabul / Reddet.
- `pk_pending_banner.dart` — gönderen taraf: "Yanıt bekleniyor · 00:47" + İptal.
- `pk_countdown_overlay.dart` — `starting` durumu için tam ekran 5-4-3-2-1 animasyonu.
- `pk_score_bar.dart` — aktif PK: iki taraflı oransal skor barı, her iki tarafın avatar+adı, kalan süre. `paused` ise donuk görünüm + "Duraklatıldı" rozeti.
- `pk_result_overlay.dart` — `completed`: kazanan animasyonu; `isDraw` ise "Berabere". 5 sn sonra otomatik kapanır.
- Tüm bileşenler hem oda ekranında hem yayın ekranında yeniden kullanılabilir olmalı — ekranın tipi sadece contextId ve buton görünürlüğünü etkiler.

### 5. Ekranlara bağlama
- Sesli oda ekranı: sahibe ⚔️ PK butonu, `pk_score_bar` üstte, davet modali, `create_user` için koltuktaki kullanıcıya uzun basınca "Bu kullanıcıyla PK" seçeneği (taraf başına max 4 kişi, herkes odada olmalı).
- Canlı yayın ekranı: yayıncıya ⚔️ PK butonu, aynı overlay'ler, PK aktifken ekran ikiye bölünmüş skor barı.

### 6. Hata yönetimi (kod → kullanıcı mesajı)
Her hata kodu için Türkçe kullanıcı mesajı üret; asla ham kodu gösterme:
- NOT_OWNER / NOT_STREAM_OWNER → "PK başlatma yetkiniz yok"
- ROOM_INACTIVE / STREAM_NOT_LIVE → "Yayınınız kapanmış, tekrar başlatın"
- ROOM_NOT_FOUND / STREAM_NOT_FOUND → "Oturum bulunamadı, sayfayı yenileyin"
- TARGET_NOT_FOUND / TARGET_INACTIVE / TARGET_NOT_LIVE → "Rakip artık yayında değil" + aday listesini yenile
- PK_EXISTS → "Zaten aktif bir PK var"
- SELF_PK → "Kendinizle PK yapamazsınız"
- PK_EXPIRED → "Davet zaman aşımına uğradı"
- PK_NOT_PENDING → "Bu davet zaten yanıtlanmış"
- RATE_LIMITED → "Çok hızlı denediniz, biraz bekleyin" + butonu 30 sn kilitle, OTOMATİK RETRY YAPMA
- 409 "PK durumu değişti, tekrar deneyin" → sessizce GET ile state'i yenile

### 7. Testler
- `test/features/pk/pk_service_test.dart`: mock HTTP ile create/accept/reject/cancel/end, zarflı ve zarfsız yanıtların parse'ı, her hata kodunun doğru istisnaya dönüşmesi.
- `test/features/pk/pk_state_test.dart`: durum makinesi geçişleri; `pending → end` reddedilmeli, `pending → cancel/reject` kabul edilmeli.

## Teslim
1. `flutter pub get`
2. `flutter analyze` — sıfır hata
3. `flutter test` — tüm testler geçmeli
4. `flutter build apk --release`
5. Değişen/eklenen dosyaların listesini ve her birinin ne yaptığını özetle.

Önce yapacağın değişikliklerin dosya bazlı planını çıkar, sonra uygula. Mevcut mimariye ve isimlendirme kurallarına uy; projede olmayan bir paket ekleme (SSE için zaten kullanılan çözümü kullan).
```

---

## Kurulum adımları

1. `PK_ENTEGRASYON.md` dosyasını Flutter projenizde `docs/` klasörüne kopyalayın.
2. `dart/pk_models.dart` ve `dart/pk_service.dart` dosyalarını `lib/features/pk/data/` altına kopyalayın.
3. Cursor'da Composer'ı açın, bu üç dosyayı bağlam olarak ekleyin (`@docs/PK_ENTEGRASYON.md` vb.).
4. Yukarıdaki promptu yapıştırıp çalıştırın.
5. Cursor plan sunduğunda onaylayın; üretilen kodda endpoint yollarının sözleşmeyle aynı olduğunu **gözle doğrulayın**.

## Doğrulama kontrol listesi

- [ ] Oda sahibi olmayan kullanıcıda ⚔️ butonu görünmüyor
- [ ] Aday listesi yalnız canlı/aktif ve PK'da olmayan taraflar gösteriyor
- [ ] Davet 60 sn sonra kendiliğinden kapanıyor
- [ ] Gönderen `cancel`, alıcı `reject` kullanıyor (`end` değil)
- [ ] Geri sayım `serverNow` farkı ile hesaplanıyor
- [ ] SSE koptuğunda `GET /api/live/pk` ile tam senkron yapılıyor
- [ ] 429 sonrası otomatik retry YOK
- [ ] Oda↔oda, yayın↔yayın ve oda↔yayın (karışık) PK'lar çalışıyor
