# Test hesapları — Flutter QA / acceptance

**Tarih:** 2026-08-18  
**Durum:** GitHub Secrets + Stage5 raporundan derlenmiştir. Üretim hesapları — yalnızca QA.

---

## GitHub Actions secrets (release gate)

Kaynak: `docs/ACCEPTANCE_TESTS.md`

| Secret | Rol | Varsayılan (secret yoksa) |
|--------|-----|---------------------------|
| `ACCEPTANCE_USER_EMAIL` | Normal kullanıcı (`TEST_USER`) | `cursor.test.1786235468@mailinator.com` |
| `ACCEPTANCE_USER_USERNAME` | Giriş adı | `cursorusr1786235468` |
| `ACCEPTANCE_USER_PASSWORD` | Şifre | `CursorTest!1786235468` |
| `ACCEPTANCE_HOST_EMAIL` | Canlı yayın host (`TEST_LIVE_HOST`) | `cursor.host.1786235468@mailinator.com` |
| `ACCEPTANCE_HOST_PASSWORD` | Host şifresi | `CursorTest!1786235468` |
| `ACCEPTANCE_ADMIN_EMAIL` | Admin (`TEST_ADMIN`) | — (secret zorunlu) |
| `ACCEPTANCE_ADMIN_PASSWORD` | Admin şifresi | — |
| `ACCEPTANCE_VIEWER_*` | İzleyici / hediye testi | Opsiyonel |
| `ACCEPTANCE_TELLER_*` | Falcı (`TEST_FORTUNE_TELLER`) | Opsiyonel |

Kurulum:

```bash
bash scripts/set-acceptance-secrets.sh
bash scripts/acceptance-preflight.sh
```

---

## Stage5 E2E (örnek kimlikler)

Kaynak: `docs/STAGE5_REAL_E2E_ACCEPTANCE_REPORT.md`

| Rol | E-posta | Kullanıcı ID (örnek) |
|-----|---------|----------------------|
| TEST_USER_A | cursor.test.1786235468@mailinator.com | cmsl2h8fe007fns08myytsk6b |
| TEST_USER_B | cursor.host.1786235468@mailinator.com | cmsl2h8tv007mns08gtxf0l8x |

---

## Sesli oda müzik testi (M5)

| Alan | Değer |
|------|--------|
| Oda | `cmoohrbr` |
| Komut | `!istek Sanatçı - Şarkı` |
| APK | `apk-latest` release |
| Hesap | `ACCEPTANCE_USER_*` veya oda sahibi hesabı (`TEST_ROOM_OWNER` — backend tanımlı değil) |

**Eksik:** Backend'in resmi `TEST_ROOM_OWNER` credential'ı yok; oda sahibi hesabı manuel veya admin panelden atanmalı.

---

## Yerel API (opsiyonel)

```bash
# api/.env + DATABASE_URL ile
API_BASE_URL=http://127.0.0.1:3000/api/v1
```

Emülatör: `10.0.2.2:3000`

---

## Backend'den istenen (A8 tam kapanış)

1. Sabit QA ortamı (`staging.canlifal.com`) + roller
2. `TEST_ROOM_OWNER` — `cmoohrbr` oda sahibi
3. Başlangıç jetonu grant API veya seed script
