# Canlifal Mobile — Fix Plan (Aşama 2)

**Tarih:** 2026-09-18  
**Kaynak:** [`AUDIT_REPORT.md`](AUDIT_REPORT.md) (Aşama 1)  
**Talimat:** `5_TAM_UYGULAMA_AUDIT_TALIMATI` madde 31  
**Sürüm hedefi:** `mobile/pubspec.yaml` → `1.0.559+601` (fix’lerde patch bump)  
**Kılavuz:** [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](docs/FLUTTER_ENTegrasyon_KILAVUZU.md) §9 — yeni endpoint icat etme

---

## Genel kurallar (düzeltme aşaması)

1. Her madde **tek commit** (mantıksal değişiklik); push sonrası `dart analyze` + ilgili `flutter test`.
2. Değişiklik öncesi: `grep`/referans araması — dosya **silme** yalnızca kullanım kanıtlandıktan sonra.
3. **PK / live RTC / SSE / auth refresh** — davranış değiştirmeden önce mevcut testleri çalıştır.
4. Backend değiştirme yok; yalnızca mobil istemci + CI script + dokümantasyon (gerekirse).
5. Mock/dummy veri ekleme yok.
6. Büyük refactor yok; P1-2 yalnızca **extract widget** (mantık taşınmaz).

**Doğrulama komutları (her batch sonrası):**

```bash
cd mobile && flutter pub get && dart analyze && flutter test
# Cihaz gerektiren maddeler: scripts/psychic-p0-checklist.sh, P1 device checklist
# Release metadata: bash scripts/verify-apk-latest-release.sh (CI veya token ile)
```

---

## Özet sıra

| Sıra | Öncelik | Madde sayısı | Kim |
|------|---------|--------------|-----|
| 1 | P0 | 1 (+ kullanıcı cihaz) | Kullanıcı + agent hotfix |
| 2 | P1 | 4 | Agent |
| 3 | P2 | 14 | Agent |
| 4 | P3 | 8 | Agent |
| 5 | P4 | 6 | Agent |
| — | Docs / release | 3 | Agent + kullanıcı |

---

## P0 — Kritik (release bloker)

### P0-1 — Psychic TRTC T+5s A/V donması

| Alan | Değer |
|------|--------|
| Audit | P0-1, `LIVE AUDIT`, `RELEASE BLOCKERS` #1 |
| Amaç | `Psychic P0 PASS` → RELEASE READY kapısı açılabilir |
| Sahip | **Kullanıcı:** cihaz testi · **Agent:** yalnızca FAIL kanıtı varsa hotfix |

**Adımlar**

1. **Kullanıcı (zorunlu)**  
   - APK: apk-latest · danışan + falcı hesapları → `docs/PSYCHIC_P0_START.md`  
   - `bash scripts/psychic-p0-prereqs.sh` → `bash scripts/psychic-p0-checklist.sh`  
   - Sonuç: `bash scripts/record-user-test-result.sh p0 PASS|FAIL "not"`  
   - Agent’a: **`Psychic P0 PASS`** veya **FAIL** + logcat / ekran kaydı

2. **Agent (yalnızca FAIL)** — önce dosya taraması:
   - `grep -r TrtcRoomManager\|psychic_trtc\|trtc/token mobile/lib/features/live_psychics`
   - `mobile/lib/features/trtc/` (varsa ortak gate)
   - Test: `flutter test test/features/live_psychics/psychic_trtc_freeze_test.dart`

3. **Olası hotfix alanları** (FAIL logcat’e göre seç — hepsini birden yapma):
   - `psychic_trtc_connection.dart` — rejoin debounce / duplicate enterRoom  
   - Oda SSE + TRTC `trtcRoomId` drift (audit: `psychic_trtc_freeze_test` senaryoları)  
   - Token yenileme: kılavuz §9 TRTC token path (üretim `POST /api/trtc/token`)

4. **Test kapısı**  
   - Unit: `psychic_trtc_freeze_test` + `live_psychics` datasource testleri  
   - Cihaz: T0, T+1s, **T+5s**, T+30s, arka plan/ön plan  
   - PASS olmadan P1 koduna geçme (AGENTS: Psychic P0 freeze)

**Risk:** Yüksek — yanlış TRTC değişikliği canlı yayını etkilemez ama falcı modülünü kırar.  
**Rollback:** Tek commit revert; TRTC değişikliklerini `live/` ile paylaşılan gate’te minimal tut.

---

### P0-2 — Hediye jeton düşümü atomik değil (BACKEND)

> ### ✅ KAPSAM KARARI VERİLDİ — 2026-09-18
>
> Bu planın **Genel kural 4**'ü başlangıçta *"Backend değiştirme yok"* diyordu. Ancak doğrulama koşusunda bulunan **en ciddi kusur backend'deydi** (`api/src/routes/gifts.ts`) ve mobil taraftan düzeltilemez — para bütünlüğü sunucuda sağlanmak zorundadır.
>
> **Kullanıcı kararı: backend kapsama alındı.** Genel kural 4 bu madde için geçersizdir.
>
> **Durum: UYGULANDI.** Doğrulama: `npm run typecheck` temiz · `npm test` **59 geçti / 0 başarısız** (taban 53 + 6 yeni test).

| Alan | Değer |
|------|--------|
| Audit | `AUDIT_REPORT.md` → P0-2 + P0 yan bulgu |
| Dosya | `api/src/routes/gifts.ts` — `sendStreamGift` (163–290) **ve** `sendRoomGift` (366–508) |
| Sahip | Backend (kapsam kararı sonrası) |

**Önce arandı (kullanım araştırması tamamlandı):**

| Soru | Cevap |
|---|---|
| Kaç handler? | **İki, birebir aynı kusur.** Yalnızca birini düzeltmek yarım çözüm — ortak yardımcıya (`api/src/lib/giftCharge.ts`) çıkarılmalı |
| Yanıt sözleşmesi | `{...payload, newBalance, balance, coinBalance, streamerBalance, pkBattle}` — **korunmalı**, istemci değişmemeli |
| Transaction dışında kalacaklar | `giftQueueEnqueue` (245), `emitGiftEvent` (251), `applyPkGift` (253), `emitPkBattleEvent`/`emitPkStreamSignal` (264–267), `processLiveGiftReferral` (270) |
| İstemci yolları | `chat_room_gifts_remote_datasource.dart:67`, `shorts_repository_impl.dart:227`, `LiveFieldApiRemoteDataSource…gifts.sendGift` |
| Proje deseni biliyor mu? | Evet — `$transaction` 10 yerde kullanılıyor (`pkBattleService.ts:601`, `referralCommissionService.ts:410,478,538`, `voiceRoomRevenue.ts:120,196`, `video_streams.ts:703`, `short_videos.ts:300,313,415`). **Gelir tarafı korunmuş, harcama tarafı korunmamış.** |

**Üç kusur:**
1. **Check-then-act yarışı** — bakiye okuma (200) ile düşme (205) ayrı sorgular, aralarında koşul yok → eşzamanlı istekler bakiyeyi **negatife indirebilir**
2. **Transaction yok** — jeton 205'te düşüyor, `giftEvent` 228'de oluşuyor; arada hata → **jeton gitti, hediye yok**
3. **Idempotency yok** — retry/çift dokunuşta çift ücret *(mevcut planın P2-14 maddesiyle aynı konu — oraya bağlanmalı)*

**Plan**
1. Koşullu atomik düşme: `updateMany({ where: { id, coins: { gte: totalCost } }, data: { coins: { decrement: totalCost } } })` → `count === 0` ise 402.
2. Transaction sınırı **yalnızca** düşme + `giftEvent.create`; yan etkiler commit sonrası (aksi halde rollback'te hayalet event yayılır).
3. Ortak yardımcıya çıkar — iki handler'da aynı hatayı tekrar etme riskini kalıcı kapat.
4. `newBalance` artık `updateMany`'den gelmiyor; sözleşmeyi bozmadan ayrıca okunmalı.

**Test:** (a) `Promise.all` ile eşzamanlı iki istek → negatif bakiye yok, biri 402; (b) `giftEvent.create` fail → jeton iade; (c) yanıt alanları değişmemiş.

**Risk:** Orta — en büyük tehlike yan etkileri transaction içine almak. **Rollback:** tek dosya + yardımcı, istemci değişmediği için `git revert` güvenli.

---

### P0-3 — Hediye alıcısı benzersiz olmayan `displayName` ile çözülüyor (BACKEND)

> **Durum: UYGULANDI — 2026-09-18.** Planın önerdiği güvenli ara adım seçildi: `displayName` yolu **kaldırılmadı**, yalnızca belirsizlikte reddediliyor. Bu sayede üretimde `receiverName` oranını ölçmeye gerek kalmadan uygulanabildi — davranış yalnızca mevcut kodun zaten yanlış olduğu (çok eşleşmeli) durumda değişiyor.
>
> `resolveGiftReceiverId()` (`api/src/lib/giftCharge.ts`): benzersiz `username` tercih edilir; `displayName` yalnızca **tek** eşleşmede kabul edilir; belirsizlikte alıcı boş bırakılır (hediye yine kaydedilir, gelir yanlış hesaba yazılmaz). Her iki handler da bu yardımcıyı kullanıyor.
>
> Doğrulama: `npm run typecheck` temiz · `npm test` **65 geçti / 0 başarısız** (taban 59 + 6 yeni test).

- **Dosya:** `api/src/routes/gifts.ts:214–226` ve `sendRoomGift` içindeki eşdeğeri (~419)
- **Problem:** `findFirst({ OR: [{ username }, { displayName }] })` — `username` benzersiz ama **`displayName` değil** (`api/src/routes/users.ts:36` yalnızca `min(1).max(120)`). Çoklu eşleşmede rastgele kullanıcı seçiliyor → hediye ve gelir **yanlış kişiye** yazılabilir.
- **Plan:** Alıcı öncelikle `receiverId`; isimle çözüm gerekiyorsa yalnızca `username`; belirsizlikte 409.
- **⚠ Uygulamadan önce ölçüm gerekli:** Üretimde isteklerin ne kadarı `receiverName` ile geliyor? İstemcilerin `receiverId` göndermediği bir yol varsa hediye alıcısız kalır. Ölçüm yapılmadan `displayName` yolu tamamen kapatılmamalı — ara adım: **loglama + belirsizlikte reddetme**.
- **Test:** Aynı `displayName`'li iki kullanıcı seed'le → belirsiz alıcıya yazılmamalı.

---

## P1 — Yüksek

### P1-1 — PK battle stale latch (`refresh()` clearBattle)

| Alan | Değer |
|------|--------|
| Audit | P1-1, PK AUDIT, BROKEN FLOWS PK→single-live |
| Dosya | `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart` (~104–166) |
| İlgili | `live_pk_broadcast_stage.dart`, `live_broadcast_room_page.dart` (listen 2660–2680) |

**Önce ara:**  
`grep clearBattle\|refresh(\|applyRemoteBattle mobile/lib/features/live`

**Plan**

1. `refresh()` içinde `clearBattle` öncesi **latch**:  
   - Son bilinen `battleId` + `isLivePkActiveStatus` / `isLivePkStartingStatus` ve son başarılı ingest zamanı (ör. 30–60 sn TTL).  
   - Geçici null/eksik dual-stream yanıtında **önceki battle** korunur; yalnızca sunucu explicit `ended` veya TTL aşımı + SSE uyumu ile temizlenir.
2. `_mergeBattleMap` — opponent stream id’lerinin boş string ile overwrite edilmesini engelle (mevcut koruma genişlet).
3. Unit test ekle/güncelle: `live_video_pk_provider_test.dart` — senaryolar:  
   - API null + önceki active battle → battle kalır  
   - API ended → clear  
   - partial JSON (dual-stream eksik) → latch

**Test:** `flutter test test/features/live/live_video_pk_provider_test.dart` + PK paketi smoke.

**Risk:** Orta-yüksek — PK UI takılı kalabilir; TTL + ended status ile sınırla.

---

#### 🔎 2026-09-18 doğrulama koşusu — P1-1'in kök nedeni ve latch tasarımını etkileyen üç bulgu

Yukarıdaki latch planı doğru yönde, ancak kod okumasında **latch'in zaten var olduğu** ve eksik kapsadığı tespit edildi. Latch'i sıfırdan yazmak yerine mevcut olanı genişletmek gerekiyor (talimat §13 — ikinci sistem kurma).

**Mevcut latch:** `mobile/lib/features/live/domain/pk/live_pk_refresh_stale_guard.dart` → `shouldRetainPkBattleOnEmptyRefresh()`, `staleTtl = 90 sn`. Tek çağıran: `live_video_pk_provider.dart:82-88`.

**(a) `paused` statüsü hiçbir yerde kapsanmıyor — net eksik**
Guard'ın koruduğu statüler (`pk_status_helper.dart` + `live_pk_broadcast_stage.dart`): `pending, invited, created, waiting, active, started, in_progress, running, starting, countdown, preparing, ended, completed, finished, tie, draw, cancelled, canceled`. **`paused` yok.** Oysa `pk_session_notifier.dart:102-104,245-247` `PkStatus.paused`'ı aktif maç gibi ele alıyor → maç duraklatılmışken boş refresh gelirse battle siliniyor. Bu düzeltme **ürün kararından bağımsız olarak gerekli**.

**(b) TTL maç süresinden kısa**
`staleTtl` **90 sn**, varsayılan maç süresi `pk_session_notifier.dart:261` → **180 sn**. 90 sn'yi aşan ağ sorununda maç canlıyken UI düşüyor. TTL `battleEndsAt` üzerinden türetilmeli.

**(c) Hata yolu ile "battle yok" yolu aynı sonuca bağlanmış**
`live_video_pk_provider.dart:170-181` — `catch` bloğu hatayı yazıp silme yoluna düşüyor. Tek bir timeout/500 PK ekranını düşürebiliyor. *Hata* bilgi yokluğudur, *boş yanıt* bilgidir; ayrılmalı. **Bu, üç düzeltme içinde en düşük riskli olanı ve önce yapılmalı** — tek başına "tek timeout PK'yı düşürüyor" senaryosunu kapatır.

> ### ⚠ Bu madde mevcut bir test beklentisini değiştirmek zorunda — önce ürün kararı gerekiyor
>
> `mobile/test/features/live/live_pk_refresh_stale_guard_test.dart` **zaten var** (4 test) ve 2. vakası şunu **kasıtlı olarak** kodluyor:
>
> `does not retain active battle after TTL when dual streams missing` → active + 120 sn + dual stream yok → **`isFalse`**
>
> Yani düşme davranışı "unutulmuş" değil, **bilinçli alınmış bir karar**. Latch'i genişletmek bu testi değiştirmeyi gerektirir. Uygulamadan önce cevaplanmalı:
>
> **"Aktif bir PK maçında sunucudan 90+ sn doğrulama gelmiyorsa ve elde çift yayın kimliği yoksa — PK ekranı kalmalı mı, düşmeli mi?"**
>
> Bu mühendislik değil **ürün** kararıdır: yanlış pozitif (bitmiş maç ekranda takılı) ↔ yanlış negatif (süren maç ekrandan düşer). `paused` düzeltmesi (a) bu karardan bağımsız ilerleyebilir.

**Önerilen alt sıra:** (c) catch ayrımı → (a) `paused` kapsamı → (b) TTL türetme → ardından P1-1'in `_mergeBattleMap` maddesi.

**Ek test vakaları:** `paused` + boş refresh → korunmalı · `active` + 120 sn authority + 180 sn maç → korunmalı · gerçek `ended` → **silinmeli** (regresyon koruması).

**Ek madde — `pkSessionProvider` `autoDispose` state kaybı:** `pk_session_notifier.dart:356-359` `NotifierProvider.autoDispose.family` kullanıyor; izleyici kalmadığında state imha olup `const PkSessionState()` (battle yok) dönüyor. Navigasyon/sheet açılışı izleyicileri anlık düşürürse PK state sıfırlanır — latch'ten bağımsız **ikinci bir düşme yolu**. Ayrıca `loadState()` (116-130) ve `_action()` (338-353) `await` sonrası `state` yazıyor, `ref.mounted` kontrolü yok. *Çözüm:* battle non-null iken `ref.keepAlive()`, `ended`'de bırak (bırakılmazsa sızıntı — testle kanıtlanmalı).

> **Durum: UYGULANDI + TEST EDİLDİ — 2026-09-18.** Düzeltme `691200a8`'de yapıldı; o commit'te kendi testinin olmadığı açıkça belirtilmişti. Boşluk `mobile/test/features/pk/pk_session_keep_alive_test.dart` ile kapatıldı (`pkServiceProvider` sahte servisle, `pkBattleRemoteProvider` yutucu stub ile override ediliyor; 3 vaka: süren maçta korunma, bitmiş maçta bırakma, battle yokken tutmama).
>
> **Testin gerçekten koruduğu doğrulandı:** `_retainLive()` geçici olarak devre dışı bırakıldığında 1. vaka bug'ın semptomuyla düşüyor — `Expected: 'pk-1', Actual: <null>`. Sonrasında kod geri yüklendi.
>
> Not: `ref.mounted` riverpod **2.6.1'de public değil** (3.0'da geldi); planda öngörülen `ref.mounted` yerine `onDispose`'da set edilen `_disposed` bayrağı kullanıldı.
>
> Doğrulama: `flutter analyze` **657** (taban çizgisiyle aynı, 0 error) · `flutter test` **1419 geçti / 0 başarısız** (taban 1416 + 3 yeni).

---

### P1-2 — `live_broadcast_room_page` kontrollü parçalama

| Alan | Değer |
|------|--------|
| Audit | P1-2, PERFORMANCE, LIVE AUDIT |
| Dosya | `live_broadcast_room_page.dart` (3209 satır) |

**Önce ara:**  
Mevcut extract’ler: `widgets/broadcast_room/*`, `grep class _LiveBroadcast`

**Plan (3 aşamalı, RTC mantığı taşınmaz)**

1. **Aşama A:** PK dinleyicileri + `_postPkHeartScore` → `live_broadcast_pk_interaction_mixin.dart` veya mevcut `live_pk_*` widget dosyası (yalnızca taşıma).  
2. **Aşama B:** SSE connection banner / `_onLiveSseConnectionChanged` → `live_room_sse_status_banner.dart`.  
3. **Aşama C:** `ref.watch` → `select` daraltma (pk error, viewerCount ayrı).

Her aşama sonrası: `flutter test test/features/live/` + analyze.

**Risk:** Orta — import döngüsü; public API değiştirme.

---

### P1-3 — Kritik akış test boşluğu (CI)

| Alan | Değer |
|------|--------|
| Audit | P1-3, TEST AUDIT, MISSING integration test |

**Plan**

1. Kısa vadede: `scripts/run-acceptance-tests.sh` / API gate’e **PK smoke** ve **discovery action** HTTP adımları ekle (secret’lar `docs/ACCEPTANCE_TESTS.md`).  
2. Orta vade: `integration_test/` paketi — yalnızca **auth mock + router smoke** (emülatör CI yok; dokümante “local optional”).  
3. Doküman: `docs/ACCEPTANCE_TESTS.md` — Psychic/PK cihaz zorunlu maddeler.

**Risk:** Düşük (script/doc).

---

### P1-4 — apk-latest metadata doğrulama

| Alan | Değer |
|------|--------|
| Audit | BROKEN FLOWS metadata, RECOMMENDED FIX ORDER #4 |
| Dosya | `scripts/verify-apk-latest-release.sh`, `upload-apk-latest-release.sh` |

**Plan**

1. `main` üzerinde son başarılı workflow run + `METADATA=PASS` doğrula.  
2. FAIL ise yalnızca script düzeltmesi (Flutter dokunma yok).  
3. `docs/LATEST_APK_BUILD.md` senkron.

**Test:** Manuel workflow veya `verify-apk-latest-release.sh`.

---

## P2 — Orta

### P2-1 — Auth verify-device metot netleştirme

- **Dosyalar:** `api_endpoints.dart` (39–40), `auth_remote_datasource.dart`, kılavuz §9 Auth tablosu  
- **Plan:** Üretim/canlı probe ile GET/POST kesinleştir; tek implementasyon; yorum çelişkisini kaldır.  
- **Test:** Auth unit veya acceptance auth adımı.

### P2-2 — Live SSE kopması UX

- **Dosyalar:** `live_broadcast_room_page.dart` (2727+), `live_room_providers.dart`, psychic modülündeki banner pattern  
- **Plan:** Tutarlı banner + retry; sonsuz loading guard.  
- **Test:** Widget test veya mevcut live provider test.

### P2-3 — PK heart score hata geri bildirimi

- **Dosya:** `live_broadcast_room_page.dart` 2005–2031  
- **Plan:** `catch` → rate-limited snackbar veya debug-only log; skor burst korunur.  
- **Test:** Mock datasource fail testi (yeni küçük unit).

### P2-4 — PK polling yalnızca SSE down iken

- **Dosya:** `live_video_pk_provider.dart` 86–96, PK SSE abonelik noktaları  
- **Plan:** `video_stream_sse` veya `pkMatchStream` bağlıyken polling durdur; SSE disconnect’te başlat.  
- **Test:** `live_pk_*` testleri.

### P2-5 — Voice oda deprecated admin sheets

- **Dosyalar:** `voice_room_hub_settings.dart`, `voice_room_sheets.dart` → `showVoiceRoomManagementPanel`  
- **Plan:** `grep showVoiceRoomHubSettings\|voice_room_hub_settings` — referansları tek panele yönlendir; deprecated export kaldır (kanıt sonrası).  
- **Test:** `test/features/voice_hub/`.

### P2-6 — Wallet payment path migration

- **Dosyalar:** `profile_remote_datasource.dart` (`_deprecatedPaymentApiPath`), `wallet/*`, kılavuz §9 cüzdan  
- **Plan:** Tüm ödeme/talep çağrılarını wallet repository + güncel path; profile yalnızca UI delegasyon.  
- **Test:** Wallet/membership mock dio testleri.

### P2-7 — Gold / discovery limit API UX

- **Dosyalar:** `social_discovery_providers.dart`, action POST body kılavuz §9, `membership_controller`  
- **Plan:** 403/limit response → upgrade sheet; client-side limit bypass yok.  
- **Test:** Discovery action mock 403.

### P2-8 — Chat REST / DM SSE tek kaynak

- **Dosyalar:** `messages_repository_impl.dart`, `api_endpoints.dart` 74–81, 1011–1013, inbox providers  
- **Plan:** Liste kaynağı `/api/messages`; conversations legacy yalnızca feature flag yoksa kaldır; SSE lease inbox’ta.  
- **Test:** messages test klasörü.

### P2-9 — Tanış konum + duplicate like

- **Dosyalar:** `tanis_kaynas_page.dart`, `tanis_discover_tab.dart`, discovery remote  
- **Plan:** İzin reddi empty state; action debounce/idempotency (UI lock 500ms + sunucu hata).  
- **Test:** Provider unit + manuel swipe.

### P2-10 — Fortune jeton akışı checklist

- **Dosyalar:** `fortune_repository_impl.dart`, router fortune routes  
- **Plan:** Ekran listesi + her biri loading/empty/error; jeton düşümü hata mesajı.  
- **Test:** Mevcut fortune testleri genişlet.

### P2-11 — Profile block / privacy

- **Dosyalar:** `profile_repository`, moderation block API  
- **Plan:** Block sonrası profil/DM gizleme; deep link guard.  
- **Test:** Moderation mock.

### P2-12 — Push OneSignal + FCM

- **Dosyalar:** push bootstrap, `psychic_flow_push_test` (örnek)  
- **Plan:** Tek giriş noktası routing tablosu; duplicate notification azaltma (doc + kod minimal).  
- **Test:** Push payload unit testleri genişlet.

### P2-13 — Live room performans `select`

- **Dosya:** `live_broadcast_room_page.dart` 2622+  
- **Plan:** P1-2 C ile birlikte veya önce hızlı select patch.  
- **Test:** Analyze + live widget test.

### P2-14 — Gift idempotency

- **Dosyalar:** `gift_repository.dart`, live gift send path  
- **Plan:** İstek body kılavuz alanları; isteğe bağlı client `requestId` (sunucu destekliyorsa — önce grep canlifal envanter).  
- **Test:** `live_pk_gift_stabilize_test.dart`.

### P2-15 — Admin UI 403 standardı

- **Dosyalar:** `admin/*`, `meAdminCapabilities`  
- **Plan:** Yetkisiz route → redirect; API 403 snackbar.  
- **Test:** Router test veya widget.

---

### P2-16 — PK sayacı saniyede bir tüm ekranı rebuild ediyor *(2026-09-18 eklendi)*

- **Dosya:** `mobile/lib/features/pk/presentation/providers/pk_session_notifier.dart:93–114`
- **Problem:** `Timer.periodic(1 sn)` her tetiklenmede `state = state.copyWith(...)` yazıyor → `pkSessionProvider`'ı izleyen **her** widget saniyede bir rebuild oluyor. PK ekranı zaten video + skor + chat + hediye animasyonu taşıyor; 60 FPS hedefiyle doğrudan çelişiyor. *(P2-13 "live room select daraltma" ile aynı amaç, farklı dosya — birlikte planlanabilir.)*
- **Plan:** Kalan süre dar kapsamlı ayrı provider/`ValueNotifier`'a taşınır; yalnızca sayaç widget'ı dinler. Alternatif: `select` ile daraltma.
- **Test:** Rebuild sayacı ile widget testi.
- **Risk:** Düşük. **Sıra notu:** P1-1'in `keepAlive` maddesiyle aynı dosyaya dokunuyor — ondan sonra yapılmalı.

### P2-17 — Sesli oda rütbesi kısıtsız `nickname`'den türetiliyor *(2026-09-18 eklendi)*

- **Dosyalar:** `voice_moderation_target_color.dart:22`, `voice_seat_avatar_frame.dart:31`
- **Problem:** Rütbe kullanıcı adının ilk karakterinden türetiliyor (`voice_staff_rank.dart:15-22`: `%`→admin, `~`→founder, `@`→op). Bu iki call-site kısıtsız `nickname ?? name` geçiyor; `displayName` backend'de karakter kısıtı taşımıyor (`users.ts:36`) → kullanıcı `%Mesut` yazıp **admin rozeti** gösterebilir.
- **⚠ Ölçülü değerlendirme — yetki yükseltmesi DEĞİL:** Gerçek yetki kararı `voice_room_permissions.dart:146` üzerinden güvenli `user.username` ile veriliyor ve `username` backend'de `^[a-zA-Z0-9_]+$` ile korunuyor (`users.ts:43`). Etki yalnızca **rozet rengi ve koltuk çerçevesi** → sosyal mühendislik riski, yetki kaybı değil. Bu nedenle P2, P0 değil.
- **Plan:** Bu iki call-site de `user.username` kullanmalı; `nickname`/`displayName` hiçbir rol türetmesine girmemeli.
- **Test:** `displayName = '%Sahte'` → rütbe `none`.
- **Risk:** Çok düşük.

### P2-18 — Sayfalama yok: `page: 1` beş yerde sabit *(2026-09-18 eklendi)*

- **Dosyalar:** `social_discovery_providers.dart:23`, `social_providers.dart:44,59`, `user_social_posts_notifier.dart:18,30`
- **Problem:** Keşif akışı, sosyal akış ve kullanıcı gönderileri **yalnızca 1. sayfayı** çekiyor; sonsuz kaydırma fiilen yok.
- **⚠ Kullanım araştırması uyarısı:** `core/pagination/` yalnızca `paged_result.dart` içeriyor — **hazır altyapı yok.** Bu madde "mevcut altyapıyı bağla" değil, **tasarım gerektiren** bir iş. Talimat §13 gereği paralel yeni bir sayfalama katmanı yazılmamalı; önce `paged_result.dart` incelenip yetersizse genişletilmeli.
- **Ek karmaşıklık:** Bu provider'lar `autoDispose FutureProvider` — sayfalama eklenince liste state'i ve scroll pozisyonu yönetimi de değişir.
- **Plan:** **Ekran ekran**, tek seferde değil: önce keşif → sonra sosyal akış → sonra profil gönderileri.
- **Risk:** **Orta–yüksek** (üç ekranı birden etkiler). En geç yapılacak P2 maddesi.

### P2-19 — Hata durumu kapsamı çok düşük *(2026-09-18 eklendi)*

- **Ölçüm:** `ErrorState`/`ErrorView` yalnızca **6 dosyada**; `EmptyState` 39, loading göstergesi 192 — toplam **138 sayfaya** karşılık.
- **Problem:** Loading yaygın, error neredeyse yok → hata durumunda kullanıcı boş ekran veya sonsuz loading görüyor (talimat §25'in en zayıf ayağı). P2-2 (Live SSE UX) bu sorunun tek bir ekrandaki görünümü; bu madde genel çözüm.
- **Plan:** Retry aksiyonlu ortak `ErrorState` bileşeni; **önce yalnızca kritik akışlara** bağlanır (auth, live, PK, wallet, chat, discovery). Tüm ekranlara yayılım ayrı iş kalemi.
- **Risk:** Düşük, artımlı.

---

## P3 — UI/UX

### P3-1 — Feed → social provider migrasyonu

- `feed_providers.dart` deprecated referans temizliği → yalnızca `socialNotifierProvider`.

### P3-2 — Auth gateway deprecated

- `auth_flow_app.dart` → `AuthGatewayHost` tek giriş.

### P3-3 — Sosyal responsive / kenar boşluğu

- `social_page.dart`, `cds_responsive.dart` — 360dp layout doğrulama; gerekirse maxWidth.

### P3-4 — CDS homojenlik sprint (fonksiyon dokunmadan)

- Öncelik: inbox, fortune hub, wallet, tanış — token’lar `canlifal_design_system.dart`.

### P3-5 — Dark mode kritik ekranlar

- live, PK, chat, psychic — kontrast pass.

### P3-6 — Animation FPS budget live/PK

- `CanlifalMotion`/reduce motion; PK sırasında ağır Lottie kısıt.

### P3-7 — `use_build_context_synchronously` (30)

- Batch fix: mounted guard; en kritik: live, auth, payment sheets.

> **Kısmi ilerleme — 2026-09-18: 5/30 kapandı.** `fortune_reading_coordinator.dart` (en yoğun dosya, 5 ihlal) → **0 ihlal**. Toplam analyze **657 → 652**, tam olarak −5.
>
> **Toplu düzeltme bilinçli olarak yapılmadı** (planın P4-02 uyarısı): her ihlal ayrı bir `await` sınırı ve farklı bir erken-dönüş kararı gerektiriyor. Beş nokta tek tek incelendi; hepsi gerçekti — `showFortuneImageCaptureSheet`, `consumeGrant`, `_resolveBirthDate` (×2) ve `_resolveBirthTime` await'lerinden sonra `context` korumasız kullanılıyordu. Dosyanın mevcut deseni (`if (!context.mounted) return null;`) izlendi.
>
> **Test notu:** Bu sınıf için birim testi eklenmedi — "await sırasında widget dispose oldu" senaryosunu kurmak tüm fal akışını sürmeyi gerektiriyor. Regresyon koruması **analyzer'ın kendisi**: kural CI'daki `API + Flutter analyze` işinde koşuyor ve yeni ihlal eklenirse sayı artar.
>
> **Kalan 25 ihlal, dosya bazında:** `voice_room_leave_flow` (3), `open_voice_chat_room_flow` (3), `shorts_explore_page` (3), `membership_page` (2), `admin_user_command_actions` (2), ve 13 dosyada 1'er.
>
> Doğrulama: `flutter analyze` **652** · `flutter test` **1423 geçti / 0 başarısız** (değişmedi).

### P3-8 — Notification SSE lifecycle

- Hub + app lifecycle; badge stale fix.

---

### P3-9 — `yacht` hediyesi yanlış animasyon gösteriyor, varlık eksik *(2026-09-18 eklendi)*

- **Dosya:** `mobile/lib/features/gifts/data/gift_catalog_maps.dart:13,19,24` (`'lottie:yacht'`, `'yacht'`, `'yat'`)
- **Problem:** Üç anahtar da `assets/gifts/lottie/star.json`'a işaret ediyor. `mobile/assets/gifts/lottie/` içeriği doğrulandı: **`car, crown, heart, rose, star`** — `yacht.json` **yok**. Katalogdaki en pahalı hediyelerden biri yıldız animasyonu oynatıyor; kullanıcı ödediği hediyeyi ayırt edemiyor.
- **Plan:** (a) `yacht.json` varlığı eklenir — **bu adım dışarıdan tasarım varlığı bekler**; (b) varlık gelene kadar ayırt edilebilir başka bir animasyona yönlendirilir; (c) **kalıcı koruma:** katalogdaki her anahtarın var olan bir asset'e çözüldüğünü doğrulayan birim testi — bu tür sessiz eksikleri bir daha oluşmadan yakalar.
- **Risk:** Yok (varlık + test ekleme).

### P3-10 — Feed'de sahte kullanıcılar empty-state yerine geçiyor *(2026-09-18 eklendi)*

- **Dosya:** `mobile/lib/features/feed/presentation/widgets/feed_story_strip.dart:23–30`
- **Problem:** Gerçek gönderi yokken var olmayan `'Özge'`, `'Ela'`, `'Arda'` kullanıcıları `i.pravatar.cc` avatarlarıyla gösteriliyor. Hem talimatın yasakladığı **sahte veri** hem **eksik empty-state** — boşluk uydurma insanlarla doldurulmuş. *(P4-5 "social fake post deprecated metod" farklı bir konu; bu madde hikâye şeridi fallback'i.)*
- **Plan:** Fallback kaldırılır, gerçek empty-state konur (metin + hikâye oluşturma çağrısı).
- **Test:** `posts: []` ile widget testi — sahte isimler render edilmemeli.
- **Risk:** Çok düşük.

> **Durum: UYGULANDI — 2026-09-18.** Sahte kullanıcı fallback'i kaldırıldı; gerçek hikâye yokken şerit hiç çizilmiyor (`SizedBox.shrink()`).
>
> **Plandan sapma — bilinçli:** Plan "metin + hikâye oluşturma çağrısı" diyordu, ancak widget'ta hiç tıklama işleyicisi yok (tamamen dekoratif). CTA eklemek yeni işlevsellik icat etmek olurdu ve navigasyon bağlantısı gerektirirdi — bu ayrı bir ürün kararıdır. 100px yüksekliğindeki yatay bir şeritte metin placeholder'ı da yersiz durur; şeridi gizlemek standart desendir (hikâye yoksa satır gösterilmez).
>
> Test: `mobile/test/features/feed/feed_story_strip_empty_test.dart` (4 vaka). **Testin gerçekten koruduğu doğrulandı:** sahte fallback geçici geri konduğunda 1. ve 2. vaka düşüyor (`Found 1 widget with type "ListView"`, beklenen: hiç).
>
> Doğrulama: `flutter analyze` **657** (taban çizgisiyle aynı) · `flutter test` **1423 geçti / 0 başarısız** (taban 1419 + 4).

### P3-11 — Üretim kodunda üçüncü parti placeholder görselleri *(2026-09-18 eklendi)*

- **Dosyalar:** `fortune_type_images.dart:5`, `section_visual_catalog.dart:3`, `discover_live_carousel.dart:124,132,140,412`, `live_background_picker_sheet.dart:25,29,33`
- **Problem:** `images.unsplash.com` (27 kullanım) ve `i.pravatar.cc` sabit URL olarak gömülü. SLA'sız üçüncü parti CDN; erişim kesilirse fal kategorileri, ana sayfa görselleri ve canlı arka planları boş kalır.
- **Plan:** Kendi CDN/asset'lerine taşınır veya backend'den yönetilir. **Ürün/tasarım kararı gerektirir** (hangi görseller kullanılacak) — saf mühendislik değil.
- **Risk:** Düşük.

---

## P4 — Cleanup

### P4-1 — Analyze info sprint 1

- `dart fix --apply` (unused_import) + manual unnecessary_underscores (test dosyaları ayrı PR).

### P4-2 — Deprecated API sabitleri

- `api_endpoints.dart` — kullanılmayan `@Deprecated` kaldır (grep zorunlu).

### P4-3 — Voice music / Agora exception dead code

- `room_music_remote_datasource.dart`, `voice_trtc_exception.dart` alias temizliği.

### P4-4 — Cookie jar mobil yolu

- Dokümante optional; davranış değiştirmeden yorum/netleştirme.

### P4-5 — Social fake post deprecated metod silme

- `social_providers.dart` 157+ — referans yoksa kaldır.

### P4-6 — Profile timeline deprecated widget

- `user_posts_timeline.dart` → sliver migrasyon tamamlama.

---

## Dokümantasyon ve release (paralel)

| ID | İş | Dosya |
|----|-----|--------|
| DOC-1 | Sürüm banner senkron | `docs/DOCS_RELEASE_INDEX.md`, `AGENTS.md` üst satır → pubspec |
| DOC-2 | RELEASE READY bayrağı | Kullanıcı P0 PASS sonrası checklist |
| DOC-3 | Flutter pin | `.flutter-version` vs CI image — tek kaynak notu |

**Kullanıcı (release):** keystore, Play Console — `docs/KALAN_ISLER.md`, `bash scripts/kullanici-sonraki.sh`

---

## Aşama 3 uygulama sırası (onaylı fix plan)

Agent bir sonraki turda **sırayla**:

1. P0-1 → kullanıcı sonucu beklenir veya FAIL hotfix  
2. **P0-2 / P0-3 → yalnızca backend kapsam kararı verildiyse** (bkz. P0-2 uyarısı; verilmediyse ayrı iş kalemine devredilir)  
3. P1-1 → önerilen alt sıra: **(c) catch ayrımı → (a) `paused` kapsamı → (b) TTL türetme → `keepAlive`** · ardından P1-2 → P1-4  
4. P2-* (önce 6, 8, 3, 4 — kullanıcı görünür bug’lar), sonra 16 → 17 → 19 → **18 en son** (orta–yüksek riskli)  
5. P3/P4 batch’ler — P3-9/P3-10 erken alınabilir (risk yok/çok düşük)  
6. **`RELEASE_AUDIT.md`** (madde 33) — tüm düzeltmeler bittikten sonra

Her commit sonrası:

```bash
cd mobile && dart analyze && flutter test
# mobile/ veya workflow değiştiyse: git push origin main && bash scripts/wait-apk-build.sh 900
```

**Taban çizgisi (2026-09-18, Flutter 3.44.8 = CI pin'i ile ölçüldü):**

| Kontrol | Değer |
|---|---|
| `flutter analyze` | **657 bulgu, 0 error** (261 warning, 396 info · `lib/` 592, `test/` 65) |
| `flutter test` | **1.408 geçti, 2 atlandı, 0 başarısız** (4:20) |

Bir adım bu taban çizgisini bozarsa **geri alınır** ve daha güvenli çözüm üretilir (talimat §32). Not: mevcut doğrulama komutu `dart analyze` kullanıyor; CI pin'i `flutter analyze` ile ölçüm yapıldığında sayılar farklı çıkar (660 info vs 657/0-error) — kıyaslama aynı araçla yapılmalı.

**Uygulamadan önce cevaplanması gereken sorular:**

1. **Backend kapsamı** — P0-2/P0-3 bu planın kapsamına alınsın mı? (Genel kural 4 şu an backend'i dışlıyor; en ciddi kusur backend'de.)
2. **P1-1 ürün kararı** — aktif PK'da 90+ sn doğrulama yoksa ve çift yayın kimliği elde yoksa PK ekranı kalmalı mı, düşmeli mi? (Mevcut test "düşmeli" diyor; kullanıcı şikâyeti "kalmalı" diyor.)
3. **P0-3 ölçümü** — üretimde hediye isteklerinin ne kadarı `receiverId` yerine `receiverName` ile geliyor?
4. **P2-14/P0-2 idempotency kapsamı** — yalnızca backend mi (geriye dönük uyumlu, yarım fayda), yoksa istemciler de anahtar gönderecek mi?
5. **P3-9 varlık** — `yacht.json` tasarım varlığı sağlanabilir mi, yoksa geçici yönlendirme mi?

---

## Onay kaydı

- **Aşama 1:** `AUDIT_REPORT.md` — tamamlandı  
- **Aşama 2:** `FIX_PLAN.md` — kullanıcı onayı **2026-09-18**  
- **Aşama 3:** Kod düzeltmeleri — bir sonraki agent turunda P0/P1 ile başlanacak

---

*Bu planda henüz kod değişikliği uygulanmamıştır.*
