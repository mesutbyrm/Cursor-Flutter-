# P1 — Genel platform cihaz testi (P0 sonrası)


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** · Önce [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md) **PASS** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

P0 (Psychic TRTC freeze) **PASS** olduktan sonra iki cihazla genel platform kabulü.

---

## Checklist

```bash
bash scripts/p1-platform-checklist.sh
```

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

- **`P1 PASS`** — RELEASE adayı (P0 + P1 birlikte)
- **`P1 FAIL`** — madde + ekran kaydı

Takip: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) · [`REMAINING_WORK.md`](REMAINING_WORK.md)
