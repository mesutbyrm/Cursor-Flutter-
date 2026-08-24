# Canlifal Flutter — Performans Sonrası Ölçüm (FAZ 12)

**Tarih:** 2026-08-23  
**Baseline:** [`PERFORMANCE_BASELINE.md`](PERFORMANCE_BASELINE.md)  
**Audit:** [`PERFORMANCE_AUDIT.md`](PERFORMANCE_AUDIT.md)  
**Changelog:** [`PERFORMANCE_CHANGELOG.md`](PERFORMANCE_CHANGELOG.md)  
**Durum:** Şablon — **gerçek cihaz ölçümü gerekir** (cloud agent emülatörsüz)

---

## 1. Amaç

FAZ 3–11 optimizasyonlarından sonra kullanıcı deneyimini **sayısal olarak** doğrulamak. Bu belge ölçüm protokolü ve sonuç tablosu şablonudur; değerler fiziksel cihazda doldurulur.

---

## 2. Cihaz matrisi (önerilen)

| Segment | Örnek cihaz | Android | Not |
|---------|-------------|---------|-----|
| Düşük | Redmi 9A / Galaxy A12 | 10–11 | 2–3 GB RAM |
| Orta | Redmi Note 11 / Galaxy A54 | 12–13 | 4–6 GB RAM |
| Yüksek | Pixel 7 / Galaxy S23 | 13–14 | 8+ GB RAM |

Her segmentte **en az 1 cihaz** ile tüm senaryolar çalıştırılmalı.

---

## 3. Kurulum

```bash
# Release veya profile mod
cd mobile
flutter build apk --release
# veya CI arm64: scripts/build-apk-arm64.sh

adb install -r ../canlifal-mobile-arm64-release.apk
```

**DevTools:** `flutter pub global activate devtools` → `adb reverse tcp:9100 tcp:9100` → uygulamayı profile modda çalıştır veya `flutter run --profile`.

**Temiz oturum:** Uygulamayı force-stop + cache temizle veya yeni kullanıcı profili.

---

## 4. Senaryolar ve ölçüm

### 4.1 Cold start

1. Uygulamayı force-stop
2. Kronometre veya `adb shell am start -W` ile ilk frame
3. **3 tekrar** — medyan al

| Metrik | Baseline hedef | Ölçüm (cihaz) | FAZ 11 sonrası | PASS? |
|--------|---------------:|--------------:|---------------:|:-----:|
| Cold start (ms) | < 2000 | _doldur_ | _doldur_ | |
| İlk anlamlı UI (ms) | < 1500 | _doldur_ | _doldur_ | |

```bash
adb shell am force-stop com.mesutbyrm.canlifal
adb shell am start -W -n com.mesutbyrm.canlifal/.MainActivity
```

### 4.2 Warm start

1. Home'a bas, 5 sn bekle
2. Uygulamayı geri getir
3. **3 tekrar**

| Metrik | Hedef | Ölçüm | Sonrası | PASS? |
|--------|------:|------:|--------:|:-----:|
| Warm start (ms) | < 1000 | | | |

### 4.3 Scroll FPS — sosyal feed

1. Ana feed'e git, 30 sn aşağı/yukarı kaydır
2. DevTools → Performance → Frame chart
3. Jank (>16,67 ms) yüzdesi

| Metrik | Hedef | Ölçüm | Sonrası | PASS? |
|--------|------:|------:|--------:|:-----:|
| Ortalama FPS | ≥ 58 | | | |
| Jank frame % | < 1% | | | |

### 4.4 Sesli oda — koltuk grid

1. Dolu bir odaya gir (≥6 koltuk dolu)
2. Başka kullanıcı konuşurken / hediye gelirken 60 sn gözlem
3. DevTools rebuild sayacı veya `--trace-skia` (isteğe bağlı)

**Beklenen iyileşme (FAZ 7–9):** hediye flaşı ve koltuk değişiminde tüm grid rebuild yok.

| Metrik | Hedef | Ölçüm | Sonrası | PASS? |
|--------|------:|------:|--------:|:-----:|
| Konuşma sırasında hissedilen takılma | Yok | | | |
| 60 sn jank % | < 1% | | | |

### 4.5 Keşfet — presence SSE

1. Sesli oda keşfet sekmesi, 20 oda listesi
2. Android Studio Network Profiler veya log: eşzamanlı SSE bağlantı sayısı

| Metrik | Baseline | Hedef (FAZ 6) | Ölçüm | PASS? |
|--------|----------|---------------|------:|:-----:|
| Max eşzamanlı discover SSE | 12 | **6** | | |
| Home şeridi SSE | 6 | **4** | | |

### 4.6 Bellek — 30 dk soak

1. Giriş yap
2. 30 dk karışık kullanım: feed scroll, 1 oda, 1 shorts, profil
3. DevTools Memory → heap snapshot başlangıç vs bitiş

| Metrik | Hedef | Ölçüm | Sonrası | PASS? |
|--------|------:|------:|--------:|:-----:|
| Heap artışı (MB) | < 50 MB net | | | |
| Sürekli yükselen eğri | Yok | | | |

### 4.7 Ağ — duplicate istek

Charles / mitmproxy veya Dio log:

| Endpoint | Baseline risk | Hedef | Ölçüm | PASS? |
|----------|---------------|-------|------:|:-----:|
| `/api/mobile/home` (shell açılış) | 3× | **1×** | | |
| `secure_storage` read / istek | Her istek | **peekAccess** | | |
| `/api/me` (15+ path) | Yüksek | Dedupe/cache | | |

---

## 5. Statik regression (CI — otomatik)

| Metrik | Baseline | Güncel | Kaynak |
|--------|----------|--------|--------|
| `flutter test` | 994 | **1007+** | CI |
| `shrinkWrap: true` | 51 | _rg sayımı_ | repo |
| APK universal | ~241 MB | CI | apk-latest |
| APK arm64-only | — | CI | apk-arm64 asset |

```bash
cd mobile && flutter test
rg -c 'shrinkWrap:\s*true' lib/ | awk -F: '{s+=$2} END {print s}'
```

---

## 6. Kabul kriterleri (özet)

Tümü **PASS** olmalı:

- [ ] Cold start < 2,0 s (orta segment)
- [ ] Feed scroll jank < %1
- [ ] 30 dk bellek sızıntısı yok
- [ ] Discover SSE ≤ 6 eşzamanlı
- [ ] `flutter test` 100% pass
- [ ] Acceptance testleri (CI) yeşil

---

## 7. Sonuç özeti (doldurulacak)

| Kategori | Baseline | Sonrası | Δ | Not |
|----------|----------|---------|---|-----|
| Cold start | | | | |
| Feed FPS | | | | |
| Voice room jank | | | | |
| APK arm64 | — | | | |
| Test sayısı | 994 | | | |

**Genel değerlendirme:** _Optimizasyon hedeflerine ulaşıldı / kısmen / ek iş gerekli_

**Ölçümü yapan:** _______________  
**Tarih:** _______________
