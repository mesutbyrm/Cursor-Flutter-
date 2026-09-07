# M5 / M7 — Jeton engeli ve çözüm



> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Son güncelleme:** 2026-09-07 · APK `1.0.371+409`  
**Durum (probe 2026-09-07):** Test danışan **jeton=100000** — P0-j kapandı. **Psychic P0** cihaz testi sırada.

---

## Ne engelleniyor?

| Madde | Gereksinim | Şu an (2026-09-07) |
|-------|------------|---------------------------|
| **P0-j jeton** | Danışan jeton | ✅ **~99880+** (admin) |
| **M7 API** | song-request HTTP **200** | ✅ [`M7_MUSIC_SSE_CAPTURE.md`](M7_MUSIC_SSE_CAPTURE.md) |
| **M5 API smoke** | Test 1–4 + SSE | ✅ PASS=6 (`M5_API_SMOKE_REPORT.md`) |
| **m5-preflight** | Jeton + voice seat API | ✅ geçti |
| **M5 cihaz** | Test 1–10 Android | ⏳ kullanıcı (sonra) |
| **Psychic P0 cihaz** | T+5s TRTC | ⏳ kullanıcı (sonra) |
| **API gate 3** | Session accept + TRTC | ✅ PASS (host listede, 2026-09-07) |

Önkoşul kontrolü: `bash scripts/psychic-p0-prereqs.sh`

Üretimde `skipPayment` **yok sayılır** — her istek **10 jeton** gerektirir.

> **Not:** Test hesabında `credits=50` olabilir; müzik isteği **jeton** kullanır (`jetonBalance`), kredi değil.

> **Günlük görevler (`POST /api/daily-missions`):** yalnızca **credits** verir (jeton değil). Otomatik deneme Ağu 2026: tüm görevler `completed` + `earnedJeton` alanı dolu olsa bile `jetonBalance` 0 kalır; `credits` artar.
>
> **Diğer otomatik yollar (Ağu 2026):** `POST /api/daily-login` → zaten alındı; `POST /api/games/daily-spin` → credits; `POST /api/games/daily-reward` → credits (+5); `POST /api/jeton` `{"action":"daily_login"}` → zaten alındı; `POST /api/user/watch-ad` → credits. **Jeton kazanımı yok** — yalnızca admin top-up.
>
> Tanı: `bash scripts/probe-jeton-earn.sh`

---

## Çözüm A — Admin panel (hızlı)

```bash
bash scripts/admin-jeton-cheatsheet.sh   # user id + adımlar
```

1. [canlifal.com](https://canlifal.com) admin paneline girin
2. Kullanıcı: `cursor.test.1786235468@mailinator.com` (veya `cursorusr1786235468`)
3. **≥500 jeton** ekleyin (Psychic 10 dk seans + M5/M7 + yedek; minimum deneme için ≥100)
4. Doğrula:

```bash
bash scripts/psychic-p0-prereqs.sh         # jeton + giriş (Psychic P0 öncesi)
bash scripts/after-admin-jeton.sh          # jeton ekledikten hemen sonra (önerilen)
bash scripts/wait-for-jeton.sh 10 3600     # otomatik bekleme + M7 + m5-preflight
bash scripts/m5-preflight.sh               # jeton + API + unit
bash scripts/m7-on-jeton.sh                # yalnızca song-request HTTP 200
bash scripts/m5-ready.sh                   # FAZ12 kapıları + m5-preflight
```

5. Cihaz: `docs/M5_DEVICE_TEST_CHECKLIST.md`

---

## Çözüm B — GitHub Secrets (CI otomatik top-up)

Repo **Settings → Secrets and variables → Actions** altına ekleyin:

| Secret | Açıklama |
|--------|----------|
| `ACCEPTANCE_ADMIN_EMAIL` | Admin e-posta |
| `ACCEPTANCE_ADMIN_PASSWORD` | Admin şifre — **geçerli admin hesabı olmalı** |

> CI log (Ağu 2026): `admin login email failed` + `admin login username failed` → secret'ları güncelleyin veya manuel jeton ekleyin.

İsteğe bağlı: `ACCEPTANCE_ADMIN_USERNAME` (e-posta yerine kullanıcı adı ile giriş).

Kullanıcı/host secret'ları (varsayılan test hesapları):

```bash
bash scripts/set-acceptance-secrets.sh   # USER + HOST (admin hariç)
```

Admin secret'ları **manuel** eklenmelidir (`set-acceptance-secrets.sh` admin bilgisini bilmez).

CI'da `faz0-verify` / `m5-preflight` admin secret varsa `POST /api/admin/credits` ile otomatik top-up dener.

**CI tanısı (2026-08-18):** GitHub'da `ACCEPTANCE_ADMIN_*` secret'ları **var** ama **giriş başarısız** (email ve username denendi). `ACCEPTANCE_USER_*` secret'ları da hatalı — varsayılan test hesabına düşülüyor.

**CI düzeltmesi:** `faz0-verify` adımı artık yalnızca `ACCEPTANCE_ADMIN_*` alır; USER/HOST secret'ları verilmez (hatalı secret CI'yı kırmaz). Secret doğrulama ayrı adımda (`validate-acceptance-secrets.sh`, `continue-on-error`).

**CI notu:** Secret'lar var ama top-up başarısızsa:

1. `ACCEPTANCE_USER_*` şifresi hatalı olabilir (CI log: *Secret kimlik bilgileri başarısız*)
2. `ACCEPTANCE_ADMIN_*` hesabı admin rolünde olmayabilir veya şifre yanlış
3. Tanı: CI `faz0-music` job → *Jeton top-up tanı* adımı veya `JETON_TOPUP_DEBUG=1 bash scripts/debug-jeton-topup.sh`

**Hızlı çözüm:** Admin panelden manuel jeton → `bash scripts/m7-on-jeton.sh`

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
