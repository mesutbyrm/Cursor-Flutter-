# Kullanıcı cihaz test günlüğü


> **Sürüm:** `1.0.371+409` · **RELEASE READY: NO** · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

Psychic P0 ve P1 sonuçlarını buraya kaydedin. Agent'a tek satır bildirim yeterlidir.

---

## Nasıl kaydedilir

```bash
bash scripts/record-user-test-result.sh p0 PASS
bash scripts/record-user-test-result.sh p0 FAIL "T+5s video dondu"
bash scripts/on-p0-pass.sh                    # PASS + P1 checklist
bash scripts/on-p0-fail.sh "T+5s donma"       # FAIL + hotfix yönlendirme
bash scripts/on-p1-pass.sh                    # P1 PASS
```

Agent'a kopyala-yapıştır: **`Psychic P0 PASS`** veya **`Psychic P0 FAIL`**

---

## Kayıtlar

_(Henüz kayıt yok — P0 cihaz testi sonrası doldurulacak.)_
