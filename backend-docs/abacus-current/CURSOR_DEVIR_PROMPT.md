# CanlıFal — Cursor Devir Paketi

Bu dosya iki bölümden oluşur:

1. **Cursor'a yapıştıracağın hazır prompt** (kopyala-yapıştır)
2. **Cursor'a vermen gereken her şeyin listesi**: MCP sunucusu, endpoint'ler, kütüphane dosyaları, MD dokümanları

---

# BÖLÜM A — CURSOR'A YAPIŞTIRILACAK PROMPT

> Aşağıdaki metnin tamamını Cursor sohbetine yapıştır.

```
Sen CanlıFal projesinin backend + web geliştiricisisin. Proje kökü: fortune_telling_platform,
uygulama kodu nextjs_space/ altında. Veritabanı Prisma ile yönetiliyor ve DEV + PROD ORTAK.
Dolayısıyla ŞEMA DEĞİŞİKLİKLERİ SADECE EKLEMELİ (additive) olabilir; hiçbir alan silinemez,
yeniden adlandırılamaz, tip değiştiremez. `prisma db push --accept-data-loss` ve
`--force-reset` KESİNLİKLE yasak.

## PROJEDE SON TAMAMLANAN İŞ: PARA BİRİMİ EKONOMİSİ (BÖLÜM 6 → 8b)

Platformda iki iç para birimi var:

- **Jeton** (`User.jetonBalance`) — TEK çevrilebilir/çekilebilir birim.
  ASLA ödül olarak verilmez. Ama GELİR olarak jetondur: hediye, canlı yayın,
  sesli görüşme, misafirlik kazançları ve JETON yüklemelerinden doğan ajans komisyonu.
- **CFC** (`User.credits`) — çevrilemez, çekilemez. Harcama ve ödül birimi:
  Fal/Tarot, Bana Özel, oyunlar, Şanslı Hediye (hem bahis hem kazanç),
  referans komisyonu (HER ZAMAN CFC), jeton dışı yüklemelerden doğan ajans daveti ödülü,
  günlük giriş ödülleri, görev ödülleri.

Bu kurallar iş kuralıdır, kod içinde sabitlerle temsil edilir. Değiştirme, sadece uy:

  lib/currency-branding.ts
    CONVERTIBLE_CURRENCIES = ['jeton']
    NON_CONVERTIBLE_CURRENCIES = ['cfc','credits']
    REWARD_CURRENCY = 'cfc'   REWARD_BALANCE_FIELD = 'credits'
    isConvertibleCurrency()

  lib/referral-commission.ts
    REFERRAL_PAYOUT_CURRENCY = 'cfc' / REFERRAL_PAYOUT_BALANCE_FIELD = 'credits'
    AGENCY_PAYOUT_CURRENCY   = 'cfc' / AGENCY_PAYOUT_BALANCE_FIELD   = 'credits'  (varsayılan)
    resolveAgencyPayout(topupCurrency) -> yükleme 'jeton' ise jeton, değilse cfc öder

### 1) Yönetici tarafından değiştirilebilir para birimi markalaması
Jeton ve CFC'nin ADI (TR+EN), İKONU ve RENGİ admin panelinden değiştirilebilir.
PlatformSettings anahtarları:
  currency_jeton_name / _name_en / _icon / _color   (varsayılan: Jeton, /currency/jeton.svg, #F5C542)
  currency_cfc_name   / _name_en / _icon / _color   (varsayılan: CFC,   /currency/cfc.svg,   #A78BFA)

Arayüzde para birimi adı/ikonu ASLA sabit metin olarak yazılmaz. Her zaman şu bileşenler kullanılır:
  components/currency-amount.tsx  -> default CurrencyAmount, named CurrencyIcon, CurrencyName
  lib/currency-branding-context.tsx -> CurrencyBrandingProvider, useCurrencyBranding, useCurrencyBrand
Provider app/layout.tsx içinde LanguageProvider'ın içine sarılmış durumda. SSR güvenli
(ilk render varsayılanlarla, sonra /api/currency-branding ile tazeleme + localStorage cache).

KURAL: Yeni bir bakiye/fiyat/ödül yüzeyi eklerken "Jeton" veya "CFC" kelimesini elle yazma;
<CurrencyName currency="jeton" /> ve <CurrencyIcon currency="cfc" /> kullan.

### 2) Yükleme bonusu (kademeli yüzde)
Model: TopupBonusTier (topup_bonus_tiers). Varsayılan kademeler 10.000→%5, 25.000→%7, 50.000→%10.
lib/currency-branding.ts: resolveTopupBonus(), applyTopupBonus().
Yükleme yolları (sistemde self-servis kart ödemesi YOK, sadece bu iki yol):
  app/api/admin/credits/route.ts
  app/api/admin/cfc-payment-requests/route.ts  (approve dalı)
Her ikisinde önce applyTopupBonus, sonra awardTopupCommissions çağrılır (fire-and-forget .catch()).

### 3) Referans & ajans komisyon motoru
Model: ReferralCommission (referral_commissions).
lib/referral-commission.ts: getCommissionConfig(), awardTopupCommissions(), getCommissionSummary(userId),
invalidateCommissionConfigCache(). 8 ayar anahtarı (0 = sınırsız):
  referral_commission_enabled / _rate / _monthly_limit / _total_limit / _min_topup
  agency_invite_commission_enabled / _rate / _monthly_limit
awardTopupCommissions ASLA throw etmez.
Not: Agency.commissionRate (üye KAZANÇ komisyonu, lib/agency-commission.ts) ayrı bir sistemdir,
jeton olarak kalır, dokunma.

### 4) Bana Özel ödeme zinciri: CFC → Jeton → Reklam
app/api/bana-ozel/open/route.ts:
  Önce CFC (credits), yetmezse Jeton (jetonBalance), ikisi de yetmezse ücretsiz reklam açılışı.
  Reklam limiti ayarı: bana_ozel_ad_daily_limit, VARSAYILAN '0' = SINIRSIZ, admin panelinden ayarlanır.
  402 yanıtı: { error, required, current, cfcBalance, jetonBalance, canWatchAd, adRemaining, adUnlimited }
  200 yanıtı: paymentMethod: 'cfc' | 'jeton' | 'ad'
DİKKAT: "Bana Özel" arayüzünün ÜÇ kopyası var, üçünü de senkron tut:
  app/[lang]/bana-ozel/page.tsx  (gerçekte /bana-ozel'de render edilen dosya)
  components/bana-ozel-section.tsx
  components/bana-ozel-popup.tsx

### 5) Bakiye & Kazanç sayfası
  app/[lang]/kazanc/page.tsx  +  app/api/user/wallet/route.ts
Cüzdan API'si tek çağrıda döner: balances (cfc/jeton), branding, rules, earnings,
referralCode, withdrawal (limitler + geçmiş), birleşik transactions (creditTransaction + jetonTransaction,
id önekleri c_ / j_). Çift kimlik doğrulama: mobil JWT (authenticateRequest) → web oturumu (getServerSession) yedeği.
ÖNEMLİ: totalEarnings ve canWithdraw alanları User'da DEĞİL, LiveFortuneTeller modelindedir.
Navigasyon: aktif tema 'canlidark' iken navbar render EDİLMEZ
(components/theme-aware-chrome.tsx null döner) — bu yüzden /kazanc girişi hem
components/navbar.tsx profil menüsünde hem components/canlidark-home.tsx üst navında var.
Yeni bir global menü öğesi eklerken İKİSİNE birden ekle.

### 6) Son düzeltmeler (BÖLÜM 8b, canlıya alındı)
- components/fortune-access-gate.tsx: bakiyeyi CFC üzerinden kontrol ediyordu ama "Jeton" yazıyordu.
  Artık CFC etiketli, buton "Bakiye Yükle".
- app/api/bana-ozel/route.ts GET yanıtına cfcBalance eklendi (eskiden yalnız jetonBalance dönüyordu,
  arayüz Jeton rozetini CFC değeriyle eziyordu).
- Markalı bileşene bağlanan diğer yüzeyler: components/game-shell.tsx, app/[lang]/oyunlar/page.tsx,
  components/floating-profile.tsx, components/navbar.tsx, app/[lang]/jeton/page.tsx.

## ÇALIŞMA KURALLARIN
1. Kod yazmadan ÖNCE canlifal-backend MCP sunucusundan ilgili endpoint ve modeli oku
   (get_endpoint, get_model, search_source). Uydurma; kaynağı oku.
2. Şema değişikliği sadece additive. Yeni alanlar opsiyonel veya @default'lu olmalı.
3. Para birimi etiketi hiçbir yere sabit metin yazılmaz — CurrencyName/CurrencyIcon kullanılır.
4. Ödül = CFC, çekim = yalnız Jeton. Bu kuralı bozan bir kod görürsen düzelt ve bana bildir.
5. Yeni endpoint'ler mevcut standarda uyar: dual auth (mobil JWT + web oturumu),
   export const dynamic = 'force-dynamic', Türkçe hata mesajları,
   finansal uçlarda rate limit (lib/rate-limit-guard.ts) + idempotency + ledger (lib/ledger.ts).
6. Değişiklikten sonra: yarn tsc --noEmit ve yarn build temiz olmalı.
7. Türkçe cevap ver.

## İLK GÖREVİN
Projeyi MCP üzerinden tara ve şunu raporla:
"Jeton" veya "CFC" metnini sabit olarak içeren, henüz CurrencyName/CurrencyIcon
bileşenlerine bağlanmamış tüm bakiye/fiyat/ödül yüzeylerini listele.
Her biri için dosya yolu + satır + önerilen düzeltme ver. Kod değiştirmeden önce onay iste.
```

---

# BÖLÜM B — CURSOR'A VERMEN GEREKENLER

## B.1 — MCP Sunucusu (en önemli parça)

Projede Cursor için hazır, **salt-okunur** bir MCP sunucusu var:

```
fortune_telling_platform/mcp-server/
  index.mjs                 # MCP sunucusu (stdio)
  lib.mjs                   # canlı dosyaları okuyan yardımcılar
  package.json
  README.md                 # Türkçe kurulum
  cursor-mcp.example.json
```

**Kurulum (kendi bilgisayarında):**

```bash
cd fortune_telling_platform/mcp-server
npm install
node index.mjs --selftest      # doğrulama
```

**Cursor ayarı** — repo kökündeki `.cursor/mcp.json` dosyasındaki yolu kendi mutlak yolunla değiştir:

```json
{
  "mcpServers": {
    "canlifal-backend": {
      "command": "node",
      "args": ["/MUTLAK/YOL/fortune_telling_platform/mcp-server/index.mjs"]
    }
  }
}
```

**Sunduğu 10 araç:** `list_endpoints`, `get_endpoint`, `search_endpoints`, `list_models`, `get_model`,
`search_schema`, `get_auth_flow`, `read_source`, `list_services`, `search_source`

**Kaynaklar:** `schema://prisma`, `openapi://spec`, `endpoints://index`, `docs://<dosya>.md`

> `get_endpoint` en değerlisi: index + OpenAPI + canlı `route.ts` kaynağını birlikte döner.
> Bu MCP dağıtılan uygulamanın parçası değildir, yalnızca yerel geliştirici aracıdır.

## B.2 — Vermen gereken MD / şema dosyaları

### Öncelik 1 — mutlaka ver

| Dosya | Neden |
|---|---|
| `.project_instructions.md` (proje kökü) | Tüm fazların canlı tarihçesi; BÖLÜM 6→8b burada |
| `backend-docs/ENDPOINTS.md` | Tüm uçların listesi |
| `backend-docs/openapi.json` | Makine okunur sözleşme |
| `backend-docs/schema.prisma` | Veri modeli |
| `backend-docs/DATABASE_REFERENCE.md` | Tablo/alan referansı |
| `docs/CANLIFAL_DATA_MODEL.md` | Model ilişkileri |
| `docs/CANLIFAL_NEW_ENDPOINT_STANDARD.md` | Yeni uç yazma standardı |

### Öncelik 2 — güçlü tavsiye

| Dosya | Neden |
|---|---|
| `docs/CANLIFAL_API.md` | Genel API rehberi |
| `docs/CANLIFAL_ERROR_CODES.md` | Hata kodu sözleşmesi |
| `docs/CANLIFAL_PERMISSIONS.md` | Rol/RBAC (admin, yonetici, moderator, finans) |
| `docs/CANLIFAL_FEATURE_FLAGS.md` | Özellik bayrakları |
| `docs/CANLIFAL_SECURITY.md` | Rate limit / idempotency / ledger |
| `docs/CANLIFAL_AGENCY.md` | Ajans sistemi (komisyonlar için şart) |
| `docs/CANLIFAL_REALTIME_EVENTS.md` | SSE olayları |
| `backend-docs/postman_collection.json` | Manuel uç testi |

### Öncelik 3 — sadece o alana dokunacaksa

`docs/CANLIFAL_WEBRTC.md` · `docs/CANLIFAL_PERFORMANCE.md` · `docs/CANLIFAL_REMOTE_CONFIG.md` ·
`backend-docs/CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md` ·
`backend-docs/CANLIFAL_REALTIME_SISTEMLER_DOKUMANTASYONU.md` ·
`docs/CANLIFAL_FLUTTER_BACKEND_CONTRACT.md` (mobil taraf)

> `docs/CANLIFAL_PHASE*_REPORT.md` dosyaları eski faz raporlarıdır — Cursor'a verme, gürültü yapar.
> Güncel gerçek `.project_instructions.md` içindedir.

## B.3 — Son işle ilgili ENDPOINT'ler (tam liste)

### Genel (public / kullanıcı)

| Metot | Yol | İş |
|---|---|---|
| GET | `/api/currency-branding` | Jeton/CFC adı, ikonu, rengi + çevrilebilirlik kuralları |
| GET | `/api/user/wallet` | Bakiyeler, kazanç özeti, çekim durumu, birleşik işlem geçmişi |
| GET | `/api/user/referral-earnings` | Referans kazanç özeti + sayfalı defter |
| GET | `/api/agency/invite-earnings` | Ajans sahibi davet kazançları |
| GET | `/api/bana-ozel` | Ürün listesi + `cfcBalance` + `jetonBalance` |
| POST | `/api/bana-ozel/open` | CFC → Jeton → Reklam ödeme zinciri |
| POST | `/api/withdrawals` | Çekim talebi (yalnız jeton; `isConvertibleCurrency` guard) |
| POST | `/api/daily-login` | Günlük ödül (CFC) |
| POST | `/api/gifts/lucky/send` | Şanslı hediye (bahis + kazanç CFC) |
| POST | `/api/games/room`, `/api/games/sos` | Oyun girişi (`FREE` \| `CFC`) |

### Yönetici

| Metot | Yol | İş |
|---|---|---|
| GET / PATCH | `/api/admin/currency-settings` | 8 markalama anahtarı |
| GET / POST | `/api/admin/topup-bonus-tiers` | Bonus kademeleri (+ `action:'seed_defaults'`) |
| PATCH / DELETE | `/api/admin/topup-bonus-tiers/[id]` | Kademe düzenle/sil |
| GET | `/api/admin/referral-commission` | Komisyon defteri + 10 istatistik |
| GET / PATCH | `/api/admin/referral-commission/settings` | 8 komisyon anahtarı |
| POST | `/api/admin/credits` | Manuel bakiye yükleme (bonus + komisyon tetikler) |
| POST | `/api/admin/cfc-payment-requests` | CFC ödeme onayı (bonus + komisyon tetikler) |
| GET / PATCH | `/api/admin/settings` | `bana_ozel_ad_daily_limit` dahil genel ayarlar |
| GET / PATCH | `/api/admin/currency-config` | Aksiyon başına para birimi (game_entry = cfc) |

### Yönetici sayfaları

```
/admin/currency-settings      🪙 Para Birimi & Bonus
/admin/referral-commission    🤝 Referans & Ajans Komisyonu
/admin/settings               📺 Bana Özel reklam limiti (0 = sınırsız)
```

## B.4 — Kütüphane ve bileşen dosyaları (Cursor'un bilmesi şart)

| Dosya | Rolü |
|---|---|
| `lib/currency-branding.ts` | Kurallar, ayar anahtarları, `getCurrencyBranding()`, bonus çözümleme |
| `lib/currency-branding-context.tsx` | İstemci provider + `useCurrencyBrand()` |
| `components/currency-amount.tsx` | `CurrencyAmount` / `CurrencyIcon` / `CurrencyName` |
| `lib/referral-commission.ts` | Referans + ajans daveti komisyon motoru |
| `lib/agency-commission.ts` | Üye kazanç komisyonu (ayrı sistem, jeton) |
| `lib/ledger.ts` | Değiştirilemez muhasebe defteri |
| `lib/rate-limit-guard.ts` | Hız sınırı |
| `lib/cache.ts` | Ayar/metadata önbelleği + `invalidateCache` |
| `lib/mobile-auth.ts` + `lib/auth-options.ts` | Çift kimlik doğrulama |
| `scripts/seed.ts` | Varsayılan ayarlar + bonus kademeleri (upsert, silme yok) |

## B.5 — Prisma modelleri (son işte eklenenler)

```
ReferralCommission  -> referral_commissions
TopupBonusTier      -> topup_bonus_tiers
```

İlgili mevcut alanlar: `User.credits` (CFC), `User.jetonBalance`, `User.cfcBalance` (eski),
`User.referralCreditsEarned`, `LiveFortuneTeller.totalEarnings`, `LiveFortuneTeller.canWithdraw`,
`Agency.totalEarnings`, `Agency.commissionRate`.

## B.6 — Cursor'a mutlaka söylemen gereken yasaklar

1. `prisma db push --accept-data-loss` / `--force-reset` yok. Şema sadece additive.
2. Veritabanı dev + prod ORTAK — veri silme, truncate, toplu update yok.
3. `prisma/schema.prisma` bir symlink'tir — silme, üzerine yazma, `prisma init` çalıştırma.
4. Paket yöneticisi yalnızca **yarn**.
5. Para birimi adı/ikonu asla sabit metin yazılmaz.
6. "Bana Özel" üç kopyalıdır — biri düzeltilirse üçü de düzeltilir.
7. Yeni global menü öğesi hem `navbar.tsx` hem `canlidark-home.tsx` içine eklenir.
