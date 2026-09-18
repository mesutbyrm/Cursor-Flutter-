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

### P3-8 — Notification SSE lifecycle

- Hub + app lifecycle; badge stale fix.

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
2. P1-1 → P1-4  
3. P2-* (önce 6, 8, 3, 4 — kullanıcı görünür bug’lar)  
4. P3/P4 batch’ler  
5. **`RELEASE_AUDIT.md`** (madde 33) — tüm düzeltmeler bittikten sonra

Her commit sonrası:

```bash
cd mobile && dart analyze && flutter test
# mobile/ veya workflow değiştiyse: git push origin main && bash scripts/wait-apk-build.sh 900
```

---

## Onay kaydı

- **Aşama 1:** `AUDIT_REPORT.md` — tamamlandı  
- **Aşama 2:** `FIX_PLAN.md` — kullanıcı onayı **2026-09-18**  
- **Aşama 3:** Kod düzeltmeleri — bir sonraki agent turunda P0/P1 ile başlanacak

---

*Bu planda henüz kod değişikliği uygulanmamıştır.*
