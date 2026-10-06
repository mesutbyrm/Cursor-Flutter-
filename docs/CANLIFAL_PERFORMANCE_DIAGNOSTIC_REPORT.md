# CANLIFAL — Performans, Donma ve Kendi Kendine Tanı Raporu

> Sürüm **1.0.727+780** · Kapsam: Canlı Falcı → İstek → Seans akışı + kalıcı tanı altyapısı.
>
> **Dürüstlük notu:** Bu rapor kod incelemesi ve otomatik testlere dayanır. Gerçek cihazda
> (TRTC, gerçek ağ) ölçüm yapılmadı; «önce/sonra» sayıları koddan türetilmiş **yapısal**
> değerlerdir, ölçülmüş süre değildir. Donmanın cihazdaki tek kök nedeni **kanıtlanmadı**;
> aşağıdaki bulgular kodda doğrulanmış gerçek hatalardır ve donmaya katkı sağlayabilir.
> Kesin teşhis için cihazda `Ayarlar → Hakkında → sürüm satırına uzun bas` ile açılan
> **CANLIFAL DIAGNOSTICS** ekranındaki izleri (Performance / Errors) paylaşın.

## 1. Bulunan problemler ve kök nedenler

| # | Bulgu | Konum | Etki |
|---|-------|-------|------|
| 1 | **İstek akışında `ref` await sonrası kullanılıyordu.** Kullanıcı istek sürerken ekranı kapatırsa `WidgetRef` geçersizleşir → `StateError`, yakalanmamış hata. | `psychic_flow.dart` `bookAndOpenWaiting` (eski: `ref.read(psychicBookingFeedbackProvider…)` await sonrası), `psychic_profile_screen.dart` `finally { ref.read(...) }` | Çökme / «uygulama kapanmaya zorluyor» |
| 2 | **Çift istek koruması yalnız profil ekranındaydı.** `psychic_quick_session.dart` ve `live_broadcast_room_page.dart` aynı akışı korumasız çağırıyordu; başka falcıya geçiş de ikinci istek atabiliyordu. | `PsychicFlow.bookAndOpenWaiting` çağıranları | Çift rezervasyon / çift jeton riski |
| 3 | **Yoklama zamanlayıcılarında devam eden istek koruması yoktu.** Bağlantı kurulurken `_signalPoll` 0,9 sn, `_roomPoll` 2 sn aralıkla tetikleniyor; her tetik, bir öncekinin bitmesini beklemeden yeni istek başlatıyordu. Yavaş ağda (istek zaman aşımı 30 sn) istekler birikir, yanıtlar sırasız gelip state'i tekrar tekrar yazar. | `psychic_video_controller.dart` `_scheduleSignalPoll`, `_scheduleRoomPoll`, `_pollRoomSignals`, `_syncRoomInfo`, `_pollChat`, `_sendPing` | Kasma, sunucu yükü, geç bağlanma |
| 4 | **Seri bağlantı hazırlığı.** `_syncRoomInfo` oda ve durum sorgularını art arda yapıyor; `_bootstrap` TRTC join'den önce bunu en az iki kez (ve `_waitForRoomBootstrap` içinde 6 tura kadar) çağırıyor. | `_syncRoomInfo`, `_bootstrap` | Join'in geç başlaması |
| 5 | **TRTC token isteğinin zaman aşımı yoktu.** Sunucu yanıtsız kalırsa join hiç başlamaz, ekran «bağlanıyor»da kalırdı. | `_joinTrtc` | Sonsuz bekleme |
| 6 | **SSE: bilerek iptal edilen istek hata sayılıp ek yeniden bağlanma zamanlıyordu.** Yeni bağlantı açılırken eskisi iptal edilince `DioException(cancel)` yakalanıp `_scheduleReconnect` çağrılıyordu. | `psychic_room_sse_service.dart`, `psychic_incoming_sse_service.dart` `_openStream` | Gereksiz yeniden bağlanma / bağlantı dalgalanması |
| 7 | Gelen-seans SSE'sinde heartbeat izleyici yok (oda SSE'sinde var). Yarı-açık bağlantı fark edilmez. | `psychic_incoming_sse_service.dart` | **Yalnız bulgu — değiştirilmedi** (sunucu heartbeat aralığı belgelenmemiş) |

### Doğrulanan **sorunsuz** alanlar (negatif bulgular)
- **Bekleme ekranı kaynak sızıntısı yok:** 10 kez gir/çık testinde kapalı ekranlardan yoklama devam etmiyor (`psychic_waiting_lifecycle_test.dart`).
- `PsychicVideoController.dispose` tüm zamanlayıcıları, bağlantı aboneliğini, SSE ve TRTC'yi kapatıyor; `_disposed` korumaları yaygın.
- Bekleme ekranı yoklaması zaten tek turda tek istek (`_checking` koruması).
- SSE yeniden bağlanma üstel geri çekilme + vazgeçme politikası kullanıyor (`SseReconnectPolicy`).
- JSON ayrıştırma için `json_isolate_perf.dart` mevcut; seans akışında ağır ana-isolate işi bulunmadı.

## 2. Değiştirilen dosyalar

**Yeni**
- `mobile/lib/core/diagnostics/cf_diag.dart` — kategorili halka tampon kayıt, hata sınıflandırma, gizlilik süzgeci
- `mobile/lib/core/diagnostics/cf_trace.dart` — `CfTrace` (traceId + adım süreleri), `CfSingleFlight`
- `mobile/lib/core/diagnostics/cf_monitors.dart` — kare/jank izleyici, UI donma bekçisi
- `mobile/lib/core/diagnostics/cf_self_check.dart` — kendi kendine tanı çalıştırıcı
- `mobile/lib/features/debug/presentation/pages/cf_diagnostics_page.dart` — CANLIFAL DIAGNOSTICS ekranı (6 sekme)
- Testler: `test/core/diagnostics/cf_diagnostics_test.dart`, `test/features/live_psychics/psychic_flow_booking_guard_test.dart`, `psychic_waiting_lifecycle_test.dart`

**Değişen**
- `psychic_flow.dart`, `psychic_profile_screen.dart` — merkezi tekil istek kapısı, `ref` önceden alma, iz + zaman aşımı mesajları
- `psychic_video_controller.dart` — tekil-uçuş yoklamalar, paralel oda/durum sorgusu, gereksiz senkron atlama, token zaman aşımı, TRTC süre kaydı
- `psychic_room_sse_service.dart`, `psychic_incoming_sse_service.dart` — iptal ≠ hata, SSE tanı kayıtları
- `crash_reporting_bootstrap.dart`, `main.dart` — global hata kaydına kategori
- `startup_route_observer.dart` — aktif ekran adı (donma raporu için)
- `app_deferred_bootstrap.dart` — izleyicileri başlatır (yalnız debug / açıkça etkinse çalışır)
- `app_router.dart`, `profile_about_page.dart` — `/settings/diagnostics` rotası + gizli giriş

Backend, API yolları, istek/yanıt modelleri **değiştirilmedi**; migration yok.

## 3. Canlı Fal istek akışı (güncel)

```
TAP → (profil ekranı: butona basılı kilidi + PsychicFlow.isBookingInFlight)
→ PsychicFlow.bookAndOpenWaiting  [tekil kapı, ≤60 sn takılı kalma tavanı]
   · repo + feedback bildiricisi await'ten ÖNCE alınır (ekran kapansa da güvenli)
   · CfTrace 'FORTUNE_REQUEST' başlar → traceId
   → blocking-session lookup   (12 sn zaman aşımı)
   → API createSession         (25 sn zaman aşımı)
   → session store save
   → waiting ekranına yönlen   (seans oluştuysa ekran kapalı olsa da açılır; jeton kesildiği için)
→ finally: kapı açılır, iz kapanır (TOTAL ms)
```
Zaman aşımı mesajı: «Bağlantı zaman aşımına uğradı. Tekrar deneyin.» Sonsuz yükleme yok (testli).

Örnek iz çıktısı (debug konsol / Diagnostics → Performance):
```
FORTUNE_REQUEST  CF-TRACE-…
  blocking-session lookup: … ms
  API createSession: … ms
  session store save: … ms
  TOTAL: … ms  [ok]
```

## 4. TRTC bulguları
- Engine zaten `TrtcRoomManager` üzerinden tek örnek; join `tryBeginJoin` kapısıyla tekilleştirilmiş, ekran rebuild'i engine'i yeniden başlatmıyor (controller `StateNotifier`, widget'lardan bağımsız).
- Eklendi: token isteğine 20 sn zaman aşımı; token ve join süreleri `CfDiag` (TRTC kategorisi) ile kaydediliyor; join hataları kategorili kaydediliyor.
- **Ölçülmedi:** gerçek join süresi (cihaz gerekir).

## 5. SSE bulguları
- Bulgu 6 düzeltildi (iptal ≠ hata). Bağlandı / yeniden bağlanma #N / heartbeat zaman aşımı kayıtları SSE kategorisinde.
- Oda SSE'sinde heartbeat bekçisi var (40 sn); gelen-seans SSE'sinde yok (Bulgu 7).
- `CfDiag.lastRoomSseEventAt` ile Diagnostics'te «Heartbeat» kontrolü.

## 6. Flutter rebuild bulguları
- Bekleme ekranı geri sayımı saniyede bir state yazıyor (beklenen); `ref.watch(psychicWaitingControllerProvider)` tüm ekranı yeniden kuruyor. **Seçici (`select`) ile daraltma yapılmadı** — risk/yarar için cihazda Performance sekmesindeki jank sayıları görüldükten sonra karar verilmeli.
- Video seans ekranında kısmi rebuild analizi **yapılmadı** (1.7K satırlık controller; ölçümsüz refactor önerilmez).

## 7. Bellek sızıntısı bulguları
- Bekleme ekranı: 10 giriş/çıkışta sızıntı yok (otomatik test).
- Video seans controller: kod incelemesinde tüm Timer/StreamSubscription `dispose`'ta kapatılıyor. **Otomatik gir/çık testi yazılmadı** (TRTC platform kanalı gerektirir).

## 8. Tanı sistemi (Canlifal Performance & Diagnostics)

| Bileşen | Davranış | Üretimde |
|---|---|---|
| `CfDiag` | Kategorili (AUTH, NETWORK, FORTUNE, LIVE, VOICE, TRTC, SSE, PK, GIFT, PROFILE, DATABASE_API, UI, UNKNOWN) 300 kayıtlık bellek tamponu; token/JWT/şifre/e-posta/userSig süzülür | Yalnız bellek; disk/konsol yok |
| `CfTrace` | `CF-TRACE-…` kimliği, adım süreleri, TOTAL | Hafif |
| Kare izleyici | build/raster, jank (≥50 ms), en fazla saniyede 1 uyarı | **Kapalı** (debug veya Diagnostics'ten açılınca) |
| Donma bekçisi | 250 ms zamanlayıcı kayması ≥1 sn → «UI FREEZE DETECTED» + ekran, son eylem, bekleyen işlemler; arka plan dönüşünde sıfırlanır | **Kapalı** (aynı anahtar) |
| Global hata | `FlutterError`, `PlatformDispatcher`, zone hataları → kategorili `CfDiag` (+ mevcut Crashlytics/Sentry) | Açık, hafif |
| Self Diagnostic | Authentication, JWT (kalan süre, değer gösterilmez), API, Profile, Live Fortune, aktif seans sorgusu, TRTC token, SSE bağlantı, Heartbeat; her biri zaman aşımı + gecikme eşikli (≥1,5 sn ⚠, ≥6 sn ✗) | Elle çalıştırılır |
| Ekran | `/settings/diagnostics` — Diagnostics · Performance · Network · TRTC · SSE · Errors | Menüde yok; Hakkında → sürüm satırına uzun bas |

**Not (TRTC token kontrolü):** sahte oda kimliğiyle token ister; sunucu 4xx dönerse «uç erişilebilir (sahte oda)» uyarısı verir. Token değeri gösterilmez/loglanmaz.

Diğer modüllere (Canlı Yayın, Sesli Oda, PK, Hediye, Chat, Profil, Auth) uygulama: `CfTrace.start(...)` + `CfDiag.record(...)` aynı API ile eklenebilir; bu sürümde yalnız hata kategorileme ve genel izleyiciler tüm uygulamaya uygulandı.

## 9. Önce / Sonra (yapısal, ölçülmemiş)

| Konu | Önce | Sonra |
|---|---|---|
| Bağlantı sırasında eşzamanlı yoklama isteği | Sınırsız (her 0,9 sn / 2 sn yeni istek) | Yoklama türü başına 1 (sinyal 1, oda+durum 2 paralel, sohbet 1, ping 1) |
| `_syncRoomInfo` içi sorgular | 2 ardışık | 2 paralel |
| Join öncesi gereksiz senkron | Her zaman ek tur | <2 sn önce senkronlandıysa atlanır |
| Aynı anda rezervasyon | Yalnız profil ekranında korumalı | Tüm çağıranlarda merkezi kapı |
| Ekran kapanınca istek | `StateError` riski | Güvenli |
| TRTC token zaman aşımı | Yok | 20 sn |

## 10. Test sonuçları

| Senaryo | Sonuç |
|---|---|
| T4 Çok hızlı iki istek → tek istek | ✅ otomatik (`psychic_flow_booking_guard_test`) |
| T5 İstek sırasında geri çık → crash/freeze yok | ✅ otomatik |
| T7 Timeout → sonsuz loading yok | ✅ otomatik (26 sn ilerletilerek) |
| Hata sonrası tekrar denenebilir | ✅ otomatik |
| T10 10 kez gir/çık → yoklama/timer sızıntısı yok (bekleme ekranı) | ✅ otomatik |
| Kategori, gizlilik, iz, tekil-uçuş, donma/jank mantığı, self-check zaman aşımı | ✅ otomatik (`cf_diagnostics_test`, 23 test) |
| T1–T3 liste/profil/istek (UI) | ⚠ cihazda elle |
| T6 Yavaş ağ, T8 TRTC geç bağlanma, T9 SSE kopması | ⚠ **otomatik test yok** — kod değişiklikleri (tekil-uçuş, token zaman aşımı, iptal≠hata) bu senaryolara yöneliktir; cihazda doğrulanmalı |

## 11. Cihazda sonraki adım
1. Güncel APK'yı kurun → Ayarlar → Hakkında → sürüm satırına **uzun basın**.
2. «Ayrıntılı izleme»yi açın, «Kendi kendine tanıyı çalıştır»a basın (sonucu «kopyala»).
3. Canlı falcıya istek atıp donmayı yeniden üretin; sonra **Performance** (donma/jank, son işlemler) ve **Errors** sekmelerini paylaşın.
