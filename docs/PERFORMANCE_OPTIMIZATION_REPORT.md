# Performans optimizasyon raporu — 1.0.29+34

**Tarih:** 2026-07-14  
**Hedef:** Soğuk açılış &lt; 2 sn, ekran geçişleri &lt; 300 ms (mevcut özellikler korunarak)

## Özet

Uygulama genelinde analiz yapıldı; yüksek etkili düzeltmeler uygulandı. Altyapı zaten güçlüydü (paralel storage init, tek `Dio`, Hive + `ApiCacheStore`, `CanlifalNetworkImage`, deferred SDK bootstrap, `VoiceRoomEntryPerf`).

## Yapılan optimizasyonlar

### 1. Soğuk açılış (cold start)

| Değişiklik | Dosya | Etki |
|------------|-------|------|
| Cookie jar `forceInit()` runApp sonrasına ertelendi | `main.dart` | İlk kare daha erken |
| Shell prefetch kademelendi: cüzdan T+200ms, bildirim+profil T+600ms (paralel), mesajlar T+1100ms, shorts T+2200ms, jeton T+3500ms | `shell_prefetch.dart`, `startup_perf.dart` | Açılışta ağ yükü azaldı |

### 2. Bağlantı durumu (rebuild düzeltmesi)

| Değişiklik | Dosya | Etki |
|------------|-------|------|
| `isOnlineProvider` artık `ConnectivityService.onlineStream` dinliyor | `online_status_notifier.dart` | Offline banner ve sync doğru tetiklenir; gereksiz stale okuma yok |

### 3. Sesli oda — gereksiz rebuild

| Değişiklik | Dosya | Etki |
|------------|-------|------|
| Basic mod: `_BasicLiveShell` ile mesajlar hariç selective watch | `voice_room_basic_page.dart` | Her chat mesajında tüm oda ağacı yeniden çizilmez |
| `VoiceRoomBasicChatFeed` → `ConsumerWidget`; yalnızca `messages` + `presence` | `voice_room_basic_premium_section.dart` | Sohbet izole rebuild |
| Sohbet overlay filtre önbelleği (uzunluk + son id) | `voice_web_chat_overlay.dart` | `build()` içinde tekrarlayan filter azaldı |
| Hediye paneli katalog sort/filter önbelleği | `voice_premium_gift_panel_2026.dart` | Panel açıkken gereksiz sort yok |

> RTC sayfası (`voice_room_rtc_page.dart`) zaten `_RtcLiveShell` kullanıyordu — dokunulmadı.

### 4. Global poll aralıkları (CPU / ağ)

| Bileşen | Eski | Yeni |
|---------|------|------|
| DM global poll | 8 sn | 12 sn |
| Psikolog gelen çağrı | 2 sn | 4 sn |
| PK davet (sesli) | 3 sn | 5 sn |
| PK davet (canlı) | 2 sn | 4 sn |
| DM sohbet sayfası | 4 sn | 5 sn |
| Yazıyor göstergesi | 2,5 sn | 3,5 sn |

Tüm timer'lar mevcut `dispose` / `ref.onDispose` ile kapatılıyor — sızıntı tespit edilmedi.

### 5. Görsel / cache

| Değişiklik | Dosya |
|------------|-------|
| Admin hediye listesinde `Image.network` → `CanlifalNetworkImage` | `admin_gift_management_page.dart` |
| Profil: `authControllerProvider.select(valueOrNull)` | `profile_page.dart` |

### 6. Zaten mevcut (değiştirilmedi)

- **Dio:** Tek `dioProvider` instance (`dio_provider.dart`)
- **Hive:** `LocalCache` (`staff_roles`, tema, bayraklar)
- **API cache:** `ApiCacheStore` + `ApiHttpCache` interceptor
- **Görseller:** `cached_network_image` via `CanlifalNetworkImage`
- **SSE:** `BaseSseService.disconnect()`, `sse_hub_provider` `onDispose`
- **Deferred:** Firebase, OneSignal, AdMob T+800ms

## Ölçüm notları

- `AppPerfMetrics.mark('cold_start')` — `main.dart` içinde ölçülüyor
- `VoiceRoomEntryPerf` — oda giriş bütçesi 2 sn
- CI / cihazda gerçek süreler donanıma bağlı; bu sürüm ağ ve rebuild yükünü azaltır

## Sonraki adımlar (öneri)

1. `VoiceRoomLiveState` alt provider'lara bölme (messages / presence / dj)
2. `ref.listen` bloklarını `initState` / notifier callback'e taşıma (RTC sayfası)
3. DM sohbet için SSE veya push öncelikli senkron (poll yedek)
4. Release profilinde `devtools` timeline ile cold start doğrulama

## Sürüm

`1.0.29+34` — `mobile/pubspec.yaml`, `mobile/CHANGELOG.md`
