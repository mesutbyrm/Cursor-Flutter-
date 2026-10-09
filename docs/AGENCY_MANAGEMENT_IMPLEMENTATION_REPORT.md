# Ajans Yönetimi — Uygulama Raporu

> **Durum: Aşama 0 — Denetim + plan (kod değişikliği yok).**
> Bu dosya her aşamada güncellenir. Aşağıdaki "Karar gereken konular" yanıtlanmadan para/komisyon kodu yazılmaz.
> Backend: `mesutbyrm/canlifal` `full-source` @ `7590554` · Mobil: `main` @ `72d7fdfc` (1.0.753+806) · Tarih: 2026-10-09

---

## 1. Mevcut durum (denetim)

### 1.1 Veritabanı (Prisma, 275 model)

**Önemli:** Depoda `prisma/migrations/` klasörü **yok**. Üretim şeması `prisma db push` ile uygulanıyor (bkz. `docs/CANLIFAL_BACKEND_RELEASE_GATE.md`). Bu yüzden her yeni model/alan, Abacus'ta **senin onayınla** `db push` gerektirir. Yalnızca ekleme (yeni tablo / boş geçilebilir alan) yapılacak; mevcut kolon silinmez veya yeniden adlandırılmaz.

| Model | Durum | Not |
|---|---|---|
| `Agency` | VAR | ad, logo, durum (pending/approved/rejected/suspended), `commissionRate` (vars. 5), `level` (bronze…diamond), APS skoru, ceza seviyesi |
| `AgencyUser` | VAR — **eksik** | `userId @unique` → tek aktif ajans garanti. **Ama geçmiş tutulmuyor**: ajans değişince aynı satır güncelleniyor, admin çıkarınca satır **siliniyor** (`admin/agencies/route.ts:266`) |
| `AgencyMemberInvite` | VAR | pending/accepted/rejected/cancelled/expired |
| `AgencyLeaveRequest` | VAR | ayrılma talebi + otomatik ayrılma cron'u |
| `AgencyEarning` | VAR | üye hediye gelirinden ajans komisyonu; uygulanan oran satırda saklanıyor ✅ |
| `AgencyTask` | VAR | haftalık **ajans** hedefi (kazanç/yeni üye/aktif üye). Yayıncı bazlı saat hedefi **yok** |
| `AgencyWallet` + `AgencyWalletTransaction` | VAR | kurumsal Jeton cüzdanı, bakiye önce/sonra, idempotencyKey alanı |
| `AgencyCommissionRule` | VAR | kaynak bazlı (stream_gift, chat_gift…) komisyon kuralları, ajans/global |
| `AgencyBonusRule` | VAR | seviye bazlı yükleme bonusu (bronze %2 … diamond %7) |
| `WithdrawalRequest` | VAR | para çekme: pending → agency_approved → approved → completed / rejected. **`cancelled` yok** |
| `PaymentNotification` | VAR | kullanıcı Jeton/CFC/Gold satın alma bildirimi (havale/Papara), `creditApplied` idempotency bayrağı, durumda `cancelled` var |
| `CfcPaymentRequest` | VAR | CFC satın alma talebi: pending/approved/rejected |
| `VideoStream` | VAR | `startedAt`, `endedAt`, `lastMediaAt` (yayıncı medya heartbeat'i) → **doğrulanmış yayın süresi buradan hesaplanabilir** |
| `Role` / `Permission` / `RolePermission` | VAR | RBAC; `lib/rbac.ts`: `requireAuth`, `requireAdmin`, `requirePermission`, `requireSuperAdmin` |
| `LedgerEntry` | VAR | çift taraflı muhasebe (`recordLedger`) |

**Yok olanlar:** ajans vaatleri/sürümleri ve kabul kayıtları, yayıncı bazlı hedef ve hak ediş, üyelik geçmişi, ajansa özel satın alma politikası (indirim **veya** bonus), ajans satın alma siparişi, ajans içi duyuru, ajans çalışan rolleri (yalnız owner/manager/member var), ajans dağıtım komisyonu kaydı.

### 1.2 Backend uçları (zaten var)

- **Kullanıcı / ajans:** `/api/agency/{my, apply, join, invite, invites, members, leave, earnings, growth, tasks, leaderboard, live-status, withdrawals, wallet, wallet/transfer, invite-earnings, applicant-score/[id]}`
- **Admin:** `/api/admin/{agencies, agencies/[id]/wallet, agencies/[id]/commission, agency-finance, agency-applicant-config, withdrawals, payment-notifications, payment-requests, cfc-payment-requests}`
- **Cron:** `/api/cron/agency-auto-leave`

### 1.3 Ajans Jeton cüzdanı (`lib/agency-wallet.ts`)

- **Yükleme (`topUpWallet`):** Yalnızca admin ucu çağırıyor (`admin/agencies/[id]/wallet`). TL × kur = temel Jeton; üstüne **seviye bonusu** ayrı ledger satırı olarak ekleniyor. Ajansın kendisinin satın alabileceği bir akış **yok**.
- **Aktarım (`transferToUser`):**
  - Var olanlar: bakiye koşullu `updateMany` (yarış koruması ✅), kullanım türü anahtarları (`transfer_member` açık, `transfer_any_user` kapalı), tek işlem üst limiti, bildirim, audit.
  - **Eksik:** komisyon yok, günlük limit yok.
- Admin düzeltme (`adjustWallet`) ve kilit (`isLocked`) var.

### 1.4 Mobil (Flutter `mobile/lib/features/agency/`, 17 dosya)

- **Ekranlar:** başvuru, davetler, talepler, dashboard, haftalık görevler.
- **Bileşenler:** Jeton aktarım sheet'i.
- **Uçlar:** `api_endpoints.dart` 300–316 satırlarında. Rotalar: `/ajans-ol`, `/ajans/{basvur,davetler,dashboard,weekly-tasks,talepler}`.
- **Eksikler:**
  - Ajans keşif sayfası
  - Ajans detay sayfası
  - Yayıncı paneli
  - Performans raporu
  - Vaatler
  - Ajans Jeton satın alma
  - Herhangi bir kullanıcıya Jeton yükleme

### 1.5 Ödeme sistemi

- **Online ödeme sağlayıcısı yok.** Mevcut tek otomatik doğrulama Google Play / App Store IAP (`/api/billing/*/verify`).
- Kullanıcı Jeton/CFC alımı **manuel bildirim** üzerinden yürüyor: `PaymentNotification` → admin onayı → bakiye.

---

## 2. Denetimde bulunan hatalar (mevcut koddaki riskler)

| # | Önem | Yer | Sorun | Önerilen düzeltme |
|---|---|---|---|---|
| H1 | **Kritik** | `api/admin/withdrawals` POST `approve` | Durum kontrolü transaction **dışında**. İki admin aynı anda onaylarsa kullanıcının Jetonu **iki kez düşer**. Onay ile ret yarışında ikisi de yazabilir. | Durum geçişini `updateMany({where:{id, status:{in:[...]}}})` ile koşullu yap; `count !== 1` → 409. Bakiye düşümü de `jetonBalance >= amount` koşullu `updateMany`. Hepsi tek `$transaction`. |
| H2 | Yüksek | `lib/agency-wallet.ts` `transferToUser` / `topUpWallet` | Idempotency yalnızca `findFirst` ile, alanda **unique kısıt yok** → aynı anahtarla eşzamanlı iki istek ikisi de geçer. `balanceBefore/After` transaction **dışında** hesaplanıyor → eşzamanlı işlemlerde ledger yanlış. | Mevcut `beginIdempotent/completeIdempotent` (DB tabanlı, wallet/transfer'de kullanılıyor) ile sarmala; önce/sonra bakiyeyi transaction içinde güncelleme sonrası oku. |
| H3 | Orta | `AgencyUser` | Ajans değişince/çıkarılınca geçmiş kayboluyor (satır güncelleniyor veya **siliniyor**). | Yeni `AgencyMembershipHistory` tablosu; mevcut satır davranışı korunur, her katılma/ayrılmada geçmişe satır yazılır. |
| H4 | Düşük | `WithdrawalRequest` | Kullanıcının kendi talebini iptal etme yolu yok. | Bkz. §5 Aşama 8. |

> H1 ve H2 para kaybına yol açabilecek mevcut hatalar. **Yeni özelliklerden bağımsız olarak önce düzeltilmesini öneririm** (küçük, geriye uyumlu, şema değişikliği yok).

---

## 3. Karar gereken konular (yanıtın gerekiyor)

| # | Soru | Seçenekler | Önerim |
|---|---|---|---|
| K1 | **Ajans komisyonu neyin üzerinden?** Ajans bir kullanıcıya 1000 Jeton yüklediğinde %5 komisyon… | (a) **Ajansın cüzdanından ek Jeton düşer** (1000 + 50; 50 platforma) · (b) **Kullanıcıya net geçer** (950 kullanıcıya, 50 platforma) · (c) **Ajans kazanır** (platform ajansa %5 Jeton/TL öder) · (d) TL satış tutarı üzerinden parasal komisyon | **(a)**. Jeton cinsinden, tek kez, ledger'da ayrı satır; kullanıcı söylenen miktarı tam alır. (c) ve (d) para/vergi niteliği taşır → **muhasebe/hukuk incelemesi gerekir**. |
| K2 | **Ajans Jeton satın alma nasıl ödenecek?** Online ödeme sağlayıcısı yok. | (a) Mevcut **havale/Papara bildirimi** akışı (`PaymentNotification`, yeni ürün türü `agency_jeton`); admin onayında cüzdana yüklenir · (b) Yeni online ödeme entegrasyonu (iyzico/PayTR — sözleşme ve anahtar gerekir) | **(a)**. "Ödeme tamamlanmadan harcanamaz" kuralı doğal olarak sağlanır. Uygulama içi satın alma (IAP) ajans için uygun değil. |
| K3 | **İndirim mi bonus mu?** | Ajans başına politika: `discount` (aynı Jeton daha ucuz TL) **veya** `bonus` (aynı TL'ye fazla Jeton). İkisi birden **asla**. | Politika tablosunda `type` tek değer; mevcut seviye bonusu, ajansa özel politika yoksa varsayılan olarak kalır. Seviye bonusu ile ajans politikası **toplanmaz**; ajans politikası varsa onu geçersiz kılar. |
| K4 | **"Kullanıcıya Jeton Yükle" kime?** | (a) Sadece kendi üyelerine (bugünkü) · (b) Herhangi bir kullanıcıya | Spec (b) istiyor. Mevcut `transfer_any_user` anahtarı ile admin açar/kapatır; günlük limit ve şüpheli işlem uyarısı zorunlu. |
| K5 | **"Ödeme talebi iptali" hangi talepler?** | `WithdrawalRequest` (para çekme), `PaymentNotification` (Jeton/CFC satın alma bildirimi), `CfcPaymentRequest` | Üçü de: yalnız **bekleyen** durumda, koşullu durum geçişiyle. Jeton ve CFC ayrı uçlar/ayrı ekranlar. |
| K6 | **Yayın saati neyi sayar?** | Yalnızca canlı **video** yayını (`VideoStream`) · video + **sesli oda** koltuk süresi | Önce yalnız `VideoStream`. Süre = `endedAt` (yoksa `lastMediaAt`, en fazla şimdi) − `startedAt`. Aynı yayıncının çakışan oturumları birleştirilir. Sesli oda için güvenilir oturum kaydı yok; ayrı iş. |
| K7 | **Şema değişikliği** (yeni tablolar, §4) | Abacus'ta `prisma db push` | Her aşamada yalnızca **ekleme**. Push öncesi sana tam listeyle sorulur. Üretim DB'ye ben dokunmam. |

---

## 4. Veri modeli tasarımı (yalnız ekleme)

Yeni tablolar (hepsi `@@map` ile snake_case, mevcut tablolara dokunmaz):

```
AgencyMembershipHistory  id, agencyId, userId, role, joinedAt, leftAt?, leaveReason?, endedBy?(user|agency|admin|auto)
AgencyStaffRole          id, agencyId, userId, permissions(Json: ["members","invites","reports","announce","wallet_transfer"]), createdById
AgencyPromise            id, agencyId, title, status(draft|pending_review|approved|rejected|archived), currentVersionId?
AgencyPromiseVersion     id, promiseId, version(int), body, targetHoursPerWeek?, minDaysPerWeek?, bonusRule(Json), periodStart, periodEnd,
                         measurement(text), status(pending|approved|rejected), reviewedBy?, reviewedAt?, createdAt   — onaylandıktan sonra DEĞİŞMEZ
AgencyPromiseAcceptance  id, versionId, userId, acceptedAt, ip?, deviceId?   @@unique([versionId,userId])
BroadcasterTarget        id, agencyId, userId, promiseVersionId?, period(daily|weekly|monthly), targetMinutes, startsAt, endsAt
BroadcasterAccrual       id, agencyId, userId, targetId, periodStart, periodEnd, verifiedMinutes, status(earned|pending|paid|void), amount, paidTxnId?
AgencyAnnouncement       id, agencyId, authorId, title, body, createdAt
AgencyPurchasePolicy     id, agencyId @unique, type(discount|bonus), percent, dailyLimitJeton?, active, updatedById
AgencyPurchaseOrder      id, agencyId, packageId, listPriceTl, policyType?, policyPercent?, finalPriceTl, jetonAmount, bonusJeton,
                         paymentNotificationId? @unique, status(pending|paid|cancelled|refunded), idempotencyKey @unique
AgencyDistributionCommission id, agencyId, walletTxnId @unique, baseJeton, rate, commissionJeton, reversedAt?, reversalTxnId?
```

Mevcut tablolara yalnızca boş geçilebilir alan:
- `WithdrawalRequest`: `cancelledAt?`, `cancelledBy?`, `cancelReason?` (durum metni `cancelled` eklenir)
- `CfcPaymentRequest`: aynı üç alan
- `AgencyWalletTransaction`: `idempotencyKey` için `@@unique([agencyId, idempotencyKey])` — **önce üretimde tekrar eden anahtar var mı kontrol edilmeli**; varsa kısıt yerine mevcut idempotency tablosu kullanılır.

## 5. Formüller

- **Satın alma (sunucuda yeniden hesaplanır, istemci değeri yok sayılır):**
  - `listPriceTl = CreditPackage.price`, `jeton = CreditPackage.credits + bonusCredits`
  - `discount`: `finalPriceTl = round2(listPriceTl × (1 − p/100))`, `bonusJeton = 0`
  - `bonus`: `finalPriceTl = listPriceTl`, `bonusJeton = floor(jeton × p/100)`
  - Politika yoksa: `finalPriceTl = listPriceTl`, `bonusJeton = floor(jeton × seviyeBonusu/100)` (bugünkü davranış)
- **Dağıtım komisyonu (K1-a):**
  - `commission = ceil(amount × rate/100)`
  - Cüzdandan `amount + commission` düşer; kullanıcıya `amount` geçer; `commission` platform hesabına yazılır.
  - Oran ve taban satırda saklanır; iadede ters kayıt üretilir.
- **Yayın süresi:**
  - Her `VideoStream` için `[startedAt, min(endedAt ?? lastMediaAt ?? now, now)]` aralığı alınır.
  - Aralıklar dönem sınırlarına kırpılır, çakışanlar birleştirilir (sweep), sonra dakika toplanır.
  - Hedef sağlandı ⇔ `verifiedMinutes ≥ targetMinutes`.

## 6. Yetki matrisi

| İşlem | Kullanıcı | Yayıncı (üye) | Ajans çalışanı | Ajans sahibi | Admin (RBAC) |
|---|---|---|---|---|---|
| Ajans listesi/detay | ✅ | ✅ | ✅ | ✅ | ✅ |
| Başvuru/davet yanıtı | kendi | kendi | — | — | ✅ |
| Üye listesi/performans | — | yalnız kendisi | izin `reports` | kendi ajansı | tümü |
| Davet/üye yönetimi | — | — | izin `members` | ✅ | ✅ |
| Vaat taslağı | — | — | — | ✅ | onay/ret |
| Cüzdan satın alma / yükleme | — | — | izin `wallet_transfer` (yalnız yükleme) | ✅ | denetim + düzeltme |
| Politika/komisyon/limit | — | — | — | — | `agency.finance` izni |

Her ajans ucu `agencyId`'yi oturumdan çözer; istemciden gelen `agencyId` yalnızca admin uçlarında kabul edilir. Testte: A ajansı sahibi B ajansının üyesini/raporunu/cüzdanını göremez (403).

## 7. Uygulama sırası (küçük PR'lar)

| Aşama | İçerik | Şema? | Durum |
|---|---|---|---|
| 0 | Denetim + plan (bu dosya) | — | ✅ |
| 1 | **H1/H2 düzeltmeleri** (çekim onayı atomik, cüzdan idempotency) + yarış testleri | Hayır | Bekliyor (onay) |
| 2 | Üyelik geçmişi + Ajanslar keşif/detay sayfası (gerçek istatistik, admin sıralama ayarı) | Evet (1 tablo) | Bekliyor |
| 3 | Ajans paneli: başvuru/davet akışları, çalışan rolleri, duyurular | Evet | Bekliyor |
| 4 | Vaatler + sürümleme + kabul; yayıncı hedefleri | Evet | K1–K7 sonrası |
| 5 | Performans raporları (doğrulanmış yayın süresi) | Hayır | K6 sonrası |
| 6 | Ajans Jeton satın alma + politika | Evet | K2, K3 sonrası |
| 7 | Herhangi kullanıcıya yükleme + dağıtım komisyonu | Evet | K1, K4 sonrası |
| 8 | Ödeme talebi iptali (çekim, Jeton/CFC bildirimleri) | Evet (alan) | K5 sonrası |
| 9 | Admin Ajans Yönetimi: raporlar, CSV, şüpheli işlem, denetim | Hayır | — |
| 10 | Flutter ekranlarının tamamı + cihaz doğrulaması | — | — |

## 8. Abacus'a uygulanacaklar

Her aşama sonunda buraya eklenir. Şu an: **yok** (kod değişikliği yapılmadı).

## 9. Test sonuçları

Aşama 0'da kod değişikliği yok → test çalıştırılmadı.

## 10. Açık riskler

- Ajansın kullanıcılara Jeton satması ve platformun komisyon alması **elektronik para / ödeme hizmeti** sayılabilir. K1(c)/(d) seçilirse hukuk ve muhasebe görüşü **zorunlu**.
- Vaatlerin bağlayıcılığı (yayıncı ile ajans arasında sözleşme niteliği) için hukuki inceleme ayrı iş olarak gerekir; sistem yalnızca sürüm, kabul ve hak ediş kaydını tutar.
- Şema `db push` ile yönetildiği için geri alma planı: yeni tablolar boş başlar; geri almak gerekirse kod geri alınır, tablolar zarar vermeden kalır.
