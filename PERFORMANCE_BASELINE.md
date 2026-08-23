# Canlifal Flutter — Performans Baseline (FAZ 2 öncesi)

**Tarih:** 2026-08-22  
**Sürüm:** `1.0.336+372`  
**Audit eşleniği:** [`PERFORMANCE_AUDIT.md`](PERFORMANCE_AUDIT.md)  
**Durum:** Optimizasyon **başlamadı** — yalnızca ölçülebilir baseline ve bütçe tanımı

---

## 1. Amaç

Optimizasyon öncesi/sonrası karşılaştırma için **sayısal referans noktası**. Sahte veya tahmini cihaz metrikleri üretilmedi; ölçülemeyen kalemler açıkça işaretlendi.

---

## 2. Performans bütçesi (hedefler)

Kullanıcı spesifikasyonundan — optimizasyon kabul kapısı:

| Kategori | Metrik | Hedef |
|----------|--------|-------|
| **Startup** | Cold start | **< 2,0 s** |
| | Warm start | **< 1,0 s** |
| | İlk anlamlı UI | **< 1,5 s** |
| **Navigation** | Sekme/ekran geçişi (hissedilen) | **< 300 ms** |
| **Scroll** | FPS | **≥ 60** (90/120 Hz cihazda native'e yakın) |
| **Jank** | >16,67 ms frame oranı | **< %1** |
| **Memory** | 30 dk kullanım | Sürekli artış yok |
| **Network** | Aynı endpoint+param duplicate | **0** |
| **SSE** | Aynı oda duplicate connection | **0** |
| **TRTC** | Duplicate SDK init | **0** |
| **Video** | Eşzamanlı gereksiz player | **≤ 1 aktif** (+1 preload) |
| **Image** | Gereksiz full-res decode | **0** (widget boyutuna göre) |
| **Cache** | Logout sonrası önceki kullanıcı verisi | **PASS** |
| **Functional** | Acceptance testleri | **994+ pass** |

---

## 3. Şu an ölçülen değerler (CI / statik / cloud agent)

### 3.1 Derleme ve test

| Metrik | Değer | Ortam | Komut / kaynak |
|--------|------:|-------|----------------|
| `flutter test` | **994 pass**, **0 fail**, **2 skip** | Cloud agent, 2026-08-22 | `cd mobile && flutter test` (~133 s) |
| `flutter analyze` | **404 issue** (çoğunlukla `info`) | Cloud agent | `cd mobile && flutter analyze` |
| Flutter SDK (ortam) | **3.47.1** | Cloud agent | `flutter --version` |
| Flutter SDK (proje pin) | **3.44.8** | Repo | `mobile/.flutter-version` |
| Dart SDK | **3.13.1** (ortam) | Cloud agent | `flutter --version` |

### 3.2 APK boyutu

| Metrik | Değer | Kaynak |
|--------|------:|--------|
| Release APK (`canlifal-mobile-release.apk`) | **252 276 640 B** (**240,6 MiB**) | GitHub release `apk-latest`, CI run [32506705382](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32506705382) |
| `mobile/assets/` | **9,4 MiB** | `du -sh mobile/assets` |
| Dart kaynak dosyası | **1595** | `find mobile/lib -name '*.dart'` |

### 3.3 Statik kod metrikleri (baseline snapshot)

| Metrik | Değer | Yöntem |
|--------|------:|--------|
| `ref.watch(` | **963** | `rg -c` toplam |
| `shrinkWrap: true` | **51** | `rg` |
| `ListView(` dosya sayısı | **76** | `rg -l` |
| `ListView.builder` dosya | **37** | `rg -l` |
| `AnimationController(` | **83** | `rg -c` toplam |
| `Timer(` | **65** | `rg -c` toplam |
| `BackdropFilter` | **53** | `rg -c` toplam |
| `VideoPlayerController` ref | **54** | `rg -c` toplam |
| `pubspec` dependency satırı | **~75** | `pubspec.yaml` |

### 3.4 Mevcut altyapı sabitleri (kod içi)

| Sabit | Değer | Dosya |
|-------|-------|-------|
| Auth bootstrap cap | 1 s | `startup_perf.dart` |
| Auth boot timeout | 12 s | `startup_perf.dart` |
| Deferred SDK delay | 400 ms | `startup_perf.dart` |
| Shell prefetch T1 | 200 ms | `startup_perf.dart` |
| Shell prefetch T2 | 1100 ms | `startup_perf.toml` → `startup_perf.dart` |
| Shell prefetch T3 (shorts) | 2200 ms | `startup_perf.dart` |
| Shell prefetch T4 (jeton) | 3500 ms | `startup_perf.dart` |
| HTTP cache default TTL | 45 s | `api_cache_policy.dart` |
| JSON isolate eşiği | 50 KB | `json_isolate_perf.dart` |
| Image memory max | 100 MB / 200 entry | `canlifal_image_cache.dart` |
| Image disk max | 600 dosya / 30 gün | `canlifal_image_cache_manager.dart` |
| Shorts video pool max | **5** controller | `shorts_video_controller_pool.dart` |
| Discover SSE max rooms | **12** (home: **6**) | `voice_rooms_presence_provider.dart` |
| SSE heartbeat timeout | 45 s | `base_sse_service.dart` |
| Gift seat flash max / TTL | 3 / 3 s | `voice_seat_gift_flash_provider.dart` |

### 3.5 Perf unit testleri (regression gate)

| Test dosyası | Ne doğrular |
|--------------|-------------|
| `test/app_perf_metrics_test.dart` | Span kayıt / rapor |
| `test/network_perf_test.dart` | Paralel future, silent fail |
| `test/scroll_perf_test.dart` | LazyListView yalnızca görünür satır |
| `test/state_perf_test.dart` | SelectiveConsumer gereksiz rebuild engeli |
| `test/json_isolate_perf_test.dart` | Büyük JSON isolate eşiği |
| `test/voice_room_entry_perf_test.dart` | TRTC credential tek kullanım cache |
| `test/animation_perf_test.dart` | Animation lifecycle |
| `test/effects_perf_test.dart` | GPU efekt yardımcıları |
| `test/widget_perf_test.dart` | Widget perf helper |
| `test/live_entry_perf_test.dart` | Canlı giriş perf |
| `test/core/performance/animation_perf_test.dart` | Animation perf core |

**Sonuç:** 994 test PASS — perf alt kümesi dahil.

---

## 4. Henüz ölçülmeyen metrikler (gerçek cihaz gerekli)

Aşağıdaki tablo **boş** — optimizasyon öncesi/sonrası doldurulacak. Cloud agent'ta emülatör/fiziksel cihaz olmadığı için ölçüm yapılamadı.

### 4.1 Startup

| Senaryo | Ölçüm | Hedef | Baseline (öncesi) | Sonrası |
|---------|-------|------:|-------------------|---------|
| Cold start ×5 ortalama | `adb shell am start -W` / `AppPerfMetrics` | < 2,0 s | **ÖLÇÜLMEDİ** | — |
| Warm start ×5 ortalama | Aynı | < 1,0 s | **ÖLÇÜLMEDİ** | — |
| İlk anlamlı UI (home shell) | Timeline / `StartupPerf` span | < 1,5 s | **ÖLÇÜLMEDİ** | — |

### 4.2 Ekran geçişleri

| Senaryo | Hedef | Baseline | Sonrası |
|---------|------:|----------|---------|
| Home → Social | < 300 ms | **ÖLÇÜLMEDİ** | — |
| Home → Shorts | < 300 ms | **ÖLÇÜLMEDİ** | — |
| Home → Voice discover | < 300 ms | **ÖLÇÜLMEDİ** | — |
| Profile open | < 300 ms | **ÖLÇÜLMEDİ** | — |
| DM open | < 300 ms | **ÖLÇÜLMEDİ** | — |

### 4.3 Scroll / FPS / jank

| Senaryo | Hedef | Baseline | Sonrası |
|---------|------:|----------|---------|
| Home scroll ×3 | 60 FPS, jank < %1 | **ÖLÇÜLMEDİ** | — |
| Social feed scroll ×3 | 60 FPS | **ÖLÇÜLMEDİ** | — |
| Shorts swipe ×3 | 60 FPS | **ÖLÇÜLMEDİ** | — |
| Voice room UI scroll | 60 FPS | **ÖLÇÜLMEDİ** | — |

### 4.4 Voice / TRTC / SSE

| Senaryo | Hedef | Baseline | Sonrası |
|---------|------:|----------|---------|
| Voice room join | < 1 s hissedilen | **ÖLÇÜLMEDİ** | — |
| Voice room leave | Kaynak temizliği PASS | **ÖLÇÜLMEDİ** | — |
| Room switch | Duplicate SSE/TRTC 0 | **ÖLÇÜLMEDİ** | — |
| 10 ardışık gift | FPS drop < %5 | **ÖLÇÜLMEDİ** | — |

### 4.5 Memory / CPU / network

| Senaryo | Hedef | Baseline | Sonrası |
|---------|------:|----------|---------|
| Idle RAM (app açık, home) | Stabil | **ÖLÇÜLMEDİ** | — |
| Feed scroll 5 dk RAM | Unbounded growth yok | **ÖLÇÜLMEDİ** | — |
| 30 dk mixed usage RAM | Sürekli artış yok | **ÖLÇÜLMEDİ** | — |
| Home ilk 10 sn network request sayısı | Minimize | **ÖLÇÜLMEDİ** | — |
| Duplicate `/api/me` sayısı | 0 | **ÖLÇÜLMEDİ** | — |

---

## 5. Gerçek cihaz benchmark prosedürü (FAZ 10)

### 5.1 Cihaz matrisi (minimum)

| Segment | Örnek | Refresh |
|---------|-------|---------|
| Düşük/orta | 4 GB RAM, Snapdragon 6xx / MediaTek G serisi | 60 Hz |
| Güçlü | 8+ GB RAM, flagship SoC | 90–120 Hz |

### 5.2 Araçlar

1. **Flutter DevTools** — Performance, CPU profiler, Memory  
2. **`flutter run --profile`** — release'e yakın  
3. **`adb shell am start -W`** — startup Intent timing  
4. **Android Studio Profiler** — RAM/CPU (opsiyonel)  
5. **`AppPerfMetrics.formatApiReport()`** — debug log / API span  

### 5.3 Tekrar protokolü

Her senaryo:

- Cold start: uygulama force-stop → 5 ölçüm → ortalama + p95  
- Warm start: background → foreground → 5 ölçüm  
- Scroll: 30 sn sürekli scroll, Timeline'dan jank %  
- Memory: 30 dk script (home → social → shorts → voice → gift → logout)  

### 5.4 Kayıt şablonu

```
Tarih:
Cihaz:
APK: 1.0.336+372
Cold start avg: ___ s (n=5)
Warm start avg: ___ s
Social feed jank: ___ %
Shorts first frame: ___ ms
Voice join: ___ ms
RAM idle: ___ MB
RAM 30min: ___ MB (delta: ___)
Network dup /api/me: ___
```

---

## 6. Kabul kapısı (PERFORMANCE GATE)

Optimizasyon **tamamlandı** sayılmadan önce:

| Gate | Baseline (şimdi) | Hedef |
|------|------------------|-------|
| Cold start | ÖLÇÜLMEDİ | < 2,0 s |
| Navigation | ÖLÇÜLMEDİ | < 300 ms |
| Scroll FPS | ÖLÇÜLMEDİ | ≥ 60 |
| Jank | ÖLÇÜLMEDİ | < %1 |
| Memory 30 dk | ÖLÇÜLMEDİ | Stabil |
| Network dedupe | Kısmen (HTTP cache) | 0 duplicate |
| SSE duplicate | Risk var (audit #1,#4) | 0 |
| TRTC duplicate | Risk var (audit #5) | 0 |
| Functional tests | **994 pass** | 994+ pass |
| APK size | **240,6 MiB** | ≤ baseline veya gerekçeli |

---

## 7. Sonraki adımlar

1. **Kullanıcı onayı** — audit + baseline kabulü  
2. FAZ 3'ten itibaren optimizasyon (bkz. `PERFORMANCE_AUDIT.md` §9)  
3. Her faz sonrası bu dosyadaki §4 tablolarını doldur → `PERFORMANCE_AFTER.md`  
4. Değişiklik günlüğü → `PERFORMANCE_CHANGELOG.md`  
5. Backend ihtiyacı çıkarsa → `BACKEND_REQUIRED_CHANGES.md`

---

## 8. Referanslar

- Audit: [`PERFORMANCE_AUDIT.md`](PERFORMANCE_AUDIT.md)  
- APK CI: [`docs/LATEST_APK_BUILD.md`](docs/LATEST_APK_BUILD.md)  
- Acceptance: [`docs/ACCEPTANCE_TESTS.md`](docs/ACCEPTANCE_TESTS.md)  
- API sözleşmesi: [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](docs/FLUTTER_ENTegrasyon_KILAVUZU.md)

---

*Ölçülemeyen metrikler için "tahmini" değer yazılmadı. Optimizasyon sonrası karşılaştırma yalnızca gerçek ölçümlerle yapılacaktır.*

---

## 9. Post-optimizasyon snapshot (FAZ 15 sonrası — 2026-08-23)

**Sürüm:** `1.0.347+383`

| Metrik | Baseline (FAZ 2) | FAZ 17 sonrası |
|--------|------------------|----------------|
| `flutter test` | 994 pass | **1010 pass** |
| `shrinkWrap: true` (`mobile/lib`) | **51** | **~3** |
| Discover SSE max | 12 | **6** (home: **4**) |
| Shorts video pool max | 5 | **3** |
| Token secure read / istek | Her istek | Bellek cache (`peekAccess`) |
| `/api/me` refresh | Her çağrı | 8 sn throttle + dedupe |
| Voice hub sheets `shrinkWrap` | 9 | **0** |
| CI arm64 APK | Yok | `canlifal-mobile-arm64-release.apk` |

**Kalan `shrinkWrap` alanları (düşük öncelik):** gifts sheet'leri, shorts studio, admin/agency panelleri, eski profil widget'ları (`profile_content_tabs`, `user_posts_*`).

**Cihaz metrikleri:** Hâlâ ölçülmedi — [`PERFORMANCE_AFTER.md`](PERFORMANCE_AFTER.md) protokolü ile fiziksel cihazda doldurulacak.
