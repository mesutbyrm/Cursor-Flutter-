# Cihaz testi — hızlı referans (1 sayfa)


> **Sürüm:** `1.0.391+429` · **RELEASE READY: NO** · Agent prep **✅ TAMAM** · Cihaz + keystore sizde

## APK

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

## Hesaplar

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Host = onaylı falcı (`Cursor Host Test`). Doğrula: `bash scripts/probe-psychic-teller.sh`

## Komut sırası

```bash
bash scripts/kullanici-sonraki.sh           # ★ kullanıcı kalan adımlar
bash scripts/agent-prep-tamam.sh            # agent prep OK?
bash scripts/print-release-blockers.sh      # RELEASE READY engelleri
bash scripts/cihaz-sonra.sh                 # cihaz (sonra)
bash scripts/basla.sh                       # canlı durum + devir teslim
bash scripts/kalan-isler.sh                 # durum tablosu
bash scripts/p0-go.sh                       # P0 GO
bash scripts/p1-prep-go.sh                  # P1 checklist GO
bash scripts/p2-prep-go.sh                  # Play Store GO
bash scripts/user-test-start.sh p0          # Psychic P0 (2 telefon)
bash scripts/on-p0-pass.sh                  # PASS → P1
bash scripts/on-p1-pass.sh                  # P1 PASS
bash scripts/on-release-ready-candidate.sh  # RELEASE adayı
```

FAIL: `bash scripts/on-p0-fail.sh "T+5s donma"`

P0 PASS sonrası: `bash scripts/p1-go.sh` → P1 checklist

Kayıt: `docs/USER_DEVICE_TEST_LOG.md` · `bash scripts/record-user-test-result.sh p0 PASS`

## Kritik (P0)

**T+5s** — video/audio donmamalı (eski bug buradaydı)

## Bildirim

`Psychic P0 PASS` → `P1 PASS` → agent RELEASE READY günceller

Detay: [`KALAN_ISLER.md`](KALAN_ISLER.md) · [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md) · [`AGENT_CLOSED.md`](AGENT_CLOSED.md)
