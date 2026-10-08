# CANLIFAL — Kritik Hatalar (Gerçek Kanıt)

> **Not:** Aşağıdaki FAIL maddeleri **gerçek cihaz diagnostic log** veya **kullanıcı raporu** ile desteklenir. Cloud VM interaktif test **BLOCKED**.

---

## P1 — Canlı Falcılar / hediye görselleri 401

| Alan | Değer |
|------|--------|
| **Durum** | **Kodda düzeltildi (731+784); cihaz retesti bekliyor** |
| **Test** | Canlı fal veya hediye paneli açıkken görsel yükleme |
| **Ekran** | Canlı Falcılar / canlı fal oturumu |
| **Event** | `[API]` `HttpException: Invalid statusCode: 401` |
| **Endpoint** | `GET https://canlifal.com/api/upload/get-url?path=gift/uploads/{uuid}.png` |
| **Timestamp** | ~2026-10-07T03:26:23Z (Telefon A log) |
| **Exception** | 401 Unauthorized (CachedNetworkImage, Bearer yok) |
| **Dosya** | `mobile/lib/core/images/canlifal_image_urls.dart` |
| **Fonksiyon** | `CanlifalImageUrls.resolve` / `_unwrapUploadGetUrl` |
| **Satır** | ~12–19, ~119–128 |
| **Muhtemel neden** | Backend veya katalog URL’si oturumlu `get-url` döndürüyor; ağ görseli katmanı JWT eklemez |
| **Önerilen çözüm** | CDN path unwrap (731+) veya authenticated image loader; retest kart avatarları |
| **Fix durumu** | **731+784** unwrap eklendi — **cihaz retest BLOCKED** |

---

## P1 — Sesli odadan çıkınca ses devamı (Telefon A)

| Alan | Değer |
|------|--------|
| **Durum** | **Kod düzeltmesi mevcut (731+); kullanıcı cihaz retesti bekliyor** |
| **Test** | Sesli oda → odadan çık / koltuktan in |
| **Ekran** | Voice room RTC |
| **Event** | `[TRTC]` / `[VOICE_ROOM]` |
| **Log kanıtı** | `TRTC_JOIN_SUCCESS` → kullanıcı çıkış sonrası ses sürüyor (kullanıcı); logda `TRTC_LEAVE` psychic oturumu için var, voice pipeline erken kesinti riski |
| **Dosya** | `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` |
| **Fonksiyon** | `leaveRoomSession` → leave coordinator step 1 |
| **Satır** | ~1211–1225 |
| **Muhtemel neden** | TRTC `leave()` 400 ms timeout ile iptal (731 öncesi) |
| **Önerilen çözüm** | 4 sn await (731+); koltuk: `releaseSeatVoice` + audience rejoin — `chat_room_providers_seat.dart` ~656–672 |
| **Retest** | Odadan çık → 30 sn sessizlik; başka oda → eski oda sesi yok |

---

## P2 — DUPLICATE_SSE (sesli oda keşif + oda)

| Alan | Değer |
|------|--------|
| **Durum** | **Kodda azaltıldı (2026-10-08); cihaz retesti bekliyor** |
| **Test** | Oda değiştir / ana sayfaya dön |
| **Event** | `[SSE]` DUPLICATE_SSE |
| **Log** | `voice_sse:cmuvuazea…`, `cmuvu9e2n…`, `cmuviw5ug…` eşzamanlı CREATE |
| **Dosya** | `mobile/lib/core/network/sse/sse_connection_hub.dart` |
| **Fonksiyon** | `forceReleaseVoiceRoom` |
| **Satır** | ~80+ |
| **Muhtemel neden** | Keşif SSE + in-room SSE ref-count; route leave ile yarış |
| **Kod düzeltmesi** | Keşif SSE bağlantıları oda başına tekilleştirildi; artık izlenmeyen oda el sıkışması tamamlanınca lease bırakılıyor. |
| **Retest** | Oda değiştir / ana sayfaya dön; Diagnostics SSE sekmesinde duplicate ve açık lease sayısını kontrol et. |
| **Önem** | P2 |

---

## P2 — LEAK_SUSPECTED after SCREEN EXIT

| Alan | Değer |
|------|--------|
| **Durum** | **Kodda azaltıldı (2026-10-08); cihaz retesti bekliyor** |
| **Test** | Ekrandan çık (EXIT) |
| **Event** | `[SSE]` / resource leak |
| **Snapshot** | `sse: 3` oturum sonu |
| **Dosya** | `mobile/lib/core/diagnostics/cf_diagnostic_logger.dart` |
| **Kod düzeltmesi** | Bağlantı kurulurken oda izleme listeden çıkarsa tamamlanan SSE lease'i bırakılıyor. |
| **Önem** | P2 — performans + hayalet olaylar |

---

## P2 — TweenSequence evaluate > 1.0

| Alan | Değer |
|------|--------|
| **Durum** | **Kodda düzeltildi (731+); cihaz retesti bekliyor** |
| **Timestamp** | 2026-10-07T03:26:22.950751Z |
| **Test** | Canlı fal hediye combo animasyonu |
| **Exception** | `StateError: Bad state: TweenSequence.evaluate() could not find an interval for 1.029…` |
| **Dosya** | `mobile/lib/features/gifts/presentation/engine/gift_engine_overlay.dart` |
| **Fonksiyon** | `_ComboBadgeState` / `_pulse.forward(from: 0)` |
| **Satır** | ~388–410 |
| **Önerilen çözüm** | `_replayPulse()` stop+reset+forward (731+) |
| **Önem** | P2 — UI jank / donma hissi |

---

## P2 — live_fortune TIMER_COUNT_HIGH (5)

| Alan | Değer |
|------|--------|
| **Durum** | FAIL (diagnostic) |
| **Event** | `[TIMER]` module=live_fortune count=5 |
| **Dosya** | `mobile/lib/features/live_psychics/presentation/controllers/psychic_video_controller.dart` |
| **Önem** | P2 — gecikme riski (Telefon A donma şikâyeti ile uyumlu) |
| **Retest** | Tek seans, Diagnostics Timer |

---

## P2 — Duplicate pending session polling

| Alan | Değer |
|------|--------|
| **Durum** | **Kodda düzeltildi (2026-10-08); cihaz retesti bekliyor** |
| **Endpoint** | `GET /api/fortune-tellers/sessions?status=pending` |
| **Event** | `[POLLING]` / `[API]` aynı saniyede çoklu REQUEST_CREATE |
| **Dosya** | `mobile/lib/features/live_psychics/presentation/widgets/psychic_incoming_host.dart` (ve ilgili provider) |
| **Düzeltme** | Poll çağrıları tek uçuş kilidiyle sınırlandı; istek hatasında kilit `finally` ile bırakılıyor. |
| **Önem** | P2 |

---

## BLOCKED — Auth / PK / Admin / Network switch

Bu oturumda **interaktif test yok**. Neden: Flutter SDK + Android cihaz yok (`flutter devices` çalıştırılamadı).

Kontrollü retest için: `docs/ACCEPTANCE_TESTS.md` test hesabı + iki fiziksel cihaz (PK, sesli oda).
