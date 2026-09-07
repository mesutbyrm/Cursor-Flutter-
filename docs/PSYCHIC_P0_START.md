# Psychic P0 — hızlı başlangıç (2 telefon)


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Tek manuel bloker: **Canlı falcı TRTC** — T+5 saniyede A/V donması olmamalı.

---

## 1. Jeton (zorunlu)

Probe (2026-09-07): danışan `cursor.test.*` hesabında **jeton≈100000** — P0-j kapandı.

```bash
bash scripts/psychic-p0-prereqs.sh       # jeton + APK + giriş doğrulama
```

Jeton 0 ise: `bash scripts/admin-jeton-cheatsheet.sh` (≥500 önerilir)

Detay: [`M5_M7_JETON_BLOCKER.md`](M5_M7_JETON_BLOCKER.md)

---

## 1.5 Falcı hesabı (Psychic P0)

Host (`cursor.host.*`) **onaylı falcı** — aynı şifre ile falcı telefonunda giriş.

```bash
bash scripts/probe-psychic-teller.sh           # listede mi?
bash scripts/open-approved-teller.sh           # aç/doğrula
bash scripts/list-production-tellers.sh        # 9 falcı (host dahil)
```

Detay: [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md)

---

## 2. APK (2 telefon)

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

> **Falcı:** `Cursor Host Test` — tellerId `cmtrllf67004omm08mnp8psba` · [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md).

---

## 3. P0 checklist

```bash
bash scripts/psychic-p0-checklist.sh
```

Kritik satır: **T+5s** — eski bug burada donuyordu.

---

## 4. Sonuç bildirimi

```bash
bash scripts/record-user-test-result.sh p0 PASS    # veya FAIL "not"
```

Agent'a tek satır:

- **`Psychic P0 PASS`** → P1 checklist
- **`Psychic P0 FAIL`** → hotfix + logcat / ekran kaydı

---

## 5. P0 sonrası (P1)

```bash
bash scripts/print-live-psychics-e2e-checklist.sh   # Tam falcı E2E
```

Genel platform: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) P1

---

## Tek komut özeti

```bash
bash scripts/user-test-start.sh       # menü (önerilen)
bash scripts/psychic-p0-all.sh        # P0 akışı
bash scripts/record-user-test-result.sh p0 PASS
```

Tam rehber: [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md)
