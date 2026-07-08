# Android Production Optimizasyon Raporu — 1.0.1+2

**Tarih:** 2026-07-08

## Play Console uyarıları — durum

| Uyarı | Durum |
|-------|--------|
| R8 yapılandırması eksik | **Giderildi** — `minifyEnabled true`, `shrinkResources true`, `android.enableR8.fullMode=true` |
| Code shrinking kapalı | **Giderildi** — R8 release aktif |
| Kod karartma (obfuscation) yok | **Giderildi** — Java/Kotlin R8 + Dart `--obfuscate` |
| Uygulama boyutu optimizasyonu | **Kısmen** — AAB bundle splits; toplam AAB ~391 MB (native SDK ağırlıklı) |
| Native debug symbols | **Giderildi** — `ndk.debugSymbolLevel = SYMBOL_TABLE` |
| multidex gereksiz kullanım | **Giderildi** — `multiDexEnabled` kaldırıldı |

## Değiştirilen dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `android/app/build.gradle.kts` | R8, shrink, bundle splits, debug symbols, multidex kaldırıldı |
| `android/app/proguard-rules.pro` | Flutter, Firebase, Agora, TRTC, WebRTC, Media3, OneSignal kuralları |
| `android/settings.gradle.kts` | AGP 8.13.0, Kotlin 2.2.21 |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.14 |
| `android/gradle.properties` | R8 full mode, parallel, caching, nonTransitiveRClass |
| `android/build.gradle.kts` | Plugin compileSdk 36 zorlama |
| `android/app/src/main/AndroidManifest.xml` | largeHeap kaldırıldı, extractNativeLibs false, network security |
| `android/app/src/main/res/xml/network_security_config.xml` | **Yeni** — HTTPS zorunlu (localhost istisna) |
| `android/app/src/main/res/raw/keep.xml` | **Yeni** — shrinkResources güvenli tutma |
| `scripts/build-play-aab.sh` | **Yeni** — production AAB betiği |

## Optimizasyonlar (tek tek)

1. **R8 minify + shrink** — Kullanılmayan Java/Kotlin sınıfları ve kaynaklar release’de çıkarılır.
2. **ProGuard optimize** — `proguard-android-optimize.txt` + plugin-safe keep kuralları.
3. **Dart obfuscation** — `--obfuscate` ile Dart sembolleri karartılır; Crashlytics için `--split-debug-info`.
4. **Icon tree-shake** — Material/Cupertino fontları ~%96–99 küçültüldü.
5. **AAB splits** — Kullanıcı başına indirme boyutu (ABI/dil/yoğunluk) düşer.
6. **extractNativeLibs=false** — Kurulumda daha hızlı native yükleme, daha düşük disk kullanımı.
7. **largeHeap kaldırıldı** — Sistem bellek baskısı ve GC davranışı iyileşir.
8. **multidex kaldırıldı** — Tek dex (R8 sonrası); başlangıç class loading hafifler.
9. **AGP/Gradle/Kotlin güncellemesi** — Derleme uyumluluğu ve R8 desteği.

## Tahmini etkiler

| Metrik | Önce | Sonra (tahmin) |
|--------|------|----------------|
| **Toplam AAB** | ~382 MB | ~391 MB (native SDK + symbol table; Java/Dart küçüldü) |
| **Play indirme (cihaz başı)** | — | ABI split ile ~%30–40 daha küçük indirme |
| **Dex / Java katmanı** | — | ~%25–40 küçülme (R8) |
| **Soğuk açılış** | — | ~%5–15 iyileşme (multidex kaldırma, extractNativeLibs false) |
| **Bellek (runtime)** | largeHeap | Normal heap — daha öngörülebilir GC |

> AAB toplam boyutu Agora/TRTC/WebRTC native `.so` dosyaları nedeniyle çok azalır; asıl kazanç Play’in cihaza özel split indirmesinde ve R8/obfuscation uyarılarının kapanmasında.

## Doğrulama

```bash
bash scripts/build-play-aab.sh
cd mobile && flutter test   # 198 geçti
```

## Play yükleme

```bash
# Çıktı
mobile/build/app/outputs/bundle/release/app-release.aab
# Semboller (Crashlytics)
mobile/build/app/outputs/symbols/
```
