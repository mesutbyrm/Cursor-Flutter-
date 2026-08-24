# CanlıFal — 2026 Premium Flutter UI · Teknik Şartname

> **Sürüm:** `1.0.57+84` · **Tarih:** 19 Temmuz 2026  
> **Mobil paket:** `mobile/` → `canlifal_social`  
> **API tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](./FLUTTER_ENTegrasyon_KILAVUZU.md)  
> **Yol haritası giriş:** [`FLUTTER_PART0_BASLANGIC.md`](./FLUTTER_PART0_BASLANGIC.md)

Bu belge, 2026 Premium ürün vizyonunun **mobil istemci + üretim backend** karşılığını tek tabloda özetler.  
İşaretler: **✅** tam · **🟡** kısmen · **🔵** üretim altyapısı (bu repo dışı) · **📋** planlı

---

## 1. Mimari ve standartlar

| Bileşen | Durum | Mobil (Flutter) | Üretim (canlifal.com) |
|---------|-------|-----------------|------------------------|
| Backend API mimarisi | ✅ | `dio_provider`, `api_endpoints.dart`, kılavuz §9 repository grupları | Next.js App Router, 384+ API, Prisma |
| API standartları | ✅ | JWT Bearer, `{success,data}` zarfı, 401 → `mobile-refresh` | REST + SSE; admin `/api/admin/*` |
| Veritabanı yapısı | 🔵 | — | PostgreSQL + Prisma (149 model) |
| Redis | 🔵 | — | Oda durumu, cache, kuyruk |
| CDN / Cloudflare | 🔵 | `CanlifalNetworkImage`, statik `Env.webOrigin` | CDN + WAF (mobil doğrudan yönetmez) |
| Güvenlik | 🟡 | HTTPS-only WebView, `flutter_secure_storage`, admin rol kapısı | JWT mobil ≠ NextAuth web; SSO köprüsü backend |
| Admin yetkileri | ✅ | `StaffRoles`, `staffAccessProvider`, `adminWebAccessProvider` | Rol: admin, superadmin, yonetici, … |
| Performans optimizasyonu | 🟡 | `CacheFirstLoader`, API cache, görsel prefetch, RepaintBoundary | Sunucu ölçekleme ayrı |
| Cache | ✅ | `api_cache_store`, kozmetik katalog 30 dk, sesli oda discover 3 dk | Redis + HTTP cache headers |
| Offline mod | 🟡 | `offline_status_banner`, GET stale cache, yerleşik kozmetik katalog | Tam offline senkron yok |

---

## 2. Premium UI (2026 UX)

| Özellik | Durum | Konum |
|---------|-------|--------|
| 2026 UX — cam kart, neon, motion | ✅ | `core/ui/premium_2026/`, `discover_premium_2026/`, `home_approved_design.dart` |
| Ana sayfa premium sesli oda kartları | ✅ | `VoiceRoomSection` → `DiscoverPremiumRoomCard` |
| Kategori görselleri (fal, tarot, burç, Gold) | 🟡 | `DiscoverRoomVisuals`, `FortuneSection` API + gradient; bitmap paketi opsiyonel |
| Keşfet | ✅ | `/voice-rooms`, `VoiceDiscoverHub2026`, premium discover widget’ları |
| Animasyon sistemi | ✅ | `flutter_animate`, CustomPainter çerçeveler, Lottie hediyeler |
| Lottie / GIF / WebP / APNG | 🟡 | Lottie hediyeler ✅; kozmetik `assetUrl` hazır; APNG/GIF oynatıcı kozmetikte 📋 |

---

## 3. Gold ve kozmetik sistemi

| Özellik | Durum | API / dosya |
|---------|-------|-------------|
| Gold üyelik sistemi | ✅ | `vip_gold/`, `membership/`, jeton paketleri |
| Profil çerçeveleri (yetkiye göre) | ✅ | `cosmetics/`, `CosmeticAvatarFrame`, `resolvedProfileFrameProvider` |
| Gold çerçeve seçimi | ✅ | `/profile/cosmetics` |
| Yazı efektleri | ✅ | `CosmeticNameLabel`, Gold+ seçim |
| Profil efektleri | ✅ | `CosmeticParticleOverlay` |
| Giriş efektleri | 🟡 | Katalog `CosmeticCatalogDefaults._entrances`; oda girişinde oynatma 📋 |
| Rozet sistemi | 🟡 | `GET /api/membership-badges` + profil chip; başarım rozetleri `profile/growth` |
| Flutter güncellemesiz yeni efekt | 🟡 | `GET /api/profile-frames` + JSON `render`; equip cihazda (backend equip 📋) |
| Admin’den dinamik içerik | 🟡 | Web admin + mobil WebView; kozmetik CRUD web tarafında |

---

## 4. Admin paneli

| Özellik | Durum | Konum |
|---------|-------|--------|
| Admin paneli (web) | 🔵 | `https://canlifal.com/admin` — Next.js |
| Mobil WebView admin | ✅ | `/admin/web`, `AdminWebPanelPage` |
| SSO (tek oturum, JWT) | 🟡 | `AdminWebSsoService` bootstrap + Bearer; tam NextAuth köprüsü backend |
| Yerel mobil admin (yedek) | ✅ | `/admin`, `/admin/panel`, kullanıcı/ödeme/hediye |
| Dinamik çerçeve/efekt/tema ekleme | 🟡 | Web admin + `profile-frames` API; mobil equip senkronu 📋 |

---

## 5. Sesli sohbet ve canlı

| Özellik | Durum | Konum |
|---------|-------|--------|
| Sesli sohbet sistemi | ✅ | `voice_hub/`, SSE presence, koltuk, moderasyon |
| Tencent RTC | ✅ | `trtc/`, `voice_trtc_engine.dart`, `tencent_rtc_sdk` |
| PK sistemi | ✅ | `pk_battle`, `POST /api/live/pk`, sesli + canlı PK |
| Canlı yayın | ✅ | `live/`, TRTC/LiveKit, hediye, sohbet |
| Oda temaları | 🟡 | `backgroundImageUrl` + kategori gradyanı; admin oda arka planı `/admin/voice-backgrounds` |
| Hediye sistemi | ✅ | Lottie/SVGA tam ekran, katalog, sıralama, admin CRUD |

---

## 6. Fal, burç, AI

| Özellik | Durum | Konum |
|---------|-------|--------|
| Tarot | ✅ | `fortune/`, fal hub |
| Günlük burç | ✅ | `home_horoscope_section.dart`, burç modülleri |
| AI fal | ✅ | Streaming SSE fal, görsel analiz |
| Fal & tarot ana sayfa | ✅ | `FortuneSection`, `GET /api/homepage-fortune-cards` |

---

## 7. Bildirim ve altyapı

| Özellik | Durum | Konum |
|---------|-------|--------|
| Bildirim sistemi | ✅ | FCM + uygulama içi, `notifications/` |
| OneSignal | ✅ | `onesignal_flutter`, çift gönderim önleme |
| Tencent RTC yönetimi | 🔵 | Admin web + token API `/api/agora/token`, TRTC |
| PostgreSQL / Redis | 🔵 | Üretim; mobil yalnızca REST/SSE tüketir |

---

## 8. Yayınlanmaya hazır kontrol listesi

### Mobil APK (bu repo)

- [x] `flutter test` + acceptance gate (`scripts/run-acceptance-tests.sh`)
- [x] CI `build-apk.yml` → `apk-latest` release
- [x] Sürüm `pubspec.yaml` + `CHANGELOG.md` + `app_version.dart` senkron
- [x] Kılavuz uyumu: yalnızca `canlifal.com` API, SSE §5–6
- [ ] Giriş efektleri oda entegrasyonu
- [ ] Kozmetik equip sunucu senkronu
- [ ] Web admin tam SSO köprüsü (backend)

### Üretim (canlifal.com — ayrı deploy)

- [x] JWT mobil auth (`/api/auth/mobile-*`)
- [x] Admin API `/api/admin/*`
- [x] Profil çerçeveleri API `GET /api/profile-frames`
- [ ] `POST /api/mobile/auth/web-session` (mobil → web admin SSO)
- [ ] Kozmetik equip endpoint
- [ ] CDN asset pipeline (GIF/Lottie/APNG admin yükleme)

---

## 9. Yol haritası (öncelik sırası)

1. **Backend SSO köprüsü** — mobil JWT → web admin oturumu (şifresiz WebView girişi)
2. **Kozmetik equip API** — çerçeve/efekt seçimi cihazlar arası senkron
3. **Giriş efektleri** — `entranceAnimation` loadout + voice room overlay
4. **Kozmetik asset oynatıcı** — Lottie/GIF/APNG `assetUrl` ile tam ekran çerçeve
5. **Keşfet bitmap paketi** — fal/tarot/burç/Gold hero görselleri (opsiyonel CDN)
6. **SSL pinning** — sertifika pin listesi + `dio` custom HttpClient

---

## 10. Hızlı referans — mobil rotalar

| Rota | Açıklama |
|------|----------|
| `/feed` | Ana sayfa (premium oda kartları) |
| `/profile/cosmetics` | Gold profil çerçevesi / efekt seçimi |
| `/admin/web` | WebView yönetim paneli (Admin/Süper Admin) |
| `/admin/panel` | Yerel mobil admin |
| `/voice-rooms` | Sesli oda keşfet |
| `/vip-gold` | Gold üyelik |

**APK:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

---

*Bu dosya ürün durumu özetidir; detaylı API için kılavuz §9, geliştirme sırası için PART0 kullanın.*
