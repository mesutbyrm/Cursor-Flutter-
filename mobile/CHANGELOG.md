# Sürüm notları — canlifal_social

## 1.0.78+80 (2026-05-19)

### PART 3 — Premium sesli sohbet odası

- Responsive yarım daire 8 mikrofon + merkez host (`VoiceRoomResponsiveStage`)
- Konuşma glow + CustomPainter ses dalgası halkası
- VIP çerçeve, level rozeti, blur üst bar (oda adı, ID, online, takip, jeton)
- Blur sohbet + gradient mesajlar + hediye banner + emoji seçici
- Alt bar: büyük mikrofon, hediye, müzik, efekt, davet, ayarlar
- Yüzen parçacıklar + RepaintBoundary optimizasyonu

## 1.0.77+79 (2026-05-19)

### PART 2 — Premium keşfet / ana sayfa

- Galaksi arka plan, blur üst bar, cam arama
- 8 kategori (Gece, Oyun, Fal, Müzik, PK, VIP, Eğlence, Flört)
- Trend / Sesli / Canlı sekmeleri, neon oda kartları, online göstergesi
- Hikâye şeridi, VIP & trend odalar, canlı yayın carousel

## 1.0.76+78 (2026-05-19)

### PART 1 — Premium splash & auth (2026)

- Splash: galaksi gradient, neon glow, logo pulse, parçacıklar, Hero logo
- Giriş / kayıt: liquid glass kart, floating label input, neon CTA
- Google giriş; TikTok / Apple placeholder (yakında); misafir modu
- Paylaşılan `CosmicGalaxyBackground` (core premium_2026)

## 1.0.75+77 (2026-05-19)

### Sesli sohbet — Premium 2026

- Kozmik arka plan, yarım daire 8 mikrofon sahnesi, cam efektli üst/alt bar
- Sohbet klavyeye yapışık; mesajlar ses (LiveKit/TRTC) bağlanmasa da çalışır
- Keşfet: kategoriler + öne çıkan odalar; PK savaş ekranı (`/voice-room/:id/pk`)
- Gold VIP kapısı; alt barda **Jeton Al**; hediye şeridi
- API: oda `id`/`slug` tek kanonik anahtar (`resolveRoomId`) — presence, mesaj, socket

## 1.0.64+66 (2026-05-19)

### Ana sayfa ve Fal & Tarot düzeni

- Hikâyeler keşfet ana sayfaya taşındı; sosyal sekmesinden kaldırıldı
- «Canlı yayınlara katıl…» başlığı kaldırıldı
- Fal & Tarot altında canlı istatistikler + son 5 giriş
- Sohbet odaları tek sıra kaydırmalı; odadaki kullanıcı avatarları altta
- Fal & Tarot: fal türleri 3 sütunlu grid

## 1.0.63+65 (2026-05-19)

### Firebase / canlifal.com yapılandırması

- `scripts/sync-canlifal-config.sh` — resmi URL’lerden google-services, Admin SDK, API docs
- `google-services.json` → otomatik `FirebaseOptionsGenerated` + CI `GOOGLE_SERVICES_JSON_BASE64`
- Dokümantasyon: `docs/CANLIFAL_OFFICIAL_CONFIG.md`

## 1.0.62+64 (2026-05-19)

### Açılış, bildirimler ve sosyal

- Splash görseli ekrana sığdırılır (`BoxFit.contain`); Android native splash arka planı koyu tema
- Push: OneSignal/FCM tıklama yönlendirmesi, izin banner’ı ve token kaydı iyileştirmeleri
- Bildirimler ve jeton mağazası: kabukta ön yükleme, `keepAlive`, jeton sayfasında anında yedek paketler
- Sosyal: «Fal hikayeleri» kaldırıldı; paylaşım kartında profil + beğeni/yorum/izlenme tek kutuda

## 1.0.53+55 (2026-05-19)

### Açılış ve sosyal UX

- Mistik splash görseli tam ekran açılış
- Sosyal akış: her 2 gönderi arasında sesli sohbet odaları
- Paylaşım metni 250 karakter + «daha fazla»
- Profil üstüne tıklayınca paylaşan profili
- Kullanıcı profilinde TikTok tarzı paylaşım ızgarası

## 1.0.52+54 (2026-05-19)

### canlifal.com mobil JWT API

- Oturum: `POST /api/auth/mobile-register|login|google|tiktok|refresh`
- Profil ve bakiye: `GET /api/me` (Bearer)
- DM: `GET/POST /api/messages`, `GET/POST /api/messages/{userId}`
- Dio: 401 → `mobile-refresh`; WebView Google OAuth kaldırıldı
- Kayıt: `name`, `birthDate`, `birthTime`, `preferredLanguage`

## 1.0.47+49 (2026-05-22)

### Anlık push bildirimleri

- Mesaj, ödeme (admin onayı), canlı yayın → OneSignal yüksek öncelik
- Bildirime tıklayınca doğru ekrana yönlendirme
- API: `push_events`, `POST /api/video-streams/.../live-started`

## 1.0.46+48 (2026-05-22)

### Yayın (CI)

- `apk-latest` GitHub Release yayını düzeltildi (sürekli sürüm akışı)

## 1.0.45+47 (2026-05-19)

### OneSignal push

- SDK entegrasyonu; App ID: `578518ed-7b16-46a9-a1e6-7692d3ba55d8`
- Girişte `OneSignal.login(userId)`; token `POST /api/devices/fcm`
- Kurulum: `docs/ONESIGNAL_SETUP.md`

## 1.0.44+46 (2026-05-19)

### Android paket kimliği

- `applicationId` / Firebase paket adı: **`com.mesutbyrm.canlifal`** (önceki: `com.canlifal.canlifal_social`)
- iOS/macOS bundle ID aynı değere hizalandı
- Firebase Console’da yeni paket adıyla `google-services.json` indirilmeli

## 1.0.38+40 (2026-05-22)

### Jeton ödeme + CFC verisi

- Jeton talebi: `amount` + `coins` (canlifal.com eski API uyumu) — **Geçersiz miktar** düzeltmesi
- CFC ödeme ayarları yalnız siteden (`/api/payment/config`); bakiye metni API CFC
- Jeton paket grid: aralıklar kaldırıldı (bitişik kartlar)

## 1.0.37+39 (2026-05-22)

### Gold Üyelik + ödeme bilgileri

- Premium sayfa API/HTML hatasında varsayılan paketler (artık boş ekran yok)
- Üyelik satın alma: API yoksa WhatsApp/Papara/Havale ödeme akışı
- Varsayılan ödeme: WhatsApp 05327170173, Papara 1555517633, Garanti IBAN (Mesut bayram)

## 1.0.36+38 (2026-05-22)

### Profil, Jeton, Premium — responsive + mockup

- `ResponsiveLayout`: tablet/desktop ortalanmış içerik (max 560px), adaptif grid
- **Premium Üyelik:** mockup dikey kartlar (Basic/Premium/Gold/Diamond), özellik grid, Gold durum
- **Profil / Jeton yükle:** responsive padding ve geniş ekran düzeni

## 1.0.35+37 (2026-05-22)

### Jeton Satın Al — mockup mağaza

- 2×2 paket grid (50–500 jeton) + tam genişlik 1000 jeton
- Gold üye banner, özel miktar (jeton / ₺), `jetonTlRate` API
- Varsayılan paketler: 1 Jeton = ₺0,50

## 1.0.34+36 (2026-05-22)

### Logo ve uygulama ikonu

- Gönderilen **CanlıFal** ikon tasarımı: `assets/brand/` + Android `ic_launcher` + web favicon
- Giriş ve kayıt ekranında aynı kare marka ikonu

## 1.0.33+35 (2026-05-22)

### Giriş / Kayıt — mockup tasarım

- Şeffaf marka PNG’leri (`assets/brand/`) — kristal küre logo + uygulama ikonu
- Koyu mor arka plan, cam form kartı, mor **Giriş Yap** / **Kayıt Ol** butonları
- Kayıt: Ad Soyad, telefon, şifre tekrar alanları

## 1.0.32+34 (2026-05-21)

### Jeton mağazası — boş liste asla gösterilmez

- UI katmanında da varsayılan paketler (API boş dönse bile)
- 401 dahil tüm API hatalarında satın alma akışı varsayılan paketlerle devam eder

## 1.0.31+33 (2026-05-21)

### Jeton mağazası — paket listesi düzeltmesi

- `/api/jeton` boş veya hatalı yanıtta **varsayılan paketler** (100–5000 jeton, mockup 1000/₺500 dahil)
- Geliştirilmiş JSON ayrıştırma; 401 için net oturum mesajı

## 1.0.30+32 (2026-05-21)

### Jeton yükleme — site + mobil (mockup)

- Web: `site/jeton/` — paket listesi, ödeme yöntemi, WhatsApp, Papara, Havale/IBAN
- Mobil: `/jeton-store` mockup checkout akışı + ödeme talebi
- API: `POST /api/payment/requests` `requestType: jeton`, admin onayda `coins` artışı
- Bildirimler: `jeton_payment_*` tipleri
- Kurulum: `docs/SITE_JETON_KURULUM.md`

## 1.0.29+31 (2026-05-21)

### CanlıFal Sosyal — otomatik fal paylaşımı

- Fal sonucu otomatik sosyal akış paylaşımı (`POST /api/social/posts/auto-fortune`)
- Akış kartı: Otomatik paylaşıldı rozeti, birlikte bakanlar, Kart/Detay
- `DELETE /api/social/posts/:id`

## 1.0.28+30 (2026-05-21)

### Cüzdan + CFC + Gold Üyelik (birleşik)

- `/wallet` cüzdan merkezi (Jeton, CFC, Premium)
- `/premium-membership` Gold üyelik sayfası (mockup: 4 paket, karşılaştırma tablosu)
- CFC yükleme ile ortak bakiye başlığı ve Gold üye şeridi
- API: `GET/POST /api/membership/*`, kullanıcı `membership` alanları

## 1.0.27+29 (2026-05-21)

### CFC ödeme API (canlifal.com dokümantasyonu)

- `GET /api/user/credits` — jetonBalance, cfcBalance, üyelik alanları
- CFC yükleme: `/cfc-store` (amount, bank_transfer, talep geçmişi)
- Admin: onay/red `PATCH /api/admin/cfc-payment-requests`
- Bildirimler: `cfc_payment_*` tipleri
- API dokümantasyonu: `docs/CFC_ODEME_API.md`

## 1.0.26+28 (2026-05-21)

### Cüzdan, ödeme, bildirim ve yönetim

- **Jeton + CFC** çift bakiye (profil, shell, jeton mağazası)
- Bildirime tıklayınca ilgili sayfaya yönlendirme
- Jeton yükleme: WhatsApp, Papara, Havale/EFT — uygulama içi (web’siz)
- Ödeme talebi → admin + site bildirim paneli
- Profilde **Yönetim** bölümü (admin, yönetici, moderatör, destek, yardım)
- Premium açılış ekranı + CanlıFal logo
- `/gift-send` native hediye alanı

## 1.0.25+27 (2026-05-21)

### TikTok tarzı gelişmiş hediye sistemi

- Backend: `Gift` + `GiftEvent`, platform (`mobile`/`web`), rarity, Socket.IO
- Flutter: premium hediye paneli (blur, neon, yatay liste), top gifters
- Lottie + Rive + SVGA fallback, fullscreen animasyon, combo, ses (audioplayers)
- Animasyon önbelleği (`GiftCacheService`), lazy loading

## 1.0.24+26 (2026-05-21)

### CanlıFal Sosyal — premium mistik akış

- Başlık: **CanlıFal Sosyal** (yıldız ikonu, bildirim noktaları)
- Hikâye şeridi: «Hikayen», mor halka, mistik dekor kartı
- Composer: «Ne düşünüyorsun, Canlıfal?» — mor çerçeve, renkli aksiyonlar
- Gönderi kartı: doğrulanmış rozet, zaman + herkese açık, metin → görsel, **Falına Bak** CTA
- Etkileşim sayıları ikon yanında; **Aktif Odalar** yatay şerit (canlı / ses / demo)

## 1.0.23+25 (2026-05-21)

### Fal & Tarot — premium mistik hub

- Tam sayfa `/fortune`: hero, 14 fal grid (Keşfet), günlük fal kartı, Premium upsell
- Oturum ekranları: Tarot, aşk, kahve, yıldız, el, rüya, evet/hayır, pendül, runik…
- Sonuç + paylaşım (Instagram / WhatsApp / Telegram / kaydet)
- Keşfet önizlemesi → native hub

## 1.0.22+24 (2026-05-21)

### Sosyal paylaşım (Instagram + Facebook)

- Facebook tarzı «Ne düşünüyorsun?» composer (fotoğraf / video / duygu)
- Instagram tarzı tam ekran gönderi oluşturma (galeri, kamera, açıklama)
- `POST /api/social/posts` — metin veya multipart görsel
- Freezed DTO’lar, moderasyon, Firebase (isteğe bağlı), discover widget bölünmesi

## 1.0.19+21 (2026-05-20)

### Auth & mesajlaşma premium

- Şifremi unuttum + 6 haneli OTP ekranları
- Sohbet: okundu tikleri, yazıyor animasyonu, modüler composer
- `LiveStreamDto` Freezed + `scripts/codegen.sh`
- Sekme hızlı işlemler `AppColors` birleşimi

## 1.0.18+20 (2026-05-20)

### Production mimari

- `ARCHITECTURE.md` — Clean Architecture, yol haritası (Freezed, Firebase, moderasyon)
- Canlı oda modüler: `widgets/broadcast_room/*` (~900 → ~400 satır orchestrator)
- Premium: skeleton loading, glass surface, bottom sheet, sayfa geçişleri
- Hive `LocalCache`, `hive_flutter` + codegen bağımlılıkları hazır

## 1.0.17+19 (2026-05-20)

### Premium UI — tüm modüller

- Canlı: `LiveStreamListTile`, cache thumb, `LiveBadge`, `AppColors`
- Sesli oda, profil, auth, mesajlar, bildirimler: `AppDesign` → `AppColors` birleşimi
- `discover_tab_layout` token düzeltmeleri

## 1.0.16+18 (2026-05-20)

### Premium UI — Keşfet & Sosyal

- Keşfet: `AppColors`, RepaintBoundary, premium header/coin/ikon, `GradientFab` hızlı işlem
- Sosyal: stories rail aktif, `DiscoverRefresh`, premium app bar, liste performansı
- Yeni bileşenler: `PremiumCoinCapsule`, `PremiumIconButton`, `PremiumQuickActionTile`, `PremiumEmptyHint`

## 1.0.15+17 (2026-05-20)

### Premium design system (temel)

- Birleşik `AppColors` + `CanlifalTokens` (Material 3 ThemeExtension)
- Açık/koyu tema (`themeModeProvider`, varsayılan koyu)
- Yeniden kullanılabilir UI kit: `PremiumNavBar`, `PremiumCard`, `NeonButton`, `LiveBadge`, `GradientFab`
- Alt bar: BackdropFilter kaldırıldı (performans)
- Canlı carousel: `CachedNetworkImage` + `LiveBadge`
- `DESIGN_SYSTEM.md` migrasyon rehberi

## 1.0.14+16 (2026-05-20)

### Keşfet

- **Canlı Yayın Başlat:** tam yuvarlak tuş, kamera ikonu, nabız glow animasyonu

## 1.0.13+15 (2026-05-20)

### Derleme (CI)

- Dart SDK `^3.8.0` (Actions ile uyumlu; `^3.11.5` kırılıyordu)
- `pubspec.lock` güncellendi (`flutter_web_auth_2`)
- `glow_panel` null-aware liste sözdizimi düzeltildi

### Google giriş düzeltmeleri

- **403 disallowed_useragent:** Chrome Mobile user-agent + güvenli tarayıcı (Custom Tab) yedek
- Oturum çerezleri uygulamaya aktarılıyor (`sessionCookieMarker` + yeniden deneme)
- Site ana sayfası / onboarding WebView’da açılmıyor (yalnızca `/api/auth/*`)

### Ana sayfa ve canlı (1.0.12+14)

- Sesli odalar: 4 sütun grid, gerçek `/api/chat/rooms` verisi
- Canlı izleme native TRTC (WebView yok); yayın bitince liste yenilenir
- TRTC izleyici video düzeltmesi (`hostUserId`)

## 1.0.10+11 (2026-05-20)

### Giriş ve çıkış

- Google girişi uygulama içi OAuth (site gezintisi yok, oturum otomatik)
- Ana ekranda geri tuşu: «Çıkış yap» / «Uygulamayı kapat» / «İptal»

## 1.0.9+10 (2026-05-20)

### Canlı yayın TRTC

- İzleyici: otomatik ses/video alımı (`setDefaultStreamRecvMode`)
- Uzak yayıncı sesi açık (`muteRemoteAudio` + hoparlör)
- Oda kimliği tutarlılığı (usersig + `strRoomId`)
- Yayıncı video/ses callback’leri iyileştirildi

## 1.0.8+9 (2026-05-20)

### Sesli sohbet listesi

- Tüm odalar tek ekranda; **4 sütunlu** kompakt grid karo
- Büyük tek kart / boş “Tüm odalar” bölümü kaldırıldı
- Benim oda grid’de ilk sırada altın çerçeve ile

## 1.0.7+8 (2026-05-20)

### Sesli sohbet

- Odalar tamamen **native Flutter + TRTC** (WebView yok)
- **Benim odam** bölümü; popüler odalar responsive grid (1–2 sütun)
- Koltuk 1 yalnızca **oda sahibi** için (yoksa rezerve boş koltuk)
- Üst bar: genel ADMIN yerine sahip bilgisi / “Benim odam”
- Hediye ve jeton yükleme native (`/api/chat/rooms/.../gifts`, jeton mağazası)
- Oda sahibi TRTC’de `isHost: true`

## 1.0.6+7 (2026-05-20)

### Ana sayfa (Keşfet)

- Üst bar: **jeton** dokununca jeton mağazası; **profil** (avatar/isim) dokununca profil sekmesi
- **3** canlı yayın kartı
- **5** hızlı işlem tek satırda (hepsi görünür)
- **Tüm** sohbet odaları listelenir; native sesli oda açılışı
- **Fal & Tarot:** 14 kart, satırda 5
- Daha hızlı pull-to-refresh (paralel yenileme, kısa animasyon)

### Önceki sürümlerden (1.0.5)

- Sesli sohbet neon UI + canlifal.com chat API
- TRTC canlı yayın, hediye sistemi
- Shell hızlı işlemler, jeton mağazası, davet arkadaş

## 1.0.5+6

- Sesli oda, TRTC, hediye, shell entegrasyonu

## 1.0.4+5

- İlk neon sesli oda + API entegrasyonu
