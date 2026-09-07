# P1 — Genel platform cihaz testi (P0 sonrası)


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** · Önce [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md) **PASS** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

P0 (Psychic TRTC freeze) **PASS** olduktan sonra iki cihazla genel platform kabulü.

---

## Checklist

```bash
bash scripts/p1-go.sh
bash scripts/p1-platform-checklist.sh
bash scripts/print-full-user-checklist.sh   # P0+P1 birleşik yazdır
```

P0 PASS kaydı: `bash scripts/on-p0-pass.sh` (P1 checklist'i de açar)

| Alan | Beklenen |
|------|----------|
| Sesli oda | Join/leave/rejoin, koltuk senkron |
| Hediye | Jeton düşümü, SSE, sıralama |
| PK | Davet, kabul, skor |
| Müzik | Oda değişince eski şarkı durur |
| Mesaj / bildirim | Unread sayaç |
| Oturum | A logout → B login, cache karışmaz |

Müzik ayrıntı: [`M5_DEVICE_TEST_CHECKLIST.md`](M5_DEVICE_TEST_CHECKLIST.md)

---

## Sonuç

```bash
bash scripts/on-p1-pass.sh
```

- **`P1 PASS`** — RELEASE adayı (P0 + P1 birlikte)
- **`P1 FAIL`** — madde + ekran kaydı · `record-user-test-result.sh p1 FAIL`

Takip: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) · `bash scripts/on-release-ready-candidate.sh`
