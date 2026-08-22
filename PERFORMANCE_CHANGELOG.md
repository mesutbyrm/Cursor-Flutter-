# Performans Değişiklik Günlüğü

**Sürüm:** `1.0.337+373`  
**Tarih:** 2026-08-22  
**Fazlar:** FAZ 3 (network/startup), FAZ 5 (social video), FAZ 6 (SSE)

---

## FAZ 3 — Startup + Network

### Token bellek önbelleği (`TokenStorage`)

| Önce | Sonra |
|------|--------|
| Her Dio isteğinde `flutter_secure_storage.read()` | İlk okuma sonrası `peekAccess()` — bellekten |
| 12+ secure read / saniye (yoğun scroll) | 1 read / oturum (refresh/logout hariç) |

**Dosyalar:** `mobile/lib/core/network/token_storage.dart`, `dio_provider.dart`  
**Test:** `mobile/test/token_storage_perf_test.dart`

### MobileCompoundRemoteDataSource tekilleştirme

| Önce | Sonra |
|------|--------|
| 3 ayrı instance (home, profile, fortune) | 1 shared `mobileCompoundRemoteProvider` |
| 3× `/api/mobile/home` bellek önbelleği | 1× paylaşımlı 45 sn TTL cache |

**Dosyalar:** `mobile_compound_remote_datasource.dart`, `home_providers.dart`, `profile_providers.dart`, `user_session_cleanup.dart`

---

## FAZ 5 — Social Video

### Sosyal feed video player

| Önce | Sonra |
|------|--------|
| Her video kartı `initState`'te controller + `play()` | Dokunana kadar poster; 0 aktif player scroll sırasında |
| N eşzamanlı `VideoPlayerController` (feed'de N video post) | Max 1 (kullanıcı oynattığı) |

**Dosya:** `social_post_video_player.dart`

---

## FAZ 6 — SSE

### Oda SSE `connect()` — keşif → oda geçişi

| Önce | Sonra |
|------|--------|
| `isLiveForRoom` → erken çıkış, `onConnected` bir daha çağrılmaz | Bağlı + connected fazında `onConnected` yeniden çağrılır |
| Presence join / seat refresh kaçabilir | Oda sayfası keşif SSE'sini yeniden kullanır |

**Dosya:** `chat_room_sse_service.dart`

---

## Henüz yapılmadı (sonraki fazlar)

- Discover SSE sayısı azaltma (12 → 4-6)
- `voice_room_rtc_page` granular `select` rebuild
- `shrinkWrap` nested scroll refactor
- Shorts pool 5 → 3
- Gerçek cihaz benchmark (`PERFORMANCE_AFTER.md`)

---

## Regression

- `flutter test`: beklenen 996+ pass (2 yeni token test)
- `flutter analyze`: mevcut info seviyesi korunmalı
- Backend API: değişiklik yok
