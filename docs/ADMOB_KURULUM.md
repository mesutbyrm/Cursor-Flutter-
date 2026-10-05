# AdMob kurulumu — reklamlar neden görünmüyor, nasıl açılır

## Mevcut durum (kodda)
- Uygulama kimliği: `ca-app-pub-1362974509433002~1394571120` (AndroidManifest ile aynı)
- Tek reklam birimi: **Ödüllü geçiş** `ca-app-pub-1362974509433002/8698346072` (`mobile/lib/features/fortune/core/admob_config.dart`)
- Debug/profile derlemede Google test birimi, release'te üretim birimi kullanılır
- Site: `https://canlifal.com/app-ads.txt` yayında (`google.com, pub-1362974509433002, DIRECT, f08c47fec0942fa0`)
- Sunucu tarafı: `/api/ads/ssv/admob` (SSV), `/api/ads/reward-callback`, ayarlar `ad_credits_per_watch` (=10) ve `admob_ssv_grant_credits` (=1)

## Reklam görünmemesinin olağan nedenleri (sırayla kontrol edin)
1. **AdMob'da uygulama "Hazır değil / İnceleniyor"**: AdMob → Uygulamalar → uygulamanın durumu. Play Store'da yayında olmayan veya reddedilen (taslak) uygulamada üretim birimleri çoğu zaman *dolu envanter yok* (no fill, hata kodu 3) döner. Uygulama mağazaya bağlanıp onaylanana kadar reklam gelmeyebilir.
2. **Ödeme / kimlik doğrulama** AdMob hesabında tamamlanmamış olabilir (AdMob → Ödemeler).
3. **app-ads.txt** AdMob'da doğrulanmamış: AdMob → Uygulamalar → app-ads.txt → "Doğrula".
4. Yeni oluşturulan birimler birkaç saat–2 gün içinde dolmaya başlar.
5. GitHub'dan yüklenen APK, Play'den kurulmadığı için bazı hesaplarda *dolu envanter yok* verebilir; test için `--dart-define=ADMOB_REWARDED_UNIT_ID=ca-app-pub-3940256099942544/5354046379` (Google test birimi) ile derleyin.

## Başka reklam türleri nasıl eklenir
AdMob → Uygulamalar → Canlifal → **Reklam birimleri → Reklam birimi ekle**:
- **Geçiş (Interstitial)**: geçiş ekranları için → birim kimliğini bana verin, `InterstitialAd` ile ekran geçişlerine bağlarım
- **Banner**: sayfa altı → `BannerAd`
- **Native**: akış içi → `NativeAd`
- **Ödüllü**: video izle-kazan (mevcut ödüllü geçiş birimi bunun için kullanılıyor)

Her birimin kimliği `ca-app-pub-1362974509433002/xxxxxxxxxx` biçimindedir; kimlikleri verdiğinizde `AdMobConfig` içine eklenir.

## Siteye (canlifal.com) uygulama
- `app-ads.txt` zaten yayında (yukarıdaki satır)
- Ödül sunucuda **yalnızca geçerli SSV geri çağrısıyla** verilir: AdMob → ödüllü birim → Düzenle → *Sunucu taraflı doğrulama* → URL: `https://canlifal.com/api/ads/ssv/admob`, ödül: 10
- Yönetici ayarları: `ad_credits_per_watch=10`, `admob_ssv_grant_credits=1`
