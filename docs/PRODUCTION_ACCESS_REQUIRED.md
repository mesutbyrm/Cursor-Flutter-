# Production Access Required

> **Durum:** `PRODUCTION SOURCE ACCESS = BLOCKED`  
> **Tarih:** 2026-08-09  
> **Flutter repo (bu workspace):** `mesutbyrm/Cursor-Flutter-`

---

## PRODUCTION HOST

| Alan | Değer |
|------|--------|
| **URL** | `https://canlifal.com` |
| **API prefix** | `/api/*` |
| **Stack** | Cloudflare → Envoy → Abacus.ai → Next.js 14 → Prisma → PostgreSQL |
| **Games/PK API (ayrı)** | `https://canlifalapi.abacusai.app` (`instance: canlifal-api-1`) |

---

## PRODUCTION PLATFORM

| Katman | Platform |
|--------|----------|
| CDN | Cloudflare (`cf-cache-status: DYNAMIC`) |
| Reverse proxy | Envoy (`x-envoy-upstream-service-time`) |
| App host | Abacus.ai AppLLM (`apps.abacus.ai`) |
| Runtime | Next.js 14 App Router |
| ORM | Prisma |
| Database | PostgreSQL |

**Not:** Vercel deployment yok (`x-vercel-id` header yok).

---

## ABACUS PROJECT

| Alan | Değer | Güven |
|------|--------|-------|
| **Platform** | Abacus.ai AppLLM | Gözlem + dokümantasyon |
| **Tahmini proje ID** | **`27294`** | S3 asset URL pattern (`…/27294/public/uploads/…`) |
| **S3 bucket** | `abacusai-apps-a0f193e2eb4b9dad540f619b-us-west-2` | us-west-2 |
| **Dashboard URL** | `https://apps.abacus.ai` | Auth gerekli — erişim yok |
| **Deployment ID** | **Bilinmiyor** | API yanıtlarında expose edilmiyor |
| **Build ID** | **Bilinmiyor** | HTML'de `buildId` key var, değer erişilemedi |
| **Active revision** | **Bilinmiyor** | Deploy paneli erişimi yok |

---

## SOURCE STATUS

**NOT ACCESSIBLE**

| Kaynak | Durum |
|--------|--------|
| canlifal.com Next.js `app/api/` kaynak kodu | ❌ Bu workspace'te yok |
| Prisma schema (production) | ❌ Erişilemedi |
| Abacus source export | ❌ Yapılamadı |
| Git connected repo | ❌ Doğrulanamadı |
| Deployment history | ❌ Erişilemedi |

### Bu workspace içeriği (production DEĞİL)

| Dizin | İçerik |
|-------|--------|
| `mobile/` | Flutter istemci (`canlifal_social`) |
| `api/` | Express + Prisma **mirror** (yerel test) |
| `site/canlifal-jeton-web/` | Jeton sayfası mockup (canlifal.com'a kopyalanacak paket) |
| `mcp-server/` | Yerel dokümantasyon MCP (matrix/audit okur) |
| `docs/` | Entegrasyon kılavuzları ve raporlar |

`docs/CANLIFAL_SITE_NEDEN_GORUNMUYOR.md` açıkça belirtir: **canlifal.com web kaynak kodu bu repoda yok.**

---

## GITHUB STATUS

| Kontrol | Sonuç |
|---------|--------|
| `git remote -v` | `origin` → `mesutbyrm/Cursor-Flutter-` only |
| `gh repo list mesutbyrm` | Yalnızca `Cursor-Flutter-` |
| `gh search repos canlifal` | Production Next.js repo bulunamadı |
| `gh api user/repos` | 403 (integration token kapsamı dışı) |

**Production Next.js repository:** **NOT FOUND** (erişilebilir GitHub hesabında)

---

## REQUIRED ACCESS

Aşağıdakilerden **en az biri** zorunlu:

1. **Abacus.ai AppLLM** — `mesutbyrm1@gmail.com` hesabıyla proje **`27294`** (veya canlifal.com projesi) paneline giriş
2. **Production Next.js GitHub repo** — clone/push erişimi (URL paylaşımı)
3. **Abacus collaborator** — bu Cloud Agent workspace'e source export veya git bağlantısı
4. **Deploy credentials** — Abacus API token / deploy key (varsa)

### Gerekli kullanıcı/izin

- Abacus.ai proje **owner** veya **collaborator**
- Production GitHub repo **read + write** (patch commit + deploy trigger)

---

## REQUIRED ACTION

1. Abacus.ai → AppLLM → canlifal.com projesini açın (tahmini ID: **27294**)
2. **Source export** veya connected Git repo URL'sini paylaşın
3. Bu Cloud Agent ortamına production Next.js repo **clone erişimi** verin
4. Patch uygulayın (aşağıda) → redeploy
5. `bash scripts/acceptance-tests/api-stage8-production.sh` → **0 FAIL** doğrulayın

---

## PATCH READY

Mirror referans kodu bu Flutter repo'da hazır (production'a **henüz deploy edilmedi**):

| Bileşen | Dosya |
|---------|-------|
| `parseFortuneCreateBody()` | `api/src/lib/streamFortuneRequestService.ts` |
| `mapFortuneCreateException()` | aynı dosya (P2002→409, P2003→400) |
| Stream existence → 404 | `api/src/routes/video_streams.ts` |
| Unit tests (mirror) | `api/src/lib/streamFortuneRequestService.test.ts` (12/12 PASS) |
| Deploy kılavuzu | `docs/PRODUCTION_FORTUNE_REQUEST_DEPLOY.md` |

### Hedef endpoint davranışı

`POST /api/video-streams/{id}/fortune-requests`

| Senaryo | Beklenen | Üretim (şu an) |
|---------|----------|----------------|
| Valid body | 200 | ✅ 200 |
| Unauthorized | 401 | ✅ 401 |
| Duplicate pending | 400 | ✅ 400 |
| Invalid body | **400** | ❌ **500** |
| Invalid streamId | **404** | ❌ **200** |
| Legacy body | **400/200** | ❌ **500** |

---

## DEPLOY COMMAND / MECHANISM

**Mevcut (dokümantasyon):** Abacus.ai AppLLM paneli → prompt/deploy

Bkz. `docs/ABACUS_FLUTTER_PARITY_DEPLOY.md` — Abacus paneline yapıştırılacak deploy prompt'u.

**Alternatif (git bağlantısı varsa):** Production Next.js repo → commit → Abacus auto-deploy veya manuel redeploy.

Bu agent oturumunda **hiçbir deploy mekanizması tetiklenemedi**.

---

## POST-DEPLOY TEST COMMAND

```bash
# 1) Production fortune-request gate (hedef: 0 FAIL)
bash scripts/acceptance-tests/api-stage8-production.sh

# 2) Regression koruma
bash scripts/acceptance-tests/api-acceptance.sh          # 17/17
bash scripts/acceptance-tests/p0-production-smoke.sh   # 25/25
bash scripts/acceptance-tests/sse-20-cycle.sh            # 20/20

# 3) Flutter (değiştirmeden)
cd mobile && flutter analyze && flutter test
```

**API PARITY COMPLETE** yalnızca Stage 8 script **0 FAIL** + koruma testleri geçtikten sonra.

---

## MCP NOTU

`.cursor/mcp.json` içindeki `canlifal-backend` MCP sunucusu (`mcp-server/index.mjs`):

- Yalnızca **bu repo'daki dokümantasyon** okur (`docs/API_ENDPOINT_MATRIX.md` vb.)
- Production Next.js source, Abacus deployment veya Prisma schema **erişemez**
- `read_source` / `search_source` → **bu MCP'de implement edilmemiş** (matrix dokümantasyonu aspirational)

**MCP SOURCE ACCESS = READ-ONLY DOCS (local mirror) — production source DEĞİL**

---

## FINAL

```
PRODUCTION SOURCE ACCESS = BLOCKED
PRODUCTION DEPLOY = BLOCKED
API PARITY = NOT COMPLETE
```
