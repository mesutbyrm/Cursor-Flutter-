# Release — kullanıcı sonraki adımlar


> **Güncel (2026-09-07):** **`1.0.371+409`** · **RELEASE READY: NO** · Cihaz sonucu **sonra** · Agent P2 prep **devam**

**İki hat:** Cihaz testi sonraya bırakıldı; agent Play Store / P1 checklist hazırlığına devam eder.

---

## Tek giriş

```bash
bash scripts/kalan-isler-agent.sh    # agent · şimdi (= devam-et)
bash scripts/devam-et.sh             # agent devam
bash scripts/print-paralel-mod.sh    # tek ekran özet
bash scripts/cihaz-sonra.sh            # cihaz · sonra
bash scripts/kalan-isler.sh            # durum tablosu
```

---

## Sıra

| # | İş | Durum | Komut |
|---|-----|--------|-------|
| A | **Agent P2 prep** | ▶ devam | `p2-prep-go.sh` · `p2-prep-all.sh` |
| A2 | Keystore / AAB CI | ⏳ secret sizde | `play-keystore-secrets-cheatsheet.sh` |
| 0 | Jeton (danışan) | ✅ ~98k | `psychic-p0-prereqs.sh` |
| 0b | Falcı hesabı | ✅ host onaylı | `probe-psychic-teller.sh` |
| 1 | **Psychic P0** | ⏸ sonuç sonra | `cihaz-sonra.sh` → `user-test-start.sh p0` |
| 2 | **P1 platform** | ⏸ sonuç sonra | `p1-prep-now.sh` (checklist şimdi) |
| 3 | M5 cihaz (müzik) | ⏸ | [`M5_DEVICE_TEST_CHECKLIST.md`](M5_DEVICE_TEST_CHECKLIST.md) |
| 4 | Play Store P2 | ▶ agent prep | [`PLAY_STORE_AGENT_CHECKLIST.md`](PLAY_STORE_AGENT_CHECKLIST.md) |

---

## Otomatik (agent — tamam)

| Test | Sonuç |
|------|--------|
| Release gate CI | ✅ FINAL PASS [34146919509](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509) |
| M5 API smoke | ✅ 6 geçti / 2 atlandı |
| M7 song-request | ✅ HTTP 200 |
| m5-preflight | ✅ |
| Flutter unit (1081) | ✅ CI |

Özet: `bash scripts/run-api-automation-summary.sh`

---

## APK

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

---

## Test hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı (Psychic P0) | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Üretim falcı listesi: `bash scripts/list-production-tellers.sh` (9 falcı)

---

## Sonuç bildirimi

Test bittikten sonra:

```bash
bash scripts/record-user-test-result.sh p0 PASS
bash scripts/on-p0-pass.sh                    # P0 PASS → P1 checklist
bash scripts/on-p1-pass.sh                    # P1 PASS → RELEASE adayı
bash scripts/on-p0-fail.sh "T+5s donma"       # P0 FAIL → hotfix
```

Agent'a tek satır: **`Psychic P0 PASS`** veya **`Psychic P0 FAIL`**

P0 PASS → P1 → **`P1 PASS`** → `bash scripts/on-release-ready-candidate.sh`

---

## Hızlı referans

[`USER_TEST_QUICK_REF.md`](USER_TEST_QUICK_REF.md) — tek sayfa özet

Canlı durum (jeton + falcı): `bash scripts/p0-go.sh`

## Agent ne zaman kod değiştirir?

Yalnızca **`Psychic P0 FAIL`** (hotfix) veya yeni özellik isteği. Paralel P1/P2 hazırlık **devam** (`bash scripts/devam-et.sh`).

Detay: [`REMAINING_WORK.md`](REMAINING_WORK.md) · [`AGENTS.md`](../AGENTS.md)
