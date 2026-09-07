# Dokümantasyon — release durumu indeksi

**Son güncelleme:** 2026-09-07  
**Sürüm:** `1.0.371+409`  
**Release gate:** **FINAL PASS** — [Run 34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509)  
**RELEASE READY:** `NO` — Psychic P0 cihaz testi bekleniyor

> Tüm `docs/**/*.md`, kök `*.md` parity raporları ve `mobile/docs/*.md` dosyalarına **2026-09-07** güncel durum banner'ı eklendi. Gövde metni tarihsel olabilir; karar için **birincil** tabloya bakın.

---

## Birincil (güncel — önce bunlara bakın)

| Dosya | Amaç |
|-------|------|
| [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) | Production checklist, P0/P1 maddeler |
| [`RELEASE_GATE_CLOSURE.md`](RELEASE_GATE_CLOSURE.md) | Otomatik kapı özeti |
| [`REMAINING_WORK.md`](REMAINING_WORK.md) | Agent vs kullanıcı kalan iş |
| [`KALAN_ISLER.md`](KALAN_ISLER.md) | Kalan işler statik özet (1 sayfa) |
| [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md) | Psychic P0 freeze + E2E |
| [`USER_TEST_QUICK_REF.md`](USER_TEST_QUICK_REF.md) | 1 sayfa cihaz test özeti |
| [`USER_DEVICE_TEST_LOG.md`](USER_DEVICE_TEST_LOG.md) | P0/P1 sonuç günlüğü |
| [`AGENT_CLOSED.md`](AGENT_CLOSED.md) | Agent paralel mod — özet durum |
| [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md) | Kullanıcı tek sayfa rehber (cihaz sonra + agent P2) |
| [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md) | **2 telefon hızlı başlangıç (jeton → P0)** |
| [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md) | Falcı probe — host onaylı (`Cursor Host Test`) |
| [`P1_DEVICE_START.md`](P1_DEVICE_START.md) | P0 sonrası genel platform 2-cihaz |
| [`P2_PLAY_STORE_START.md`](P2_PLAY_STORE_START.md) | Play Store / Stage 8 backlog (P0+P1 sonrası) |
| [`PLAY_STORE_AGENT_CHECKLIST.md`](PLAY_STORE_AGENT_CHECKLIST.md) | Play Store agent prep (şimdi) |
| [`PLAY_CONSOLE_APP_ACCESS.md`](PLAY_CONSOLE_APP_ACCESS.md) | Play Console App access metni |
| [`LATEST_APK_BUILD.md`](LATEST_APK_BUILD.md) | Son CI derlemesi |
| [`FAZ13_RELEASE_STATUS.md`](FAZ13_RELEASE_STATUS.md) | Faz 13 release |
| [`GITHUB_ACTIONS_CI.md`](GITHUB_ACTIONS_CI.md) | CI/APK iş akışları |
| [`KULLANICI_TEST_KILAVUZU.md`](KULLANICI_TEST_KILAVUZU.md) | Basit kullanıcı test adımları |
| [`TEST_ACCOUNTS.md`](TEST_ACCOUNTS.md) | QA hesapları |
| [`FAZ0_STATUS.md`](FAZ0_STATUS.md) | Faz 0 özet |
| [`PHASE_MASTER_TRACKER.md`](PHASE_MASTER_TRACKER.md) | Faz master tablo |
| [`../APK_DOWNLOAD.md`](../APK_DOWNLOAD.md) | İndirme linkleri |
| [`../AGENTS.md`](../AGENTS.md) | Agent handoff (Cloud) |

## Script

```bash
bash scripts/kalan-isler.sh                 # kalan işler + canlı durum
bash scripts/user-handoff.sh                # devir teslim (canlı jeton + falcı)
bash scripts/print-kalan-isler.sh           # statik 1 sayfa özet
bash scripts/user-test-start.sh             # cihaz testi tek giriş (P0/P1)
bash scripts/print-full-user-checklist.sh  # P0+P1 birleşik yazdır
bash scripts/print-user-test-quick-ref.sh    # 1 sayfa terminal özeti
bash scripts/print-p0-live-status.sh       # jeton + falcı tek ekran
bash scripts/validate-pre-device-handoff.sh  # cihaz öncesi API+jeton doğrulama
bash scripts/agent-closure-status.sh      # agent paralel mod + canlı durum
bash scripts/user-test-start.sh ready         # pre-device doğrulama (validate)
bash scripts/basla.sh                       # tek komut başlangıç
bash scripts/kalan-isler-agent.sh           # agent paralel (cihaz sonra)
bash scripts/cihaz-sonra.sh                   # cihaz testi sonraya
bash scripts/p2-prep-go.sh                    # P2 agent GO
bash scripts/p2-prep-all.sh                   # Play Store hazırlık (tam)
bash scripts/p2-prep-now.sh                   # Play Store özet
bash scripts/play-aab-readiness.sh            # AAB öncesi kontrol
bash scripts/play-store-checklist.sh          # Console checklist
bash scripts/print-play-foreground-service-declaration.sh  # FGS metni
bash scripts/print-play-data-safety-summary.sh  # Data safety özeti
bash scripts/print-play-content-rating-summary.sh  # IARC
bash scripts/print-play-store-listing.sh      # Store listing
bash scripts/print-ci-aab-steps.sh            # CI AAB
bash scripts/print-play-console-prep-index.sh # Prep indeks
bash scripts/devam-et.sh                    # agent devam
bash scripts/print-release-blockers.sh        # RELEASE READY engelleri
bash scripts/print-paralel-mod.sh           # paralel özet
bash scripts/p1-prep-go.sh                  # P1 checklist GO
bash scripts/kalan-isler.sh                 # kalan işler + yol haritası
bash scripts/p0-go.sh                       # P0 GO ekranı
bash scripts/p1-go.sh                       # P1 GO (P0 PASS sonrası)
bash scripts/p2-go.sh                       # P2 GO (P0+P1 sonrası)
bash scripts/open-approved-teller.sh        # host → onaylı falcı aç/doğrula
bash scripts/list-production-tellers.sh   # üretim falcı listesi (9)
bash scripts/on-p0-pass.sh                 # P0 PASS sonrası P1
bash scripts/on-p1-pass.sh                 # P1 PASS sonrası özet
bash scripts/on-release-ready-candidate.sh # P0+P1 sonrası RELEASE adayı
bash scripts/on-p0-fail.sh                 # P0 FAIL hotfix kaydı
bash scripts/record-user-test-result.sh p0 PASS  # sonuç kaydı
bash scripts/release-remaining-status.sh   # P0-j/P0/P1/P2 canlı özet
bash scripts/run-non-device-release-prep.sh  # cihaz dışı tek komut
bash scripts/run-api-automation-summary.sh # M5/M7 otomatik API özeti (cihaz ayrı)
bash scripts/run-psychic-unit-tests.sh     # Psychic Flutter unit
bash scripts/print-go-commands.sh             # GO / prep indeks
bash scripts/print-play-target-audience-summary.sh  # Target audience + ads
bash scripts/probe-psychic-teller.sh       # falcı listesi kontrolü (Psychic P0)
bash scripts/psychic-p0-all.sh            # Önkoşul + checklist (tek akış)
bash scripts/p1-platform-checklist.sh     # P1 (P0 PASS sonrası)
bash scripts/psychic-p0-prereqs.sh        # APK + giriş + jeton (P0 öncesi)
bash scripts/user-handoff.sh           # Kullanıcı devir özeti (Psychic P0)
bash scripts/print-build-status.sh      # Özet
bash scripts/psychic-p0-checklist.sh    # Psychic P0 tablosu
bash scripts/print-live-psychics-e2e-checklist.sh  # Tam E2E (P0 sonrası)
```

## Modül V2 raporları (banner güncel, gövde tarihsel)

| Dosya | Aşama |
|-------|--------|
| [`SOCIAL_V2.md`](SOCIAL_V2.md) | Sosyal |
| [`GAMES_V2.md`](GAMES_V2.md) | Oyunlar |
| [`GIFT_PK_MUSIC_V2.md`](GIFT_PK_MUSIC_V2.md) | Hediye/PK/Müzik |
| [`LIVE_VOICE_V2.md`](LIVE_VOICE_V2.md) | Canlı + sesli (Faz 1 SSE) |
| [`PROFILE_V2.md`](PROFILE_V2.md) | Profil |
| [`NOTIFICATIONS_MESSAGES_SETTINGS_V2.md`](NOTIFICATIONS_MESSAGES_SETTINGS_V2.md) | Gelen kutu |

## Faz parity / status (banner güncel)

`FAZ1_STATUS.md` … `FAZ12_E2E_STATUS.md`, `FAZ2_*_PARITY.md` … `FAZ9_*_PARITY.md`

## Stage / acceptance (banner güncel, gövde tarihsel)

`STAGE5_*`, `STAGE6_*`, `STAGE7_*`, `STAGE8_*`, `STAGE10_*`, `MASTER_ACCEPTANCE_REPORT.md`, `FINAL_*`, `P0_*`

## Mobil değişiklik özeti

| Dosya | Not |
|-------|-----|
| [`../mobile/CHANGELOG.md`](../mobile/CHANGELOG.md) | **1.0.371+409** sürüm geçmişi |
| [`../mobile/README.md`](../mobile/README.md) | Geliştirici giriş |
| [`../mobile/ARCHITECTURE.md`](../mobile/ARCHITECTURE.md) | Mimari |
| [`../backend-docs/README.md`](../backend-docs/README.md) | MCP/OpenAPI referans |

- **Faz 1:** SSE SoT, Socket.IO kapalı (`1.0.370+408`)
- **Faz 2:** Psychic TRTC 5 sn freeze kök nedeni (`1.0.371+409`)

---

_Agent oturumlarında yeni status dosyası eklenirse bu indekse satır ekleyin._
