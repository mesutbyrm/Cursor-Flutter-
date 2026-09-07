# Dokümantasyon — release durumu indeksi

**Son güncelleme:** 2026-09-07  
**Sürüm:** `1.0.371+409`  
**Release gate:** **FINAL PASS** — [Run 34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509)  
**RELEASE READY:** `NO` — Psychic P0 cihaz testi bekleniyor

---

## Birincil (güncel — önce bunlara bakın)

| Dosya | Amaç |
|-------|------|
| [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) | Production checklist, P0/P1 maddeler |
| [`RELEASE_GATE_CLOSURE.md`](RELEASE_GATE_CLOSURE.md) | Otomatik kapı özeti |
| [`REMAINING_WORK.md`](REMAINING_WORK.md) | Agent vs kullanıcı kalan iş |
| [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md) | Psychic P0 freeze + E2E |
| [`LATEST_APK_BUILD.md`](LATEST_APK_BUILD.md) | Son CI derlemesi |
| [`FAZ13_RELEASE_STATUS.md`](FAZ13_RELEASE_STATUS.md) | Faz 13 release |
| [`GITHUB_ACTIONS_CI.md`](GITHUB_ACTIONS_CI.md) | CI/APK iş akışları |
| [`KULLANICI_TEST_KILAVUZU.md`](KULLANICI_TEST_KILAVUZU.md) | Basit kullanıcı test adımları |
| [`TEST_ACCOUNTS.md`](TEST_ACCOUNTS.md) | QA hesapları |
| [`../APK_DOWNLOAD.md`](../APK_DOWNLOAD.md) | İndirme linkleri |

## Script

```bash
bash scripts/print-build-status.sh      # Özet
bash scripts/psychic-p0-checklist.sh    # Psychic P0 tablosu
```

## Tarihsel raporlar (üst banner güncellendi)

Aşağıdaki dosyaların gövdesi eski oturumlara aittir; karar için **birincil** tabloya bakın.

| Dosya | Orijinal tarih |
|-------|----------------|
| [`FINAL_PRODUCTION_AUDIT.md`](FINAL_PRODUCTION_AUDIT.md) | 2026-08-21 |
| [`MASTER_ACCEPTANCE_REPORT.md`](MASTER_ACCEPTANCE_REPORT.md) | 2026-08-10 |
| [`STAGE8_FINAL_ACCEPTANCE_REPORT.md`](STAGE8_FINAL_ACCEPTANCE_REPORT.md) | 2026-08-09 |
| [`PRODUCTION_READINESS_REPORT.md`](PRODUCTION_READINESS_REPORT.md) | 2026-07-11 |
| [`FLUTTER_PRODUCTION_MASTER_STATUS.md`](FLUTTER_PRODUCTION_MASTER_STATUS.md) | 2026-08-09 |
| [`RELEASE_REPORT.md`](RELEASE_REPORT.md) | 2026-08-04 |
| [`PHASE_MASTER_TRACKER.md`](PHASE_MASTER_TRACKER.md) | Faz tablosu + tarihsel detay |
| [`PHASE_PLAN.md`](PHASE_PLAN.md) | Faz planı |
| [`M5_DEVICE_TEST_CHECKLIST.md`](M5_DEVICE_TEST_CHECKLIST.md) | Müzik M5 cihaz |
| [`M5_M7_JETON_BLOCKER.md`](M5_M7_JETON_BLOCKER.md) | Jeton |

## Mobil değişiklik özeti

[`../mobile/CHANGELOG.md`](../mobile/CHANGELOG.md) — **1.0.371+409** Faz 2 Psychic TRTC + Faz 1 SSE

---

_Agent oturumlarında yeni status dosyası eklenirse bu indekse satır ekleyin._
