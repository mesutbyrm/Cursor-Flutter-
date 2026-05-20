# Eksikler ve yapılan değişiklikler

Bu dosya proje durumunu özetler. **Senin yaptığın ek değişiklikleri** aşağıdaki [Senin notların](#senin-notların) bölümüne tarih + madde olarak ekle; böylece tek yerde takip edilir.

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

*Son güncelleme: repodaki `cursor/live-voice-apk-fixes-763b` dalı ile uyumlu özet. Dal birleştikçe veya sen not ekledikçe bu dosyayı güncelle.*
