# Kullanıcı cihaz test günlüğü


> **Sürüm:** `1.0.391+429` · **RELEASE READY: NO** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Psychic P0 ve P1 sonuçlarını buraya kaydedin. Agent'a tek satır bildirim yeterlidir.

---

## Nasıl kaydedilir

```bash
bash scripts/basla.sh                            # canlı durum + yol haritası
bash scripts/record-user-test-result.sh p0 PASS
bash scripts/record-user-test-result.sh p0 FAIL "T+5s video dondu"
bash scripts/on-p0-pass.sh                    # PASS + P1 checklist
bash scripts/on-p0-fail.sh "T+5s donma"       # FAIL + hotfix yönlendirme
bash scripts/on-p1-pass.sh                    # P1 PASS
```

Agent'a kopyala-yapıştır: **`Psychic P0 PASS`** veya **`Psychic P0 FAIL`**

---

## Test hesapları (P0)

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Doğrula: `bash scripts/p0-go.sh`

---

## Akış (P0 → P1 → RELEASE)

| Adım | Komut |
|------|--------|
| P0 GO | `bash scripts/p0-go.sh` |
| P0 test | `bash scripts/user-test-start.sh p0` |
| P0 PASS | `bash scripts/on-p0-pass.sh` |
| P1 GO | `bash scripts/p1-go.sh` |
| P1 PASS | `bash scripts/on-p1-pass.sh` |
| RELEASE adayı | `bash scripts/on-release-ready-candidate.sh` |
| P2 GO | `bash scripts/p2-go.sh` |

---

## Kayıtlar

_(Henüz kayıt yok — P0 cihaz testi sonrası doldurulacak.)_
