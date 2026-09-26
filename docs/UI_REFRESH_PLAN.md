# Canlifal Flutter — UI/UX yenileme planı

> Başlangıç: 2026-09-26 · Taban: `1.0.605+656` · Kapsam: yalnızca görsel katman — API, SSE, TRTC, oda durumu ve navigasyon sözleşmeleri değişmez.

## 1. Analiz özeti

`mobile/lib` ≈ 2170 Dart dosyası, 47 feature modülü. Görsel dil **beş ayrı, birbiriyle çakışan tasarım katmanına** dağılmış durumdaydı:

| Katman | Kullanım | Sorun |
|---|---|---|
| `AppThemeColors` + `AppTheme` (Material 3) | 283 dosya | Ana kaynak; ama koyu tema mor-siyah (`#0F0B1D`), açık tema pembe (`#E91E63`) — iki tema farklı marka rengi |
| `HomeApprovedDesign` / `HomePremiumDesign` / `HomePalette` | 48 + 10 + 3 dosya | Ana sayfa kendi mavi-siyah paletini (`#070A12`) kullanıyordu; tema ile uyumsuz |
| `PlatformSocialPalette` | 21 dosya | Lacivert (`#0B0F1E`) + ayrı vurgu (`#B832FF`, `#448AFF`) |
| `premium_2026`, `premium`, `pro_glass`, `cds` | 67 / 46 / 13 / 42 dosya | Kısmen tema üstüne sarmalayıcı; kendi gradyanları |

### Tespit edilen gerçek hatalar

1. **Font hiç yüklenmiyordu.** `GoogleFonts.config.allowRuntimeFetching = false` ama font dosyaları pakette yoktu → uygulama tasarlanan Plus Jakarta Sans / Playfair Display yerine sistem fontuna düşüyordu.
2. **Açık temada görünmeyen metin.** Ana sayfa bölüm başlıkları (`HomeSectionTitle`, 21 bölüm) ve 26 bölüm dosyası koyu tema metin rengini (`#F5F5FA`) sabit kullanıyordu → açık temada beyaz zemin üzerinde beyaz metin. Gelen kutusu ikonu da aynı sorunu taşıyordu.
3. **Kontrast.** Koyu temada `#8B5CF6` üzerinde beyaz buton metni 4.23:1, açık temada turkuaz üzerinde beyaz 3.75:1 — WCAG AA (4.5:1) altı.
4. **ColorScheme eksik.** `primaryContainer` / `secondaryContainer` tanımsız → M3 tonal buton, seçili çip vb. düz renk dolguya düşüyordu; `surfaceTint` yükseltilmiş yüzeylere mor ton bindiriyordu.
5. **Erişilebilirlik.** Alt navigasyonda seçili sekme bildirilmiyordu; dokunma alanları 24 px'ti.
6. **Ölü kod.** `home_header.dart` içinde kullanılmayan `_IconBadge`, `_CoinPill` ve importlar (analizör doğruladı).
7. **Not:** `voice_rooms_mock_data.dart` adı yanıltıcı ama yalnızca statik kategori/sekme etiketleri için kullanılıyor; sahte kullanıcı/oda göstermiyor → korunuyor.

## 2. Tasarım sistemi (Aşama 0 — ✅ tamam)

Tek kaynak: `lib/core/theme/canlifal_brand_colors.dart`.

| Rol | Koyu | Açık |
|---|---|---|
| Zemin | `#09090D` (derin siyah) | `#F6F6FA` |
| Yüzey / yükseltilmiş | `#121218` / `#1C1C24` (antrasit) | `#FFFFFF` |
| Birincil (dolgu) | `#7C3AED` mor | `#7C3AED` mor |
| Metin vurgusu | `#A78BFA` | `#7C3AED` |
| İkincil | `#2DD4BF` turkuaz | `#0F766E` |
| Canlı / beğeni | `#FE2C55` (değişmedi) | — |

- `AppThemeColors` (dark / amoled / light), `CanlifalTokens`, `AppColors`, `HomeApprovedDesign`, `HomePremiumDesign`, `HomePalette`, `PlatformSocialPalette` artık bu paletten besleniyor → 380+ dosya ekran ekran yeniden yazılmadan tutarlı hale geldi.
- `AppTheme`: tipografi ölçeği (başlıklarda negatif izleme), dokunma dalgası (InkRipple — sparkle'dan ucuz), kart ince kenarı, sekme göstergesi, FAB, rozet, tooltip, menü, çip, form alanı, slider, checkbox/radio, switch temaları.
- Font: Plus Jakarta Sans (5 ağırlık) ve Playfair Display (fal başlıkları) `assets/google_fonts/` altında, OFL lisansı `LicenseRegistry`'de. Plus Jakarta Sans pubspec'te **tek aile + gerçek ağırlık dosyaları** olarak tanımlı — `TextStyle(fontWeight: w800)` sahte kalınlık yerine ExtraBold dosyasını kullanır. (+~950 KB APK)
- Android sayfa geçişi: doğrusal fade → `easeOutCubic` fade + 2 % dikey kayma (barrier'sız yapı korunuyor).
- Skeleton: `RepaintBoundary` ile izole, "animasyonları azalt" açıksa durağan.

## 3. Ekran aşamaları

| # | Ekran grubu | Durum |
|---|---|---|
| 1 | Ana sayfa + alt navigasyon | ✅ tamam (bu PR) |
| 2 | Sosyal akış + hikâyeler | ⏳ sıradaki |
| 3 | Profil + kullanıcı kartları | ⏳ |
| 4 | Fal türleri + sonuç ekranları | ⏳ |
| 5 | Sesli oda + koltuklar | ⏳ (SSE/presence yeni stabilize edildi; yalnızca görsel katman) |
| 6 | Canlı yayın + hediye + PK | ⏳ |
| 7 | Sohbet, mesajlaşma, diğer | ⏳ |

### Aşama 1 — yapılanlar

- **Alt navigasyon** (`bottom_navigation_widget.dart`): eşit esnek sütunlar (sabit 56 px kaldırıldı → 320 px'te "Fal & Tarot" kesilmez), her zaman görünen etiketler, M3 hap göstergesi, dolu/boş ikon geçişi, ortada gradyanlı "Canlı" oluşturma butonu, dokunsal geri bildirim, TalkBack için seçili durum + dokunma eylemi, büyük yazıda üst sınırlı ölçek. Genel API (parametreler, `HomeBottomTab`) değişmedi.
- **Başlık / arama**: temaya duyarlı arama çubuğu, 40 px dairesel gelen kutusu butonu, semantik etiketler; ölü kod silindi.
- **Bölüm başlıkları**: tema rengi + "Tümü ›" geniş dokunma alanı.
- **26 bölüm dosyası**: sayfa zeminindeki metin/yüzeyler `textPrimaryOf(context)` vb. temaya duyarlı karşılıklara taşındı; görsel/gradyan üzerindeki metinler bilerek beyaz bırakıldı.

## 4. Doğrulama yöntemi (her aşamada)

1. `dart analyze lib` → 0 hata; değiştirilen dosyalarda yeni uyarı yok.
2. `flutter test` → tüm paket (1600+ test).
3. Yeni testler: `test/core/theme/canlifal_theme_test.dart` (WCAG kontrast, ColorScheme bütünlüğü), `test/features/home/bottom_navigation_widget_test.dart` (geri çağrılar, semantik, 320 px + %160 yazıda taşma).
4. Gerçek fontlarla PNG render (koyu / açık / AMOLED) — görsel inceleme.
5. `flutter build apk --debug`.
6. **Cihaz testi (kullanıcı)** — emülatör/cihaz bu ortamda yok; Redmi Note 13 Pro 5G üzerinde akıcılık ve dokunma testi kullanıcı tarafında yapılmalı.

## 5. Riskler ve kurallar

- Yeni paket eklenmez; mevcut `flutter_animate`, `shimmer`, `cached_network_image` kullanılır.
- Sahte veri, sahte bakiye, işlevsiz buton eklenmez (ör. arama çubuğuna filtre ikonu eklenmedi — işlevi yok).
- Sesli oda / canlı yayın aşamalarında yalnızca widget ağacının görsel kısmına dokunulur; provider, SSE, presence ve TRTC çağrıları değişmez.
- Görsel varlıklar (tarot/kahve illüstrasyonları) için lisanslı kaynak gerekir; lisansı belirsiz görsel eklenmez — kullanıcıdan marka görselleri beklenir.
