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
| 2 | Sosyal akış + hikâyeler | ✅ tamam |
| 3 | Profil + kullanıcı kartları | ✅ tamam |
| 4 | Fal türleri + sonuç ekranları | ✅ tamam |
| 5 | Sesli oda + koltuklar | ✅ tamam (yalnızca görsel katman; SSE/presence/TRTC değişmedi) |
| 6 | Canlı yayın + hediye + PK | ⏳ sıradaki |
| 7 | Sohbet, mesajlaşma, diğer | ⏳ |

### Aşama 1 — yapılanlar

- **Alt navigasyon** (`bottom_navigation_widget.dart`): eşit esnek sütunlar (sabit 56 px kaldırıldı → 320 px'te "Fal & Tarot" kesilmez), her zaman görünen etiketler, M3 hap göstergesi, dolu/boş ikon geçişi, ortada gradyanlı "Canlı" oluşturma butonu, dokunsal geri bildirim, TalkBack için seçili durum + dokunma eylemi, büyük yazıda üst sınırlı ölçek. Genel API (parametreler, `HomeBottomTab`) değişmedi.
- **Başlık / arama**: temaya duyarlı arama çubuğu, 40 px dairesel gelen kutusu butonu, semantik etiketler; ölü kod silindi.
- **Bölüm başlıkları**: tema rengi + "Tümü ›" geniş dokunma alanı.
- **26 bölüm dosyası**: sayfa zeminindeki metin/yüzeyler `textPrimaryOf(context)` vb. temaya duyarlı karşılıklara taşındı; görsel/gradyan üzerindeki metinler bilerek beyaz bırakıldı.

### Aşama 2 — yapılanlar

- **Hikâye izleyici** (`story_viewer_page.dart`) yeniden yazıldı. Giderilen hatalar: basılı tut/bırak hikâyeyi baştan başlatıyordu; videoda her devam, dinleyiciyi yeniden ekleyip bitişte `_next`'in çoklu çağrılmasına yol açıyordu; ilerleme `Timer.periodic(50ms)` + `setState` ile tüm sayfayı çiziyordu; görsel yüklenmeden süre işliyordu; tam ekran görsel küçük önizleme çözünürlüğündeydi. Yeni: `AnimationController` ile yalnızca çubuğu çizen ilerleme, kişiden kişiye geçiş (`StoryViewerArgs.rings`, geriye uyumlu), yatay kaydırma, aşağı kaydır-kapat, avatar + göreli zaman, uygulama arka plana geçince duraklatma.
- **Hikâye şeridi**: `StoriesStrip` + `StoryRingTile` ortak bileşenleri; ana sayfa `StoriesSection` ve `SocialStoriesRail` artık aynı kodu kullanıyor. İzlenme bilgisi backend'de olmadığı için cihazda (`storySeenProvider`, en çok 600 kimlik) tutuluyor. Ana sayfadaki her halkada sonsuz döngüde çalışan bulanık-gölge nabız animasyonu (`HomeStoryRingPulse`) kaldırıldı.
- **Sosyal sayfa**: şerit, `23720058` commit'inde bilinçli olarak kaldırıldığı için sosyal sayfaya **eklenmedi**. Kısayollar + paylaşım kutusu akışla birlikte kayan başlığa taşındı.
- **Gönderi kartı**: `SocialCdsPostShell(CdsCard.glass)` → `ProGlassCard(blur: 14)` → kenarlıklı kutu üçlüsü tek düz yüzeye indirildi; görsele çift dokunuş beğenir (beğeniyi geri almaz); sil ikonu → "⋯" menüsü; semantik etiketler; ölü `_ActionIcon` silindi.
- **Açık tema**: paylaşım kutusu (`#12122A` sabit dolgu), etiketleme/duygu alt sayfaları (`#120A24`), metin-only gönderi kutusu, rozetler, `#25F4EE` bağlantı rengi ve `UserAvatar` yer tutucusu temaya bağlandı.

### Aşama 3 — yapılanlar

- **Hızlı menü taşması:** `ProfileHubQuickMenu` 72×78 px kutucukta 3 sütun grid için tasarlanmış `ProfileActionTile`'ı kullanıyordu (~98 px içerik) → ~390 dp ekranda 30 px taşma. `ProfileActionTile(compact: true)` + `compactHeight` (92 px, %130 yazıda sığar). Regresyon testi eski ölçülerle başarısız oluyor.
- **Kırık rota:** `profile_follow_list_page.dart` ve `live_viewers_sheet.dart` tanımsız `/profile/<id>` rotasına gidiyordu → `buildSocialUserProfileRoute` (`/user/<id>`). İzleyici listesi router'ı `Navigator.pop`'tan önce alıyor.
- **Takip butonu** (`ProfileFollowButton`): iyimser güncelleme, istek sırasında kilit, hata olursa geri alma + SnackBar.
- **Açık tema:** `ProfilePremiumTheme`'e temaya duyarlı yardımcılar (`surfaceOf`, `textOf`, `borderOf`, `accentOf`, `glassDecorationOf`…) eklendi; 20 hub/profil dosyası bunlara taşındı. Sabit koyu gradyan üzerindeki metinler (VIP afişi, fal/canlı kartları, küçük resim yer tutucusu) bilerek beyaz bırakıldı — render ile tek tek doğrulandı.
- **Başlık yerleşimi:** ad bloğu kapağın kenarına biniyordu; kapağın altına alındı, eylemler tam genişlik buton satırına taşındı.
- **Takipçi listesi:** `UserListTile`, iskelet, yeniden denemeli hata, çekip yenileme.

### Aşama 4 — yapılanlar

- **Fal koyu teması:** fal sayfaları sabit koyu zemin (`#0A0118`, `deepNight`) çiziyor; açık temada içteki tema-duyarlı bileşenler açık renk alıyordu. `FortuneLaneTheme` (merkez + `FortuneAnimationRouteShell` altındaki tüm fal rotaları) açık temada koyu `ThemeData` verir; koyu/AMOLED seçimine dokunmaz. Alt sayfalar `showModalBottomSheet`'in tema yakalaması sayesinde kapsamı devralır.
- **Giriş sayfası:** fotoğraf gerekirken butonlar `() {}` idi → `_onOpenPressed` önce `showFortuneImageCaptureSheet`, sonra fal. Fotoğraf kutucuğu başlığında taşma giderildi.
- **Sonuç:** `FortuneReadingHeadlines.sectionTitle` — bilinmeyen anahtarda sunucu başlığı.
- **Kart çevirme** (`CanlifalTarotFlipCard`): kalkma + dinamik gölge + ışık yansıması, `RepaintBoundary`, azaltılmış hareket desteği; genel API geriye uyumlu (`borderRadius` eklendi).
- **Görsel önbelleği:** `maxWidthDiskCache`/`maxWidth` (ImageCacheManager gerektirir) kaldırıldı; ön-yükleme `ResizeImage`.
- **Ölü kod:** `fortune/presentation/screens/` (17 ekran) ve yalnızca onların kullandığı 17 sağlayıcı + 3 model silindi; `lib`/`test`'te referans olmadığı HEAD üzerinde doğrulandı.
- **Açık soru (kullanıcıya):** sonuç kartındaki "Enerji/Aşk/Para/Kariyer/Şans %" değerleri sunucudan gelmiyor, özet metninin hash'inden türetiliyor (`FortuneEnergyScores`). Değiştirilmedi.

### Aşama 5 — yapılanlar

- **Koltuk ölçüsü** (`VoiceMicSeat`): her koltuk `boxWidth(size)` × `footprintHeight(size)` sabit alan kaplar. İsim koltuk genişliğinde kısaltılır; hediye rozeti (`FittedBox`) avatarın alt kenarına, hediye bildirimi (`VoiceSeatGiftFlashStack`, `IgnorePointer`) avatarın üstüne biner. `VoiceWebOwnerStage` sahne yüksekliğini ve sütun genişliğini bu ölçülerden hesaplar (eskiden 5 × (hücre + 10 px çerçeve) hesaba katılmıyordu). İki sıra aynı 5 sütunlu ızgarada.
- **Sahte seviye:** `_levelLabel` koltuk numarasından `Lv$seat` üretiyordu → `_roleLabel` yalnızca sunucu `roleSymbol` ve yayıncı "MOD".
- **Kilitli koltuk:** `_EmptySeat` kilitliyken `onTap`/`onLongPress` null'dı → dokunma işleyicileri (zaten kilit kontrolü yapıyor) her zaman bağlı. `onVoiceRoomBasicSeatTap` kilitli koltukta yetkiliye atama/kilit menüsünü açar.
- **Animasyon** (`VoiceSeatAvatarFrame`): `_orbit` kaldırıldı; `_spin` yalnızca rol çerçevesi + mikrofon açık, `_pulse` yalnızca konuşurken; `MediaQuery.disableAnimations` desteği. Test: konuşmayan konuk koltuğu kare zamanlamaz.
- **Koyu kapsam:** `FortuneLaneTheme` → ortak `core/theme/dark_lane_theme.dart` (`DarkLaneTheme`; `FortuneLaneTheme` artık typedef). `/voice-rooms` ve `/voice-room/:id` rotaları sarıldı.
- **Oda listesi:** `VoiceRoomsDiscoverMapper._distanceLabel` konum yoksa `''` döner; `NearbyRoomTileCard` satırı gizler. `VoiceRoomsMockData` içinden kullanılmayan sahte sabitler silindi (kategori/sekme etiketleri kaldı).
- **Ölü kod:** yalnızca barrel'dan dışa aktarılan ya da hiç içe aktarılmayan 45 dosya silindi (ikinci tur: silinenlerin tek kullanıcısı olduğu 3 dosya). Her biri için `lib`/`test` içe aktarma + sınıf adı taraması yapıldı, silme sonrası `dart analyze` 0 hata.

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
