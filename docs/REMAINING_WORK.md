# Kalan işler — canlı takip listesi



> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son güncelleme:** 2026-09-07 — sürüm `1.0.371+409` · **Cihaz testi SONRA** · **Agent P2 prep devam**  
**Agent paralel:** `bash scripts/devam-et.sh` · **Cihaz sonra:** `bash scripts/cihaz-sonra.sh`  
**Tek komut:** `bash scripts/kalan-isler.sh` · P0: `p0-go.sh` · P1: `p1-go.sh` · P2 prep: `p2-prep-go.sh` · P2 yükleme: `p2-go.sh`  
**Master:** `docs/PHASE_MASTER_TRACKER.md` | **Release:** `docs/RELEASE_CHECKLIST.md` | **Psychic P0:** `docs/LIVE_PSYCHICS_REMAINING.md` | **Tüm MD indeks:** [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

---

## Durum özeti

| Alan | Durum | Not |
|------|--------|-----|
| Faz 1 SSE SoT | `[x]` | main — Socket.IO kapalı, presence replace |
| Faz 2 Psychic TRTC | `[x]` kod | Token-only join; **P0 cihaz testi OPEN** |
| Release gate CI | `[x]` | apk-latest + metadata PASS |
| Release 502 fix | `[x]` | `814f8758` |
| docs/LATEST_APK_BUILD | `[x]` | Run `34146919509` |
| **Jeton (danışan)** | `[x]` | ~98k (2026-09-07) |
| **M7 API / M5 API smoke** | `[x]` | song-request 200 + smoke PASS=6 |
| **m5-preflight** | `[x]` | Jeton + voice seat API OK |
| **Manuel testler** | `[ ]` | **Kullanıcı sonra** — P0 → P1 → M5 cihaz |
| FAZ 0–13 otomatik | `[x]` | Geçmiş faz testleri CI'da |
| APK `1.0.371+409` | `[x]` | apk-latest güncel |

---

## Tek manuel bloker (release için)

| # | İş | Referans |
|---|-----|----------|
| **P0-j** | Danışan jeton (admin) | ✅ ~98k (2026-09-07) |
| **P0** | Psychic TRTC 2-cihaz (T+5s donma yok) | ⏳ **OPEN** — `bash scripts/p0-go.sh` |
| P1 | Voice / gift / PK / müzik 2-cihaz | ⏸ P0 sonrası — `bash scripts/p1-go.sh` |
| P2 | Stage 8 / Play Store | ▶ agent prep · yükleme P0+P1 sonrası | `p2-prep-go.sh` · `p2-go.sh` |

**Otomatik işler tamam** — kalan yalnızca cihaz kabul testleri.

---

## Faz otomatik testleri (2026-08-18)

| Faz | Sonuç |
|-----|--------|
| FAZ1 core/network | PASS |
| FAZ2 profile | PASS |
| FAZ3 social | PASS |
| FAZ4 fortune | PASS |
| FAZ5 live | PASS |
| FAZ6 voice_hub (93) | PASS |
| FAZ7 gifts | PASS |
| FAZ8 shorts | PASS (3 test dosyası) |
| FAZ9 messages | PASS |
| FAZ0 MCP | PASS |

`bash scripts/run-phase-tests.sh`

---

## P0 — Müzik (FAZ 6)

M1–M12 `[x]` | M5 API smoke `[x]` | M5 cihaz `[ ]` | M7 API `[x]` | M7 cihaz `[ ]`

---

## FAZ 0 audit

A1–A8 `[x]` | A9 M5 cihaz `[ ]` (API smoke geçti)

---

## FAZ 1–13 dosyaları

| Faz | Doc |
|-----|-----|
| 1 | `FAZ1_STATUS.md`, `FAZ1_API_ERROR_ENVELOPE.md` |
| 2 | `FAZ2_PROFILE_PARITY.md` |
| 3 | `FAZ3_SOCIAL_PARITY.md` |
| 4–13 | `FAZ4_FORTUNE_PARITY.md` … `FAZ13_RELEASE_STATUS.md` |

---

## Oturum günlüğü (2026-09-07 — KALAN_ISLER.md + menü sadeleştirme)

- docs/KALAN_ISLER.md — statik kalan işler özeti
- user-test-start menü: kalan-isler/p0-go öncelik, numaralar sadeleştirildi
- print-kalan-isler.sh · USER_TEST_QUICK_REF güncellendi

## Oturum günlüğü (2026-09-07 — rehber senkron kalan-isler)

- PSYCHIC_P0_START, faz0-handoff, user-handoff, on-p1-pass
- PHASE_MASTER, KULLANICI_TEST, TEST_ACCOUNTS → kalan-isler / p0-go
- psychic-p0-all: PASS/FAIL komutları + kalan-isler yönlendirme

## Oturum günlüğü (2026-09-07 — device-test-log + giriş noktaları)

- `device-test-log-lib.sh` — P0/P1 PASS log satırı kontrolü
- on-release-ready-candidate: doğru log grep; agent-closure → kalan-isler
- README/AGENTS/print-build-status: kalan-isler birincil giriş

## Oturum günlüğü (2026-09-07 — kalan işler yol haritası)

- `kalan-isler.sh` — P0→P1→P2 tablo + release-remaining-status
- `p2-go.sh` — Play Store backlog GO ekranı
- p1-go: yanlış P0 PASS grep düzeltmesi (log satırı `## … **PASS**`)
- user-test-start: `kalan` · `p2-go` kısayolları

## Oturum günlüğü (2026-09-07 — P1 GO + AGENTS senkron)

- `p1-go.sh` — P0 PASS sonrası platform test GO ekranı
- p1-platform-checklist: cursor.test + cursor.host hesapları
- AGENTS.md, P1_DEVICE_START, USER_DEVICE_TEST_LOG akış tablosu

## Oturum günlüğü (2026-09-07 — P0 GO ekranı)

- `p0-go.sh` — canlı durum + hesaplar + başlat komutları
- user-test-start: `go` / `p0-go` kısayolu
- APK_DOWNLOAD, FAZ13, PLAY_STORE B-host güncellendi

## Oturum günlüğü (2026-09-07 — indeks + P2 Play Store senkron)

- README, DOCS_RELEASE_INDEX, PLAY_STORE_PRODUCTION_ACCESS — host falcı ✅
- USER_DEVICE_TEST_LOG hesap tablosu; on-release-ready-candidate checklist
- run-non-device-release-prep: open-approved-teller idempotent adım

## Oturum günlüğü (2026-09-07 — P0 betik + kullanıcı rehberi senkron)

- psychic-p0-checklist / psychic-p0-all / user-handoff — host = falcı
- TEST_ACCOUNTS, KULLANICI_TEST_KILAVUZU, LIVE_PSYCHICS_REMAINING, RELEASE_CHECKLIST
- user-test-start: `ready` → validate-pre-device-handoff

## Oturum günlüğü (2026-09-07 — host onaylı falcı + doc senkron)

- `open-approved-teller.sh` — host başvuru/onay; probe ✅ (9 falcı)
- Gate 3 teller resolve pipe fix → **PASS** (session + TRTC)
- Doc senkron: AGENT_CLOSED, USER_TEST_QUICK_REF, PSYCHIC_P0_START, RELEASE_GATE_CLOSURE
- `release-remaining-status.sh` — probe grep `listede` düzeltmesi

## Oturum günlüğü (2026-09-07 — non-device prep)

- `run-non-device-release-prep.sh` — API + gate + unit + P2 tek komut
- `run-api-automation-summary.sh` — release gate özeti eklendi
- RELEASE_GATE_CLOSURE Gate 3 SKIP notu

## Oturum günlüğü (2026-09-07 — cihaz dışı devam)

- Kullanıcı: cihaz testleri sonraya bırakıldı
- `api-release-gate.sh` Gate 3: pool[0] fallback kaldırıldı; host → SKIP (FAIL değil); TRTC token
- `run-psychic-unit-tests.sh`, `p2-play-store-prep.sh`
- AGENT_CLOSED: cihaz dışı hazırlık notu

## Oturum günlüğü (2026-09-07 — test günlüğü şablonu)

- `USER_DEVICE_TEST_LOG.md` oluşturuldu (P0/P1 kayıt şablonu)
- DOCS_RELEASE_INDEX + USER_TEST_QUICK_REF senkron

## Oturum günlüğü (2026-09-07 — quick ref senkron)

- USER_TEST_QUICK_REF + AGENT_CLOSED: print-p0-live-status adım 0
- release-remaining-status: canlı durum satırı

## Oturum günlüğü (2026-09-07 — P0 canlı durum)

- `print-p0-live-status.sh` — jeton + falcı tek ekran
- `user-test-start.sh live` — kısayol
- PSYCHIC_P0_START: falcı tablosu onaylı hesap olarak düzeltildi

## Oturum günlüğü (2026-09-07 — P0 falcı rehberi)

- psychic-p0-checklist: falcı = onaylı hesap (host değil)
- psychic-p0-all: falcı uyarısında otomatik list-production-tellers
- validate-pre-device-handoff: tekrarlayan falcı probe kaldırıldı
- API raporları yenilendi (M5/M7 probe)

## Oturum günlüğü (2026-09-07 — host token bootstrap)

- `bootstrap_host_token`: username `cursorhost1786235468` önce; USER_USERNAME yalnız HOST_EMAIL==USER_EMAIL
- `psychic-p0-prereqs`: `/api/me` e-posta doğrulaması (danışan token uyarısı)
- `faz0-status` / `faz0-next`: user-test-start yönlendirmesi
- Doğrulama: psychic-p0-prereqs + release-remaining-status host girişi ✅

## Oturum günlüğü (2026-09-07 — doc giriş noktaları)

- APK_DOWNLOAD, M5_DEVICE, TEST_ACCOUNTS → user-test-start / quick ref
- release-remaining-status: print-user-test-quick-ref satırı
- API music/voice raporları validate yenilemesi

## Oturum günlüğü (2026-09-07 — KULLANICI_TEST senkron)

- KULLANICI_TEST_KILAVUZU → user-test-start / on-p0-pass akışı
- print-user-test-quick-ref.sh

## Oturum günlüğü (2026-09-07 — hızlı referans)

- `USER_TEST_QUICK_REF.md` — 1 sayfa cihaz test özeti
- RELEASE_CHECKLIST / user-handoff / user-test-start senkron

## Oturum günlüğü (2026-09-07 — RELEASE adayı akışı)

- `on-release-ready-candidate.sh` — P0+P1 sonrası RELEASE READY kontrol listesi
- README, P2, RELEASE_GATE_CLOSURE, user-test-start güncellendi

## Oturum günlüğü (2026-09-07 — upload day + agent prep status)

- `print-play-upload-day-checklist.sh` — P0+P1 PASS sonrası Play yükleme adımları
- `print-agent-prep-status.sh` — agent prep betik envanteri + AAB readiness
- `user-handoff` + `on-release-ready-candidate` → upload day yönlendirme

## Oturum günlüğü (2026-09-07 — GO indeks + target audience)

- `print-go-commands.sh` — tüm GO/prep komut indeksi
- `print-play-target-audience-summary.sh` — Play Console audience + ads
- `p2-play-store-prep.sh` → `p2-prep-go` alias; devam-et birincil referans sync

## Oturum günlüğü (2026-09-07 — release blockers + devam-et sync)

- `print-release-blockers.sh` — RELEASE READY engelleri tek ekran
- USER_TEST_QUICK_REF / RELEASE_USER / kalan-isler → devam-et birincil giriş

## Oturum günlüğü (2026-09-07 — paralel mod giriş noktaları)

- `devam-et.sh` — kalan-isler-agent alias
- `print-paralel-mod.sh` — tek ekran agent/cihaz özeti
- `p1-prep-go.sh` — P1 checklist GO (P0 sonucu sonra kayıt)

## Oturum günlüğü (2026-09-07 — p2-prep-go + status sync)

- `p2-prep-go.sh` — agent P2 GO ekranı (cihaz beklemeden)
- `release-remaining-status` P2 → paralel agent prep
- `p2-go.sh` → CI AAB adımları · `validate-pre-device-handoff` paralel yönlendirme

## Oturum günlüğü (2026-09-07 — Play Console print paketi)

- `print-play-content-rating-summary.sh` · `print-play-store-listing.sh`
- `print-ci-aab-steps.sh` · `print-play-console-prep-index.sh`
- `user-handoff.sh` → paralel mod · `p2-prep-all` genişletildi

## Oturum günlüğü (2026-09-07 — P2 prep ALL + paralel mod)

- `p2-prep-all.sh` — Play Store + app access + FGS + data safety + keystore
- `print-play-data-safety-summary.sh` — Play Console Data safety rehberi
- `kalan-isler.sh` / `run-non-device-release-prep.sh` — paralel P2 yol haritası

## Oturum günlüğü (2026-09-07 — agent paralel mod özeti)

- `AGENT_CLOSED.md` — paralel mod (cihaz sonra, agent P1/P2 devam)
- `print-full-user-checklist.sh` — P0+P1 birleşik yazdır
- release-remaining-status → user-test-start öncelik

## Oturum günlüğü (2026-09-07 — pre-device doğrulama)

- `validate-pre-device-handoff.sh` — API + jeton + falcı tek doğrulama
- print-build-status, after-admin-jeton, release-status güncellendi

## Oturum günlüğü (2026-09-07 — PASS/FAIL akış betikleri)

- `on-p0-pass.sh` / `on-p0-fail.sh` / `on-p1-pass.sh` — test sonrası otomatik adımlar
- `faz0-handoff.sh` → user-test-start yönlendirmesi
- ACCEPTANCE_TESTS gate 3 falcı notu

## Oturum günlüğü (2026-09-07 — agent kapanış rehberi)

- `RELEASE_USER_NEXT_STEPS.md` — kullanıcı tek sayfa (paralel mod)
- `list-production-tellers.sh` — 8 üretim falcısı tablosu
- `agent-closure-status.sh` → release-remaining-status

## Oturum günlüğü (2026-09-07 — test sonuç kaydı)

- `record-user-test-result.sh` — P0/P1 PASS/FAIL → `USER_DEVICE_TEST_LOG.md`
- AGENTS/README/APK_DOWNLOAD/release-status güncellendi

## Oturum günlüğü (2026-09-07 — kullanıcı test girişi)

- `user-test-start.sh` — P0/P1 tek menü girişi
- Birincil doc senkron: jeton ✅, falcı uyarısı (PHASE_MASTER, FAZ13, TEST_ACCOUNTS, KULLANICI_TEST)
- `run-api-automation-summary.sh` — falcı probe eklendi

## Oturum günlüğü (2026-09-07 — falcı probe)

- `probe-psychic-teller.sh` — host falcı listesinde değil (8 falcı); örnek isimler
- `PSYCHIC_TELLER_STATUS.md` — cihaz testi falcı rehberi
- prereqs/checklist/handoff/release-status entegrasyonu

## Oturum günlüğü (2026-09-07 — API otomasyon + kalan işler)

- `run-api-automation-summary.sh` — M5/M7 otomatik özet (cihaz ayrı)
- `release-remaining-status.sh` — P1/P2 bölüm düzeltmesi, M5 PASS algılama
- `P2_PLAY_STORE_START.md` — Play Store backlog rehberi
- `PSYCHIC_P0_START.md` — jeton OK + onaylı falcı notu
- M5/M7 raporları yenilendi (song-request 200, smoke 6/2/0)

## Oturum günlüğü (2026-09-07 — jeton eklendi)

- Kullanıcı admin jeton → **jeton≈98k** (probe OK)
- P0-j ✅ kapandı; P0 cihaz testi sırada
- API gate 3: respond=403 (host/teller API — cihaz akışı ayrı doğrulanacak)

## Oturum günlüğü (2026-09-07 devam 9 — kalanlar)

- `release-remaining-status.sh` — P0-j/P0/P1/P2 canlı özet
- `p1-platform-checklist.sh` + `docs/P1_DEVICE_START.md` (P0 sonrası)
- Jeton hâlâ 0 — P0-j kullanıcı/admin bloker

## Oturum günlüğü (2026-09-07 devam 8 — agent kapanış)

- `scripts/psychic-p0-all.sh` — jeton + prereqs + checklist tek akış
- RELEASE_GATE_CLOSURE: P0-j jeton satırı; FAZ13, AGENTS, APK_DOWNLOAD güncellendi
- **Agent işi kapandı** — kullanıcı: admin jeton → `psychic-p0-all.sh` → PASS/FAIL

## Oturum günlüğü (2026-09-07 devam 7)

- `docs/PSYCHIC_P0_START.md` — jeton → APK → P0 tek sayfa rehber
- `after-admin-jeton.sh`: varsayılan min 100 jeton, Psychic P0 yönlendirme
- `user-handoff.sh`, DOCS_RELEASE_INDEX, REMAINING_WORK jeton satırı

## Oturum günlüğü (2026-09-07 devam 6)

- Jeton probe: danışan jeton=0 — Psychic P0 bloker (credits≠jeton)
- M5_M7_JETON_BLOCKER, LIVE_PSYCHICS, RELEASE_CHECKLIST güncellendi
- psychic-p0-checklist: otomatik jeton uyarısı + hesaplar
- admin-jeton-cheatsheet: Psychic P0, ≥500 jeton önerisi

## Oturum günlüğü (2026-09-07 devam 5)

- `psychic-p0-prereqs.sh`: APK HTTP, giriş, jeton uyarısı
- API gate 3: falcı secret yoksa host fallback (`defaults.sh`)
- KULLANICI_TEST: jeton ~5000 → gerçek probe (jeton 0 uyarısı)
- `faz0-handoff.sh` → `user-handoff.sh` yönlendirmesi

## Oturum günlüğü (2026-09-07 devam 4)

- README: eski `1.0.93+95` → `1.0.371+409`; kullanıcı test bölümü
- `print-live-psychics-e2e-checklist.sh`: P0 önceliği + sürüm
- API acceptance gate 3–8: 3 PASS, 0 FAIL (local preflight)
- `docs/ACCEPTANCE_TEST_REPORT.md` güncellendi

## Oturum günlüğü (2026-09-07 devam 3)

- `scripts/user-handoff.sh` — kullanıcı devir özeti (Psychic P0, hesaplar, APK)
- `print-build-status.sh` → user-handoff yönlendirmesi
- Kök parity banner: **RELEASE READY: NO** hizalandı
- `RELEASE_GATE_CLOSURE`: bana_ozel P2 bloker değil (CI pass)
- `site/canlifal-jeton-web/*` banner

## Oturum günlüğü (2026-09-07 devam 2)

- **213 MD banner:** `docs/**`, kök parity, `mobile/docs/*` — commit `8db37eea`
- **Birincil MD tamamlama:** FAZ13, GITHUB_*, PHASE_MASTER, TEST_ACCOUNTS, mobile/README, backend-docs/*, LATEST_APK_BUILD banner
- **CI:** `build-apk.yml` LATEST_APK_BUILD şablonuna banner eklendi
- Agent kalan: **yok** — yalnızca Psychic P0 cihaz

## Oturum günlüğü (2026-08-20 devam 6)

- Env setup: `ACCEPTANCE_ADMIN_*` kullanıcı tarafından atlandı; mevcut jeton≈9580 yeterli
- `faz0-verify` PASS=5; `m5-device-prep` + API smoke PASS=6

## Oturum günlüğü (2026-08-20 devam 5)

- `m5-api-smoke.sh` — Test 1–4 API: song-request 200, kuyruk, presence, SSE (PASS=6)
- M5 cihaz Test 5–10 hâlâ Android'de manuel

## Oturum günlüğü (2026-08-20 devam 4)

- Jeton=10000 yüklendi; M7 slug→500 düzeltmesi (`probe-music-room.sh` tam cuid + audio body)
- M7 song-request **HTTP 200**; m5-preflight **geçti**; jeton=9920

## Oturum günlüğü (2026-08-20 devam 3)

- `faz0-sequential.sh` — 7 otomatik kapı PASS; jeton+M5 bloke
- `FAZ0_SEQUENTIAL_PROGRESS.md` canlı rapor

## Oturum günlüğü (2026-08-20 devam 2)

- `cursor/voice-seat-api-probe-0710` → `main` merge
- `faz0-verify.sh`: AUTOMATED_PASS — PASS=4 WARN=1 (jeton) FAIL=0
- `faz0-handoff.sh`: jetonsuz API komutları eklendi

## Oturum günlüğü (2026-08-20 devam)

- `api-voice-seat-phase.sh` — presence join, seats list, take/leave, voice join, SSE (jeton yok)
- `run-voice-seat-acceptance.sh` + `m5-preflight.sh` / `faz0-verify.sh` entegrasyonu
- `M5_M7_JETON_BLOCKER.md` sürüm senkronu (`1.0.291+327`)

## Oturum günlüğü (2026-08-20)

- Sesli oda P0: `canSpeak` seatIndex, koltuk kaybı mic, USER_MUTED, auto-seat — `1.0.289+325`
- Sesli oda P1: `canManageUsers` mod popup, dinleyici self-seat, SSE giriş banner — `1.0.290+326`
- Sesli oda P2: `VoiceRoomUserActions.openUserSheet`, VIP `formatTierEntranceLine` — `1.0.291+327`
- M5 checklist: Test 7–10 (koltuk-ses, mod popup, self-seat, giriş şeridi)
- Faz testleri 15/15 PASS

## Oturum günlüğü (2026-08-19 devam 24)

- `faz0-handoff.sh` — agent→kullanıcı devir teslim betiği (jeton + M5 checklist)
- `faz0-status.sh` admin URL + kod otomasyonu tamam mesajı
- FAZ12 otomatik 4/4 doğrulandı

## Oturum günlüğü (2026-08-19 devam 23)

- Push `/home` ve `/index` → `/feed` testleri (4 PASS)
- PK REST davet parse: `invited` durumu testi
- `admin-jeton-cheatsheet.sh` admin URL düzeltmesi

## Oturum günlüğü (2026-08-19 devam 22)

- PK parse testi: `pkBattleId` + ayrı `inviteId` → effectiveId
- `wait-for-jeton.sh` admin panel URL hatırlatması
- Faz testleri yenilendi (15 PASS)

## Oturum günlüğü (2026-08-19 devam 21)

- PK bildirim metin yedeklemesi testleri (PK/düello → voice-room veya /live) — 10 PASS
- faz0-verify yenilendi: AUTOMATED_PASS; jeton=0

## Oturum günlüğü (2026-08-19 devam 20)

- Push navigation testleri: `/` → `/feed`, PK push → voice-room (3 PASS)
- Jeton=0 bloker devam; otomatik kapılar geçer durumda

## Oturum günlüğü (2026-08-19 devam 19)

- PK bildirim yönlendirme testleri: canlı yayın path + targetId yok → `/live` (8 PASS)
- Jeton hâlâ 0 — M5/M7/A9 manuel bloker

## Oturum günlüğü (2026-08-19 devam 18)

- Canlı PK davet listesi hata: `ApiException.userMessage` (live_pk_invite_page)

## Oturum günlüğü (2026-08-19 devam 17)

- Oda keşif provider + PK geçmişi: `ApiException.userMessage` (ham exception yok)
- FAZ1 userMessage kapsamı voice_hub discover/history genişletildi

## Oturum günlüğü (2026-08-19 devam 16)

- Müzik arama sheet + oda moderasyon (kick/ban/mute): `ApiException.userMessage`
- `pkChallengerRoomLabelFromRooms` saf fonksiyon + 2 test (9 PASS toplam)
- `faz0-status.sh` apk-latest release adı gösterir

## Oturum günlüğü (2026-08-19 devam 15)

- `pickPkInviteTargetRoom` saf fonksiyon + aktif oda önceliği testleri (7 PASS)
- PK dialog hata: `ApiException.userMessage` (ham exception yok)
- `LATEST_APK_BUILD.md` 1.0.285+321 ile senkron; `print-build-status` apk-latest adı

## Oturum günlüğü (2026-08-19 devam 14)

- PK `opponentVoiceRoomId` eşleşmesi için birim test eklendi (`pk_opponent_room_filter_test.dart`)
- faz0-verify yenilendi: AUTOMATED_PASS; jeton=0 bloker devam
- APK CI: run 32298394670 başarılı; 32299026600 devam ediyor

## Oturum günlüğü (2026-08-19 devam 13)

- Otomatik doğrulama yenilendi: faz0-verify AUTOMATED_PASS, 15/15 faz testi, FAZ12 4/4, FAZ11 PASS
- Jeton hâlâ 0 — M5/M7/A9 manuel bloker devam
- `voice_room_session_utils.dart` yinelenen import temizlendi; `m5-device-prep.sh` PK test hatırlatması

## Oturum günlüğü (2026-08-19 devam 12)

- **1.0.285+321:** PK bildirimi `/` fix, PK davet donması, oda geçişi presence leave
- **1.0.284+320:** Sesli oda müzik isteği ANR (`deferVoiceMusicSubmit`)

## Oturum günlüğü (2026-08-19 devam 11)

- **1.0.283+319:** LiveGiftPanel + PremiumGiftPanel jeton hata UX (sessiz catch kaldırıldı)

## Oturum günlüğü (2026-08-19 devam 10)

- **1.0.282+318:** Canlı hediye + oyun lobisi + fal jeton UX

## Oturum günlüğü (2026-08-19 devam 9)

- **1.0.281+317:** Hediye gönderimi jeton diyaloğu + FAZ0_STATUS güncelleme

## Oturum günlüğü (2026-08-19 devam 8)

- **1.0.280+316:** RTC/Basic state error → `showJetonAwareError`; FAZ0/M5 doc sync

## Oturum günlüğü (2026-08-19 devam 7)

- **1.0.279+315:** Sesli oda tüm `err` SnackBar → `showJetonAwareError`; üyelik jeton diyaloğu

## Oturum günlüğü (2026-08-19 devam 6)

- **1.0.278+314:** `showJetonAwareError` — !duyuru, RTC/basic şarkı, oyunlar

## Oturum günlüğü (2026-08-19 devam 5)

- **1.0.277+313:** Falcı profil + fal sheet jeton UX (`showInsufficientJetonDialog` / Görevler)

## Oturum günlüğü (2026-08-19 devam 4)

- **1.0.275+311:** Komut paneli Görevler butonu + `m5-device-prep.sh`
- **1.0.274+310:** Oda açma jeton diyaloğu + FAZ0 checklist

## Oturum günlüğü (2026-08-19 devam 3)

- **1.0.270+306:** Growth Hub tamamlanan görev ilerlemesi, mission rotaları, claim tap

## Oturum günlüğü (2026-08-19 devam 2)

- **1.0.269+305:** Daily missions `type`/`reward`/`earnedJeton` parse; `taskType` claim; Growth Hub jeton daily_login
- `daily_task_entity_test.dart` (FAZ2)

## Oturum günlüğü (2026-08-19 devam)

- `wait-for-jeton.sh` + `m5-ready.sh` — jeton eklenince otomatik M7/M5-preflight
- Jeton probe: daily-missions tamam, credits=107, jeton=0 (admin gerekli)
- FAZ12 otomatik 4/4 doğrulandı

## Oturum günlüğü (2026-08-18 devam)

- `PHASE_MASTER_TRACKER.md` + `run-phase-tests.sh` + `phase-progress.sh`
- FAZ3–13 parity/status belgeleri
- Social `getUserPosts` kılavuz ucu (`1.0.267+303`)
- Faz testleri: 12 PASS, 0 FAIL
