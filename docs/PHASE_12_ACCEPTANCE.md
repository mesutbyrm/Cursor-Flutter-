# FAZ 12 — E2E kabul (25 senaryo)

**Otomatik kapı:** `bash scripts/faz12-automated-gates.sh`  
**Manuel:** Android gerçek cihaz — aşağıdaki senaryolar

---

## Otomatik (agent)

| # | Kapı | Komut |
|---|------|--------|
| A1 | FAZ0 verify | `faz0-verify.sh` |
| A2 | Faz testleri | `run-phase-tests.sh` |
| A3 | FAZ11 security | `faz11-security-scan.sh` |
| A4 | Release gate API | `run-release-gate.sh` (secrets) |

---

## Manuel (cihaz) — özet

| # | Senaryo | Faz |
|---|---------|-----|
| 1 | Giriş / çıkış | 1 |
| 2 | Profil düzenleme | 2 |
| 3 | Feed scroll + like | 3 |
| 4 | Fal SSE akışı | 4 |
| 5 | Canlı yayın giriş/çıkış | 5 |
| 6 | Sesli oda + `!istek` müzik | 6 |
| 7 | Hediye gönder | 7 |
| 8 | Shorts feed | 8 |
| 9 | DM mesaj | 9 |
| 10 | Bildirim listesi | 9 |
| 11–25 | `docs/ACCEPTANCE_TESTS.md` genişletilmiş |

**FAZ0 bloker:** Senaryo 6 için jeton ≥10 gerekli.

---

## Kapanış

Tüm otomatik + manuel PASS → `docs/FINAL_CANLIFAL_FLUTTER_REPORT.md`
