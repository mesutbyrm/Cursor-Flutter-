# Psychic P0 — falcı hesabı durumu


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** (cihaz P0/P1 bekliyor) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son probe:** 2026-09-07 · `bash scripts/probe-psychic-teller.sh`

---

## Özet

| Hesap | Falcı listesinde | Psychic P0 |
|-------|------------------|------------|
| `cursor.host.1786235468@mailinator.com` | ✅ Evet (`Cursor Host Test`) | **Falcı telefonu** — aynı şifre |
| `cursor.test.1786235468@mailinator.com` | — (danışan) | Jeton OK (~100k) |

**tellerId:** `cmtrllf67004omm08mnp8psba` · **userId:** `cmsyoxo48006emo085hxfy9l7` · **status:** `approved`

**Üretim falcı sayısı:** 9 (host dahil)

| # | Görünen ad | Not |
|---|------------|-----|
| 1 | İlhamperisi | Üretim falcı |
| 2 | CanliFal | Üretim falcı |
| 3 | Deneme | Test |
| 4 | Test Falcı | Test |
| 5 | Ayhan Uçan | |
| 6 | Ayşe Kise | |
| 7 | Onur Kalafat | |
| 8 | DESTEK | |
| 9 | **Cursor Host Test** | Acceptance QA — Psychic P0 |

Tam liste (id): `bash scripts/list-production-tellers.sh`

---

## Otomatik açma / doğrulama

Host hesabını onaylı falcı yapmak veya durumu kontrol etmek:

```bash
bash scripts/open-approved-teller.sh   # başvuru + admin onayı (ACCEPTANCE_ADMIN_* varsa)
bash scripts/probe-psychic-teller.sh   # /fortune-tellers listesinde mi?
bash scripts/user-test-start.sh open-teller
```

Şifre: `docs/TEST_ACCOUNTS.md` → `CursorTest!1786235468`

---

## Cihaz testi (Psychic P0)

- **Danışan telefonu:** `cursor.test.1786235468@mailinator.com`
- **Falcı telefonu:** `cursor.host.1786235468@mailinator.com` (onaylı — ayrı admin falcı gerekmez)

```bash
bash scripts/user-test-start.sh p0
# PASS → bash scripts/on-p0-pass.sh
# FAIL → bash scripts/on-p0-fail.sh "kısa not"
```

---

## API gate 3

Madde 3 (`Canlı falcı görüntülü görüşme`) host falcı listesindeyken **PASS** (session + TRTC). Jeton yoksa SKIP; admin jeton secret yoksa madde 5 SKIP.

---

## Komutlar

```bash
bash scripts/probe-psychic-teller.sh      # falcı listesi kontrolü
bash scripts/open-approved-teller.sh      # onaylı falcı aç/doğrula
bash scripts/psychic-p0-prereqs.sh        # jeton + giriş + falcı uyarısı
bash scripts/psychic-p0-all.sh            # tam P0 akışı
```

Detay: [`TEST_ACCOUNTS.md`](TEST_ACCOUNTS.md) · [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md)
