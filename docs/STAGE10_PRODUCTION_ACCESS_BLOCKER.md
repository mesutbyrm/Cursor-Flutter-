# Stage 10 — Production Access Blocker

> **Durum:** `PRODUCTION DEPLOY = BLOCKED`  
> **Tarih:** 2026-08-09  
> **Flutter repo:** `mesutbyrm/Cursor-Flutter-` (bu workspace)

---

## Production host

| Alan | Değer |
|------|--------|
| **Ana site** | `https://canlifal.com` |
| **Games / PK API** | `https://canlifalapi.abacusai.app` (ayrı Abacus deployment; `instance: canlifal-api-1`) |
| **CDN** | Cloudflare (`server: cloudflare`, `cf-cache-status: DYNAMIC`) |
| **Reverse proxy** | Envoy (`x-envoy-upstream-service-time` header) |
| **Uygulama** | Next.js 14 App Router (`/_next/static`, `x-middleware-rewrite`) |
| **Veritabanı** | PostgreSQL + Prisma (üretim envanteri) |

---

## Hosting platform

| Katman | Platform / kanıt |
|--------|------------------|
| **Edge CDN** | Cloudflare |
| **Upstream proxy** | Envoy |
| **Ana web + API** | Abacus.ai hosted Next.js (`apps.abacus.ai` HTML/JS referansları; S3 `abacusai-apps-*` asset URL'leri) |
| **Oyun backend** | Abacus.ai (`canlifalapi.abacusai.app`, health: Redis + DB connected) |
| **Vercel** | **Yok** (`x-vercel-id` header yok) |

Deploy mekanizması (dokümantasyon): Abacus.ai proje paneli üzerinden Next.js redeploy — bkz. `docs/ABACUS_FLUTTER_PARITY_DEPLOY.md`.

---

## Production source repository / project

| Kaynak | Bulgu |
|--------|--------|
| **Bu repo (`mesutbyrm/Cursor-Flutter-`)** | Flutter mobil + `api/` Express mirror — **canlifal.com production deploy kaynağı DEĞİL** |
| **Next.js web kaynak kodu** | Bu repoda **yok** (`docs/WEB_FLUTTER_SYNC_ANALYSIS_REPORT.md`) |
| **GitHub erişimi (`gh repo list mesutbyrm`)** | Yalnızca `Cursor-Flutter-` görünür; production Next.js repo **erişilemiyor** |
| **GitHub arama (`canlifal`)** | `mesutbyrm` altında backend repo bulunamadı |
| **Abacus AI project** | Cloud Agent ortamında Abacus dashboard / API / MCP erişimi **yok** |
| **Tahmini kaynak** | Abacus.ai'ye bağlı özel Next.js + Prisma projesi (git bağlantısı bu ortamda doğrulanamadı) |

**Kesin sonuç:** `canlifal.com` hangi git commit/branch'ten build edildiği bu agent oturumunda **doğrulanamadı**. Erişim olmadan deploy yapılmadı.

---

## Erişilemeyen kaynak

1. **canlifal.com Next.js production repository** (App Router `app/api/video-streams/[id]/fortune-requests/route.ts` veya eşdeğeri)
2. **Abacus.ai deployment paneli** (build tetikleme, revision, connected git)
3. **Production environment secrets / deploy keys**

---

## Gereken erişim

Aşağıdakilerden **en az biri** Stage 10 deploy için zorunlu:

| # | Erişim | Amaç |
|---|--------|------|
| 1 | Production Next.js git repo (read + push) | Patch commit + CI/CD tetikleme |
| 2 | Abacus.ai proje erişimi (owner/collaborator) | Connected repo, build config, manual redeploy |
| 3 | Production deploy pipeline credentials (SSH, Abacus API token, vb.) | Doğrudan revision deploy |

**Önerilen:** Production Next.js reposunu bu Cloud Agent workspace'e clone edilebilir hale getirin veya Abacus collaborator ekleyin.

---

## Mevcut patch dosyası (mirror — deploy bekliyor)

Bu Flutter repo'daki mirror, production'a taşınacak referans kod:

| Dosya | İçerik |
|-------|--------|
| `api/src/lib/streamFortuneRequestService.ts` | `parseFortuneCreateBody()`, `mapFortuneCreateException()`, legacy type map |
| `api/src/routes/video_streams.ts` | POST handler: stream 404 check, parser, structured errors |
| `api/src/lib/streamFortuneRequestService.test.ts` | 12/12 unit test (mirror'da PASS) |
| `docs/PRODUCTION_FORTUNE_REQUEST_DEPLOY.md` | Adım adım deploy kılavuzu |

### Deploy edilmesi gereken davranış

| Senaryo | Beklenen HTTP |
|---------|----------------|
| Valid `{typeId, nickname, question, isHidden}` | 200 |
| Unauthorized | 401 |
| Invalid body (typeId yok) | **400** (şu an **500**) |
| Invalid `streamId` | **404** (şu an **200**) |
| Legacy body (`displayName` + `fortuneType`) | **400** veya mapped **200** (şu an **500**) |
| Duplicate pending | 400 |
| Prisma P2002 | 409 |
| Prisma P2003 | 400 |

---

## Deploy sonrası çalıştırılacak test komutu

```bash
# 1) Production fortune-request gate (hedef: 0 FAIL)
bash scripts/acceptance-tests/api-stage8-production.sh

# 2) Regression — önceden geçen sonuçları bozmamalı
bash scripts/acceptance-tests/api-acceptance.sh          # 17/17
bash scripts/acceptance-tests/p0-production-smoke.sh   # 25/25
bash scripts/acceptance-tests/sse-20-cycle.sh          # 20/20

# 3) Flutter (kod değiştirmeden)
cd mobile && flutter analyze && flutter test
```

**API PARITY COMPLETE** yalnızca `api-stage8-production.sh` → **0 FAIL** olduktan sonra ilan edilebilir.

---

## Stale deployment kontrol listesi (deploy sonrası hâlâ eski davranış varsa)

`cf-cache-status: DYNAMIC` olduğu için sorun otomatik olarak CDN cache'e bağlanmamalı. Kontrol edilecekler:

- [ ] Abacus deployment revision (aktif build commit)
- [ ] Envoy upstream pool (hangi pod/revision)
- [ ] Next.js serverless / edge function revision
- [ ] Cloudflare Worker / route override (varsa)
- [ ] Database migration drift (Prisma schema)

---

## Final

```
PRODUCTION DEPLOY = BLOCKED
API PARITY = NOT COMPLETE
```

**Sebep:** Production Next.js kaynak koduna ve Abacus deploy paneline erişim yok. Sahte deploy veya mock PASS üretilmedi.
