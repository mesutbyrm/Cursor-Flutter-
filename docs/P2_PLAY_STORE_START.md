# P2 — Play Store / Stage 8 (backlog)


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** · P0 + P1 cihaz testleri sonrası · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Play Store production access — P0/P1 cihaz kabulünden **sonra**.

---

## Önkoşullar

- [ ] Psychic **P0 PASS**
- [ ] Platform **P1 PASS**
- [ ] Release-signed AAB (`bash scripts/build-play-aab.sh` — CI secret gerekli)
- [ ] Play Console closed test

---

## Referans

| Dosya | İçerik |
|-------|--------|
| [`PLAY_STORE_PRODUCTION_ACCESS.md`](PLAY_STORE_PRODUCTION_ACCESS.md) | Tam paket (imza, AAB, checklist) |
| [`STAGE8_FINAL_ACCEPTANCE_REPORT.md`](STAGE8_FINAL_ACCEPTANCE_REPORT.md) | Stage 8 kabul |
| [`PRODUCTION_ACCESS_REQUIRED.md`](PRODUCTION_ACCESS_REQUIRED.md) | Bloker özeti |

---

## Durum (2026-09-07)

- Mobil release gate CI: **FINAL PASS** (`1.0.371+409`)
- Play Store paketi: tarihsel doc — **release keystore + güncel AAB** gerekir
- Agent: doc/backlog; Console işlemleri **kullanıcı**

Takip: `bash scripts/release-remaining-status.sh`
