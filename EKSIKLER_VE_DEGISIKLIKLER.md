# Eksikler ve yapılan değişiklikler

Bu dosya proje durumunu özetler. **Güncel sürüm:** **v1.0.5** — aşağıdaki [birleşik saat kronolojisi](#birleşik-saat-kronolojisi-v105-v104-üzerine) `main` dalına göre bu entegrasyon dalında yapılan tüm işleri **yazılım saati (author date) sırasıyla** listeler.

**Senin yaptığın ek değişiklikleri** [Senin notların](#senin-notların) bölümüne tarih + madde olarak ekle.

---

## Birleşik saat kronolojisi (v1.0.5, v1.0.4 üzerine)

**v1.0.4** (ürün / PR #12 hattı): premium Keşfet, sesli sohbet neon küreler ve cam UI, canlı akış hero’su, `canlifal.com` REST uçları ve OAuth / WebView akışı; APK + CI (`apk-latest`) dokümantasyonu. Bu kapsam, aşağıdaki tabloda **19 Mayıs 2026 15:42 – 20 Mayıs 01:44** arasındaki commit satırlarında toplanmıştır (`main`’e zaten girmiş daha eski mobil commit’ler bu fark listesinde yok; yalnızca `origin/main..HEAD`).

**v1.0.5**: aynı hatta **20 Mayıs 01:21 – 02:00** aralığında shell üst çubuğu, jeton mağazası (`/jeton-store`), davet (`/invite-friends`), `share_plus`, Sosyal / Canlı / Mesaj / Profil ve Canlı→Sohbet hızlı işlemleri ile **tek dalda birleştirme** (`8deabe4`); `pubspec` sürüm **1.0.5** ve bu dosyadaki **v1.0.5** damgası.

*Kaynak: `git rev-list --reverse --author-date-order origin/main..HEAD` + `git log -1 --format` (yerel saat, `YYYY-MM-DD HH:MM`).*

| Tarih — saat | Commit | Özet |
|--------------|--------|------|
| 2026-05-19 15:42 | `2f86a20` | UI mockup PNG’leri; giriş/kayıtta APK bağlantısı; `APK_DOWNLOAD` görselleri. |
| 2026-05-19 16:11 | `1337f27` | Kozmik tema + alt FAB çubuğu web ile hizalı. |
| 2026-05-19 16:43 | `e67a077` | Keşfet: web ile uyum (hikâyeler, canlı slotlar, ses daireleri, trendler). |
| 2026-05-19 16:53 | `0733f86` | Keşfet başlığı, trend meta chip, ses odaları hub giriş metni. |
| 2026-05-19 17:22 | `0d6e9eb` | Canlı ve sesli oda akışları; APK indirme linki (`AppLinks`) ve doküman bağları. |
| 2026-05-19 18:23 | `e822c43` | Premium canlı yayın ana sayfa (carousel, cam alt nav, bölümler). |
| 2026-05-19 18:40 | `f937781` | Hero +128 izleyici satırı, worm gösterge, ses sırası. |
| 2026-05-19 20:06 | `750045e` | Premium tema ve hero kart (mockup’a yakın neon / Montserrat). |
| 2026-05-19 20:13 | `b7eefcb` | Chrome Android APK takılması notları; GitHub sürüm sayfası linki. |
| 2026-05-19 20:26 | `5bdd6c8` | Ana sayfa `PremiumHomeScreen`; hikâye şeridi + hero cilası. |
| 2026-05-19 20:36 | `93426d9` | Mockup hizası: Keşfet shell, çubuk carousel göstergesi, hero başlık, header. |
| 2026-05-20 01:21 | `f462e51` | Ana sayfa profil / jeton kısayolları; jeton ve davet sayfaları. |
| 2026-05-20 01:27 | `30b9dba` | Sosyal, Canlı, Mesaj sekmelerinde shell bar ve hızlı işlemler. |
| 2026-05-20 01:30 | `32ae3b0` | Profil ve Canlı–Sohbet hızlı işlemleri; `ShellFeedLeading`. |
| 2026-05-20 01:41 | `aa6ea05` | Bu eksikler dosyası ve README bağlantıları. |
| 2026-05-20 01:44 | `61aa1bc` | 19–20 Mayıs commit kronolojisinin ilk dokümantasyonu (önceki tablo biçimi). |
| 2026-05-20 02:00 | `8deabe4` | Jeton/davet/shell hızlı işlemler + PR12 (live-voice premium) dalı **merge**. |

**Not:** `main` üzerinde daha önce birleşmiş mobil commit’ler (ör. sosyal API, WebView, Android `INTERNET`, `apk-latest` CI şablonu) bu fark listesinde görünmez; tam geçmiş için `git log origin/main -- mobile/` kullanılabilir. Depo kökündeki örnek Actions şablonları (Clojure, Python, Azure vb.) Flutter davranışını değiştirmez.

---

## APK indirme

| Açıklama | Bağlantı |
|----------|----------|
| **v1.0.5** doğrudan APK (etiket + CI sonrası) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/v1.0.5/canlifal-mobile-release.apk |
| **v1.0.5** sürüm sayfası (Assets’ten indirme) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/tag/v1.0.5 |
| Doğrudan indirme (`apk-latest`, `main` son derleme) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk |
| Sürüm sayfası (`apk-latest`, Chrome takılırsa) | https://github.com/mesutbyrm/Cursor-Flutter-/releases/tag/apk-latest |
| CI iş akışı | https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml |

**v1.0.5 APK’sını üretmek:** `v1.0.5` etiketi push edildikten sonra [Build release APK](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml) iş akışı etiket üzerinde çalışır; bitince yukarıdaki doğrudan bağlantı geçerli olur. Etiket yoksa veya 404 ise aynı iş akışında dal olarak `cursor/live-voice-apk-fixes-763b` seçip **Artifacts** → `canlifal-social-release-apk` kullanın.

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

### Alt gezinme (shell) ve v1.0.5 ekleri

- **Keşfet** (`Icons.explore`), **Abonelikler**, orta **FAB** (`PremiumPlanetFabIcon` — CustomPainter), **Mesajlar** (pembe bildirim noktası), **Profil**.
- Cam efekt: `BackdropFilter` + üst köşe yuvarlatma; seçili sekmede mor neon glow.
- **Jeton mağazası** ve **davet** rotaları; sekme ve profil / Canlı–Sohbet **hızlı işlem** kutuları; paylaşım için **`share_plus`**.

### Diğer

- Eski **`FeedPage`** (Keşfet listesi) kullanılmıyor; `@Deprecated` — yanlışlıkla router’a bağlanmasın diye.
- Giriş / kayıtta **APK indir** + **İndirme takılıyorsa: GitHub sürüm sayfası** (`AppLinks`).
- **`AppTheme.dark()`** içinde **`useMaterial3: true`**.
- **CI:** `.github/workflows/build-apk.yml` — `apk-latest` ( `main` ) ve `v*` etiketleriyle sürüm APK yükleme.
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
- **`apk-latest`** yalnızca `main` üzerinde CI başarılı olduktan sonra güncellenir; **v1.0.5** için `v1.0.5` etiketi veya dal üzerinden workflow kullanın (`APK_DOWNLOAD.md`).

### Bilinen istemci sorunları

- **Chrome Android** bazen indirmeyi %100’de “İndiriliyor…” diye bırakır; çözüm notları `APK_DOWNLOAD.md` içinde.

---

## Senin notların

_Buraya kendi yaptığın değişiklikleri ekle (tarih — dosya veya özellik — kısa açıklama)._

- _(Örnek) 2026-05-20 — `mobile/...` — …_

---

*Son güncelleme: 2026-05-20 — v1.0.5; dal: `cursor/live-voice-apk-fixes-763b`.*
