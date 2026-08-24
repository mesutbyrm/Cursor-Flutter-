# Canlifal Flutter — Performans Optimizasyon Özeti

**Program:** FAZ 3–18 (2026-08-22 → 2026-08-23) — **TAMAMLANDI**  
**Başlangıç sürümü:** `1.0.336+372`  
**Bitiş sürümü:** `1.0.348+384`  
**Test:** 994 → **1011 pass**

---

## Sonuç

| Metrik | Önce (audit) | Sonra (FAZ 18) |
|--------|-------------|----------------|
| `shrinkWrap: true` | **51** | **0** |
| Discover SSE max | 12 | **6** (home: **4**) |
| Shorts video pool | 5 | **3** |
| Token secure read/istek | Her istek | Bellek cache |
| `/api/me` refresh | Her çağrı | 8 sn throttle + dedupe |
| Voice hub sheet shrinkWrap | 9 | **0** |
| CI arm64 APK | Yok | `canlifal-mobile-arm64-release.apk` |

---

## Tamamlanan ana iyileştirmeler

| Alan | Değişiklik |
|------|------------|
| **Network** | Token cache, compound API singleton, `/api/me` dedupe |
| **SSE** | connect() fix, discover 12→6 SSE |
| **Video** | Social tap-to-play, shorts pool 5→3 |
| **Voice UI** | Seat ref.select, gift flash, sheet shrinkWrap cleanup |
| **Profil** | LazyNestedGridView, CustomScrollView + sliver timeline |
| **Grid helper** | `ListPerf.nestedGridHeight` / `nestedGridHeightForDelegate` |
| **APK** | arm64 split artifact (~%30–40 küçük indirme) |

---

## Dokümantasyon

| Dosya | Açıklama |
|-------|----------|
| [`PERFORMANCE_AUDIT.md`](PERFORMANCE_AUDIT.md) | İlk audit |
| [`PERFORMANCE_BASELINE.md`](PERFORMANCE_BASELINE.md) | Ölçüm bütçesi + final snapshot |
| [`PERFORMANCE_CHANGELOG.md`](PERFORMANCE_CHANGELOG.md) | FAZ 3–18 günlüğü |
| [`PERFORMANCE_AFTER.md`](PERFORMANCE_AFTER.md) | Cihaz benchmark şablonu (kullanıcı doldurur) |
| [`PERFORMANCE_APK_AUDIT.md`](PERFORMANCE_APK_AUDIT.md) | APK boyut analizi |

---

## Kullanıcı aksiyonu

1. [`PERFORMANCE_AFTER.md`](PERFORMANCE_AFTER.md) protokolünü fiziksel cihazda uygulayın
2. GitHub **Watch → Releases** ile APK güncellemelerini takip edin

---

## Kalan backlog (kod dışı)

- Fiziksel cihaz cold start / FPS / 30 dk RAM ölçümü
- Hediye animasyon CDN offload (APK boyutu — native SDK baskın)
- Backend değişikliği: **gerekmedi**

---

## Kısıtlar (korundu)

- API: `https://canlifal.com` — değişiklik yok
- TRTC (Tencent), SSE mimarisi korundu
- Mock/fake API yok
