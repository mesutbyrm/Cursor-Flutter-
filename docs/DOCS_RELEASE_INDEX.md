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
| [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md) | Psychic P0 freeze + E2E |
| [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md) | **2 telefon hızlı başlangıç (jeton → P0)** |
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
bash scripts/psychic-p0-all.sh            # Önkoşul + checklist (tek akış)
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
