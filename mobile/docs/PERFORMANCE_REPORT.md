# Canlifal Mobil — Performans Raporu (Görev 19)

**Sürüm:** `1.0.444+448`  
**Backend:** `https://canlifal.com` (değişiklik yok)  
**Ölçüm:** `AppPerfMetrics` + mevcut `StartupPerf` + kod analizi  
**Not:** Cloud ortamında Flutter DevTools CPU/Memory profiler çalıştırılamaz; aşağıdaki tablo statik analiz + unit test + CI kabul testlerine dayanır. Yerelde DevTools → Performance / Network ile doğrulayın.

## Hedef metrikler

| Metrik | Hedef | Mevcut durum (tahmini) | Yapılan iyileştirme |
|--------|-------|------------------------|---------------------|
| Soğuk açılış (ilk kare) | < 2 s | ~1.0–1.8 s (StartupPerf cap) | Paralel init, deferred SDK, cache warm |
| Ekran geçişi | < 300 ms | 250–450 ms (cihaza bağlı) | Route observer + PremiumMotion |
| API sonrası UI güncelleme | < 100 ms | 80–200 ms | HTTP memory cache + inflight dedupe |
| Liste scroll jank | minimal | İyi (LazyListView) | ScrollPerf cacheExtent |

## En yavaş 20 işlem (statik analiz — öncelik sırası)

| # | İşlem | Tip | Tahmini süre | Optimizasyon |
|---|--------|-----|--------------|--------------|
| 1 | İlk Gradle/NDK soğuk derleme | Build | 3–8 dk | CI cache (dış scope) |
| 2 | `GET /api/chat/rooms` (liste) | API | 800 ms–5 s | HTTP cache 30s + SSE presence |
| 3 | Fal SSE `POST /api/fortunes/*` | Stream | 5–90 s | İptal token + idle timeout |
| 4 | Voice room SSE reconnect | SSE | 1–30 s backoff | BaseSseService hub (tek bağlantı) |
| 5 | Auth boot `/api/me` + site profile | API | 400–1200 ms | Paralel Future.wait |
| 6 | Wallet `/api/me` → credits fallback | API | 600–1500 ms | HTTP cache 45s/20s |
| 7 | Mesajlar çift fetch (cache+force) | Bug | 2× RTT | **Düzeltildi** — cache-first tek istek |
| 8 | Bildirimler forceRefresh açılış | Bug | 2× RTT | **Düzeltildi** — cache-first |
| 9 | Discover oda listesi 25s poll | Poll | Sürekli | **30s** + SSE presence |
| 10 | 12× discover room SSE | SSE | 12 conn | SseConnectionHub ref-count |
| 11 | Voice room presence poll + heartbeat | Poll | 25s+30s | SSE varken mesaj poll kapalı |
| 12 | Büyük feed JSON parse | CPU | 50–200 ms | JsonIsolatePerf ≥50 KB |
| 13 | Cinematic hero network image | Image | 200–800 ms | CanlifalNetworkImage + prefetch |
| 14 | Fortune loading overlay animasyon | UI | 16 ms/frame | RepaintBoundary + büyük kart |
| 15 | Chat room `refresh()` parallel | API | 3–5 paralel | NetworkPerf.parallel |
| 16 | Duplicate wallet invalidate | Bug | 2× refresh | **Düzeltildi** — tek invalidate |
| 17 | VideoStreamSseService (ayrı Dio) | SSE | — | BaseSseService migrate (planlı) |
| 18 | Psychic SSE (ayrı implementasyon) | SSE | — | Hub birleştirme (planlı) |
| 19 | POST ödeme (retry yok) | API | — | Retry yalnızca idempotent GET |
| 20 | Route transition (GoRouter) | UI | 200–400 ms | AppPerfMetrics izleme eklendi |

## Görev 19 — uygulanan kod değişiklikleri

### Ağ katmanı
- **`Connection: keep-alive`** + `persistentConnection` (Dio)
- **`ApiRetryInterceptor`:** GET timeout/connection error → max 2 retry, exponential backoff
- **`ApiTimingInterceptor`:** Her istek süresi → `AppPerfMetrics`
- **`ConnectivityService`:** `connectivity_plus` ile online/offline; POST çevrimdışı reddi, GET stale cache
- **`HttpRequestScope`:** Riverpod `ref.onDispose` ile `CancelToken` iptali
- **`safeGet` / `safePost`:** `cancelToken` parametresi

### Tekrarlayan istekler
- Mesaj/sohbet listesi: açılışta `forceRefresh` kaldırıldı (`CacheFirstLoader` arka plan yeniler)
- Bildirimler: ilk yükleme cache-first
- Cüzdan: çift `invalidateWalletCacheFromRef` kaldırıldı

### SSE
- Fal stream: **`FortuneSseSession.cancel()`** — iptal dialogunda sunucu akışı kesilir
- Base SSE Dio: keep-alive

### Ölçüm
- **`AppPerfMetrics`:** API, route, custom span; `slowest(limit: 20)` debug API
- **`StartupRouteObserver`:** Geçiş süreleri kaydı
- **`main()`:** `cold_start` span

## Mevcut altyapı (Görev 1–18 — korundu)

- HTTP cache: memory 256 + disk TTL + inflight dedupe
- JSON isolate: ≥50 KB
- LazyListView / ScrollPerf / ListPerf
- SseConnectionHub (voice + live video)
- Image: CachedNetworkImage + 80 MB cap
- Shell prefetch: wallet, notifications, conversations

## Yerel DevTools profili (önerilen)

```bash
cd mobile
flutter run --profile
# DevTools → Performance: Timeline, CPU, Memory
# DevTools → Network: en yavaş endpoint'ler
```

Debug build'de `[Perf]` logları ve `AppPerfMetrics.slowest()` ile API/route süreleri görülebilir.

## Sonraki adımlar (planlı)

1. `VideoStreamSseService` → `BaseSseService` migrate
2. `/api/me` tek `keepAlive` snapshot provider
3. Mesajlar gerçek sunucu pagination (cursor)
4. CI: `flutter test test/*_perf_test.dart` release gate'e ekle
