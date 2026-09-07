# Psychic P0 — hızlı başlangıç (2 telefon)


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Tek manuel bloker: **Canlı falcı TRTC** — T+5 saniyede A/V donması olmamalı.

---

## 1. Jeton (zorunlu)

Probe (2026-09-07): danışan `cursor.test.*` hesabında **jeton=0** → seans oluşturulamaz.

```bash
bash scripts/admin-jeton-cheatsheet.sh   # Admin panel + user ID
# Admin: ≥500 jeton önerilir (min. deneme ≥100)
bash scripts/psychic-p0-prereqs.sh       # jeton OK olana kadar tekrar
```

Detay: [`M5_M7_JETON_BLOCKER.md`](M5_M7_JETON_BLOCKER.md)

---

## 2. APK (2 telefon)

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

---

## 3. P0 checklist

```bash
bash scripts/psychic-p0-checklist.sh
```

Kritik satır: **T+5s** — eski bug burada donuyordu.

---

## 4. Sonuç bildirimi

Bize yazın (tek satır yeter):

- **`Psychic P0 PASS`** → RELEASE READY adayı
- **`Psychic P0 FAIL`** → hangi adım + logcat / ekran kaydı

---

## 5. P0 sonrası (P1)

```bash
bash scripts/print-live-psychics-e2e-checklist.sh   # Tam falcı E2E
```

Genel platform: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) P1

---

## Tek komut özeti

```bash
bash scripts/user-handoff.sh
```

İlgili: [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md) · [`KULLANICI_TEST_KILAVUZU.md`](KULLANICI_TEST_KILAVUZU.md)
