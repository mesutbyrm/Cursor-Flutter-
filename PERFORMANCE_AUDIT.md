# Canlifal Mobil — Performans Denetimi

**Tarih:** 2026-07-06  
**Sürüm:** `1.0.499+503`  
**Kapsam:** `mobile/` Flutter istemcisi — özellik eklemeden yalnızca performans

## Ölçüm yöntemi

| Kaynak | Durum |
|--------|--------|
| Flutter DevTools (CPU / Memory / Raster / UI thread) | Cloud agent ortamında çalıştırılamadı — yerelde `flutter run --profile` + DevTools Timeline önerilir |
| `AppPerfMetrics` + `StartupPerf` | Kod içi span / route süreleri |
| Statik kod analizi | Hot path, `ref.watch`, poll, cache, dispose |
| CI `*_perf_test.dart` | Release gate Gate 2 |

Sahte APM metrikleri üretilmedi. Aşağıdaki tablolar kod analizi + mevcut altyapıya dayanır.

## Hedefler vs mevcut durum

| Hedef | Durum | Not |
|-------|--------|-----|
| Ana sayfa < 1 sn | Yakın | Bootstrap cap 1 sn; shell prefetch sıfır gecikme |
| Sesli odalar < 1 sn | İyileştirildi | Presence/live stream lazy gecikme 450/900 ms → 0/200 ms |
| Canlı falcılar < 1 sn | İyi | HTTP cache 2 dk + `select()` rebuild azaltma |
| Kısa video anında | İyileştirildi | 3 videoluk pool, shell prefetch, tile rebuild azaltma |
| FPS 60+ | Altyapı hazır | `RepaintBoundary`, `ListenableBuilder`, scroll cache |
| Jank %0 | Hedef | DevTools ile cihazda doğrulanmalı |
| Memory leak 0 | Kontrol | Video pool dispose, controller listener temizliği |
| Crash 0 | CI gate | Release gate + acceptance |

## Bu oturumda yapılan optimizasyonlar

### Kısa video (TikTok preload)

- `ShortsVideoControllerPool`: max **6 → 3** controller (önceki / aktif / sonraki)
- Disk preload: yalnızca **sonraki** video
- Feed tile penceresi: **7 → 3** tam tile (`_videoWindow = 1`)
- `ShortVideoPageTile`: gereksiz `shortsActiveVideoIdProvider` watch kaldırıldı
- Video yüzeyi: `ListenableBuilder` — parent `setState` azaltıldı
- Shell prefetch: For You feed ilk sayfa arka planda

### Ağ

- `GET /api/short-videos` HTTP cache TTL **25 sn** (inflight dedupe mevcut)
- Mevcut: `ApiCacheInterceptor`, stale offline, `ApiRetryInterceptor` (GET ×2)

### Sesli oda keşfet

- Presence SSE: lazy başlatma **0 ms**
- Canlı yayın listesi lazy: **200 ms** (önce 900 ms)
- Jeton rozeti: `select()` ile dar rebuild

### Canlı falcılar

- AppBar: `approvedPsychicProvider.select()` — liste gövdesi yeniden çizilmez

## Mevcut altyapı (korundu)

- `CanlifalNetworkImage` — memory + disk cache, thumbnail genişliği
- `CacheFirstLoader` — mesajlar / bildirimler offline-first
- `BaseSseService` — SSE reconnect hub, tek bağlantı ref-count
- `LazyListView` / `ScrollPerf` — liste cacheExtent
- `main()` — image cache 80 MB, deferred SDK (OneSignal/Firebase)

## Dürüst kapsam sınırları

| Konu | Neden burada yapılmadı |
|------|-------------------------|
| Gerçek CPU/GPU frame time | Production/cihaz DevTools gerekir |
| Cloudflare CDN | Edge panel yapılandırması |
| WebP/AVIF transcode | Ayrı medya hattı |
| Kısa video CDN adaptive streaming | `canlifal.com` video origin; mobil yalnızca preload |
| Cursor pagination API | Sözleşme kırma riski |
| Brotli | Marjinal kazanç, sunucu bağımlı |

## Yerel doğrulama

```bash
cd mobile
flutter run --profile
# DevTools → Performance: frame chart, shader compilation
# DevTools → Memory: image cache, video controllers
flutter test test/*_perf_test.dart
```

## Sonraki adımlar (planlı)

1. `VideoStreamSseService` → `BaseSseService` birleştirme
2. `/api/me` tek `keepAlive` snapshot provider
3. Mesajlar sunucu cursor pagination (API uyumlu olduğunda)
4. Release gate'e perf test zorunluluğu
