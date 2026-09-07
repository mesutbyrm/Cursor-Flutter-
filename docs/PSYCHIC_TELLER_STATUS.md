# Psychic P0 — falcı hesabı durumu


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son probe:** 2026-09-07 · `bash scripts/probe-psychic-teller.sh`

---

## Özet

| Hesap | Falcı listesinde | Psychic P0 |
|-------|------------------|------------|
| `cursor.host.1786235468@mailinator.com` | ❌ Hayır | Canlı yayın host — seans kabul edilmeyebilir |
| `cursor.test.1786235468@mailinator.com` | — (danışan) | Jeton OK (~100k) |

**Üretim falcı sayısı:** 8

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

Tam liste (id): `bash scripts/list-production-tellers.sh`

---

## Ne yapmalısınız?

### Seçenek A — Mevcut onaylı falcı hesabı (önerilen)

Psychic P0'da **falcı telefonu** için admin panelde onaylı bir falcı hesabının e-posta/şifresini kullanın.

Repo secret (isteğe bağlı):

```bash
# GitHub → Settings → Secrets
ACCEPTANCE_TELLER_EMAIL=<onaylı falcı e-postası>
ACCEPTANCE_TELLER_PASSWORD=<şifre>
```

Doğrula:

```bash
bash scripts/probe-psychic-teller.sh
# ✅ Falcı listesinde — beklenen çıktı
```

### Seçenek B — Host hesabını falcı yap

Admin panel → falcı başvurusu / onay → `cursor.host.*` hesabını onaylı falcı listesine ekleyin.

---

## API gate 3 notu

Otomatik release gate madde 3 (`respond=403`) aynı kök nedenden etkilenir: host hesabı `/api/fortune-tellers` listesinde değil. **Cihaz testi** onaylı falcı ile yapıldığında bu otomasyon maddesi ayrı kalır; mobil akış doğru hesapla test edilir.

---

## Komutlar

```bash
bash scripts/probe-psychic-teller.sh      # falcı listesi kontrolü
bash scripts/psychic-p0-prereqs.sh        # jeton + giriş + falcı uyarısı
bash scripts/psychic-p0-all.sh            # tam P0 akışı
```

Detay: [`TEST_ACCOUNTS.md`](TEST_ACCOUNTS.md) · [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md)
