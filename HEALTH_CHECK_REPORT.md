# Canlifal Flutter Health Check Report

Tarih: 2026-06-10

## Kapsam

Bu rapor `mobile/` Flutter uygulamasinin genel saglik denetimini kapsar.
Kod degisikligi yapilmadan once olusturulmustur.

Kaynaklar:

- `mobile/lib` altindaki 602 Dart dosyasi
- `mobile/analysis_options.yaml`
- Son CI/analyze ve APK workflow ciktilari
- Onceki parity raporlari ve son surum notlari

Kisit:

- Bu cloud ortaminda yerel Flutter SDK `PATH` icinde yok; bu nedenle lokal
  `dart analyze`/`flutter test` calistirilamadi.
- Dogrulama icin GitHub Actions `Build release APK` workflow'u esas alinir.

## Modül envanteri

| Modul | Durum | Not |
|---|---|---|
| `app/router`, `app/app` | Calisiyor | Route sayisi genis; bazi `state.extra as ...` castleri runtime risk tasir |
| `core/network` | Calisiyor | Bearer JWT + refresh var; hata mapping var |
| `core/firebase`, `core/onesignal`, `core/push` | Kismi | Firebase config yoksa toleransli; FCM endpoint 404 sessiz gecilebilir |
| `auth` | Calisiyor | Mobil JWT akisi mevcut |
| `feed/home/discover` | Calisiyor/kismi | Bircok fallback liste var; web CMS native degil |
| `social` | Calisiyor | Post/like/comment temel akisi var |
| `messages` | Calisiyor | REST tabanli; realtime DM socket yok |
| `profile/wallet/admin` | Calisiyor/kismi | Odeme/admin kismi var; tam web admin yok |
| `notifications` | Calisiyor | Bildirim liste/okundu var |
| `fortune` | Kismi | Fal katalog/okuma var; tum web fal varyantlari dogrulanmadi |
| `live/gifts` | Calisiyor | Socket, gift, PK ve TRTC temel akisi mevcut |
| `voice_hub` | Calisiyor/kismi | Son turlarda muzik/socket/gift parity guclendirildi |
| `trtc/livekit` | Calisiyor/kismi | TRTC ana yol; LiveKit fallback |
| `content_hub/canlifal_web` | Kismi | Web-only sayfalar native degil |

## Derleme ve CI durumu

| Kontrol | Son durum | Kanit |
|---|---|---|
| `flutter pub get` | Basarili | Son APK workflow'lari `Dependencies` step |
| `dart analyze lib` | Basarili | Son APK workflow'lari `Analyze` step |
| Release APK build | Basarili | Son surumlerde `Build release APK` step |
| `apk-latest` publish | Basarili | Son release asset guncellendi |

Not: Bazı run'larda post-cleanup adimi failure sonucuna sebep oldu; ancak APK
build ve release publish adimlari basariliydi.

## Analyzer uyarilari

Son detayli analyze loglarinda cok sayida warning/info goruluyor. Bunlar
build'i kirmiyor ancak teknik borc olusturuyor.

### En yaygin uyarilar

| Uyari tipi | Etki | Ornek alanlar |
|---|---|---|
| `unused_import` | Dusuk | Core UI, auth, live, profile, voice_hub |
| `duplicate_import` | Dusuk | Birçok feature widget |
| `unused_element` | Orta | `_mapAdvisor`, `_HostBadge`, `_shareRoom`, `_submitMusicRequestByTitle` |
| `unnecessary_null_comparison` | Dusuk | `chat_room_providers.dart` socket/SSE branch |
| `deprecated_member_use` | Orta | `cacheExtent`, Radio group API, LiveKit options |
| `use_build_context_synchronously` | Orta | Home, live, voice room sheets |
| `prefer_final_fields` | Dusuk | Bazi provider/controller state alanlari |

## Derleme hatalari

Su anda bilinen aktif derleme hatasi yoktur.

Gecmis hata:

- `audio_service` config assertion (`androidNotificationOngoing` +
  `androidStopForegroundOnPause=false`) duzeltildi.

## Runtime riskleri

| Risk | Dosya/alan | Aciklama | Oncelik |
|---|---|---|---|
| Route `state.extra as Type?` castleri | `app/router/app_router.dart` | Yanlis extra tipi runtime cast hatasi uretebilir | Orta |
| `BuildContext` async gap | Birden cok UI dosyasi | Analyzer info; nadiren navigation/snackbar race yaratabilir | Orta |
| Genis `ref.watch` rebuildleri | `voice_room_rtc_page.dart`, home/live sayfalari | Performans ve jank riski | Orta |
| Coklu realtime kanal | Voice/live | SSE + socket + polling ayni anda calisabilir; tekrar event/dedupe kritik | Orta |
| YouTube stream geciciligi | `youtube_stream_resolver.dart` | Stream URL'leri gecersizlesebilir; retry var | Orta |
| Fallback listeler | home/membership/gifts | Uretim API sorunlarini gizleyebilir | Dusuk/Orta |

## Null safety riskleri

| Alan | Risk | Durum |
|---|---|---|
| Bang operator `!` | Bazi UI/state noktalari nullable alanlari zorla aciyor | Kodda mevcut; kritik pathlerde guard var, tarama gerektirir |
| API map castleri | `as Map`, `as int?` gibi castler farkli production payload'larda riskli | Bir cok parser alias destekli; yine de risk var |
| Router extras | Nullable extra yanlis tip ise fallback bazen var bazen yok | Orta risk |

## Performans problemleri

| Alan | Problem | Oneri |
|---|---|---|
| Sesli oda sayfasi | Genis state izleme, cok sayida overlay ve stream | `select`/alt provider kullanimi artirilmali |
| Hediye animasyonlari | Fullscreen + particle + lottie/rive ayni anda jank yaratabilir | RepaintBoundary ve animasyon pooling |
| Home/feed listeleri | Bazi listelerde deprecated `cacheExtent` kullanimi | `scrollCacheExtent` gecisi |
| Socket/SSE/poll | Ayni verinin birden fazla kanaldan gelmesi | Socket/SSE bagliysa poll daha seyrek |
| Image cache | Cok sayida CachedNetworkImage | CacheManager limitleri takip edilmeli |

## Kullanilmayan kod / import adaylari

Analyzer loglarinda oncelikli temizlenebilir adaylar:

- `core/ui/premium/live_badge.dart` unused import
- `core/ui/premium/premium_glass_surface.dart` unused import
- `core/ui/premium/premium_nav_bar.dart` unused import
- `core/ui/premium_2026/cosmic_galaxy_background.dart` unused import
- `core/ui/pro_glass/pro_glass.dart` unused import
- `core/webview/canlifal_cookie_sync.dart` unused import
- `features/home/data/datasources/home_remote_datasource.dart` `_mapAdvisor`
- `features/live/presentation/pages/live_broadcast_room_page.dart` `_HostBadge`
- `features/voice_hub/presentation/providers/chat_room_providers.dart` `_submitMusicRequestByTitle`
- `features/voice_hub/presentation/voice_room_rtc_page.dart` `_shareRoom`

Bu dosyalar build'i kirmadigi icin temizlik dusuk riskli ama genis kapsamli
oldugundan kucuk batchler halinde yapilmalidir.

## Oncelikli duzeltme plani

1. **Kucuk import/duplicate import temizligi**
   - Sadece build davranisi etkilemeyen importlar kaldirilacak.
2. **Voice/live runtime riskleri**
   - `unnecessary_null_comparison`, kullanilmayan helperlar ve async context
     noktalari kucuk yamalarla duzeltilecek.
3. **Router extra guardlari**
   - Direct cast yerine type check kullanilacak.
4. **Performance**
   - `cacheExtent` deprecations ve genis watch alanlari parca parca ele alinacak.

## Uygulanan duzeltmeler

### Paket 1 — dusuk riskli import temizligi

Davranis degistirmeyen analyzer uyarilari temizlendi:

- `core/ui/premium/live_badge.dart`
- `core/ui/premium/premium_glass_surface.dart`
- `core/ui/premium/premium_nav_bar.dart`
- `core/ui/premium_2026/cosmic_galaxy_background.dart`
- `core/ui/pro_glass/pro_glass.dart`
- `core/webview/canlifal_cookie_sync.dart`
- `features/admin/presentation/pages/admin_hub_page.dart`
- `features/auth/presentation/pages/otp_verify_page.dart`
- `features/content_hub/presentation/pages/content_hub_page.dart`
- `features/home/data/repositories/home_repository_impl.dart`
- `features/home/presentation/widgets/home_games_row.dart`

Kontrol:

- `git diff --check` basarili.
- CI `dart analyze lib` ve release APK build sonraki adimda dogrulanacak.

## Sonuc

Uygulamanin son CI durumuna gore aktif derleme hatasi yoktur. En buyuk saglik
borcu analyzer warning/info birikimi, runtime cast/context riskleri ve genis
rebuild/performance alanlaridir. Ilk guvenli duzeltme paketi import/unused
temizligi ve basit analyzer uyarilarindan baslamalidir.

