# Ajans Yönetimi — Uygulama Raporu

> **Durum: Aşama 1–10 kod olarak tamam.** Aşama 2–5 ve 9 yalnız **yeni tablolar** ekler. Bu tablolar ancak Abacus'ta `prisma db push` çalıştırılınca oluşur (§8). Push'u kullanıcı onaylayıp uygular.
> Gerçek cihaz doğrulaması ve üretim veritabanında yarış testi yapılmadı: **BLOCKED** (§9).
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

**Durum (Aşama 1):** H1 ✅ · H2 ✅ · H4 ✅ (§3.1). H3 şema gerektirir → Aşama 2.

Ek bulunan ve düzeltilen yarışlar:

| # | Yer | Sorun | Düzeltme |
|---|---|---|---|
| H5 | `admin/cfc-payment-requests` approve | Çift onay CFC'yi iki kez yüklüyordu | Koşullu `status:'pending'` geçişi + tek transaction |
| H6 | `admin/payments` approve ↔ reject/cancel | Onay ile ret aynı anda yazabiliyordu; bakiye mutlak değerle yazılıyordu | `creditApplied:false` + durum koşullu `updateMany`; bakiye `increment` |
| H7 | `agency-wallet` `topUpWallet` / `adjustWallet` | Mutlak bakiye yazımı (eşzamanlı işlemde kayıp) | `increment` / koşullu `decrement`; negatife düşemez |
| H8 | `agency/withdrawals` approve/reject | Kullanıcı iptalini ezebiliyordu | Koşullu `status:'pending'` → 409 |

**Henüz düzeltilmedi (bilinen):** `admin/payments` iade yolu (~568. satır) ve elle bakiye düzeltme (~663. satır) hâlâ mutlak değer yazıyor. Yalnız admin kullanır; sonraki aşamada `increment`'e çevrilecek.

---

## 3.1 Kullanıcı kararları (2026-10-09)

| # | Karar | Uygulama |
|---|---|---|
| K1 | Komisyon **yok**. Ajans toplu alımda **admin indirimi** ile daha az TL öder; panelde aldığı Jetonun tamamı görünür; kullanıcıya ne kadar yüklerse **o kadar** düşer. Yetmezse "X jeton eksik". | `transferToUser` komisyonsuz; hata `Ajans bakiyesi yetersiz: N jeton eksik` (sunucu + istemci) |
| K2 | Ajans↔kullanıcı ücreti platform dışında (WhatsApp vb.). Ajans platforma mevcut **havale/Papara bildirimi** ile öder. | `POST /api/agency/purchase` → `PaymentNotification` (`productType: agency_jeton`, notlarda `[agency:<id>]`); admin onayında **ajans cüzdanına** yüklenir (kişisel bakiyeye değil, seviye bonusu yok) |
| K3 | İndirim (bonus değil). | `agency.purchase.discount_pct` (genel) + `agency.purchase.discount_pct.<agencyId>` (ajansa özel), %0–90 |
| K4 | Ajans bakiyesi kadar **herhangi bir kullanıcıya** yükleyebilir. | `transfer_any_user` varsayılan açık; kendi üyesi değilse bu izin kullanılır |
| K5 | İptal üç türde de geçerli. | `POST /api/withdrawals/{id}/cancel`, `/api/payments/notify/{id}/cancel`, `/api/payments/requests/{id}/cancel` — yalnız bekleyen; koşullu geçiş, 409 |
| K6 | Yalnız **video** yayın süresi sayılır; sesli oda ajansın takdirine. | Aşama 5'te (henüz yapılmadı) |

**Formül notu:** Ödenecek = `min(normal fiyat × (1 − indirim%), normal fiyat)`. Örnek: 100.000 Jeton normal 200.000 TL ise %10 indirimle **180.000 TL** (mesajdaki "190.000" örneği %5'e karşılık gelir; oran admin panelinden girilir).

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
| 1 | **H1/H2 düzeltmeleri** (çekim onayı atomik, cüzdan idempotency) + H5–H8 | Hayır | ✅ |
| 2 | Üyelik geçmişi + Ajanslar keşif/detay sayfası (gerçek istatistik, admin sıralama ayarı) + katılma başvurusu | Evet | ✅ kod · db push bekliyor |
| 3 | Ajans paneli: başvuru değerlendirme, çalışan yetkileri, duyurular | Evet | ✅ kod · db push bekliyor |
| 4 | Vaatler + sürümleme + kabul; yayıncı hedefleri + hak ediş | Evet | ✅ kod · db push bekliyor |
| 5 | Performans raporları (doğrulanmış video yayın süresi) | Hayır (hedef/hak ediş tabloları hariç) | ✅ |
| 6 | Ajans Jeton satın alma + indirim | **Hayır** (platformSettings + bildirim notu) | ✅ |
| 7 | Herhangi kullanıcıya yükleme (komisyonsuz) | Hayır | ✅ |
| 8 | Ödeme talebi iptali (çekim, Jeton/CFC bildirimleri) | Hayır (`cancelled` durumu + not) | ✅ |
| 9 | Admin Ajans Yönetimi: vaat onayı, CSV raporlar, şüpheli işlem, ayarlar | Hayır | ✅ |
| 10 | Flutter ekranlarının tamamı + cihaz doğrulaması | — | ✅ ekranlar · cihaz testi BLOCKED |

## 7.1 Aşama 2–10 — uygulananlar

### Yeni tablolar (yalnız ekleme; `Agency`/`User`/mevcut tablolar değişmedi)

| Tablo | Amaç |
|---|---|
| `agency_membership_history` | Her katılma/ayrılma (kim, ne zaman, kim sonlandırdı). AgencyUser silinse de kalır |
| `agency_join_requests` | Kullanıcının ajansa katılma başvurusu (pending/accepted/rejected/cancelled) |
| `agency_staff_permissions` | Çalışana sınırlı yetki: members, invites, reports, announce, targets |
| `agency_announcements` | Ajans içi duyuru (silme = gizleme, kayıt kalır) |
| `agency_promises` / `agency_promise_versions` / `agency_promise_acceptances` | Vaat, değişmez sürümler, kabul kaydı (sürüm + kullanıcı + tarih + IP) |
| `broadcaster_targets` | Yayıncı hedefi (günlük/haftalık/aylık dakika, en az gün, bonus). Değişince eski kapanır |
| `broadcaster_accruals` | Dönem kapanışında hak ediş; `(targetId, periodStart)` benzersiz |

Geçmiş yazımı ana işlemden **sonra** ve en iyi çaba ile yapılır. Tablo yoksa ya da yazım başarısızsa katılma/ayrılma bozulmaz. Bu yazım 8 mevcut noktaya eklendi:
- admin ajans ekle/çıkar/transfer/sahip değiştir
- admin kullanıcı yönetimi
- ajans üye çıkarma
- ayrılma onayı
- davet kabulü
- davet kodu
- otomatik ayrılma

### Doğrulanmış yayın süresi (`lib/agency-performance.ts`)
- **Hangi yayınlar sayılır:** Yalnız `VideoStream` sayılır; `isImageMode` (görsel yayın) sayılmaz.
- **Bitiş zamanı:**
  - Normalde bitiş `endedAt` alanıdır.
  - Yayın sürüyorsa son medya sinyali + 2 dk tolerans, sinyal yoksa şimdiki zaman alınır.
  - Medya, bitişten önce kesilmişse süre son sinyal + 2 dk'da biter ve bu bir "kesinti" sayılır.
- **Aralık işlemleri:**
  - Ajans üyelik dönemlerine ve istenen tarih aralığına kırpılır.
  - Çakışan oturumlar birleştirilir, aynı dakika iki kez sayılmaz.
  - Gün sınırları Türkiye saatine göredir (UTC+3).
- Test: `nextjs_space/scripts/test-agency-performance.ts` → **10/10 geçti** (DB gerektirmez).

### Vaat sürümleme
1. **Taslak:** Ajans sahibi taslak önerir. Bu, sürüm 1'i `pending` durumunda oluşturur ve adminlere bildirim gider.
2. **Yönetici kararı:**
   - Onaylanan sürüm yayımlanır ve artık **değiştirilemez**.
   - Bir önceki onaylı sürüm `superseded` olur.
   - Ret gerekçesi zorunludur.
3. **Yeni şartlar:** Yeni sürüm olarak gönderilir.
   - Aynı vaatte aynı anda tek bekleyen sürüm olabilir.
   - `requiresReaccept` açıksa önceki sürümü kabul etmiş aktif üyelere yeniden kabul bildirimi gider.
   - Eski kabul kayıtları saklanır.
4. **Kabul:**
   - Kabul açık onay ister (`confirm: true`).
   - Yalnız güncel sürüm ve yalnız ajansın aktif üyesi kabul edebilir.
   - Sürümde hedef varsa yayıncıya o sürüme bağlı hedef açılır.
5. **Arşiv:** Arşivlenen vaat yeni üyelere gösterilmez; kabul kayıtları ve hedefler korunur.
6. **Admin sınırları** (`platformSettings`): vaat açık/kapalı, en yüksek bonus, en yüksek hedef dakika, izinli dönemler.

### Hedef ve hak ediş
- **Dönem kapatma:** Kapanmış önceki dönem bir kez değerlendirilir. Benzersiz anahtar sayesinde aynı dönem tekrar kapatılırsa çift kayıt oluşmaz.
- **Ödeme akışı:**
  1. `earned → paying` koşullu geçiş yapılır.
  2. Ajans cüzdanından aktarım yapılır (`idempotencyKey = accrual:<id>`).
  3. Sonuç `paid` olur.
  4. Hata olursa durum `earned`'a döner. Aynı anahtar ikinci kez Jeton aktarmaz.
- **İptal:** Yalnız ödenmemiş hak ediş, gerekçeyle iptal edilir; kayıt kalır.

### Keşif sıralaması
- **Sıralamalar:** önerilen, saat, yayıncı, başarı, seviye, en yeni.
- **Önerilen sıralama:** öne çıkan > seviye > 30 gün saat > yayıncı sayısı.
- **Admin ayarları:** varsayılan sıralama, öne çıkan ajanslar, gizlenen ajanslar.
- Hedef verisi yoksa başarı oranı `null` döner ve ekranda "Hedef verisi yok" yazar. Sahte değer üretilmez.

### Şüpheli işlem kuralları (anlık hesap, kayıt üretmez; eşikler admin ayarı)
- Tek seferde büyük aktarım
- Aynı gün aynı kullanıcıya N+ aktarım
- Günlük toplam çıkış eşiği
- Yeni açılmış hesaba aktarım
- Ajans sahibi/yönetici/çalışanına aktarım
- 3+ iptal edilen toplu sipariş

### Yeni API uçları ve yetkiler

| Uç | Yetki |
|---|---|
| `GET /api/agencies`, `GET /api/agencies/{id}` | Herkes (ilişki bilgisi için oturum isteğe bağlı) |
| `POST/DELETE /api/agencies/{id}/join-request` | Oturum; zaten üye/başka ajansta → 409; en fazla 3 açık başvuru |
| `GET/POST /api/agency/join-requests` | Ajans `members` izni; kabul atomik, tek aktif ajans (`userId` benzersiz) |
| `GET /api/agency/performance`, `/performance/{userId}` | Ajans `reports` izni; yalnız ajansın üyesi olmuş kullanıcı, üyelik dönemine kırpılmış veri; moderasyon kayıtlarında mesaj içeriği yok |
| `GET/POST/DELETE /api/agency/targets` | Okuma `reports`, yazma `targets` |
| `GET/POST /api/agency/accruals` | Okuma `reports`; dönem kapatma `targets`; öde/iptal **yalnız sahip** |
| `GET/POST/DELETE /api/agency/announcements` | Okuma: ajans üyesi; yazma `announce` (saatte en çok 5) |
| `GET/PUT/DELETE /api/agency/staff` | Yalnız sahip; yalnız ajansın aktif üyesine |
| `GET/POST /api/agency/promises` | Okuma `reports`; yazma yalnız sahip |
| `POST /api/agency/promises/{versionId}/accept` | Ajansın aktif üyesi, açık onay |
| `GET /api/agency/broadcaster` | Oturum (kendi verisi) |
| `GET/POST /api/admin/agency-management/promises` | RBAC `agency.manage` |
| `GET /api/admin/agency-management/alerts` | RBAC `agency.report.view` |
| `GET /api/admin/agency-management/reports?type=` | RBAC `agency.report.view`. Tipler: wallet, purchases, performance, accruals, history, acceptances. CSV (UTF-8 BOM, formül enjeksiyonu korumalı) veya JSON; dışa aktarım denetim kaydına yazılır |
| `GET/PUT /api/admin/agency-management/settings` | RBAC `agency.manage` |

Her ajans ucu `agencyId`'yi **oturumdan** çözer (`lib/agency-access.ts`). İstemciden gelen `agencyId` yalnız admin uçlarında kabul edilir.

### Web admin
`/admin/ajans-yonetimi` sayfasının sekmeleri:
- Vaat Onayı (yayındaki sürümle karşılaştırma dahil)
- Şüpheli İşlemler
- Raporlar (CSV)
- Ayarlar

Yönetim merkezine kart eklendi.

### Flutter ekranları

| Rota | Ekran |
|---|---|
| `/ajanslar` | Ajanslar keşfi (sıralama, arama) |
| `/ajanslar/{id}` | Ajans detayı, vaatler, başvuru |
| `/ajans/yayinci` | Yayıncı paneli |
| `/ajans/performans`, `/ajans/performans/{userId}` | Performans ve yayıncı ayrıntısı (hedef ata, hak ediş öde/iptal) |
| `/ajans/basvurular` | Katılma başvuruları |
| `/ajans/vaatler` | Vaatler ve sürüm formu |
| `/ajans/duyurular` | Duyurular |
| `/ajans/hak-edisler` | Hak edişler ve dönem kapatma |
| `/ajans/calisanlar` | Çalışan yetkileri |

**Giriş noktaları:**
- Ajans panelinde "Yönetim" ızgarası
- "Ajans Ol" sayfasında keşif kartı
- "Tüm Özellikler" menüsünde Ajanslar ve Ajans Yayıncı Panelim kutuları

Ana sayfadaki "Ajans Ol" kutusu önceki karar gereği aynı kaldı.

## 8. Abacus'a uygulanacaklar

**Aşama 1+6+7+8:** canlifal#28 ile yayına alındı (şema yok).

**Aşama 2–10 (yeni tablolar → `db push` GEREKLİ, yalnız ekleme):**

1. `full-source` dalını çek
2. `npm install` → `npx prisma generate`
3. **Yedek al**, sonra `npx prisma db push`
   - Yalnız 10 yeni tablo oluşmalı; mevcut tablo/kolon silme veya değiştirme olmamalı.
   - Push "data loss" uyarısı verirse **durdur** ve uygulama.
4. `npm run build` → yeniden başlat
5. **Doğrulama:**
   - `GET /api/agencies` istatistik döner.
   - Kullanıcı başvuru yapar, ajans kabul eder; bu sırada `agency_membership_history`'ye satır yazılır.
   - Vaat taslağı → `/admin/ajans-yonetimi` üzerinden onay → yayıncı kabul eder.
   - Hedef atanır → dönem kapatılır → bonus ödenir; ikinci ödeme denemesi tekrar Jeton aktarmaz.
   - CSV indirilir.

Sıra önemlidir: db push yapılmadan yeni kod çalıştırılırsa yeni uçlar hata döner. Mevcut katılma/ayrılma akışları bozulmaz (geçmiş yazımı en iyi çaba ile yapılır).

## 9. Test sonuçları

- **Aşama 2–10 Flutter:** `dart analyze lib test` → 0 hata · `flutter test` → **2286 geçti**, 2 atlandı
  - `test/features/agency/agency_management_test.dart` (11 test):
    - Modeller: hedef verisi yokken `null`, dakika biçimi.
    - Liste ve 409 mesajı.
    - Vaat kabulü `confirm:true` gönderir.
    - Keşif ekranında "Hedef verisi yok" yazar.
    - Başvuru mesajı gönderilir.
    - Yayıncı paneli: onay vermeden istek gitmez; kalan süre gösterilir.
    - Ajansı olmayan kullanıcıya keşif önerilir.
    - Hedef saat → dakika çevrimi (12,5 → 750).
    - Hak ediş ödeme onayı.
- **Aşama 2–10 backend:**
  - `tsc --noEmit` → yeni hata yok.
  - `scripts/test-agency-performance.ts` → 10/10.
- **Ajanslar arası erişim (A ajansı B'nin verisini göremez):**
  - Kodda: `agencyId` her zaman oturumdan çözülür; yayıncı ayrıntısı yalnız üyelik geçmişi olan kullanıcı için döner.
  - Gerçek DB ile **test edilmedi → BLOCKED**.
- **Aşama 1–8 (önceki):**
  - `test/features/agency/agency_wallet_page_test.dart`: 10.001 / 10.000 → "1 jeton eksik" ve sunucuya istek gitmez; tam miktar seçilen kullanıcıya; sunucu hatası aynen; teklif (%10, 180.000 TL), sipariş, yalnız bekleyen sipariş iptali
  - `test/features/wallet/payment_cancel_datasource_test.dart`: çekim iptali ucu + 409 mesajı; CFC talebi yoksa bildirim iptaline düşme; 400 mesajı aynen
- **Backend:** `tsc --noEmit` → yeni hata yok (önceden var olan: `admin/withdrawals` `@/lib/admin-auth`, `payments/notify` 234. satır)
- **Üretimde çalıştırılmadı:** eşzamanlı çift onay / çift yükleme yarış testi gerçek DB ile **BLOCKED** (deploy sonrası yapılmalı)

## 10. Açık riskler

- Ajansın kullanıcılara Jeton satması ve platformun komisyon alması **elektronik para / ödeme hizmeti** sayılabilir. K1(c)/(d) seçilirse hukuk ve muhasebe görüşü **zorunlu**.
- Vaatlerin bağlayıcılığı (yayıncı ile ajans arasında sözleşme niteliği) için hukuki inceleme ayrı iş olarak gerekir; sistem yalnızca sürüm, kabul ve hak ediş kaydını tutar.
- Doğrulanmış yayın süresi `lastMediaAt` sinyaline dayanır. İstemci heartbeat göndermiyorsa süre `endedAt`'a göre hesaplanır; bu durumda medya kesintisi tespit edilemez.
- Keşif istatistikleri 10 dk önbelleklenir. Çok sayıda ajansta (300+) hesap süresi izlenmeli.
- Sesli oda süresi sayılmıyor (karar K6). Ajans isterse ayrı iş olarak eklenebilir.
- `admin/payments` iade ve elle düzeltme yolları hâlâ mutlak bakiye yazıyor (§2).
- Şema `db push` ile yönetildiği için geri alma planı: yeni tablolar boş başlar; geri almak gerekirse kod geri alınır, tablolar zarar vermeden kalır.
