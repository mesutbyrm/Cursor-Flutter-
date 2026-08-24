# APK Boyutu Denetimi (FAZ 10)

**Tarih:** 2026-08-23  
**Sürüm:** `1.0.341+377`  
**Mevcut release APK (CI):** ~240,6 MiB (`252 276 640` bayt — `1.0.339+375`)

---

## 1. Özet

Canlifal APK'sı **~241 MB** — sosyal + canlı yayın + TRTC + FFmpeg + Firebase + reklam SDK kombinasyonu için beklenen üst bant. Kısa vadede **kod değişikliği gerektirmeyen** kazanımlar sınırlı; orta vadede **modüler yükleme**, **asset sıkıştırma** ve **ABI split** en yüksek ROI.

**Bu fazda yapılan:** denetim belgesi + startup prefetch kademeleme + discover grid `shrinkWrap` kaldırma (scroll perf).

---

## 2. Boyut bileşenleri (tahmini)

| Bileşen | Tahmini pay | Not |
|---------|-------------|-----|
| Tencent TRTC (`tencent_rtc_sdk`) | **~35–55 MB** | Zorunlu — sesli oda / canlı yayın |
| FFmpeg (`ffmpeg_kit_flutter_new_min_gpl`) | **~25–40 MB** | Shorts stüdyo / video işleme |
| Firebase suite (6 paket) | **~15–25 MB** | Auth, FCM, Analytics, Crashlytics |
| Google Mobile Ads | **~10–15 MB** | Reklam |
| `video_player` + codec natives | **~8–12 MB** | Feed, shorts |
| Flutter engine + Dart AOT | **~15–20 MB** | Sabit |
| Uygulama kodu + diğer plugins | **~30–50 MB** | Dio, Hive, WebView, vb. |
| **Assets (bundle)** | **~9,4 MB** | `du -sh mobile/assets` — brand 4,1M, fortune 2,9M, splash 2,4M |

> Kesin dağılım için: `flutter build apk --analyze-size` (CI veya yerel release build).

---

## 3. Asset envanteri

| Klasör | İçerik |
|--------|--------|
| `assets/gifts/lottie/` | Hediye animasyonları |
| `assets/gifts/svga/` | SVGA hediye efektleri |
| `assets/gifts/sounds/` | Hediye sesleri |
| `assets/fortune/` | Fal görselleri |
| `assets/splash/`, `assets/brand/` | Marka |

**Öneri:** SVGA/Lottie dosyalarını CDN'den lazy-load (şu an bundle'da). Büyük dosyalar (>500 KB) için envanter listesi çıkarılmalı.

---

## 4. Ağır bağımlılıklar (`pubspec.yaml`)

| Paket | Kullanım | Kaldırılabilir mi? |
|-------|----------|-------------------|
| `tencent_rtc_sdk` | Sesli oda, canlı TRTC | **Hayır** (ürün gereksinimi) |
| `ffmpeg_kit_flutter_new_min_gpl` | Shorts video edit | Yalnızca stüdyo ekranında lazy init |
| `youtube_explode_dart` + `youtube_player_iframe` | Müzik arama / oynatıcı | Oda müziği için gerekli |
| `socket_io_client` | Canlı namespace (legacy) | SSE birincil; kullanım daraltılabilir |
| `cloud_firestore` + `firebase_storage` | Firebase | Kullanım haritası — gereksizse kaldır |
| `google_mobile_ads` | Reklam | Ürün kararı |
| `lottie` + SVGA assets | Hediye efektleri | CDN offload |

---

## 5. Önerilen aksiyonlar (öncelik sırası)

### P1 — Düşük risk, orta kazanç

1. **ABI split APK** — `android/app/build.gradle` `splits.abi` → kullanıcı başına ~30–40% küçük indirme
2. **ProGuard/R8 shrink** — release'de `minifyEnabled true` doğrula (tree-shake)
3. **Asset audit script** — `scripts/audit-apk-assets.sh` (gelecek faz)

### P2 — Orta risk, yüksek kazanç

4. **Hediye animasyonları CDN** — bundle'dan çıkar, ilk kullanımda indir
5. **FFmpeg lazy load** — shorts stüdyo açılmadan native lib yükleme
6. **Firebase modüler import** — kullanılmayan Firebase modüllerini kaldır

### P3 — Uzun vade

7. **App Bundle (AAB)** Play Store — Play dinamik delivery
8. **Feature modules** — fal/oyun/shorts ayrı dynamic feature (büyük refactor)

---

## 6. Performans bütçesi (APK)

| Metrik | Mevcut | Hedef (6 ay) |
|--------|--------|--------------|
| Universal APK | ~241 MB | < 200 MB |
| arm64-v8a split | — | < 140 MB |
| İlk indirme (Play AAB) | — | < 80 MB |

---

## 7. İlgili dosyalar

- `mobile/pubspec.yaml` — bağımlılıklar
- `mobile/android/app/build.gradle` — ABI split, minify
- `PERFORMANCE_BASELINE.md` — genel bütçe
- `PERFORMANCE_CHANGELOG.md` — uygulanan optimizasyonlar
