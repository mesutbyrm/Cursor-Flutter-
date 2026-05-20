# Eksikler ve yapılan değişiklikler

Bu dosya proje durumunu özetler. **Dün ve bugün yapılan her şey** aşağıdaki [Kronoloji (19–20 Mayıs 2026)](#kronoloji-19-20-mayıs-2026) bölümünde toplanmıştır.

**Senin yaptığın ek değişiklikleri** [Senin notların](#senin-notların) bölümüne tarih + madde olarak ekle.

---

## Kronoloji (19–20 Mayıs 2026)

*Kaynak: `git log --date=short` — mobil odaklı maddeler ayrıntılı, genel şablon CI dosyaları tek satırda toplandı.*

### 20 Mayıs 2026

| Commit | Özet |
|--------|------|
| `aa6ea059` | Bu dosya (`EKSIKLER_VE_DEGISIKLIKLER.md`) eklendi; kök `README.md` ve `mobile/README.md` içinden buraya bağlantı verildi. |

### 19 Mayıs 2026 — sırayla (özet başlıklar)

| Commit | Özet |
|--------|------|
| `93426d98` | Premium mockup hizası: alt bar **Keşfet** (pusula), çubuk carousel göstergesi, hero başlık (`katıl, eğlenceye` gradient), header `Hoş geldin, Cemre`; **hikâye şeridi kaldırıldı**; `PremiumPlanetFabIcon`, `PremiumCarouselBarIndicator` eklendi; eski story model/widget silindi. |
| `5bdd6c8f` | Ana sayfa `PremiumHomeScreen` ile kilitlendi; hikâye şeridi + hero tema ince ayarı (sonraki commit’te şerit mockup dışı kaldırıldı). |
| `b7eefcb2` | Chrome Android APK indirmede %100’de takılma: `APK_DOWNLOAD.md` / `INDIR_APK.md`, `AppLinks.androidTestApkReleaseTagPage`, giriş-kayıtta “sürüm sayfası” düğmesi; `.gitignore` `*.apk`. |
| `750045ef` | Premium tema (`premium_live_theme`) ve hero kart (neon çerçeve, vignette, Montserrat); `cardRadius` 26. |
| `f9377816` | Hero carousel: `+128` izleyici satırı, **worm** gösterge (sonradan çubuk göstergesiyle değişti), sesli oda sırası. |
| `e822c439` | **Premium canlı yayın ana sayfa** ilk sürüm: carousel, cam alt nav, bölümler. |
| `0d6e9eb4` | Canlı ve sesli oda akışları düzeltmeleri; **APK indirme linki** (`AppLinks`) ve dokümantasyon bağları. |
| `0733f86d` | Keşfet başlığı, trend meta chip, ses odaları hub giriş metni cilası. |
| `e67a077a` | Ana sayfa keşfet: web ile uyum (hikâyeler, canlı slotlar, ses daireleri, trendler). |
| `1337f279` | Kozmik tema + alt **FAB** çubuğu hizası. |
| `2f86a208` | UI mockup PNG dokümantasyonu; giriş/kayıtta APK linki; `APK_DOWNLOAD` görseller. |
| `bfdf1b6d` | Premium home / sosyal / ses UI; **Google OAuth WebView** entegrasyonu. |
| `f930b56a` | **WebView**: ses odaları ve canlı; cookie senkron; hediye akışı. |
| `5f704ba7` | Site profili; ana sayfada canlı ve sohbet odaları. |
| `13a45108` | **Sosyal sekme** — `canlifal.com` `/api/social/posts`. |
| `bc1fc24e` | Giriş/kayıt: Türkçe hata metinleri. |
| `5bf8ce67` | PR #8 birleştirme: Android internet izni. |
| `0d4823ba` | **Android:** `INTERNET` manifest (release APK ağı). |
| `a2a6d170` | `android-sdk-ci/` gitignore. |
| `6ae784a3` | **CI:** `apk-latest` sürekli sürüm + sabit APK URL dokümantasyonu. |

**Aynı gün eklenen genel şablonlar (mobil dışı):** `9169c227`, `28c64c40`, `a704d1a7`, `a20abe82`, `5b0cf9f4`, `bdbf91a0`, `670d55c4`, `cfe0e949`, `80add320` — örnek GitHub Actions iş akışları (Clojure, Python, npm, CMake, OpenShift, TKE, ECS, Azure, blank vb.); depo şablonu niteliğinde, Flutter uygulamasının çekirdek davranışını değiştirmez.

---

## APK indirme

| Açıklama | Bağlantı |
|----------|----------|
| Doğrudan indirme (`apk-latest`) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk |
| Sürüm sayfası (Chrome takılırsa) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/tag/apk-latest |
| CI iş akışı | https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml |

Kod içi sabitler: `mobile/lib/core/config/app_links.dart`. Ayrıntı: `APK_DOWNLOAD.md`, `INDIR_APK.md`.

---

## Yapılan değişiklikler (özet — repodaki durum)

### Ana sayfa (premium mockup)

- `/feed` rotası yalnızca **`PremiumHomeScreen`** (`mobile/lib/screens/premium_home/`).
- **Üst bar:** `Hoş geldin, Cemre`, doğrulama rozeti, jeton hapı, bildirim; avatar `CachedNetworkImage`.
- **Hero:** `carousel_slider`; başlıkta **«katıl, eğlenceye»** gradient; canlı kartlar (LIVE, kategori, izleyici, avatar yığını, ses alanı); arka plan görseli + `heroBackdropColors`; **`PremiumCarouselBarIndicator`** (yatay çubuk gösterge).
- **Hızlı işlemler:** 5 gradient kutu, `flutter_animate` girişleri; Montserrat.
- **Sohbet odaları:** yatay neon küreler, yeşil online noktası (`voice_spheres_section`).
- **Fal & Tarot:** yatay kartlar, neon çerçeve, hafif partikül (`fal_tarot_section`).
- **Tema / zemin:** `premium_live_theme`, `premium_cosmic_background`, `premium_starfield_painter`.
- **Dummy veri:** `mobile/lib/data/premium_home_dummy_data.dart` (Unsplash + pravatar).

### Alt gezinme (shell)

- **Keşfet** (`Icons.explore`), **Abonelikler**, orta **FAB** (`PremiumPlanetFabIcon` — CustomPainter), **Mesajlar** (pembe bildirim noktası), **Profil**.
- Cam efekt: `BackdropFilter` + üst köşe yuvarlatma; seçili sekmede mor neon glow.

### Diğer

- Eski **`FeedPage`** (Keşfet listesi) kullanılmıyor; `@Deprecated` — yanlışlıkla router’a bağlanmasın diye.
- Giriş / kayıtta **APK indir** + **İndirme takılıyorsa: GitHub sürüm sayfası** (`AppLinks`).
- **`AppTheme.dark()`** içinde **`useMaterial3: true`**.
- **CI:** `.github/workflows/build-apk.yml` — `apk-latest` sürümüne APK yükleme.
- Kök **`.gitignore`:** `*.apk` (yerel derleme kopyaları repoya girmesin).

---

## Eksikler / sonraki adımlar

### Tasarım ve içerik

- Mockup ile **piksel bire bir** için Figma ölçüleri veya export görselleri (hero görselleri, Fal illüstrasyonları vb.).
- İstenirse **Lucide / Font Awesome** ile ikon seti (şu an Material ikonları).

### Fonksiyonellik

- Premium ana sayfa hâlâ **dummy veri**; gerçek **canlı listesi / odalar / jeton** API’leriyle bağlanmadı.
- Hızlı işlem ve Fal kartlarında **onTap** çoğunlukla boş veya kısmi yönlendirme.
- **Orta FAB** şu an canlı sekmesine (`/live`) gidiyor; ürün kararına göre davranış netleştirilebilir.

### Kalite ve dağıtım

- Premium widget’lar için **widget / golden test** yok (isteğe bağlı).
- **iOS** build ve mağaza süreçleri dokümante değil.
- **`apk-latest`** yalnızca CI başarılı olduktan sonra güncellenir; 404 için Actions’tan workflow çalıştırılmalı (`APK_DOWNLOAD.md`).

### Bilinen istemci sorunları

- **Chrome Android** bazen indirmeyi %100’de “İndiriliyor…” diye bırakır; çözüm notları `APK_DOWNLOAD.md` içinde.

---

## Senin notların

_Buraya kendi yaptığın değişiklikleri ekle (tarih — dosya veya özellik — kısa açıklama)._

- _(Örnek) 2026-05-20 — `mobile/...` — …_

---

*Son güncelleme: 2026-05-20 — kronoloji `git log` ile doğrulandı; dal: `cursor/live-voice-apk-fixes-763b` (birleştikçe güncelle).*
