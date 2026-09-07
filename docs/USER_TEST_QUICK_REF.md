# Cihaz testi — hızlı referans (1 sayfa)


> **Sürüm:** `1.0.371+409` · **RELEASE READY: NO** · Agent **kapalı**

## APK

https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

## Hesaplar

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Falcı | **Onaylı falcı** (host değil) | admin panel |

`bash scripts/list-production-tellers.sh`

## Komut sırası

```bash
bash scripts/user-test-start.sh              # menü
bash scripts/validate-pre-device-handoff.sh  # 1 · API doğrulama
bash scripts/user-test-start.sh p0           # 2 · Psychic P0 (2 telefon)
bash scripts/on-p0-pass.sh                 # 3 · PASS → P1
bash scripts/on-p1-pass.sh                 # 4 · P1 PASS
bash scripts/on-release-ready-candidate.sh   # 5 · RELEASE adayı
```

FAIL: `bash scripts/on-p0-fail.sh "T+5s donma"`

## Kritik (P0)

**T+5s** — video/audio donmamalı (eski bug buradaydı)

## Bildirim

`Psychic P0 PASS` → `P1 PASS` → agent RELEASE READY günceller

Detay: [`RELEASE_USER_NEXT_STEPS.md`](RELEASE_USER_NEXT_STEPS.md) · [`AGENT_CLOSED.md`](AGENT_CLOSED.md)
