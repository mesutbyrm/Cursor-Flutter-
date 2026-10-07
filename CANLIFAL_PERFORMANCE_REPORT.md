# CANLIFAL — Performans Raporu

**Ortam:** Cloud Agent VM — **FPS / CPU / memory profiler çalıştırılamadı (BLOCKED)**  
**Kısmi kanıt:** Redmi Telefon A diagnostic oturumu `DIAG-20261007-032621-E0BF`

---

## 1. Ölçüm durumu

| Metrik | Durum |
|--------|--------|
| UI jank / dropped frames | **BLOCKED** (DevTools bağlı değil) |
| FPS | **BLOCKED** |
| Memory (heap) | **BLOCKED** |
| CPU | **BLOCKED** |
| Startup / first frame | **BLOCKED** |
| Diagnostic snapshot | **Kısmi** — `summary_9462.json`: `requests: 453`, `errors: 53`, `sse: 3` |

---

## 2. Log-tabanlı performans bulguları

### P2 — TweenSequence burst (UI thread)

- **Zaman:** ~03:26:22 UTC  
- **Kategori:** `[PERFORMANCE]` / `[GIFT]`  
- **Etki:** Çoklu `StateError` kısa aralıkta → frame kaybı / “donma” algısı  
- **Dosya:** `gift_engine_overlay.dart` (~395–410)

### P2 — Yüksek eşzamanlı HTTP

- Oturum boyunca yüzlerce `REQUEST_*` (Telefon A log)  
- Falcı **pending** poll tekrarı → gereksiz ağ + main isolate JSON parse  
- **Öneri:** SSE birincilken poll aralığını genişlet / tek uçuşlu guard

### P2 — TIMER_COUNT_HIGH (live_fortune = 5)

- Canlı fal modülünde eşzamanlı timer sayısı diagnostic eşiğini aşıyor  
- **Dosya:** `psychic_video_controller.dart` (retest ile satır doğrulanacak)  
- **Öneri:** SSE connected → poll/timer birleştir

### P2 — LEAK_SUSPECTED (SSE 2–4 after EXIT)

- Ekran kapandıktan sonra açık SSE → arka planda event işleme, rebuild  
- **Hub:** `sse_connection_hub.dart`

### P2 — Redmi hedef cihaz

- Kullanıcı hedefi: Redmi Note 13 Pro 5G — **bu VM’de test edilmedi**  
- Keşif SSE limiti 730’da 6→4 (`voice_rooms_presence_provider.dart`) — etki **retest gerekir**

---

## 3. Statik envanter (doğrulanmadı — sadece risk haritası)

**Voice hub** içinde `Timer`/`Timer.periodic` kullanan dosya sayısı: **40+** (grep).  
Kritik alanlar:

- `chat_room_providers.dart` — oturum timer’ları (`_cancelSessionTimers` leave’de)  
- `pk_battle_provider.dart` — PK timer drift riski  
- `chat_room_providers_presence.dart` — heartbeat / network recovery  

**Kural:** Her timer için dispose/leave yolu integration + diagnostic ile doğrulanmalı.

---

## 4. Görsel / cache

- **401 get-url** → başarısız decode, placeholder, tekrarlı istek (performans + UX)  
- **731+** CDN unwrap — retest: CanlifalNetworkImage cache hit oranı

---

## 5. Önerilen cihaz profili testi (sizin tarafınız)

1. Diagnostics açık APK  
2. Flutter DevTools veya Android Studio Profiler  
3. Senaryo: Home → Canlı Falcılar → sesli oda 10 dk → background 2 dk → foreground  
4. Export ZIP → `CANLIFAL_PERFORMANCE_REPORT.md` güncellemesi

**Bu dosya otomatik PASS içermez.**
