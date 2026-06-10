# Canlifal Ürün İyileştirme ve Büyüme Roadmap Raporu

Tarih: 2026-06-10  
Kapsam: Canlifal web deneyimi ile Flutter mobil uygulamasını ürün sahibi bakışıyla büyüme, gelir, bağlılık ve davranış eşitliği açısından değerlendirme.

## 1. Puanlama yöntemi

Her öneri 1-5 arası puanlandı.

- **Kullanıcı memnuniyeti:** 5 = kullanıcı değerini çok artırır.
- **Gelir potansiyeli:** 5 = doğrudan Jeton/VIP/hediye gelirini artırır.
- **Geliştirme maliyeti:** 1 = düşük, 5 = yüksek.
- **Teknik risk:** 1 = düşük, 5 = yüksek.
- **Bakım maliyeti:** 1 = düşük, 5 = yüksek.

Toplam skor, maliyet/risk kalemleri ters çevrilerek hesaplandı:

`Toplam = Memnuniyet + Gelir + (6 - Geliştirme Maliyeti) + (6 - Teknik Risk) + (6 - Bakım Maliyeti)`

Bu nedenle en yüksek skor; yüksek fayda, düşük maliyet ve düşük risk kombinasyonunu gösterir.

## 2. Kategori bazlı öneriler

| Kategori | Öneri | Sorun | Neden geliştirilmeli? | Kullanıcı faydası | Gelir etkisi | Zorluk |
|---|---|---|---|---|---|---|
| Kullanıcı bağlılığı | Günlük görev sistemi | Kullanıcı her gün ne yapacağını net görmüyor | Günlük alışkanlık oluşturur | Net hedef, ödül ve geri dönüş sebebi | Orta-yüksek | Orta |
| Kullanıcı bağlılığı | Günlük giriş ödülü | Ana sayfadaki ödül görünürlüğü sınırlı | Retention döngüsünü güçlendirir | Her gün uygulamaya girme motivasyonu | Orta | Düşük |
| Oyunlaştırma | Seviye ve XP sistemi | Etkileşimlerin uzun vadeli anlamı zayıf | Profil ilerlemesi sosyal statü yaratır | Emek görünür olur | Orta-yüksek | Orta |
| Oyunlaştırma | Rozet sistemi | Başarılar koleksiyonlaşmıyor | Sosyal kanıt ve paylaşım motivasyonu sağlar | Kullanıcı kimliği güçlenir | Orta | Düşük-orta |
| Sesli odalar | Oda seviyesi sistemi | Odaların gelişim hissi yok | Oda sahiplerini aktif tutar | Daha kaliteli oda yönetimi | Yüksek | Orta-yüksek |
| Sesli odalar | Haftalık oda liderlik tablosu | Aktif odalar öne çıkmıyor | Rekabet ve keşfi artırır | Popüler odaları bulma kolaylığı | Yüksek | Orta |
| Sesli odalar | Süper moderatör sistemi | Moderasyon motivasyonu sınırlı | Güvenli topluluk ve yetki ekonomisi sağlar | Daha güvenli odalar | Orta | Orta |
| Sesli odalar | Oda başarı rozetleri | Oda başarıları görünür değil | Oda sahipleri için prestij yaratır | Odaya aidiyet | Orta | Orta |
| Hediye sistemi | Kombolu hediye serileri | Tekil hediye gönderimi seri heyecanı yaratmıyor | Canlı odada anlık harcama motivasyonu üretir | Daha eğlenceli hediye deneyimi | Çok yüksek | Orta |
| Hediye sistemi | Hediye görevleri | Hediye verme davranışı görevle yönlendirilmiyor | İlk harcama ve tekrar harcama oranını artırır | Ödüllü etkileşim | Yüksek | Orta |
| Hediye sistemi | Günlük ilk hediye bonusu | İlk hediye eşiği yüksek kalabiliyor | Günün ilk ödeme davranışını tetikler | Bonus hissi | Yüksek | Orta |
| Hediye sistemi | Hediye koleksiyon albümü | Alınan/verilen hediyeler koleksiyon değerine dönüşmüyor | Koleksiyon psikolojisi gelir artırır | Profil prestiji | Orta-yüksek | Orta |
| Premium | VIP+ üyelik | Mevcut üyelik avantajları daha net paketlenebilir | ARPU artırır | Ayrıcalıklı görünüm ve giriş efekti | Çok yüksek | Orta-yüksek |
| Premium | Profil çerçeveleri | Premium statü profil görünümünde sınırlı | Görsel statü satışını güçlendirir | Kişiselleştirme | Yüksek | Düşük-orta |
| Premium | Özel giriş efektleri | Odaya giriş anı yeterince monetized değil | Sesli odalarda statü etkisi büyüktür | Fark edilme | Yüksek | Orta |
| Premium | Ses efektleri | Premium etkileşimler işitsel olarak ayrışmıyor | Hediye/VIP algısını güçlendirir | Daha eğlenceli deneyim | Orta | Düşük-orta |
| Premium | Premium oda temaları | Oda sahipleri görsel farklılaşma satın alamıyor | Oda sahiplerinden tekrar gelir sağlar | Oda kimliği | Yüksek | Orta |
| Sosyal | Arkadaş davet sistemi | Davet akışı ayrı sayfada var ama growth döngüsüne bağlı değil | Viral büyümeyi artırır | Arkadaşla birlikte kullanım | Orta-yüksek | Düşük |
| Canlı yayın | PK turnuvaları | PK tekil savaş olarak kalıyor | Etkinlik takvimi ve rekabet yaratır | İzleme sebebi | Yüksek | Yüksek |
| Sesli odalar | Oda savaşları | Odalar arası rekabet eksik | Topluluk bazlı harcama ve bağlılık sağlar | Takım hissi | Çok yüksek | Yüksek |
| Bildirimler | Akıllı görev bildirimi | Bildirimler görev/ödül tamamlamaya yeterince bağlanmıyor | Dönüş oranını artırır | Hatırlatma ve tamamlanma hissi | Orta | Orta |
| UX | Tek büyüme merkezi | Görev, davet, rozet, ödül ve VIP farklı yerlere dağılmış | Kullanıcıya tek ilerleme ekranı verir | Anlaşılır hedefler | Orta-yüksek | Düşük |

## 3. Puan tablosu

| # | Özellik | Memnuniyet | Gelir | Geliştirme maliyeti | Teknik risk | Bakım | Toplam |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | Tek büyüme merkezi | 5 | 4 | 1 | 1 | 2 | **26** |
| 2 | Günlük giriş ödülü | 5 | 3 | 1 | 1 | 2 | **25** |
| 3 | Arkadaş davet sistemi büyüme entegrasyonu | 4 | 4 | 1 | 1 | 2 | **24** |
| 4 | Rozet sistemi | 5 | 3 | 2 | 2 | 2 | **23** |
| 5 | Günlük görev sistemi | 5 | 4 | 3 | 2 | 2 | **23** |
| 6 | Seviye ve XP sistemi | 5 | 4 | 3 | 2 | 3 | **22** |
| 7 | Profil çerçeveleri | 4 | 5 | 2 | 2 | 3 | **22** |
| 8 | Hediye koleksiyon albümü | 4 | 4 | 3 | 2 | 2 | **21** |
| 9 | Haftalık oda liderlik tablosu | 4 | 5 | 3 | 3 | 2 | **21** |
| 10 | Kombolu hediye serileri | 5 | 5 | 4 | 3 | 3 | **20** |
| 11 | Günlük ilk hediye bonusu | 4 | 5 | 3 | 3 | 3 | **20** |
| 12 | Premium oda temaları | 4 | 5 | 3 | 3 | 3 | **20** |
| 13 | Oda başarı rozetleri | 4 | 4 | 3 | 3 | 2 | **20** |
| 14 | VIP+ üyelik | 4 | 5 | 4 | 3 | 3 | **19** |
| 15 | Özel giriş efektleri | 4 | 5 | 4 | 3 | 3 | **19** |
| 16 | Hediye görevleri | 4 | 5 | 4 | 3 | 3 | **19** |
| 17 | Oda seviyesi sistemi | 4 | 4 | 4 | 3 | 3 | **18** |
| 18 | Süper moderatör sistemi | 4 | 3 | 3 | 3 | 3 | **18** |
| 19 | Akıllı görev bildirimi | 4 | 3 | 3 | 3 | 3 | **18** |
| 20 | Premium ses efektleri | 3 | 4 | 2 | 2 | 3 | **18** |
| 21 | PK turnuvaları | 5 | 5 | 5 | 4 | 4 | **18** |
| 22 | Oda savaşları | 5 | 5 | 5 | 4 | 4 | **18** |

## 4. En yüksek puanlı 10 özellik

1. Tek büyüme merkezi
2. Günlük giriş ödülü
3. Arkadaş davet sistemi büyüme entegrasyonu
4. Rozet sistemi
5. Günlük görev sistemi
6. Seviye ve XP sistemi
7. Profil çerçeveleri
8. Hediye koleksiyon albümü
9. Haftalık oda liderlik tablosu
10. Kombolu hediye serileri

## 5. Roadmap

### PHASE_1 — Düşük riskli retention ve görünür ilerleme

1. Tek büyüme merkezi
2. Günlük giriş ödülü görünürlüğü
3. Arkadaş davet sistemi entegrasyonu
4. Rozet albümü
5. Mevcut istatistiklerden seviye/XP görünümü

**Mobil implementasyon durumu:** Başlandı. `Görevler & Rozetler` ekranı eklendi; mevcut `profileStatsProvider`, `homeDailyRewardsProvider`, `walletBalancesProvider` ve `referralInfoProvider` verileriyle görev, XP, seviye ve rozet görünümü üretir. Yeni API veya database tablosu eklenmedi.

### PHASE_2 — Gelir ve sosyal statü

1. Profil çerçeveleri
2. Hediye koleksiyon albümü
3. Günlük ilk hediye bonusu
4. Premium oda temaları
5. VIP+ üyelik avantajlarının mobilde tek paket olarak sunulması

### PHASE_3 — Rekabet ve büyük etkinlikler

1. Haftalık oda liderlik tablosu
2. Kombolu hediye serileri
3. Oda seviyesi sistemi
4. PK turnuvaları
5. Oda savaşları

## 6. Ürün sahibi öncelik notu

Canlifal gibi sesli sohbet + canlı yayın + fal platformlarında büyümenin ana kaldıraçları şunlardır:

- Kullanıcıya her gün geri dönme sebebi vermek.
- Jeton/VIP harcamasını sosyal statüye bağlamak.
- Odaları ve yayınları rekabet alanına dönüştürmek.
- Davet ve arkadaşlık akışını görev/ödül sistemiyle birleştirmek.

Bu nedenle ilk implementasyon, düşük teknik riskle yüksek görünür fayda sağlayan **Tek Büyüme Merkezi + Günlük Görev + XP + Rozet + Davet entegrasyonu** olarak seçildi.

## 7. Teknik sınırlar ve riskler

- Bu rapor, yeni API ve yeni database tablosu oluşturmadan uygulanabilecek ilk adımı önceliklendirdi.
- Mobilde gösterilen XP/seviye ilk aşamada mevcut sinyallerden hesaplanan istemci görünümüdür; global sıralama, oda savaşı, hediye combo serisi ve PK turnuvası gibi özellikler kalıcı sunucu state'i gerektirdiği için sonraki fazlarda web/API sözleşmesi doğrulanarak ilerlemelidir.
- Görev tamamlama/ödül claim davranışı, mevcut web endpointleri bulunmadan mobilde kalıcı hale getirilmemelidir.
