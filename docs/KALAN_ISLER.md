# Kalan işler — özet (2026-09-07)


> **Sürüm:** `1.0.371+409` · **RELEASE READY: NO** · Canlı durum: `bash scripts/kalan-isler.sh`

Agent tarafı **tamam** (kod, CI, API, falcı onayı). Kalan yalnızca **cihaz testleri**.

---

## Yol haritası

| # | İş | Durum | Komut |
|---|-----|--------|--------|
| P0-j | Danışan jeton | ✅ ~98k | — |
| **P0** | Psychic TRTC, 2 telefon | ⏳ **OPEN** | `bash scripts/p0-go.sh` |
| P1 | Platform, 2 telefon | ⏸ P0 sonrası | `bash scripts/p1-go.sh` |
| P2 | Play Store / AAB | ⏸ P0+P1 sonrası | `bash scripts/p2-go.sh` |

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
bash scripts/basla.sh                # tek komut başlangıç (canlı durum)
bash scripts/kalan-isler.sh          # canlı durum + tablo
bash scripts/p0-go.sh                # P0 GO
bash scripts/user-test-start.sh p0   # checklist
bash scripts/on-p0-pass.sh           # P0 PASS
bash scripts/p1-go.sh                # P1 GO
bash scripts/on-p1-pass.sh           # P1 PASS
bash scripts/on-release-ready-candidate.sh
bash scripts/p2-go.sh
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
