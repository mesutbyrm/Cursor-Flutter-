# BASELINE_TEST_REPORT — site/canlifal-jeton-web

**Tarih:** 2026-08-24  
**PR:** [#244](https://github.com/mesutbyrm/Cursor-Flutter-/pull/244)  
**Base branch:** `main` @ `3e2f872b`  
**PR branch:** `dependabot/npm_and_yarn/site/canlifal-jeton-web/npm_and_yarn-f433e91868`

---

## 1. Baseline (main — Next.js 14.2.35)

| Kontrol | Komut | Sonuç |
|---------|-------|-------|
| Package manager | `npm` (package-lock.json) | PASS |
| Dependency install | `npm ci` | PASS (29 packages) |
| TypeScript | `npx tsc --noEmit` | PASS |
| ESLint | `package.json` script yok; `next build` içi lint | PASS (build sırasında) |
| Unit tests | `package.json` script yok | N/A |
| Production build | `npm run build` | PASS |
| Routes | `/` → redirect, `/jeton-yukle` static | PASS |

**Versiyonlar (baseline):**

- `next@14.2.35`
- `react@18.3.1`
- `react-dom@18.3.1`

**Build çıktısı (özet):**

```
Route (app)
┌ ○ /
├ ○ /_not-found
└ ○ /jeton-yukle
○ (Static) prerendered as static content
```

**npm audit (baseline):** 3 high (next 14.x CVE'leri, nanoid transitive)

---

## 2. PR #244 — mergeable analizi

| Alan | Değer |
|------|-------|
| mergeable (GitHub API) | `MERGEABLE` |
| mergeStateStatus | `UNSTABLE` (eski CI check failure) |
| Merge conflict | **Yok** (main merge sonrası) |
| Değişen dosyalar (PR diff) | `package.json`, `package-lock.json`, `next-env.d.ts` |
| Next.js 15 breaking change (kod) | **Gerekmedi** — App Router basit; async params/middleware yok |
| Peer dependency | React 18.3 uyumlu |

**mergeable=false değil;** PR GitHub'da mergeable. `UNSTABLE` nedeni: Temmuz 2025 CI'da **CodeQL Analyze (java-kotlin)** FAILURE — jeton-web ile ilgisiz.

---

## 3. Post-upgrade (Next.js 15.5.18 + main sync)

| Kontrol | Sonuç |
|---------|-------|
| Dependency install | PASS (`npm ci`, 30 packages) |
| TypeScript | PASS |
| Production build | PASS |
| Smoke test (`npm run start`) | PASS — `/` redirect, `/jeton-yukle` HTTP 200, "Jeton yükle" içerik |
| Flutter/mobile değişti mi | **Hayır** |
| backend/API değişti mi | **Hayır** |

**Versiyonlar (upgrade):**

- `next@15.5.18` (package.json: `^15.5.18`)
- `react@18.3.1` (değişmedi)
- `react-dom@18.3.1` (değişmedi)

**Next.js 15 migration değişiklikleri:**

| Dosya | Değişiklik | Neden |
|-------|------------|-------|
| `package.json` | `next` ^14.2.0 → ^15.5.18 | Güvenlik |
| `package-lock.json` | Lock güncelleme | Dependabot + npm ci |
| `next-env.d.ts` | `routes.d.ts` referansı | Next.js 15 otomatik tip dosyası |

**npm audit (15.5.18):** 4 high — `postcss`, `sharp` (next transitive); tam çözüm Next 16 gerektirir (`npm audit fix --force`). PR hedef CVE'leri (14.x → 15.5.18) giderildi; kalan advisory'ler Next 15.5.x transitive zincirinde bilinen sınırlama.

---

## 4. Korunan güvenlik düzeltmeleri (PR #244)

14.2.35 → 15.5.18 ile gelen advisory'ler (PR açıklaması):

- GHSA-8h8q-6873-q5fj — Server Components DoS
- GHSA-267c-6grr-h53f / GHSA-26hh-7cqf-hhc6 — Middleware bypass
- GHSA-492v-c6pp-mqqv — Dynamic route parameter bypass
- GHSA-c4j6-fc7j-m34r — WebSocket upgrade SSRF
- GHSA-h64f-5h5j-jqjh — Image Optimization DoS
- GHSA-wfc6-r584-vfw7 — RSC cache poisoning
- GHSA-ffhc-5mcf-pf4q — CSP nonce XSS
- (ve diğerleri — PR body)

**Eski 14.2.35 sürümüne geri dönülmedi.**

---

## 5. CI release gate (PR #244)

| Gate | Durum |
|------|-------|
| dependency install | PASS |
| typecheck | PASS |
| lint | PASS (next build embedded) |
| tests | N/A (test script yok) |
| production build | PASS |
| security audit | PARTIAL — transitive postcss/sharp (Next 15.5.18 sınırı) |
| Next.js 15.5.18 | PASS |
| merge conflict | PASS |
| GitHub mergeable | PASS |
| required CI checks | **FAIL** — CodeQL java-kotlin (önceden kırık, web dışı) |
| Flutter/mobile değişmedi | PASS |
| backend değişmedi | PASS |

**Sonuç:** Teknik migration PASS; PR merge için CodeQL java-kotlin veya branch protection güncellemesi gerekli.
