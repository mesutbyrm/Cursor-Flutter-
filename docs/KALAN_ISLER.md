# Kalan işler — özet (2026-09-07)


> **Sürüm:** `1.0.371+409` · **RELEASE READY: NO** · Canlı durum: `bash scripts/kalan-isler.sh`

Agent tarafı **tamam** (kod, CI, API, falcı onayı). **Cihaz testi sonuçları sonra** — agent **P1/P2 hazırlığına** devam eder.

---

## İki paralel hat

| Hat | Durum | Komut |
|-----|--------|--------|
| **Cihaz** (P0→P1) | ⏸ sonuç sonra | `bash scripts/cihaz-sonra.sh` |
| **Agent** (P1/P2 prep) | ▶ devam | `bash scripts/devam-et.sh` |

---

## Yol haritası

| # | İş | Durum | Komut |
|---|-----|--------|--------|
| P0-j | Danışan jeton | ✅ ~98k | — |
| **P0** | Psychic TRTC, 2 telefon | ⏸ **sonra** | `bash scripts/cihaz-sonra.sh` |
| P1 | Platform, 2 telefon | ⏸ sonuç sonra | `bash scripts/p1-prep-go.sh` |
| P2 | Play Store / AAB | ▶ agent prep | `bash scripts/p2-prep-go.sh` |

---

## Hesaplar

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | `cursor.host.1786235468@mailinator.com` | aynı |

APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

---

## Komutlar (sırayla)

```bash
bash scripts/devam-et.sh            # agent devam (= kalan-isler-agent)
bash scripts/print-release-blockers.sh      # RELEASE READY engelleri
bash scripts/print-paralel-mod.sh   # paralel mod tek ekran
bash scripts/cihaz-sonra.sh         # cihaz (sonra)
bash scripts/kalan-isler.sh         # durum tablosu
bash scripts/p1-prep-go.sh          # P1 checklist GO
bash scripts/p2-prep-go.sh          # P2 agent GO (özet)
bash scripts/p2-prep-all.sh         # Play Store hazırlık (tam)
bash scripts/p2-prep-now.sh         # Play Store özet
bash scripts/play-aab-readiness.sh  # AAB öncesi
bash scripts/play-store-checklist.sh # Console checklist
bash scripts/play-keystore-secrets-cheatsheet.sh  # GitHub keystore
bash scripts/print-play-console-app-access.sh   # App access metni
bash scripts/print-play-foreground-service-declaration.sh  # FGS metni
bash scripts/print-play-data-safety-summary.sh  # Data safety özeti
bash scripts/print-play-content-rating-summary.sh  # IARC özeti
bash scripts/print-play-store-listing.sh      # Store listing taslak
bash scripts/print-ci-aab-steps.sh            # GitHub Actions AAB
bash scripts/print-agent-prep-status.sh       # Agent prep envanter
bash scripts/print-go-commands.sh             # GO / prep indeks
bash scripts/print-play-upload-day-checklist.sh  # Yükleme günü (P0+P1 sonrası)
bash scripts/p1-prep-now.sh         # P1 checklist (ön)
bash scripts/basla.sh               # canlı durum
```

FAIL: `bash scripts/on-p0-fail.sh "T+5s donma"`

---

## Kritik (P0)

**T+5 saniye** — video/ses donmamalı.

---

## Agent bildirimi

- `Psychic P0 PASS` veya `Psychic P0 FAIL`
- Sonra `P1 PASS` veya `P1 FAIL`

Kayıt: `docs/USER_DEVICE_TEST_LOG.md`

Detay: [`REMAINING_WORK.md`](REMAINING_WORK.md) · [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md)
