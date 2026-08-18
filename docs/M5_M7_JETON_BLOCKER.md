# M5 / M7 — Jeton engeli ve çözüm

**Durum:** Otomatik kapılar geçti; **M5 cihaz** ve **M7 song-request 200** jeton bekliyor.  
**APK:** `1.0.266+302` (`apk-latest`)  
**Test hesabı:** `cursor.test.1786235468@mailinator.com` — **jeton=0**

---

## Ne engelleniyor?

| Madde | Gereksinim | Şu an |
|-------|------------|--------|
| **M5** | Cihazda `!istek` → song-request **200** + müzik | Jeton yok → 400 |
| **M7** | Üretim `song-request` HTTP **200** JSON dump | Jeton yok → 400 |
| **m5-preflight** | Jeton ≥10 | FAIL (jeton=0) |

Üretimde `skipPayment` **yok sayılır** — her istek **10 jeton** gerektirir.

---

## Çözüm A — Admin panel (hızlı)

1. [canlifal.com](https://canlifal.com) admin paneline girin
2. Kullanıcı: `cursor.test.1786235468@mailinator.com` (veya `cursorusr1786235468`)
3. **≥50 jeton** ekleyin (M5 + M7 + yedek)
4. Doğrula ve M7 probe:

```bash
bash scripts/m5-preflight.sh   # jeton + API + unit
bash scripts/m7-on-jeton.sh    # song-request HTTP 200
```

5. Cihaz: `docs/M5_DEVICE_TEST_CHECKLIST.md`

---

## Çözüm B — GitHub Secrets (CI otomatik top-up)

Repo **Settings → Secrets and variables → Actions** altına ekleyin:

| Secret | Açıklama |
|--------|----------|
| `ACCEPTANCE_ADMIN_EMAIL` | Admin e-posta |
| `ACCEPTANCE_ADMIN_PASSWORD` | Admin şifre |

İsteğe bağlı: `ACCEPTANCE_ADMIN_USERNAME` (e-posta yerine kullanıcı adı ile giriş).

Kullanıcı/host secret'ları (varsayılan test hesapları):

```bash
bash scripts/set-acceptance-secrets.sh   # USER + HOST (admin hariç)
```

Admin secret'ları **manuel** eklenmelidir (`set-acceptance-secrets.sh` admin bilgisini bilmez).

CI'da `faz0-verify` / `m5-preflight` admin secret varsa `POST /api/admin/credits` ile otomatik top-up dener.

**CI notu:** Secret'lar var ama top-up başarısızsa admin şifresi veya hesap rolü güncellenmeli. Tanı: `JETON_TOPUP_DEBUG=1 bash scripts/debug-jeton-topup.sh` (secret gerekli).

---

## Doğrulama komutları

```bash
bash scripts/faz0-verify.sh      # Tüm otomatik kapılar + rapor
bash scripts/m5-preflight.sh     # M5 öncesi (jeton + API + unit)
bash scripts/run-music-acceptance.sh
```

Raporlar: `docs/FAZ0_VERIFY_REPORT.md`, `docs/M7_MUSIC_SSE_CAPTURE.md`

---

## M7 kapanış kriteri

1. `M7_MUSIC_SSE_CAPTURE.md` içinde song-request **HTTP 200** JSON
2. Aynı oturumda SSE `dj` / `QUEUE_UPDATED` veya `song_started`
3. `REMAINING_WORK.md` M7 → `[x]`

## FAZ 0 kapanış

M5 cihaz checklist **PASS** → A9 → FAZ 1 başlar (`docs/PHASE_PLAN.md`).
