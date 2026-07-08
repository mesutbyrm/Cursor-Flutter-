# Performans Optimizasyon Raporu — 1.0.505+509

**Tarih:** 2026-07-08  
**Hedef:** Web sürümüne yakın açılış süresi, akıcı scroll, düşük bellek ve ağ tıkanıklığı.

---

## Özet

Bu sürümde ana sayfa, sesli odalar, canlı falcılar ve kısa videolar için **soğuk açılış**, **Riverpod rebuild**, **görsel önbellek**, **video preload** ve **arka plan animasyon** optimizasyonları uygulandı. Mevcut işlevler korundu; yalnızca yükleme sırası, cache ve widget izolasyonu iyileştirildi.

---

## Flutter — Yapılan Değişiklikler

### 1. Kabuk prefetch kademelendirme (`shell_prefetch.dart`)

| Kademe | Gecikme | İstekler |
|--------|---------|----------|
| T+0 | 0 ms | Bildirimler, cüzdan, profil istatistikleri, TRTC ön ısıtma |
| T+450 | 450 ms | Sohbet listesi |
| T+900 | 900 ms | Shorts For You feed |
| T+1400 | 1400 ms | Jeton paketleri |

**Beklenen etki:** Soğuk açılışta eşzamanlı 6+ API yerine 3 kritik istek; ana thread ve TLS el sıkışması baskısı ~%40 azalır.

### 2. Ana sayfa bootstrap (`home_bootstrap.dart`)

- `homeOnlinePsychicsProvider` paralel prefetch'e eklendi (7 paralel görev).
- Falcı listesi ana sayfa ve `/canli-falcilar` arasında paylaşımlı `keepAlive` cache.

**Beklenen etki:** Canlı Falcılar bölümü ilk boyamada ~200–400 ms daha hızlı (önbellek isabetinde).

### 3. Riverpod `keepAlive` genişletme (`home_providers.dart`, `shorts_providers.dart`)

- `homeAdvisorsProvider`, `homeGamesProvider`, `homeDailyRewardsProvider` → oturum cache.
- `ShortsFeedNotifier` → sekme değişiminde feed yeniden fetch azalır.

### 4. Gereksiz rebuild azaltma

| Dosya | Değişiklik |
|-------|------------|
| `main_app_shell.dart` | `goRouterProvider` → `ref.read`; presence ayrı `VoiceRoomsPresenceScope` |
| `voice_room_section.dart` | `homeVoiceRoomsProvider.select` ile tuple izleme |
| `psychics_list_screen.dart` | Auth `select`, skeleton loader, `CosmicGalaxyBackground(animate: false)` |

**Beklenen etki:** Kabuk ve ana sayfa bölümlerinde gereksiz rebuild ~%25–35 azalır.

### 5. Sesli odalar (`voice_rooms_page.dart`)

- `addAutomaticKeepAlives: false` — off-screen tile bellek tutma kapatıldı.
- `DeferredTickerMode` (200 ms) — parçacık/gradient animasyonu ilk kareden sonra.

**Beklenen etki:** Liste scroll bellek kullanımı ~%15 düşer; ilk paint ~100–150 ms hızlanır.

### 6. Kısa video preload (`shorts_video_controller_pool.dart`)

- Disk preload: yalnızca sonraki `[1]` → **önceki + sonraki `[-1, 1]`**.
- Placeholder tile: `Image.network` → `CanlifalNetworkImage` (disk/mem cache).

**Beklenen etki:** Yukarı/aşağı kaydırmada video başlama gecikmesi ~150–300 ms azalır.

### 7. Görsel önbellek tutarlılığı

- `profile_hub_header.dart` — kapak `CanlifalNetworkImage`
- `shorts_feed_placeholder_tile.dart` — thumbnail cache
- `short_story_share_card.dart` — paylaşım kartı thumbnail cache

**Beklenen etki:** Tekrar ziyaret edilen görsellerde ağ isteği sıfır; bellek `memCacheWidth` ile sınırlı.

### 8. Ana sayfa realtime poll (`home_realtime_bridge.dart`)

- Poll aralığı 90 s → **120 s**.

**Beklenen etki:** Arka planda gereksiz liste invalidation ~%25 azalır.

### 9. Yeni bileşen: `VoiceRoomsPresenceScope`

- SSE presence izolasyonu; kabuk `Stack` yeniden çizilmez.

---

## Beklenen Performans Kazanımları (tahmini)

| Alan | Metrik | Önce (tahmin) | Sonra (tahmin) |
|------|--------|---------------|----------------|
| Ana sayfa ilk içerik | TTFC | 1.2–1.8 s | 0.7–1.2 s |
| Sesli odalar ilk liste | TTFC | 0.9–1.4 s | 0.6–1.0 s |
| Canlı falcılar liste | TTFC | 0.8–1.2 s | 0.5–0.9 s |
| Shorts video geçiş | Kaydırma gecikmesi | 300–500 ms | 100–250 ms |
| Kabuk rebuild | Frame başına widget | Yüksek | Orta |
| Soğuk açılış ağ | Eşzamanlı istek | 8–10 | 3–4 (ilk 500 ms) |

*Gerçek ölçüm: Flutter DevTools → Performance, Network; `AppPerfMetrics` debug çıktısı.*

---

## Cloudflare / CDN — Backend Tarafı (bu repoda uygulanmadı)

Aşağıdaki görevler **canlifal.com sunucu/Cloudflare paneli** erişimi gerektirir; mobil istemci tarafında yapılamaz.

### Kontrol listesi

1. **`/shorts/*` Bot Challenge** — Video player `Range` istekleri challenge alıyorsa oynatma kesilir.  
   - **Öneri:** `cf.bot_management` bypass kuralı: path `/shorts/*` + known video MIME + mobil User-Agent veya signed URL.

2. **Cache Rules** — Statik video segmentleri için:  
   `Cache-Control: public, max-age=31536000, immutable`

3. **Video pipeline**  
   - `ffmpeg -movflags +faststart` (progressive download)  
   - Otomatik thumbnail (poster frame)  
   - HLS (`m3u8`) + çoklu bitrate (isteğe bağlı)

### Beklenen CDN etkisi

| Optimizasyon | Etki |
|--------------|------|
| Challenge bypass (video) | İlk frame 1–3 s daha hızlı; 403/retry yok |
| `immutable` cache | Tekrar izlemede edge cache hit ~%95+ |
| `faststart` | İlk oynatma 200–800 ms hızlanır |
| HLS | Adaptif kalite, zayıf ağda daha az rebuffer |

---

## Doğrulama

```bash
cd mobile && dart analyze
cd mobile && flutter test
```

DevTools ile kontrol:
- **CPU:** Voice rooms scroll sırasında frame >16 ms düşüşü
- **Memory:** Shorts 20+ video kaydırma sonrası controller sayısı ≤3
- **Network:** Soğuk açılışta ilk 500 ms istek sayısı
- **Rebuild:** Provider `select` ile izole widget ağaçları

---

_Bu dosya CI tarafından otomatik güncellenmez; sürüm notları için `mobile/CHANGELOG.md`._
