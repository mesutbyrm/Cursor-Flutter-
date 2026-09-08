# P2 — Play Store / Stage 8 (backlog)


> **Güncel (2026-09-08):** **`1.0.391+429`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Play Store production access — cihaz P0/P1 **sonra** yüklenir; agent hazırlığı **şimdi**.

---

## Agent (şimdi — cihaz sonucu beklemeden)

```bash
bash scripts/devam-et.sh
bash scripts/p2-prep-go.sh
bash scripts/p2-prep-all.sh
bash scripts/play-aab-readiness.sh
bash scripts/play-store-checklist.sh
bash scripts/print-play-console-prep-index.sh
```

Özet: [`PLAY_STORE_AGENT_CHECKLIST.md`](PLAY_STORE_AGENT_CHECKLIST.md)

---

## Önkoşullar (yükleme günü)

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

P0 PASS → P1 PASS sonrası:

```bash
bash scripts/on-release-ready-candidate.sh
bash scripts/build-play-aab.sh   # keystore secret gerekir
```

Takip: `bash scripts/release-remaining-status.sh` · [`AGENT_CLOSED.md`](AGENT_CLOSED.md)
