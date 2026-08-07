# Flutter Production Master — Durum Matrisi

> **Tarih:** 7 Ağustos 2026  
> **Sürüm:** `1.0.144+178`  
> **Tek kaynak:** `https://canlifal.com` + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9  
> **Üretim envanteri:** 692 handler / 440 benzersiz yol (ENDPOINTS.md)

## Özet

| Alan | Backend | Flutter | Durum |
|------|---------|---------|-------|
| Auth JWT | `/api/auth/mobile-*`, `/api/me` | ✅ | Tamam |
| Canlı yayın | `POST /api/video-streams`, SSE | ⚠️ | 1.0.144 retry + hata ayrımı |
| Canlı falcı | SSE + `/api/room/*` | ✅ | SSE-primary (1.0.140) |
| Sesli oda | `ChatRoomRepository` §9.3 | ✅ | Tek ayar paneli (1.0.142) |
| Müzik `!istek` | `song_*` SSE | ✅ | 1.0.138 |
| Fal paylaşım | `auto-fortune` | ✅ | 1.0.139 |
| Sosyal feed | posts, story, trend | ⚠️ | Kısmi — scroll perf devam |
| Hediye / jeton | SSE + wallet | ✅ | Backend-only animasyon |
| Performans TikTok | lazy, prefetch, 60fps | ⚠️ | RTC selective watch; tam audit yok |
| UI premium | glass, skeleton, M3 | ⚠️ | Modül bazlı yenileme planlı |
| Admin / web-only | `/admin/*` | ⏭️ | Mobil kapsam dışı |

**Tamamlanma:** P0 kritik akışlar ~%85 · Tam master prompt ~%35 (aşamalı)

---

## 1. Backend ↔ Flutter senkronizasyon

### Tamamlanan (1.0.138–144)

- Müzik sistemi web parity (`just_audio`, YouTube, SSE `song_changed`)
- Fal otomatik paylaşım `POST /api/social/posts/auto-fortune`
- Canlı yayın host `streamEnded`, SSE-aware poll
- `createVideoStream` yanıt parse + retry (1.0.144)
- Falcı panel SSE-primary, debug kartları release'te gizli (1.0.144)
- Sesli oda RTC performans + tek yönetim paneli

### Açık P0

| Madde | Dosya / alan | Not |
|-------|--------------|-----|
| Canlı yayın sahada doğrulama | `live_broadcast_prep_page.dart` | Production JWT ile create + TRTC |
| Fal paylaşım cihaz testi | `fortune_share_handler.dart` | auto-fortune feed prepend |
| Eksik endpoint raporu otomasyonu | `scripts/` | CI rapor üretici planlı |

### Açık P2

- `FEATURE_PARITY_REPORT.md` maddeleri
- Admin/moderasyon mobil ekranları (web-only uçlar hariç)
- Tam UI yenileme (TikTok/Bigo referans)

---

## 2. Performans

| Optimizasyon | Durum |
|--------------|-------|
| Lazy loading / pagination | ✅ Çoğu feed |
| Image cache (`CachedNetworkImage`) | ✅ |
| SSE reconnect backoff | ✅ kılavuz §5–6 |
| API retry GET | ✅ `ApiRetryInterceptor` |
| API retry kritik POST | ⚠️ `createVideoStream` (1.0.144) |
| Selective `ref.watch` | ✅ voice RTC, kısmi live |
| RepaintBoundary | ✅ dashboard, RTC |
| Video prefetch / autoplay | ⚠️ sosyal feed kısmi |
| Isolate JSON parse | ✅ `FusedTransformer` |
| Skeleton loading | ⚠️ modül bazlı |
| 60/120 Hz hedef | ⚠️ profil gerekli |

---

## 3. Modül durumu

### Canlı yayın (TikTok/Bigo hedef)

| Özellik | API | Flutter |
|---------|-----|---------|
| Yayın açma | `POST /api/video-streams` | ✅ prep + retry |
| Kapak / kategori | PATCH fields | ✅ |
| Canlı sohbet | messages + SSE | ✅ |
| Hediye animasyon | SSE `gift` | ✅ |
| PK | `/api/video-streams/pk` | ✅ |
| Moderasyon | mute/ban/moderator | ✅ |
| Bağlantı kalitesi UI | signal ping | ⚠️ kısmi |

### Canlı falcı

| Özellik | Durum |
|---------|-------|
| Anlık istek/kabul/red | ✅ SSE + push |
| Jeton düşme | ✅ |
| Seans başlat/bitir | ✅ |
| Puanlama/yorum | ✅ |
| Geçmiş | ✅ |
| Debug teşhis kartı | ✅ yalnız debug (1.0.144) |

### Sesli oda

| Özellik | Durum |
|---------|-------|
| Oda CRUD, presence, seats | ✅ |
| DJ / müzik / !istek | ✅ 1.0.138 |
| Video/ses istek | ✅ |
| Hediye / emoji | ✅ |
| Yönetim paneli | ✅ tek panel |

### Sosyal (Instagram hedef)

| Özellik | Durum |
|---------|-------|
| Feed, story, trend | ✅ |
| Video autoplay scroll | ⚠️ perf iyileştirme |
| Takip/beğeni/yorum | ✅ |

### Fal & tarot

| Özellik | Durum |
|---------|-------|
| Kılavuz §9 Fortune | ✅ çoğu tür |
| Premium yükleme animasyon | ⚠️ kısmi |

---

## 4. Hata yönetimi

| Alan | Durum |
|------|-------|
| ApiException / userMessage | ✅ |
| 401 → refresh → retry | ✅ |
| GET retry (timeout/5xx/429) | ✅ |
| POST retry kritik yazma | ⚠️ createVideoStream (1.0.144) |
| Offline gate | ✅ `ConnectivityService` |
| SSE reconnect | ✅ exponential backoff |

---

## 5. Test ve raporlama

| Rapor | Durum |
|-------|-------|
| `dart analyze` gate | ✅ |
| `flutter test` (374+) | ✅ |
| Acceptance tests CI | ✅ `run-acceptance-tests.sh` |
| Eksik endpoint raporu | ⏳ planlı script |
| Performans profili | ⏳ planlı |
| Production smoke (JWT) | ⏳ manuel / secrets |

---

## 6. Sonraki aşamalar (sıra)

1. **P0 doğrulama** — canlı yayın + fal paylaşım production JWT smoke
2. **Sosyal scroll perf** — video prefetch, `ListView` builder optimizasyonu
3. **UI premium faz** — glass/skeleton modül modül (live → psychic → voice)
4. **Otomatik parity raporu** — `api_endpoints.dart` vs kılavuz §9 diff script
5. **FEATURE_PARITY_REPORT** kapatma

---

## 7. Bu oturum değişiklikleri (1.0.144)

- `createVideoStream`: 25s write timeout, 1 retry (timeout/5xx/429), Dio hata ayrımı
- `live_broadcast_prep_page`: JWT ön kontrol, çift timeout kaldırıldı
- `approvedPsychicProvider`: my-profile önce, hata durumunda cache koruma
- `PsychicInviteDiagnosticCard`: `kDebugMode` only
- Falcı paneli: release'te debug slot'lar listeden çıkarıldı

---

*Bu belge master prompt ilerlemesini takip eder; %100 tamamlanma production testleri olmadan işaretlenmez.*
