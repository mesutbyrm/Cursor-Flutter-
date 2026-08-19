# Test hesapları — Flutter QA / acceptance

**Tarih:** 2026-08-19  
**APK:** `1.0.275+311` (`apk-latest`)  
**Jeton:** `bash scripts/admin-jeton-cheatsheet.sh` · **M5:** `bash scripts/m5-device-prep.sh`

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
| TEST_USER_A | cursor.test.1786235468@mailinator.com | cmsyoxjh80066mo08fo7nv5o6 |
| TEST_USER_B | cursor.host.1786235468@mailinator.com | (host — jeton=0, Ağu 2026) |

---

## Sesli oda müzik testi (M5)

| Alan | Değer |
|------|--------|
| Route anahtarı | `cmoohrbr` (kısmi cuid öneği) |
| Tam oda id (SSE) | `cmoohrbrx00a4nt08zlkdjyil` |
| Slug (API listesi) | `canlfal-` |
| Komut | `!istek Sanatçı - Şarkı` |
| APK | `1.0.275+311` veya üzeri (`apk-latest`) |
| Hesap | `ACCEPTANCE_USER_*` — **≥10 jeton** gerekli (credits≠jeton; test hesabı credits≈140+, jeton=0) |
| Oda sahibi (üretim) | `admin` (`cmokscu2y0000pnko11nctqw5`) |

Detay: `docs/VOICE_ROOM_KEY_RESOLUTION.md`

**Eksik:** `ACCEPTANCE_ADMIN_*` secret yoksa test jetonu otomatik eklenemez — `docs/M5_M7_JETON_BLOCKER.md`

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
