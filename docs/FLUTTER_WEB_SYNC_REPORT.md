# Flutter ↔ Web Senkronizasyon Raporu

> **Tarih:** 3 Ağustos 2026  
> **Sürüm:** `1.0.119+152`  
> **Referans:** Backend denetim raporu (`CANLIFAL_BACKEND_DENETIM_RAPORU`) + web üretim davranışı  
> **Kapsam:** Sesli oda, canlı yayın, hediye motoru, SSE, TRTC — yalnızca mobil istemci düzeltmeleri

---

## 1. Özet

Bu oturumda Flutter mobil istemcisi, backend denetim raporunun **§9 Flutter tarafı** maddelerine göre cerrahi düzeltmeler aldı. Backend veya endpoint değiştirilmedi. Tam uygulama yeniden yazımı yapılmadı; yalnızca tespit edilen uyumsuzluklar giderildi.

---

## 2. Web vs Flutter — Karşılaştırma Tablosu

| Alan | Web (referans) | Flutter (önce) | Flutter (sonra) |
|------|----------------|----------------|-----------------|
| Hediye SSE — legacy | Görselleştirilir (geriye uyum) | Legacy + motor **ikisi de** animasyon başlatıyordu | Legacy, motor `gift_received` görüldükten sonra **yok sayılır** |
| Hediye SSE — `gift_received` | `engine:true` → animasyon | Ayrıştırılmıyordu | `GiftEngineSseRouter` → visualize |
| Hediye SSE — `gift_queue_updated` | Yalnızca kuyruk | Animasyon tetikliyordu | `onEngineQueueUpdated` — sıra senkronu |
| Hediye SSE — `gift_finished` | Sıradan çıkar | İşlenmiyordu | `onEngineGiftFinished` → dequeue |
| SSE heartbeat | 15 sn | 20 sn timeout | **45 sn** (3×15 sn tolerans) |
| SSE Last-Event-ID | Reconnect'te gönderilir | `BaseSseService` vardı | Değişmedi (zaten uyumlu) |
| Video yayın SSE gift | Tam payload (`engine` üst seviyede) | Yalnızca iç `gift` map parse | `GiftPayloadUtil.unwrap` — tam zarf |
| Video yayın SSE heartbeat | 15 sn | Yoktu | 45 sn watchdog eklendi |
| SSE ref-count (oda çıkış) | Tek bağlantı mantığı | `forceRelease` keşif SSE'sini de kesiyordu | `releaseVoiceRoom` — ref sayacı korunur |
| Çift presence listener | Tek kaynak | RTC sayfasında ikinci SSE dinleyici | Kaldırıldı (ölü kod) |
| TRTC join/leave | Eski oda kapanır → yeni | `VoiceTrtcEngine` zaten leave-before-join | Değişmedi (uyumlu) |
| JWT refresh SSE 401 | Yenile + reconnect | `BaseSseService` | Değişmedi (uyumlu) |

---

## 3. Bulunan Sorunlar

### P0 — Kritik
1. **Hediye motoru SSE ayrımı yok** — Aynı hediye için 2–3 SSE mesajı (legacy + motor) çift animasyon / eksik sıra
2. **Video SSE gift parse** — `engine` / `event` üst seviye alanları kayboluyordu
3. **SSE heartbeat timeout** — 20 sn, backend 15 sn heartbeat ile uyumsuz (erken reconnect)

### P1 — Yüksek
4. **forceReleaseVoiceRoom** — Keşif presence SSE ref-count bozulması, yeniden girişte kopma hissi
5. **Video stream SSE** — Heartbeat watchdog ve 401 refresh eksik
6. **reconnectAllActive** — Yalnızca sesli oda, video yayın hariç

### P2 — Orta
7. **RTC duplicate SSE presence** — Kullanılmayan ikinci listener (setState maliyeti)
8. **Gift queue** — Motor `queue_updated` ile sunucu sırası senkronu yoktu

---

## 4. Düzeltilenler (`1.0.119+152`)

| Dosya | Değişiklik |
|-------|------------|
| `gift_engine_sse_router.dart` | Motor/legacy sınıflandırma |
| `gift_sse_dispatch.dart` | Merkezi SSE hediye yönlendirme (sesli + canlı) |
| `gift_session_controller.dart` | `routeGiftSsePayload`, `onEngineQueueUpdated`, `onEngineGiftFinished` |
| `live_gift_event.dart` | `engine`, `engineEvent`, `giftHistoryId`, `queueItemId` |
| `live_gifts_remote_datasource.dart` | Motor alanları parse |
| `chat_room_providers.dart` | Motor dispatch + `releaseVoiceRoom` |
| `live_room_providers.dart` | Canlı yayın motor dispatch |
| `video_stream_sse_service.dart` | Tam payload, heartbeat 45 sn |
| `base_sse_service.dart` | Heartbeat timeout 45 sn |
| `sse_connection_hub.dart` | Video reconnect + `releaseVoiceRoomSession` |
| `voice_room_rtc_page.dart` | Duplicate SSE presence listener kaldırıldı |
| `voice_room_session_utils.dart` | Gereksiz forceRelease kaldırıldı |

### Testler
- `gift_engine_sse_router_test.dart` — sınıflandırma
- `gift_session_controller_test.dart` — legacy dedup after engine

---

## 5. Düzeltilmeyenler / Kısıtlar

| Konu | Sebep |
|------|--------|
| Poll penceresi tipler-arası kronoloji | Backend davranışı — istemci `timestamp` ile sıralamalı (mevcut) |
| In-memory SSE yatay ölçekleme | Backend mimarisi — Flutter düzeltemez |
| API zarf tutarsızlığı | Mevcut parse katmanı endpoint bazlı — değiştirilmedi |
| 60 FPS / CPU profili otomasyonu | Cloud ortamda Flutter DevTools/emülatör yok — manuel cihaz testi gerekir |
| 2–20 cihaz çoklu test | Bu oturumda fiziksel cihaz farm yok |
| Video SSE 401 JWT refresh | `VideoStreamSseService` hâlâ `BaseSseService` değil — ayrı PR önerilir |
| JSON isolate parse | Büyük payload'lar için planlı; bu diff kapsamı dışı |

---

## 6. Performans — Önce / Sonra (tahmini)

| Metrik | Önce | Sonra (beklenen) |
|--------|------|------------------|
| Hediye çift animasyon | Sık | Motor dedup ile ~%50 daha az GPU/CPU |
| SSE erken reconnect | ~20 sn idle | 45 sn — daha az gereksiz reconnect |
| Odaya yeniden giriş | Kopma / ağırlaşma | Ref-count düzeltmesi ile daha stabil |
| RTC sayfa setState | Gereksiz presence SSE | Kaldırıldı |

*Kesin FPS/RAM ölçümü için fiziksel cihazda DevTools profili önerilir.*

---

## 7. Test Kontrol Listesi

| Test | Durum |
|------|--------|
| Voice Room Join/Leave | Kod incelemesi ✓ — cihaz doğrulaması bekliyor |
| Aynı odaya yeniden giriş | Ref-count fix ✓ |
| SSE Reconnect + Last-Event-ID | Mevcut altyapı ✓ |
| Heartbeat 45 sn | Uygulandı ✓ |
| Gift engine dedup | Unit test ✓ |
| Gift queue_updated / finished | Uygulandı ✓ |
| TRTC token refresh | Mevcut ✓ — değişmedi |
| Video/PNG/Lottie gift | Mevcut pipeline ✓ |
| Çoklu cihaz | Manuel test gerekir |
| Bellek sızıntısı | RTC listener temizliği ✓ — tam audit bekliyor |

---

## 8. Sonraki Adımlar (öneri)

1. `VideoStreamSseService` → `BaseSseService` refactor (401 refresh + tek kod yolu)
2. Büyük JSON için `compute()` / isolate parse (oda presence snapshot)
3. Fiziksel cihazda 5–20 kullanıcı hediye/presence stres testi
4. `RepaintBoundary` hediye overlay katmanlarında profil sonrası

---

*Backend değiştirilmedi. Tüm path'ler mevcut `https://canlifal.com/api/*` sözleşmesine uyumludur.*
