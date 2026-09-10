# CanlıFal — Cursor için Tam Dosya Yolu Listesi

Tüm yollar **proje köküne** göredir: `fortune_telling_platform/`
Uygulama kodu `fortune_telling_platform/nextjs_space/` altındadır.
Aşağıdaki her dosyanın varlığı diskte tek tek doğrulandı.

---

## 1 · MCP SUNUCUSU (Cursor'un backend'i okumasını sağlayan parça)

Dağıtılan uygulamanın parçası DEĞİLDİR; yalnızca yerel geliştirici aracıdır. `nextjs_space/` dışında durur, bu yüzden derlemeyi hiç etkilemez.

| Yol | Ne işe yarar |
|---|---|
| `.cursor/mcp.json` | Cursor'un MCP tanımı. İçindeki `/ABSOLUTE/PATH/TO/...` kısmını kendi mutlak yolunla değiştir. Cursor'u açınca sunucu otomatik başlar. |
| `mcp-server/index.mjs` | MCP sunucusunun kendisi. stdio üzerinden çalışır, 10 aracı ve 4 kaynağı yayınlar. `node index.mjs --selftest` ile doğrulanır. |
| `mcp-server/lib.mjs` | Veri kaynağı katmanı. Canlı `prisma/schema.prisma`, `app/api/**/route.ts`, `lib/*.ts` ve `backend-docs/` dosyalarını okur. Yol kaçışı korumalı, mtime önbellekli. |
| `mcp-server/package.json` | Bağımlılıklar (`@modelcontextprotocol/sdk`). Kurulumdan önce `npm install` gerekir. |
| `mcp-server/README.md` | Türkçe kurulum ve kullanım rehberi. |
| `mcp-server/cursor-mcp.example.json` | `.cursor/mcp.json` için örnek şablon. |

**Kurulum:**
```bash
cd fortune_telling_platform/mcp-server
npm install
node index.mjs --selftest
```

**Açılan 10 araç:** `list_endpoints` · `get_endpoint` · `search_endpoints` · `list_models` · `get_model` · `search_schema` · `get_auth_flow` · `read_source` · `list_services` · `search_source`

**Açılan 4 kaynak:** `schema://prisma` · `openapi://spec` · `endpoints://index` · `docs://<dosya>.md`

> `get_endpoint` en değerli aracıdır: index kaydını, OpenAPI tanımını ve canlı `route.ts` kaynağını birlikte döner.

---

## 2 · DOKÜMANLAR — ÖNCELİK 1 (mutlaka ver)

| Yol | Ne içerir |
|---|---|
| `.project_instructions.md` | **En kritik dosya.** Projenin canlı tarihçesi, 1710 satır. Tüm fazların ne yaptığı, hangi dosyanın neden değiştiği, tuzaklar. Para birimi ekonomisi `## BÖLÜM 6` → `## BÖLÜM 8b` arasında (satır ~1453–1710). |
| `backend-docs/ENDPOINTS.md` | Tüm API uçlarının insan okur listesi. |
| `backend-docs/openapi.json` | Makine okunur API sözleşmesi (468 yol). Cursor'un en çok yararlandığı format. |
| `backend-docs/endpoints_index.json` | Uç dizini (731 endpoint). MCP `list_endpoints`/`get_endpoint` bunu kullanır. |
| `backend-docs/schema.prisma` | Veri modelinin dışa aktarılmış kopyası (193 model). |
| `backend-docs/DATABASE_REFERENCE.md` | Tablo ve alan referansı, açıklamalı. |
| `docs/CANLIFAL_DATA_MODEL.md` | Model ilişkileri ve veri akışı. |
| `docs/CANLIFAL_NEW_ENDPOINT_STANDARD.md` | Yeni endpoint yazma standardı: dual auth, hata formatı, `force-dynamic`, rate limit. Cursor yeni uç yazacaksa şart. |

---

## 3 · DOKÜMANLAR — ÖNCELİK 2 (güçlü tavsiye)

| Yol | Ne içerir |
|---|---|
| `docs/CANLIFAL_API.md` | Genel API kullanım rehberi. |
| `docs/CANLIFAL_ERROR_CODES.md` | Hata kodu sözleşmesi. Yeni uçlar buna uymalı. |
| `docs/CANLIFAL_PERMISSIONS.md` | Rol/RBAC tanımları: `admin`, `yonetici`, `moderator`, `finans`. Komisyon ayarlarını kimin yazabileceği burada. |
| `docs/CANLIFAL_SECURITY.md` | Rate limit, idempotency, ledger kuralları. Finansal uç yazacaksa şart. |
| `docs/CANLIFAL_FEATURE_FLAGS.md` | Özellik bayrakları sistemi. |
| `docs/CANLIFAL_AGENCY.md` | Ajans sistemi. Komisyonlarla uğraşacaksa şart. |
| `docs/CANLIFAL_REALTIME_EVENTS.md` | SSE olay kataloğu. |
| `docs/CANLIFAL_BACKEND_ARCHITECTURE.md` | Genel mimari resmi. |
| `backend-docs/postman_collection.json` | Manuel uç testi için hazır koleksiyon. |
| `backend-docs/database_schema.sql` | Ham SQL şeması. |

---

## 4 · DOKÜMANLAR — ÖNCELİK 3 (sadece o alana dokunacaksa)

| Yol | Ne zaman gerekir |
|---|---|
| `docs/CANLIFAL_WEBRTC.md` | Canlı yayın / sesli oda / TRTC işi |
| `docs/CANLIFAL_PERFORMANCE.md` | Önbellek, sorgu optimizasyonu |
| `docs/CANLIFAL_REMOTE_CONFIG.md` | Uzaktan yapılandırma |
| `docs/CANLIFAL_FLUTTER_BACKEND_CONTRACT.md` | Mobil uygulama tarafı |
| `backend-docs/CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md` | Hediye motoru |
| `backend-docs/CANLIFAL_REALTIME_SISTEMLER_DOKUMANTASYONU.md` | Realtime altyapı |
| `backend-docs/CANLIFAL_BACKEND_GELISTIRICI_DOKUMANTASYONU.md` | Genel geliştirici el kitabı |

> **VERME:** `docs/CANLIFAL_PHASE*_REPORT.md` (29 adet) ve `docs/B1_*`, `docs/STAGE*`, `docs/API_PARITY_*` dosyaları.
> Bunlar tamamlanmış eski faz raporlarıdır, Cursor'u yanıltır. Güncel gerçek `.project_instructions.md` içindedir.

---

## 5 · PARA BİRİMİ ÇEKİRDEĞİ — kuralların yaşadığı dosyalar

Tümü `nextjs_space/` altında.

| Yol | Ne yapar |
|---|---|
| `lib/currency-branding.ts` | **Kural merkezi.** `CONVERTIBLE_CURRENCIES=['jeton']`, `NON_CONVERTIBLE_CURRENCIES=['cfc','credits']`, `REWARD_CURRENCY='cfc'`, `REWARD_BALANCE_FIELD='credits'`, `isConvertibleCurrency()`. Ayrıca 8 markalama anahtarı (`CURRENCY_SETTING_KEYS/DEFAULTS/LABELS`), `getCurrencyBranding()`, `invalidateCurrencyBrandingCache()`, `DEFAULT_BONUS_TIERS`, `resolveTopupBonus()`, `applyTopupBonus()`. |
| `lib/currency-branding-context.tsx` | İstemci tarafı provider. `CurrencyBrandingProvider`, `useCurrencyBranding()`, `useCurrencyBrand()`. SSR güvenli: ilk render varsayılanlarla, sonra `/api/currency-branding` ile tazeler, `localStorage` önbelleği tutar (`canlifal:currency-branding`). |
| `components/currency-amount.tsx` | Görüntüleme bileşenleri. Varsayılan dışa aktarım `CurrencyAmount`; adlandırılmış `CurrencyIcon`, `CurrencyName`. **Arayüzde "Jeton"/"CFC" kelimesi elle yazılmaz — bunlar kullanılır.** |
| `lib/referral-commission.ts` | Referans + ajans daveti komisyon motoru. `REFERRAL_PAYOUT_CURRENCY='cfc'`, `AGENCY_PAYOUT_CURRENCY='cfc'` (varsayılan), `resolveAgencyPayout(topupCurrency)` (jeton yüklemesi → jeton öder, diğerleri → CFC). 8 ayar anahtarı, `getCommissionConfig()`, `awardTopupCommissions()` (asla throw etmez), `getCommissionSummary()`. |
| `lib/agency-commission.ts` | **Ayrı sistem.** Üyelerin KAZANÇ komisyonu (yayın, sesli sohbet, misafirlik). Jeton olarak kalır. Dokunma. |
| `public/currency/jeton.svg` | Varsayılan Jeton ikonu (altın). Admin değiştirebilir. |
| `public/currency/cfc.svg` | Varsayılan CFC ikonu (mor/altın mistik). Admin değiştirebilir. |
| `scripts/seed.ts` | Varsayılan ayarları ve 3 bonus kademesini yazar. Yalnız `upsert`, silme yok. `bana_ozel_ad_daily_limit` varsayılanı `'0'` = sınırsız. |
| `prisma/schema.prisma` | **Symlink'tir.** Silme, üzerine yazma, `prisma init` çalıştırma. Son işte eklenen modeller: `ReferralCommission` (→ `referral_commissions`), `TopupBonusTier` (→ `topup_bonus_tiers`). |

---

## 6 · DESTEK KÜTÜPHANELERİ (yeni uç yazarken gerekir)

| Yol | Ne yapar |
|---|---|
| `lib/ledger.ts` | Değiştirilemez muhasebe defteri. `recordMultiLeg()` — finansal hareketlerde fire-and-forget çağrılır. |
| `lib/rate-limit-guard.ts` | `guardRateLimit(request, 'action', { userId })`. Auth'tan SONRA çağrılır. |
| `lib/cache.ts` | Ayar/metadata önbelleği. `getCachedPlatformSetting()`, `getCached()`, `invalidateCache()`. Ayar değiştiren PATCH'ler cache'i geçersiz kılmalı. |
| `lib/mobile-auth.ts` | Mobil JWT doğrulama. `authenticateRequest()`. Access 7 gün / refresh 30 gün. |
| `lib/auth-options.ts` | Web oturumu yapılandırması. `getServerSession(authOptions)`. |
| `lib/check-feature.ts` | Özellik bayrağı kapısı. `requireFeature()`. |

> **Dual auth kalıbı:** önce `authenticateRequest(request)` (mobil), yoksa `getServerSession(authOptions)` (web), ikisi de yoksa 401.

---

## 7 · GENEL ENDPOINT'LER (kullanıcı tarafı)

| Yol | Metot | Ne yapar |
|---|---|---|
| `app/api/currency-branding/route.ts` | GET | Jeton/CFC adı, ikonu, rengi + çevrilebilirlik kuralları. Public. `force-dynamic`. |
| `app/api/user/wallet/route.ts` | GET | **Tek çağrıda cüzdan.** `balances` (cfc/jeton), `branding`, `rules`, `earnings`, `referralCode`, `withdrawal` (limitler + geçmiş), birleşik `transactions` (creditTransaction + jetonTransaction, id önekleri `c_`/`j_`). Parametreler: `limit` (max 100), `offset`, `currency` (`all\|cfc\|jeton`). |
| `app/api/user/referral-earnings/route.ts` | GET | Referans kazanç özeti + oranlar + sayfalı defter. |
| `app/api/agency/invite-earnings/route.ts` | GET | Ajans sahibinin davet kazanç görünümü. |
| `app/api/bana-ozel/route.ts` | GET | Ürün listesi + `cfcBalance` + `jetonBalance`. (`cfcBalance` BÖLÜM 8b'de eklendi — eskiden yoktu ve arayüz Jeton rozetini CFC değeriyle eziyordu.) |
| `app/api/bana-ozel/open/route.ts` | POST | **CFC → Jeton → Reklam ödeme zinciri.** 402 yanıtı: `{ error, required, current, cfcBalance, jetonBalance, canWatchAd, adRemaining, adUnlimited }`. 200 yanıtı: `paymentMethod: 'cfc'\|'jeton'\|'ad'`. Reklam limiti `bana_ozel_ad_daily_limit`, `0` = sınırsız. |
| `app/api/withdrawals/route.ts` | POST | Çekim talebi. `isConvertibleCurrency` guard'ı var — jeton dışı birim 400 döner. |
| `app/api/daily-login/route.ts` | POST | Günlük giriş ödülü. **CFC öder** (`credits`), yanıtta `cfcEarned`. |
| `app/api/gifts/lucky/send/route.ts` | POST | Şanslı Hediye. **Bahis de kazanç da CFC.** Ekonomik olarak hassas dosya. |
| `app/api/games/room/route.ts` | POST | Oyun odası girişi. Bahis whitelist: `['FREE','CFC']`. |
| `app/api/games/sos/route.ts` | POST | SOS oyunu. Aynı whitelist. |

---

## 8 · YÖNETİCİ ENDPOINT'LERİ

| Yol | Metot | Ne yapar |
|---|---|---|
| `app/api/admin/currency-settings/route.ts` | GET / PATCH | 8 markalama anahtarı: `currency_jeton_name` · `_name_en` · `_icon` · `_color` ve aynıları `currency_cfc_*` için. PATCH sonrası branding cache'i geçersiz kılınır. |
| `app/api/admin/topup-bonus-tiers/route.ts` | GET / POST | Bonus kademeleri + istatistik. `{ action: 'seed_defaults' }` ile varsayılanları (10.000→%5, 25.000→%7, 50.000→%10) yükler. |
| `app/api/admin/topup-bonus-tiers/[id]/route.ts` | PATCH / DELETE | Tek kademe düzenle veya sil. |
| `app/api/admin/referral-commission/route.ts` | GET | Komisyon defteri + 10 istatistik, filtreli ve sayfalı. |
| `app/api/admin/referral-commission/settings/route.ts` | GET / PATCH | 8 komisyon anahtarı: `referral_commission_enabled` · `_rate` · `_monthly_limit` · `_total_limit` · `_min_topup` · `agency_invite_commission_enabled` · `_rate` · `_monthly_limit`. **0 = sınırsız.** Yazma rolleri: `admin`, `yonetici`, `finans`. |
| `app/api/admin/credits/route.ts` | POST | **Yükleme yolu 1.** Manuel bakiye yükleme. `applyTopupBonus` → sonra `awardTopupCommissions`, ikisi de fire-and-forget. |
| `app/api/admin/cfc-payment-requests/route.ts` | POST | **Yükleme yolu 2.** CFC ödeme talebi onayı. Aynı bonus + komisyon zinciri. |
| `app/api/admin/settings/route.ts` | GET / PATCH | Genel platform ayarları, `bana_ozel_ad_daily_limit` dahil. |
| `app/api/admin/currency-config/route.ts` | GET / PATCH | Aksiyon başına para birimi eşlemesi. `game_entry` varsayılanı `cfc`. |

> **Önemli:** Sistemde self-servis kart ödemesi YOK. Bakiye yalnızca yukarıdaki iki yönetici ucundan yüklenir. Yeni bir yükleme yolu eklersen bonus + komisyon zincirini oraya da bağlaman gerekir.

---

## 9 · KULLANICI SAYFALARI

| Yol | Ne gösterir |
|---|---|
| `app/[lang]/kazanc/page.tsx` | **Bakiye & Kazanç sayfası.** İki bakiye kartı (çevrilebilirlik rozetiyle), kazanç özeti, para çekme paneli, sayfalı işlem geçmişi. Zaten tamamen `branding` verisiyle çalışır. |
| `app/[lang]/bana-ozel/page.tsx` | **/bana-ozel'de gerçekten render edilen dosya budur.** İki markalı bakiye çipi, CFC ikonlu maliyet rozetleri, `paymentMethod` duyarlı "harcandı" satırı. |
| `app/[lang]/jeton/page.tsx` | Jeton satın alma. Başlıktaki iki bakiye rozeti markalı. |
| `app/[lang]/oyunlar/page.tsx` | Oyun listesi. Üstteki iki bakiye çipi markalı. |
| `app/[lang]/davet/page.tsx` | Davet sayfası + "💰 Yükleme Komisyonun" bloğu (4 istatistik + son 5 işlem). `referralEnabled` false ise gizlenir. |

---

## 10 · YÖNETİCİ SAYFALARI

| Yol | URL | Ne yönetir |
|---|---|---|
| `app/[lang]/admin/currency-settings/page.tsx` | `/admin/currency-settings` | 🪙 Para Birimi & Bonus. İki sekme: İsim & İkon / Bonus Kademeleri. |
| `components/admin/currency-settings-admin.tsx` | — | Yukarıdaki sayfanın asıl bileşeni. |
| `app/[lang]/admin/referral-commission/page.tsx` | `/admin/referral-commission` | 🤝 Referans & Ajans Komisyonu. |
| `components/admin/referral-commission-admin.tsx` | — | 5 istatistik kartı + ayar formu + filtre + defter tablosu + sayfalama. |
| `app/[lang]/admin/settings/page.tsx` | `/admin/settings` | 📺 "Bana Özel" reklam izleme limiti (min 0, `0 = sınırsız`), Koltuk Sayısı bloğunun hemen üstünde. |
| `app/[lang]/admin/page.tsx` | `/admin` | Ana panel. 💰 Finans & Jeton grubunda yukarıdaki iki karta bağlantı var (satır ~198–199). |

---

## 11 · AYGIT/GÖRÜNÜM BİLEŞENLERİ (para birimi yüzeyleri)

| Yol | Durum |
|---|---|
| `app/layout.tsx` | `CurrencyBrandingProvider` burada, mevcut `LanguageProvider`'ın **içine** sarılı. |
| `components/navbar.tsx` | Profil menüsündeki CFC ve Jeton satırları markalı. `💰 Bakiye & Kazanç` → `/kazanc` bağlantısı burada. |
| `components/theme-aware-chrome.tsx` | **Kritik:** `theme === 'canlidark'` iken `null` döner — yani navbar HIÇ render edilmez. |
| `components/canlidark-home.tsx` | Aktif temada gerçek üst navı budur. `/kazanc` girişi (Bildirim ile Panelim arasında) burada. **Yeni global menü öğesi eklerken navbar ile birlikte buraya da ekle.** |
| `components/fortune-access-gate.tsx` | BÖLÜM 8b'de düzeltilen gerçek hata: bakiyeyi CFC üzerinden kontrol ediyordu ama "Jeton" yazıyordu. Artık CFC etiketli, buton "Bakiye Yükle". |
| `components/game-shell.tsx` | Bakiye çipleri + bahis türü butonları markalı. |
| `components/floating-profile.tsx` | CFC satırı + "CFC Al" butonu markalı. |
| `components/bana-ozel-section.tsx` | Bana Özel **kopya 2**. |
| `components/bana-ozel-popup.tsx` | Bana Özel **kopya 3**. |

> **TUZAK:** "Bana Özel" arayüzünün ÜÇ ayrı kopyası var (`app/[lang]/bana-ozel/page.tsx`, `components/bana-ozel-section.tsx`, `components/bana-ozel-popup.tsx`). Birinde değişiklik yaparsan üçünü birden güncelle, yoksa bir yerde eski davranış kalır.

---

## 12 · CURSOR'A VERİLECEK YASAKLAR (aynen aktar)

1. `prisma db push --accept-data-loss` ve `--force-reset` **yasak**. Şema değişikliği yalnız **eklemeli**; alan silme, yeniden adlandırma, tip değiştirme yok.
2. Veritabanı **dev + prod ORTAK**. Veri silme, truncate, toplu update yok.
3. `prisma/schema.prisma` bir **symlink**'tir. Silme, üzerine yazma, `prisma init` çalıştırma.
4. Paket yöneticisi yalnızca **yarn**. `npm`/`npx` kullanılmaz (istisna: `mcp-server/` klasörü, o ayrı bir araçtır).
5. Arayüzde para birimi adı/ikonu **asla sabit metin** yazılmaz — `CurrencyName` / `CurrencyIcon` kullanılır.
6. Ödül = **CFC**, çekim = yalnız **Jeton**. Bu kuralı bozan kod görülürse düzeltilir ve bildirilir.
7. "Bana Özel" üç kopyalıdır — biri düzeltilirse üçü de düzeltilir.
8. Yeni global menü öğesi hem `navbar.tsx` hem `canlidark-home.tsx` içine eklenir.
9. Değişiklik sonrası `yarn tsc --noEmit` ve `yarn build` temiz olmalı.
10. Python ile import eklerken dikkat: çok satırlı `import { ... } from '...'` bloğunun **içine** düşerse derleme kırılır. Her zaman kapanış `} from '...'` satırından sonra ekle.
