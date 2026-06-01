# canlifal.com → Flutter Parite Matrisi

Bu belge, **canlifal.com** web sitesi ile **canlifal_social** mobil uygulaması arasındaki sayfa, özellik ve API eşlemesini izler. Güncelleme: 2026-05-19.

## Tasarım sistemi (web → mobil)

| Web (falclub / Tailwind) | Flutter |
|--------------------------|---------|
| `--theme-bg` `#0f0520` | `AppThemeColors.dark.scaffoldBackground` / `#0B0B1E` |
| `--falclub-pink` `#d946ef` | `accentPink` / `accentPurple` gradient |
| `--falclub-gold` `#fbbf24` | `coinGold` |
| Inter + Cinzel | `google_fonts` (Inter ağırlıklı) |
| `--radius` `0.5rem` | `AppSpacing.radiusMd` (8px grid) |
| Cam / blur kartlar | `ThemedGlassCard`, `LiquidGlass`, `ProGlassCard` (koyu mod) |

Mobil, web ile aynı koyu mor-pembe atmosferi hedefler; açık mod profesyonel düz yüzeyler kullanır (`theme_mode_provider`).

## Ana navigasyon

| Web bölüm | Web route | Flutter route | Durum |
|-----------|-----------|---------------|--------|
| Ana sayfa / Keşfet | `/`, `/kesfet` | `/feed` | ✅ |
| Sosyal | `/sosyal` | `/social` | ✅ |
| Canlı | `/canli-yayinlar`, `/sohbet/video` | `/live`, `/live/prep`, `/live/room` | ✅ |
| Fal & Tarot | `/fal`, `/kahve-fali`, … | `/fortune`, `/fortune/:slug` | ⚠️ Yerel katalog; bazı web slug'ları 404 |
| Profil | `/profil`, `/ayarlar` | `/profile`, `/profile/*` | ✅ |
| Gold | `/gold`, `/uyelik` | `/vip-gold`, `/premium-membership` | ✅ |
| Sesli sohbet | `/sohbet`, `/sohbet/{slug}` | `/voice-rooms`, `/voice-room/:id` | ✅ (native TRTC) |

## Kimlik doğrulama

| Özellik | Web | Flutter | API |
|---------|-----|---------|-----|
| Giriş | `/giris` (NextAuth) | `/login` | `POST /api/auth/mobile-login` |
| Kayıt | `/kayit-ol` | `/register` | `POST /api/auth/mobile-register` |
| Google | OAuth web | Native + WebView import | `POST /api/auth/mobile-google` |
| Şifremi unuttum | `/auth/forgot-password` (404 bazen) | `/auth/forgot-password` + WebView | ⚠️ OTP API self-hosted'da yok |
| Misafir | — | `guestModeProvider` | — |
| Token yenileme | Çerez | Secure storage + Dio | `POST /api/auth/mobile-refresh` |

## Sosyal & içerik

| Özellik | Web | Flutter | Durum |
|---------|-----|---------|--------|
| Akış | `/sosyal` | `/social` | ✅ `GET /api/social/posts` |
| Hikâyeler | `/hikayeler` | Keşfet stories rail | ✅ |
| Post oluştur | — | `/social/create` | ✅ |
| Beğeni | UI | Instagram kart | ✅ (yerel toggle + API) |
| Kullanıcı profili | `/profil/{username}` | `/user/:id` | ✅ |
| Takip | — | Profil | ✅ `POST /api/user/{id}/follow` |

## Arama & favoriler

| Özellik | Web | Flutter | Durum |
|---------|-----|---------|--------|
| Global arama | `/arama` | `/search` | ✅ `GET /api/users/search?q=` |
| Keşfet yerel filtre | — | Feed arama çubuğu | ✅ (oda/yayın metni) |
| Favoriler | `/favoriler` | `/favorites` | ⚠️ WebView + fal geçmişi API |
| Fal geçmişi | Profil / fal | Favoriler sekmesi | ✅ `GET /api/user/fortunes` |

> **Eksik API:** Dokümanda `/api/favorites` veya bookmark endpoint'i yok. Site `/favoriler` sayfası WebView ile açılır; kalıcı yerel liste için backend eklenmeli.

## Mesajlaşma & bildirimler

| Özellik | Web | Flutter | API |
|---------|-----|---------|-----|
| DM kutusu | `/mesajlar` | `/messages` | `GET /api/messages` |
| Sohbet | `/mesajlar/{id}` | `/chat/:id` | `GET/POST /api/messages/{id}` |
| Bildirimler | — | `/notifications` | `GET /api/notifications` |
| FCM | — | `registerFcmDevice` | ✅ |

## Cüzdan & üyelik

| Özellik | Web | Flutter | API |
|---------|-----|---------|-----|
| Jeton | `/jeton-yukle` (404 prod) | `/jeton-store` | `GET /api/jeton`, ödeme |
| CFC | — | `/cfc-store` | `POST /api/payment/requests` |
| Cüzdan | — | `/wallet` | `GET /api/wallet` |
| Üyelik | `/uyelik` | `/premium-membership` | `/api/membership/*` |
| Davet | `/davet` | `/invite-friends` | `GET /api/referral` |

## Canlı & ses

| Özellik | Web | Flutter |
|---------|-----|---------|
| Yayın listesi | `/canli-yayinlar` | `/live` |
| Yayın odası | Web player | TRTC / LiveKit native |
| Hediyeler | Web | `gift_send`, live room |
| Sesli oda | `/sohbet/{slug}` | Native RTC |
| YouTube DJ | Web | Voice room sheet |

## Fal modülü

| Web slug | Flutter | Backend |
|----------|---------|---------|
| `gunluk-fal`, `tarot`, `kahve-fali`, … | `FortuneCatalog` | ⚠️ Oturumlar çoğunlukla client-side |
| Fal geçmişi | `/favorites` (Fal sekmesi) | `GET /api/user/fortunes` |
| Web-only fal sayfası | `CanlifalWebView` `/fal/{slug}` | Web NextAuth |

## Yönetim

| Özellik | Web | Flutter |
|---------|-----|---------|
| Admin | `/admin` | `/admin` |
| Ödeme onayı | Panel | `admin_cfc_payment_requests` |
| Şikayet | — | `/report` |

## WebView yedekleri (`/canlifal-web`)

Aşağıdaki sayfalar production'da eksik veya yalnızca web oturumu gerektirir; mobil native + WebView kullanır:

- `/auth/forgot-password`
- `/davet` (alternatif: native invite)
- `/fal/{slug}` (site 404 olan slug'lar)
- `/favoriler` (site favorileri — API yok)
- `/jeton-yukle` (native `/jeton-store` tercih)

## Modül envanteri (Flutter `lib/features`)

| Modül | Kapsam |
|-------|--------|
| `auth` | Giriş, kayıt, splash, OTP UI |
| `shell` | 5 sekmeli alt bar |
| `feed` | Keşfet ana sayfa |
| `social` | Sosyal akış |
| `live` | Canlı yayın |
| `fortune` | Fal kataloğu & oturum |
| `profile` | Profil, cüzdan, ayarlar |
| `messages` | DM |
| `notifications` | Bildirimler |
| `wallet` | Bakiye & ödeme |
| `membership` | Premium |
| `voice_hub` | Sesli odalar |
| `vip_gold` | Gold hub |
| `gifts` | Hediye gönder |
| `admin` | Yönetici |
| `moderation` | Şikayet |
| `canlifal_web` | WebView |
| **`search`** | Kullanıcı arama (`/arama`) |
| **`favorites`** | Favoriler + fal geçmişi |

## Açık eksikler (rapor)

1. **Favoriler API** — Web `/favoriler` için public REST endpoint dokümante değil; WebView + fal geçmişi ile kısmi karşılama.
2. **Fortune backend** — Tam fal oturumu API entegrasyonu (şu an katalog + yerel UX).
3. **Şifre sıfırlama / OTP** — Self-hosted `api/` paketinde endpoint yok.
4. **Global içerik araması** — Yalnızca kullanıcı araması; post/oda araması API bekliyor.
5. **Tema migrasyonu** — ~200 dosyada hâlâ `AppColors.*` sabitleri.
6. **Web repo** — Tam Next.js kaynak kodu bu workspace'te değil (`site/` yalnızca jeton mockup).

## Sonraki modül sırası (öneri)

1. ✅ `search` + `favorites`
2. Fortune → `GET /api/user/fortunes` detay sayfası
3. Blog / rüya sözlüğü → WebView veya native SEO ekranları
4. `favoriteTeam` profil alanı (API mevcut)
5. Feed sunucu taraflı pagination
