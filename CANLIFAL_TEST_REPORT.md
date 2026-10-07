# CANLIFAL Flutter — Gerçek Cihaz Test Raporu

**Tarih (UTC):** 2026-10-07  
**Denetim ortamı:** Cursor Cloud Agent VM  
**Production API:** `https://canlifal.com` (değiştirilmedi)

---

## 1. Ortam kontrolü

| Kontrol | Sonuç | Kanıt |
|--------|--------|--------|
| `flutter --version` | **BLOCKED** | `flutter: command not found`; `/opt/flutter/bin/flutter` yok |
| `flutter doctor -v` | **BLOCKED** | SDK kurulu değil |
| `flutter devices` | **BLOCKED** | SDK yok |
| `adb devices` | **BLOCKED** | `adb: command not found` |
| Java | **OK** | OpenJDK 21.0.10 |
| Proje Flutter pin | **OK** | `mobile/.flutter-version` → `3.44.8` |
| `pubspec` sürüm | **OK** | `1.0.731+784` (repo `main`) |

**Sonuç:** Bu oturumda **interaktif gerçek cihaz testi yapılamadı**. Tahmin veya mock PASS yazılmadı.

**Yerel gerçek cihaz komutu:**

```bash
bash scripts/run-canlifal-diagnostics.sh
# veya
cd mobile && flutter test integration_test/ -d <device_id> \
  --dart-define=CANLIFAL_REAL_DEVICE_TEST=true \
  --dart-define=CANLIFAL_DIAGNOSTICS=true
```

---

## 2. Uygulama çalıştırma (`flutter run`)

| Metrik | Durum |
|--------|--------|
| APK/build süresi | **BLOCKED** (CI: son başarılı APK workflow mevcut) |
| İlk açılış / login / home süreleri | **BLOCKED** |
| Crash / ANR / first frame | **BLOCKED** |

---

## 3. Test kapsamı özeti

| Bölüm | Oturum durumu | Kanıt kaynağı |
|-------|----------------|---------------|
| Auth | **BLOCKED** | — |
| Home / Navigation | **BLOCKED** | — |
| Sesli odalar | **Kısmi (log)** | Redmi A diagnostic ZIP |
| Canlı falcılar | **Kısmi (log)** | Redmi A diagnostic ZIP |
| Canlı yayın | **BLOCKED** | — |
| PK | **BLOCKED** | — |
| Hediye | **Kısmi (log)** | 401 `get-url` satırları |
| SSE / TRTC / Timer | **Kısmi (log + statik)** | Diagnostic + kod envanteri |
| Admin | **BLOCKED** | — |
| Background / network switch | **BLOCKED** | — |
| Performans (FPS/jank) | **Kısmi (log)** | TweenSequence StateError |

---

## 4. Gerçek cihaz log kanıtı (Redmi — Telefon A)

**Oturum:** `DIAG-20261007-032621-E0BF`  
**Kaynak:** Kullanıcı ZIP export (`canlifal_diagnostic_83ee.log`, `errors_a983.json`, `summary_9462.json`)  
**APK dönemi:** Büyük olasılıkla **≤ 1.0.730+783** (731 düzeltmeleri sonrası retest gerekir)

### Özet snapshot (`summary_9462.json`)

- Oturum sonu: `sse: 3`, `errors: 53`, `requests: 453`
- `timers: 0`, `trtc: 0` (logger snapshot anında; oturum içinde TRTC join/leave kayıtlı)

---

## 5. Doğrulanmış bulgular (log + kod)

### P1 — Sesli odadan / koltuktan sonra ses (Telefon A şikâyeti)

**Durum:** FAIL (kullanıcı raporu + log uyumu)  
**Test:** Sesli oda → koltuk / çıkış  
**Log:** Psychic/voice TRTC `TRTC_JOIN_SUCCESS` → `TRTC_LEAVE` / `TRTC_DISPOSE`; ayrıca çoklu `voice_sse:*`  
**Kök neden (kod, doğrulanmış):** Odadan çıkış adımında TRTC `leave()` **400 ms timeout** ile kesiliyordu (`chat_room_providers.dart` — düzeltildi **731+784**, cihaz retest **BLOCKED** bu VM’de).  
**Dosya:** `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` (~1218–1224)  
**Önerilen retest:** Odaya gir → koltuk → in → odadan çık → başka oda; logda `TRTC_LEAVE` sonrası uzak ses yok.

### P1 — Canlı Falcılar / hediye logoları 401

**Durum:** FAIL (log)  
**Event:** `HttpException: Invalid statusCode: 401, uri = https://canlifal.com/api/upload/get-url?path=gift/uploads/...`  
**Sebep:** `CachedNetworkImage` JWT göndermez; API yalnızca oturumlu istek kabul eder.  
**Dosya:** `mobile/lib/core/images/canlifal_image_urls.dart` (`resolve` / `_unwrapUploadGetUrl`, ~12–19, ~119–128) — **731+784** CDN unwrap eklendi; retest **BLOCKED**.  
**Önem:** P1 (ana UI bozuk)

### P2 — DUPLICATE_SSE / ekran çıkışında LEAK_SUSPECTED

**Durum:** FAIL (diagnostic AI özeti + logger)  
**Test:** Ekran EXIT sonrası `sse` 2–4 açık  
**Dosya:** `mobile/lib/core/diagnostics/cf_diagnostic_logger.dart` (~354 DUPLICATE_SSE); hub: `mobile/lib/core/network/sse/sse_connection_hub.dart` (`forceReleaseVoiceRoom`, ~80+)  
**Retest:** Diagnostics → SSE sekmesi; odadan çıkınca lease sayısı 0’a inmeli.

### P2 — TIMER_COUNT_HIGH `live_fortune` (count=5)

**Durum:** FAIL (log)  
**Muhtemel etki:** Gecikme, donma (Telefon A)  
**Dosya:** `mobile/lib/features/live_psychics/presentation/controllers/psychic_video_controller.dart` (timer/polling — statik, satır retest ile doğrulanacak)  
**Retest:** Tek canlı fal seansında Diagnostics → Timer/Polling.

### P2 — TweenSequence StateError (canlı fal UI)

**Durum:** FAIL (errors_a983.json, ~03:26:22 UTC)  
**Mesaj:** `TweenSequence.evaluate() could not find an interval for 1.08…`  
**Dosya:** `mobile/lib/features/gifts/presentation/engine/gift_engine_overlay.dart` (`_ComboBadge`, ~395–410) — **731+784** `_replayPulse()`; retest **BLOCKED**.

### P2 — Falcı pending poll yığılması (Telefon A log)

**Durum:** FAIL (log pattern)  
**Event:** Ardışık `GET /api/fortune-tellers/sessions?status=pending` (request-52, 63, 64, 66…)  
**Retest:** Incoming host ekranı açıkken Network sekmesinde duplicate istek sayımı.

---

## 6. Integration test durumu (otomasyon)

| Dosya | Durum |
|-------|--------|
| `integration_test/voice_room_real_device_test.dart` | **NOT RUN** — stub harness |
| `integration_test/live_fortune_real_device_test.dart` | **NOT RUN** — cihaz gerekli |
| `integration_test/live_stream_real_device_test.dart` | **NOT RUN** — cihaz gerekli |
| `integration_test/app_global_real_device_test.dart` | **NOT RUN** — cihaz gerekli |

`CANLIFAL_REAL_DEVICE_TEST=true` olmadan unit testler **gerçek cihaz PASS sayılmaz**.

---

## 7. Son özet

| | Sayı |
|---|-----|
| **TOTAL TEST (planlanan senaryo)** | 22 bölüm |
| **PASS (bu VM, interaktif)** | 0 |
| **FAIL (log/kanıt)** | 6+ |
| **BLOCKED (ortam/cihaz)** | 16+ bölüm |

| Kategori | Adet (kanıtlı) |
|----------|----------------|
| P0 | 0 (bu oturumda crash kanıtı yok) |
| P1 | 2 |
| P2 | 4+ |
| P3 | — (retest gerek) |

| Problem tipi | |
|--------------|--|
| CRASH | BLOCKED (oturumda yok) |
| ANR | BLOCKED |
| MEMORY LEAK | LEAK_SUSPECTED (log) — P2 |
| SSE | DUPLICATE_SSE — P2 |
| TRTC | Çıkış timeout — P1 (fix 731, retest BLOCKED) |
| TIMER | live_fortune yüksek — P2 |
| POLLING | pending sessions duplicate — P2 |
| API | get-url 401 — P1 |
| UI | TweenSequence — P2 |
| PERFORMANCE | jank (log) — P2 |

---

## 8. Öncelik — önce düzeltilmesi / doğrulanması gereken 10 madde

1. **Ses odası TRTC tam kapanma** — `chat_room_providers.dart` leave adımı → retest senaryo §6 (731 uygulandı).  
2. **Koltuk sonrası izleyici TRTC** — `chat_room_providers_seat.dart` release + audience rejoin → retest koltuk in/out.  
3. **Görsel 401 get-url** — `canlifal_image_urls.dart` → Canlı Falcılar kartları retest.  
4. **DUPLICATE_SSE** — keşif + in-room; `sse_connection_hub.dart` / presence provider.  
5. **live_fortune timer sayısı** — `psychic_video_controller.dart` SSE varken poll azaltma.  
6. **Pending session poll storm** — `psychic_incoming_host.dart` / ilgili provider.  
7. **Gift combo animasyon** — `gift_engine_overlay.dart` retest canlı fal hediye.  
8. **PK uçtan uca** — BLOCKED, iki cihaz gerekir.  
9. **Jeton UI vs backend** — BLOCKED, kontrollü hediye testi.  
10. **Background/foreground ses** — BLOCKED, manuel cihaz.

Detaylar: `CANLIFAL_CRITICAL_ERRORS.md`, `CANLIFAL_TRTC_SSE_REPORT.md`, `CANLIFAL_PERFORMANCE_REPORT.md`, `CANLIFAL_API_COMPATIBILITY.md`.

---

## 9. Düzeltme politikası (bu denetim)

- Bu oturumda **yeni kod değişikliği yapılmadı** (yalnızca rapor dosyaları).  
- Daha önce `main`’e giren **731+784** maddeleri **retest ile doğrulanmalı**; bu VM’de doğrulanamadı.

**Önerilen kullanıcı adımı:** `apk-latest` (**≥ 1.0.731**, CI’da **1.0.736+789** görünüyor) + Diagnostics ZIP → aynı senaryolar.
