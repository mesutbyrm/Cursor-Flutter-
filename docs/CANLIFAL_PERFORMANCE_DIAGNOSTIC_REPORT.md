# CANLIFAL — Performans, Donma ve Kendi Kendine Tanı Raporu

> Sürüm **1.0.727+780** · Kapsam: Canlı Falcı → İstek → Bekleme → Seans akışı + kalıcı tanı altyapısı.
> Ham ölçümler: [`docs/perf-evidence/polling_metrics_before_after.txt`](perf-evidence/polling_metrics_before_after.txt)

## 0. Önce bilinmesi gerekenler (dürüst sınırlar)

- Ölçümler **sahte repo + sanal zaman (widget test)** ile yapıldı; gerçek ağ, gerçek TRTC SDK ve gerçek cihaz **yok**.
  Test ortamında **ana isolate'i CPU ile bloklayan** bir şey görülmedi (en uzun kare adımı eski kodda 9–11 ms, yeni kodda ≤24 ms).
  Yani «900 ms işlemi UI thread'ini bloklıyor» **kanıtlanmadı**. Kanıtlanan: **sınırsız eşzamanlı istek birikmesi, takılı kalan TRTC
  bağlantısı, SSE/sohbetin join'i beklemesi ve dispose sonrası state hatası** (aşağıda). Cihazdaki gerçek jank/donma bunlarla
  açıklanabilir ama **cihazda doğrulanmadı**.
- Kullanıcının bildirdiği asıl belirti (**«istek gönderince, falcıya istek gelmeden donuyor»**) bekleme ekranı aşamasıdır.
  Bu aşamada 900 ms / 2 sn yoklamaları **çalışmaz** (onlar kabulden sonraki görüşme controller'ındadır); bekleme ekranı yoklaması
  zaten tek-uçuşluydu. Bu aşamada bulduğum gerçek hatalar: `ref`'in await sonrası kullanımı, çift istek, dispose sonrası `state`
  erişimi. **Belirtinin tek kök nedeni hâlâ kesinleşmedi**; cihazdaki iz (Diagnostics → Performance/Errors) gerekir.

## 1. Kullanıcının 4 hipotezi — doğrulama sonucu

| # | Hipotez | Sonuç | Kanıt |
|---|---------|-------|-------|
| 1 | `psychic_video_controller` 900 ms sinyal yoklaması | **Kısmen doğrulandı.** İstek biriktiriyordu (yavaş ağda aynı anda **6** sinyal isteği, yanıtsız sunucuda 30 sn'de **34**). UI thread'i CPU olarak bloklamıyor (≤11 ms). | `poll_old` S1/S3 |
| 2 | 2 sn oda yoklaması | **Kısmen doğrulandı.** `fetchRoom` yavaş ağda aynı anda **10**, yanıtsızda **51** uçuşta. CPU bloklama yok. | aynı |
| 3 | await sonrası `ref`/`state` | **Doğrulandı (3 yerde).** (a) `PsychicFlow.bookAndOpenWaiting`: await sonrası `ref.read` — ekran kapanınca `StateError`; (b) profil ekranı `finally { ref.read }`; (c) `PsychicWaitingController._checkStatusOnce`: dispose sonrası `state.closed` okuması → **test, düzeltmeden önce `StateError` ile kırıldı** | `psychic_waiting_lifecycle_test` |
| 4 | Devam eden istek için iptal / in-flight koruması | **Doğrulandı (eksikti).** Yoklamalarda ve rezervasyonda yoktu. **Not:** HTTP isteği `CancelToken` ile gerçekten **iptal edilmiyor**; yanıt dispose sonrası **yok sayılıyor**. Gerçek iptal için repository katmanında değişiklik gerekir, yapılmadı. | — |

## 2. Bulunan ve düzeltilen problemler

| # | Problem | Düzeltme | Dosya |
|---|---------|----------|-------|
| 1 | İstek akışında `ref` await sonrası kullanılıyordu | `repo` + bildirici await'ten önce alınır; yazma `try/catch` | `psychic_flow.dart` |
| 2 | Çift istek koruması yalnız profil ekranında | Tüm çağıranlar için merkezi tekil kapı (`isBookingInFlight`, ≤60 sn tavan) | `psychic_flow.dart`, `psychic_profile_screen.dart` |
| 3 | Yoklama zamanlayıcıları istek biriktiriyordu | Sinyal/oda/sohbet/ping için tekil-uçuş (`CfSingleFlight`) | `psychic_video_controller.dart` |
| 4 | Oda+durum sorguları ardışık; biri hata verince diğeri havada kalıp sonraki senkronla çakışıyordu | İkisi paralel ve **ikisi de bitmeden dönülür** | aynı |
| 5 | Zamanlayıcıdan `unawaited` çağrılan yoklamada hata → yakalanmamış async hata | `_guarded` ile kayıt + güvenli dönüş | aynı |
| 6 | **SSE ve sohbet yoklaması TRTC join'i bekliyordu** (join takılırsa sohbet/oda olayları hiç başlamıyordu) | Sohbet yoklaması ve SSE join ile **paralel** başlar | aynı |
| 7 | TRTC token isteğine zaman aşımı yoktu → «joining»de sonsuz bekleme | 20 sn zaman aşımı → hata + faz `error` | aynı |
| 8 | **Paylaşılan SSE servisinde eski seansın `disconnect()` çağrısı yeni seansın bağlantısını kapatabiliyordu** | `disconnect(forSessionId:)` — servis başka seansa bağlıysa yok sayılır | `psychic_room_sse_service.dart`, controller |
| 9 | Bilerek iptal edilen SSE isteği ek yeniden bağlanma başlatıyordu | `CancelToken.isCancel` → çık | iki SSE servisi |
| 10 | Bekleme ekranı controller'ı dispose sonrası `state` okuyordu | `_closed => !mounted \|\| state.closed` | `psychic_waiting_screen.dart` |
| 11 | Bağlantı hazırlığında gereksiz tekrar senkron | <2 sn önce senkronlandıysa atlanır | controller |

**Bilinen riskli davranış değişikliği:** `_syncRoomInfo` hata verirse artık «devam et» döner (eskiden hata yakalanmadan akış yarım kalırdı). Cihazda
izlenmeli.

## 3. Önce / Sonra (aynı test, düzeltme öncesi `origin/main` kodu vs yeni kod)

| Senaryo (sanal 12–30 sn) | ÖNCE istek / eşzamanlı | SONRA istek / eşzamanlı |
|---|---|---|
| Yavaş ağ (5 sn gecikme, 12 sn) | 38 / **10** (oda), 6 (sinyal) | 10 / **1** |
| Sunucu yanıtsız (30 sn) | 85 / **51** | 3 / **1** |
| Ağ kesik (hata dönen istekler, 10 sn) | 31 / 3 | 42 / **1** (*) |
| SSE geç (20 sn) — sohbet yedeği | sohbet isteği **0** | **4** |
| TRTC token yanıtsız — join sırasında SSE / sohbet | **0 / 0** | **1 / 1** |
| TRTC token yanıtsız — 25 sn sonra | faz `joining`, hata **yok** (sonsuz) | faz `error`, «İstek zaman aşımına uğradı…» |
| 10× gir/çık — sızan istek | 0 | 0 |

(*) Toplam istek arttı: durum sorgusu artık oda yok iken de paralel atılıyor; asıl ölçüt eşzamanlılık (3 → 1).

## 4. 10 gerçek-senaryo sonucu

Tümü **PASS**. «UI freeze» = test ortamında ana isolate'i bloklayan adım görülmedi (en uzun kare adımı ms olarak). traceId'ler her çalıştırmada
yeniden üretilir; aşağıdakiler kayıtlı çalıştırmadandır. «Süre» gerçek (duvar saati) süredir; sanal bekleme dahil değildir.

| # | Senaryo | Sonuç | Süre | traceId | Çalışan istek / sayı | UI freeze | TRTC | SSE |
|---|---------|-------|------|---------|----------------------|-----------|------|-----|
| 1 | Falcıya tek tık | PASS | 19 ms | CF-TRACE-muwv3n7w4 | createSession ×1 | Hayır | — (bekleme aşaması) | — |
| 2 | 5-10 hızlı tık (10) | PASS | 90 ms | CF-TRACE-muwv3n9h5 | createSession ×1; 9 tık reddedildi | Hayır | — | — |
| 3 | İstek sürerken geri çıkma | PASS | 8 ms | CF-TRACE-muwv3n4x2 | createSession ×1; seans yine açıldı (jeton kesildiği için); bekleme ekranında: 1 istek, sızan 0, hata yok | Hayır | — | — |
| 4 | Yavaş internet | PASS | 24 ms | CF-TRACE-muwv3ncz6 | booking 8 sn: createSession ×1; bekleme (5 sn gecikme): 3 istek/12 sn, eşzamanlı 1; controller: 10 istek/12 sn, eşzamanlı 1 | Hayır (en uzun kare 0 ms) | — | SSE bağlandı ×1 |
| 5 | İnternet kesilmesi | PASS | 11 ms | CF-TRACE-muwv3net7 | createSession ×1 → «Bağlantı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.»; kapı açıldı. Controller: eşzamanlı 1, yakalanmamış hata yok | Hayır | — | — |
| 6 | API timeout | PASS | 9 ms (+26 sn sanal) | CF-TRACE-muwv3n673 | createSession ×1 → «Bağlantı zaman aşımına uğradı. Tekrar deneyin.»; loading kapandı. Yanıtsız sunucuda controller 30 sn'de 3 istek | Hayır | — | — |
| 7 | TRTC geç bağlanma | PASS | 6 ms | (controller; iz yok — `CfDiag` TRTC kaydı) | token ×1; 20 sn sonra hata; join sırasında SSE ×1, sohbet ×1 | Hayır (en uzun adım 6 ms) | 25 sn'de faz `error` (sonsuz «joining» yok) | Join'i beklemeden bağlandı |
| 8 | SSE geç bağlanma (20 sn) | PASS | 1 ms | — | SSE bağlantısı ×1; oda yoklama 21, sohbet 4 (yedek sürdü) | Hayır | — | `sseConnected=false` (12. sn), tek bağlantı |
| 9 | 10× giriş/çıkış | PASS | 2 ms | — | Bekleme: sızan 0. Controller: sızan 0; 10× yalnız kendi seansının SSE'si kapatıldı; her giriş 3 sn'de 5 sinyal yoklaması (tek zamanlayıcı kümesi) | Hayır | — | disconnect ×10 |
| 10 | Aynı falcıya tekrar istek | PASS | 48 ms | CF-TRACE-muwv3ngd9 | createSession ×2 (art arda, çakışmadan) | Hayır | — | — |

## 5. Değiştirilen / eklenen dosyalar

**Yeni:** `lib/core/diagnostics/{cf_diag,cf_trace,cf_monitors,cf_self_check}.dart`, `lib/features/debug/presentation/pages/cf_diagnostics_page.dart`;
testler: `test/core/diagnostics/cf_diagnostics_test.dart`, `psychic_flow_booking_guard_test.dart` (9), `psychic_waiting_lifecycle_test.dart` (4),
`psychic_video_controller_polling_test.dart` (7); `docs/perf-evidence/polling_metrics_before_after.txt`.

**Değişen:** `psychic_flow.dart`, `psychic_profile_screen.dart`, `psychic_video_controller.dart`, `psychic_waiting_screen.dart`,
`psychic_room_sse_service.dart`, `psychic_incoming_sse_service.dart`, `crash_reporting_bootstrap.dart`, `main.dart`,
`startup_route_observer.dart`, `app_deferred_bootstrap.dart`, `app_router.dart`, `profile_about_page.dart`.
Backend/API yolları/modeller **değişmedi**; migration yok.

## 6. Tanı sistemi

| Bileşen | Davranış | Üretimde |
|---|---|---|
| `CfDiag` | Kategorili (AUTH, NETWORK, FORTUNE, LIVE, VOICE, TRTC, SSE, PK, GIFT, PROFILE, DATABASE_API, UI, UNKNOWN) 300 kayıtlık bellek tamponu; token/JWT/şifre/e-posta/userSig süzülür | Yalnız bellek |
| `CfTrace` | `CF-TRACE-…` kimliği, adım süreleri, TOTAL | Hafif |
| Kare izleyici / Donma bekçisi | Jank ≥50 ms; 250 ms zamanlayıcı kayması ≥1 sn → «UI FREEZE DETECTED» (ekran, son eylem, bekleyen işlemler) | **Kapalı** (debug veya ekrandan açılınca) |
| Self Diagnostic | Authentication, JWT (kalan süre), API, Profile, Live Fortune, aktif seans, TRTC token, SSE, Heartbeat; zaman aşımı + gecikme eşikleri | Elle |
| Ekran | `/settings/diagnostics` — Hakkında → sürüm satırına uzun bas | Menüde yok |

## 7. Hâlâ doğrulanmamış / yapılmayanlar

- Gerçek cihazda UI jank/donma; gerçek TRTC join süresi; gerçek ağ kopması.
- İstek **iptali** (CancelToken) — yalnız yanıt yok sayma.
- Gelen-seans SSE'sinde heartbeat bekçisi yok (sunucu heartbeat aralığı belgelenmemiş).
- Video seans ekranında `select` ile kısmi rebuild analizi yapılmadı (ölçümsüz refactor önerilmez).
- Diğer modüllere (Canlı Yayın, Sesli Oda, PK, Hediye) iz altyapısı henüz bağlanmadı (yalnız genel hata kategorileme).
- **Falcıya istek → bekleme aşamasındaki donmanın tek kök nedeni** kesinleşmedi.

## 8. Cihazda sonraki adım
Ayarlar → Hakkında → sürüm satırına uzun bas → «Ayrıntılı izleme» aç → «Kendi kendine tanı» çalıştır → falcıya istek at, donmayı
yeniden üret → **Performance** ve **Errors** sekmelerini paylaş.
