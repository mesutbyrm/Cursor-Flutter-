# Release — kullanıcı sonraki adımlar (agent kapalı)


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Agent tarafı **tamamlandı**. Kalan iş yalnızca **cihaz kabul testleri** (siz).

---

## Tek giriş

```bash
bash scripts/user-test-start.sh
bash scripts/validate-pre-device-handoff.sh   # API + jeton + falcı (cihaz öncesi)
bash scripts/agent-closure-status.sh          # canlı durum özeti
```

---

## Sıra

| # | İş | Durum | Komut |
|---|-----|--------|-------|
| 0 | Jeton (danışan) | ✅ ~100k | `psychic-p0-prereqs.sh` |
| 0b | Falcı hesabı | ⚠️ host listede değil | `probe-psychic-teller.sh` · [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md) |
| 1 | **Psychic P0** | ⏳ OPEN | `psychic-p0-all.sh` — 2 telefon, T+5s donma yok |
| 2 | **P1 platform** | ⏸ P0 sonrası | `p1-platform-checklist.sh` |
| 3 | M5 cihaz (müzik) | ⏸ | [`M5_DEVICE_TEST_CHECKLIST.md`](M5_DEVICE_TEST_CHECKLIST.md) |
| 4 | Play Store P2 | ⏸ backlog | [`P2_PLAY_STORE_START.md`](P2_PLAY_STORE_START.md) |

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
| Host (canlı yayın) | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |
| **Falcı (Psychic P0)** | Admin onaylı falcı — listeden | [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md) |

Üretim falcı listesi: `bash scripts/list-production-tellers.sh`

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

P0 PASS → P1 → **`P1 PASS`** → RELEASE READY adayı.

---

## Agent ne zaman tekrar açılır?

Yalnızca **`Psychic P0 FAIL`** (hotfix) veya yeni özellik isteği.

Detay: [`REMAINING_WORK.md`](REMAINING_WORK.md) · [`AGENTS.md`](../AGENTS.md)
