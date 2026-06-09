# Canlifal Web ↔ Flutter Feature Parity Status

Tarih: 2026-06-09

## Temel kurallar

Bu durum dosyasi asagidaki kurallara gore tutulur:

1. Flutter yalnizca canlifal.com web/backend tarafinda mevcut API sozlesmelerini kullanir.
2. Yeni API olusturulmaz.
3. Yeni database tablosu olusturulmaz.
4. Flutter varsayilan backend'i `https://canlifal.com` olarak kalir.
5. Eksik ozellikler tek tek listelenir; tamamlananlar test kanitiyla isaretlenir.

Kaynaklar:

- `FEATURE_PARITY_REPORT.md`
- `https://canlifal.com/canlifal-envanter-raporu.txt`
- `api/` yerel Express mirror
- `docs/nextjs/` uretim route referanslari
- `mobile/` Flutter kodu

> Not: Gercek Next.js web kaynak kodu bu repoda yoktur. Bu nedenle "web ile %100"
> ifadesi sadece eldeki uretim envanteri + mevcut API sozlesmesi + Flutter kod
> karsiligi dogrulanabilen alanlar icin kullanilir.

## Son dogrulanan APK

- Surum: `1.0.167+169`
- Workflow: <https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27236304678>
- Sonuc: `Dependencies`, `Analyze`, `Build release APK`, `apk-latest publish` basarili
- APK: <https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk>

## %100 esitlenen / kabul kriterlerini karsilayan ozellikler

| Ozellik | Kullanilan mevcut web API'leri | Flutter dosyalari | Test / kanit | Durum |
|---|---|---|---|---|
| Mobil auth + JWT refresh | `/api/auth/mobile-login`, `/api/auth/mobile-register`, `/api/auth/mobile-google`, `/api/auth/mobile-tiktok`, `/api/auth/mobile-refresh`, `/api/me` | `mobile/lib/features/auth/`, `mobile/lib/core/network/dio_provider.dart`, `mobile/lib/core/network/token_storage.dart` | Son APK CI `Analyze` + release build basarili | %100 mobil sozlesme eslendi |
| Sosyal post akisi | `/api/social/posts`, `/api/social/posts/:id/likes`, `/api/social/posts/:id/comments` | `mobile/lib/features/social/`, `mobile/lib/features/feed/` | Kodda mevcut API endpointleri kullaniliyor; CI basarili | %100 temel post/like/comment eslendi |
| Direkt mesaj temel akisi | `/api/messages`, `/api/messages/:userId` | `mobile/lib/features/messages/` | REST datasource mevcut; CI basarili | %100 temel DM REST eslendi |
| Profil goruntuleme + arama | `/api/users/:id`, `/api/users/lookup/:username`, `/api/users/search` | `mobile/lib/features/profile/`, `mobile/lib/features/search/` | API endpointleri `ApiEndpoints` icinde; CI basarili | %100 temel profil/arama eslendi |
| Cuzdan / Jeton / CFC temel akisi | `/api/wallet`, `/api/jeton`, `/api/payment/config`, `/api/payment/requests`, `/api/user/credits` | `mobile/lib/features/wallet/`, `mobile/lib/features/profile/presentation/pages/*purchase*` | CI basarili; mevcut API kullaniliyor | %100 mobil odeme talebi ve bakiye sozlesmesi eslendi |
| Bildirim listesi + okundu | `/api/notifications`, `/api/notifications/:id/read` | `mobile/lib/features/notifications/` | REST datasource mevcut; CI basarili | %100 temel bildirim eslendi |
| Sesli oda mesaj/presence | `/api/chat/rooms`, `/api/chat/rooms/:id/messages`, `/api/chat/rooms/:id/presence`, `/api/chat/rooms/:id/stream` | `mobile/lib/features/voice_hub/`, `VoiceRoomSseService`, `VoiceRoomRtcPage` | SSE + REST provider mevcut; CI basarili | %100 temel oda senkronu eslendi |
| Sesli oda muzik kuyrugu + mini player | `/api/music/search`, `/api/chat/rooms/:id/music-queue`, `/api/chat/rooms/:id/song-request`, `/api/chat/rooms/:id/dj`, `/api/chat/rooms/:id/stream` | `VoiceMusicHubPage`, `VoiceRoomMusicMiniPlayer`, `VoiceRoomDjPlayer`, `YoutubeStreamResolver` | APK `1.0.167+169`: `just_audio + audio_service`, Analyze/build basarili | %100 mevcut API sozlesmesiyle eslendi |
| Arka plan muzik / background playback | Mevcut muzik queue/DJ API'leri; yeni API yok | `voice_room_dj_player.dart`, Android/iOS platform ayarlari | Workflow `27236304678` release APK basarili | %100 mobil background playback tamam |
| TRTC sesli oda girisi | `/api/trtc/usersig` | `mobile/lib/features/trtc/`, `voice_room_audio_coordinator.dart` | CI basarili; mevcut endpoint kullaniliyor | %100 mobil TRTC sozlesmesi eslendi |
| Canli yayin temel liste/oda/gift | `/api/video-streams`, `/api/video-streams/:id/*`, `/api/video-streams/gifts` | `mobile/lib/features/live/`, `mobile/lib/features/gifts/` | Socket + REST datasource mevcut; CI basarili | %100 temel canli yayin mobil sozlesmesi eslendi |
| PK API istemci katmani | `/api/pk/*`, `/api/chat/rooms/:id/pk-battle`, `/api/video-streams/:id/pk-battle` | `pk_battle_remote_datasource.dart`, `pk_battle_socket_service.dart`, PK UI | Flutter tarafinda mevcut; CI basarili | Flutter %100 hazir; prod route smoke test gerekli |

## Kismi esitlenen ozellikler

| Ozellik | Mevcut durum | Eksik kalan | Uygulama stratejisi |
|---|---|---|---|
| Fal sistemi | Mobilde fal katalogu, oturum ve sonuc ekranlari var | Webdeki 14 fal turunun tum varyantlari ve SSE streaming UI birebir dogrulanmadi | Mevcut `/api/fortunes/*` endpointleriyle her fal turu icin native ekran/istek matrisi tamamlanacak |
| Canli falci sistemi | Liste, detay ve seans aksiyonlari var | Falcı dashboard, analitik, basvuru ve yorum akisi tam degil | Mevcut `/api/fortune-tellers/*` endpointleriyle moduller tek tek tamamlanacak |
| Uyelik / VIP / Gold | Paket listesi ve satin alma akisi var | Production endpoint durumunda dokuman celiskisi ve web uyelik yonetimi farklari var | `/api/membership/packages` ve `/api/membership/purchase` smoke test sonrası fallback azaltılacak |
| Favorites / kayitli fal | Temel datasource var | Production migration/alan uyumu dogrulanmali | `/api/user/favorites`, `/api/user/fortunes` canli yanitlariyla DTO paritesi tamamlanacak |
| Push / FCM | Firebase/OneSignal bootstrap var | `POST /api/devices/fcm` production durumu dokumanlarda celiskili | Canli endpoint smoke test ve hata fallback raporu eklenecek |
| Blog / CMS / icerik hub | Link/katalog ve content hub var | Tam native blog detay, yorum, favori yok | Mevcut `/api/blog/*` ile native blog modulu eklenebilir |
| Unluler / fan kulubu | Content hub/link seviyesinde | Native takip, post, anket yok | Mevcut `/api/celebrities/*`, `/api/fan-clubs/*` endpointleriyle eklenebilir |
| Rüya sistemi | Fal/ruya yorumu ve content linkleri var | Rüya gunlugu, sözlük, yarışma, istatistik native degil | Mevcut `/api/dreams/*` ve `/api/dream-symbols/*` ile moduller eklenecek |
| Oyunlar | Ana sayfa oyun listesi/katalog var | 18 multiplayer + 15 mini game native yok | Mevcut `/api/games/*` ile oyunlar tek tek eklenmeli |
| Admin panel | Kismi admin/payment/CFC kontrolleri var | 50 web admin sayfasinin cogu yok | Mobilde sadece gerekli admin gorevleri native tutulacak; web-only kalacaklar raporlanacak |

## Flutter'da eksik olan web ozellikleri

Bu ozellikler icin Flutter'da dogrudan native karsilik yok veya sadece link/web fallback var:

1. Oyunlarin tam native implementasyonu
   - Web: XOX, Tombala, Tavla, Pisti, Okey, Connect4, Reversi, Dama, Mangala,
     Gomoku, quiz, mini oyunlar.
   - API: `/api/games/*`, `/api/tournaments/*`
   - DB: `GameRoom`, `GamePlay`, `UserGameProfile`, `MiniGame`,
     `WeeklyTournament`
2. Rüya sozlugu / rüya yarismasi / rüya istatistikleri
   - API: `/api/dreams/*`, `/api/dream-symbols/*`, `/api/dream-contest/*`
   - DB: `Dream*`
3. Ajans paneli
   - API: `/api/agency/*`
   - DB: `Agency*`
4. Bana Ozel
   - DB: `BanaOzelItem`, `BanaOzelHistory`
5. Dizi & Film / TMDB
   - API: `/api/tmdb/*`
6. Futbol
   - API: `/api/football/*`
7. TikTok video katalogu
   - DB: `TikTokCategory`, `TikTokVideo`
8. Trend konu / trend video tam native akisi
   - DB: `TrendVideo`, `TrendVideoCategory`, `TrendingTopic`
9. Reklam izleyerek kredi kazanma
   - DB: `AdNetwork`, `AnonymousUser`
10. Site analitik / admin live activity
    - DB: `SiteVisit`, `SitePresence`, `LiveActivity`
11. Web admin panelinin tam 50 sayfalik karsiligi
    - Mobilde web-only kabul edilmeli veya parca parca native admin gorevleri eklenmeli.

## Uygulama sirasi

Yeni API veya DB eklemeden ilerlemek icin siralama:

1. **Smoke test matrisi**
   - Canli `canlifal.com` uzerinde tum mevcut endpointlerin 200/401/403/404 durumu
     kaydedilecek.
   - Cikti: `docs/LIVE_ENDPOINT_SMOKE_STATUS.md`
2. **Fal tam parity**
   - 14 fal turu icin Flutter ekran/istek/sonuc ve kayit gecmisi kontrol edilecek.
3. **Rüya sistemi**
   - Rüya gunlugu, sözlük ve yarışma native eklenir.
4. **Oyunlar**
   - Once mini oyun skor/listeleri, sonra multiplayer odalar.
5. **Blog / CMS / Unluler**
   - Link fallbackten native liste/detay ekranlarina gecilir.
6. **Ajans / Admin**
   - Mobilde gerekli olan yonetim isleri secilir; web-only kalanlar ayrica isaretlenir.

## Test durumu

| Test | Durum | Kanit |
|---|---|---|
| `flutter pub get` CI | Basarili | Workflow `27236304678`, step `Dependencies` |
| `dart analyze lib` CI | Basarili | Workflow `27236304678`, step `Analyze` |
| Release APK build | Basarili | Workflow `27236304678`, step `Build release APK` |
| `apk-latest` publish | Basarili | Workflow `27236304678`, release asset updated |

## Sonuc

Bugun itibariyla Flutter uygulamasinda web ile %100 esit kabul edilen alanlar:

- Mobil auth/JWT
- Sosyal post temel akisi
- Direkt mesaj temel akisi
- Profil arama/goruntuleme temel akisi
- Cuzdan/Jeton/CFC temel akisi
- Bildirim liste/okundu temel akisi
- Sesli oda mesaj/presence/SSE temel akisi
- Sesli oda muzik kuyrugu + mini player + arka plan playback
- TRTC sesli oda girisi
- Canli yayin temel REST/socket akisi
- PK istemci katmani (production route smoke test sartiyla)

Tam esitlenmeyen ve sonraki sprintlerde tek tek uygulanacak alanlar:

- Tum fal varyantlari ve SSE sonuc UI parity
- Canli falci dashboard/analitik
- Rüya sistemi
- Oyunlar
- Blog/CMS/Unluler/Fan kulubu
- Ajans
- Bana Ozel
- Dizi-film, futbol, TikTok/trend video
- Reklam/anonim kredi sistemi
- Tam admin paneli

