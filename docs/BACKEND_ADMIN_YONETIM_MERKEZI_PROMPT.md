# Canlifal Backend — Admin / Finans / Jeton / Bildirim Geliştirme Prompt’u

> **Hedef ortam:** canlifal.com üretim (Next.js App Router + Prisma + PostgreSQL, Abacus.ai).  
> **Mobil istemci:** `Cursor-Flutter-` — aynı JWT (`/api/auth/mobile-*`) ve aynı REST uçları.  
> **Bu dosya:** Backend geliştiricisine / Cloud Agent’a yapıştırılacak **tek prompt** + eklenecekler listesi.  
> **Yerel `api/` mirror:** Davranış referansı; üretimle birebir olmayabilir — önce canlifal `full-source` route’larını doğrula.

---

## A. Mevcut sistem özeti (Flutter + mirror analizi)

### Ödeme / jeton (tek tablo modeli — mirror)

| Katman | Detay |
|--------|--------|
| **Tablo** | `CfcPaymentRequest` — hem **CFC** hem **jeton** (`requestType`: `cfc` \| `jeton`) |
| **Durumlar (mirror)** | `pending`, `approved`, `rejected`, `cancelled` |
| **Oluşturma** | `POST` — mobil öncelik: `/api/payments/requests`; yedek: `/api/jeton/payment-request`, `/api/payment/requests` |
| **Bekleyen kontrolü** | `findFirst({ userId, status: "pending", requestType })` → 400 + «Zaten bekleyen bir … ödeme talebiniz var» |
| **Kullanıcı listesi** | `GET /api/payments/requests` (sayfalı) |
| **İptal** | Mirror: `PATCH /api/payment/requests` (`action: cancel`); mobil ayrıca `POST /api/payments/requests/{id}/cancel` dener |
| **Admin listesi** | `GET /api/admin/cfc-payment-requests?status=pending` + `GET /api/admin/payment-requests?status=pending` (mobil ikisini birleştirir) |
| **Onay/red** | `PATCH /api/admin/cfc-payment-requests` (`requestId`, `action`: approve/reject) |
| **Canlı güncelleme** | `GET /api/admin/payments/stream` (SSE) — mobil admin dinler |
| **Denetim** | `PaymentAuditLog` |

### Mobil admin (zaten var — backend verisiyle beslenir)

- `adminPaymentRequestsProvider` — pending birleştirme, limit 50
- `adminPendingPaymentsCountProvider`, `admin_hub_page`, `admin_management_center_page`
- Staff yetki: `StaffAccess` ← `/api/me` + `/api/user/credits` (menü gizleme; **403 sunucuda zorunlu**)
- Hediye test modu: `GiftStaffFinanceMode` → POST `financeMode: staff|real` (sadece yetkili staff)

### Bilinen uyumsuzluk riskleri (jeton «bekleyen var» / admin «boş»)

1. **Farklı POST/GET yolları** — `/api/payments/requests` vs `/api/payment/requests` farklı handler’larda farklı `userId` çözümlemesi (JWT `sub` vs internal `User.id`).
2. **Admin listesi yetkisi** — `requireStaff` reddederse mobil boş liste; kullanıcı tarafında pending kayıt durur.
3. **Status drift** — Oluşturma yalnız `pending` sayar; DB’de `processing`, `awaiting_approval`, boş string vb. varsa admin `status=pending` filtresinde görünmez ama create engeli farklı sorguda kalabilir.
4. **Sayfalama** — Admin `limit=50`; kullanıcıda 51+ pending (veri hatası) görünmez; create yine tek pending kuralıyla bloklar.
5. **İptal yolu** — Kayıt `cancelled` olmadan kalırsa veya iptal farklı tabloda ise orphan pending.
6. **Çift hesap** — Mobil JWT bir `userId`, web oturumu başka; pending A hesabında, admin B kullanıcısına bakıyor.
7. **Otomatik süre dolumu** — Mobil UI 24 saat metni gösterir; mirror’da `cancelExpiredPending()` sunucuya gitmez (yalnız sayım). Süre dolunca **sunucu** pending’i kapatmalı.
8. **Onay idempotency** — Çift PATCH / webhook + manuel onay → çift jeton (mirror’da transaction var; üretimde doğrula).

---

## B. Öncelik 1 — Jeton satın alma «bekleyen ödeme» kök neden çözümü

### Backend görevleri

1. **Tek doğruluk kaynağı servisi**  
   `PaymentRequestService.assertNoBlockingRequest(userId, requestType)`  
   - Bloklayan durumları **tek enum** ile tanımla: örn. `pending`, `processing`, `awaiting_approval` (ürün kararı).  
   - `approved`, `rejected`, `cancelled`, `expired` asla bloklamasın.

2. **409 + yapılandırılmış gövde** (400 yerine tercih edilir; mobil geriye uyumlu parse eder):

```json
{
  "code": "PENDING_PAYMENT_EXISTS",
  "message": "Zaten bekleyen bir jeton ödeme talebiniz var.",
  "existingRequest": {
    "id": "clx…",
    "requestType": "jeton",
    "status": "pending",
    "amount": 100,
    "coins": 500,
    "method": "papara",
    "createdAt": "2026-10-11T12:00:00.000Z",
    "expiresAt": "2026-10-12T12:00:00.000Z"
  }
}
```

3. **Admin listesi = create kontrolü**  
   Aynı `where` koşulu + aynı `userId` join. Admin `GET` için:
   - `includeOrphanPending=true` (opsiyonel, süper admin)
   - `userId` filtre query param
   - `requestType` filtre

4. **Süre dolumu (cron veya scheduled job)**  
   `pending` + `createdAt < now - TTL` → `expired` (veya `cancelled` + audit). TTL: 24h (mobil metinle uyumlu).

5. **Kullanıcı iptali**  
   Tek kanonik uç: `POST /api/payments/requests/{id}/cancel` (mobil bunu kullanıyor).  
   Legacy `PATCH /api/payment/requests` proxy veya deprecate dokümantasyonu.

6. **Teşhis uç noktası (staff)**  
   `GET /api/admin/payment-requests/diagnostics?userId=`  
   Döndür: tüm `CfcPaymentRequest` son 90 gün, hangi kayıt create’i blokluyor, `userId` eşleşmesi, mobil JWT subject.

7. **Idempotent onay**  
   `PATCH approve`: zaten `approved` ise 200 + mevcut kayıt; jeton **ikinci kez** artmasın (`PaymentAuditLog` + unique constraint veya `idempotencyKey`).

8. **Veri onarım migration (non-destructive)**  
   - `status NOT IN (...)` → normalize  
   - `pending` + `createdAt` eski → `expired`  
   - Rapor: kaç kullanıcı etkilendi

### Testler (backend zorunlu)

| # | Senaryo |
|---|---------|
| T1 | Pending yok → POST jeton 201 |
| T2 | Pending var → 409 + `existingRequest.id` |
| T3 | Admin pending listesi T2 ile aynı `id` |
| T4 | Cancel → POST cancel → yeni POST 201 |
| T5 | Expired job → pending yok sayılır |
| T6 | Approve iki kez → jeton bir kez artar |
| T7 | JWT user A, pending user B → A için POST 201 (cross-user leak yok) |
| T8 | `requestType=jeton` pending varken CFC POST (veya tersi) — iş kuralına göre |

### Flutter (deploy backend sonrası — ayrı PR)

- 409 `PENDING_PAYMENT_EXISTS` → banner’da talep no + iptal + destek ref
- `payment_requests_notifier` — sunucu `expiresAt` ile otomatik refresh
- Admin diagnostics deep link (opsiyonel)

---

## C. Öncelik 2 — Admin bildirim merkezi (üst şerit)

### Backend

1. **`GET /api/admin/ops/summary`** (veya mevcut dashboard genişletmesi):

```json
{
  "generatedAt": "ISO",
  "buckets": [
    { "key": "payments_pending", "count": 7, "priority": "critical", "route": "/admin?tab=payments" },
    { "key": "complaints_open", "count": 3, "priority": "high", "route": "/admin/reports" },
    { "key": "membership_pending", "count": 2, "priority": "medium", "route": "/admin/membership" }
  ]
}
```

2. Sayılar **gerçek sorgular** — mock yok. Her bucket için ayrı COUNT (indeksli).

3. **SSE genişletme** — `GET /api/admin/payments/stream` yanında `GET /api/admin/ops/stream` event: `ops_summary_updated`.

4. **RBAC** — Bucket bazında permission: `payments.view`, `complaints.view`, …

5. **Okundu** — `POST /api/admin/notifications/{id}/read` yalnız UI; pending count düşmez.

---

## D. Öncelik 3 — Rol / izin (Süper Admin vs Yönetici)

### Backend (zorunlu)

1. **`StaffPermission` tablosu veya JSON rol matrisi** — örnek: `payments.view`, `payments.approve`, `users.moderate`, …
2. **`requirePermission('payments.approve')`** — her admin PATCH/POST’ta.
3. **`GET /api/me/permissions`** — web + Flutter menü.
4. **Denetim** — `AdminAuditLog`: actorId, action, targetType, targetId, before/after (bakiye), reason.

Flutter zaten UI kapısı kullanıyor; **sunucu 403** olmadan tamamlanmış sayılmaz.

---

## E. Öncelik 4 — Gerçek vs test bakiye

### Backend

1. **`UserBalanceLedger` veya mevcut alanlar:** `jetonBalance` (real), `jetonBalanceTest` (sandbox) — veya ayrı ledger tablosu.
2. **Tüm harcama POST’ları:** `financeMode: real|staff|test` — yalnızca staff JWT + permission `finance.use_test_balance`.
3. **İşlem kaydı:** `ledgerType`, `isTestTransaction` — raporlar `WHERE isTestTransaction = false`.
4. **Hediye** — `financeMode: staff` (mobil mevcut) sunucuda alıcıya jeton yazmamalı (mirror davranışını üretimde doğrula).

---

## F. Modül backlog (admin merkezi — backend uçları)

| Modül | Eklenecek / netleştirilecek API |
|--------|----------------------------------|
| Kullanıcı komuta merkezi | `GET /api/admin/users/{id}/360` — profil, bakiye, pending payments, şikayetler, audit (PII kısıtlı) |
| Şikayetler | `GET/PATCH /api/admin/complaints` — durum makinesi, assignee, lock |
| Canlı / sesli | Mevcut TRTC + oda/yayın listeleri; `POST /api/admin/moderation/actions` |
| Finans raporları | `GET /api/admin/finance/summary?from&to&granularity` — jeton satış/harcama/yükümlülük ayrımı |
| Üyelik | Pending membership payments admin bucket |
| Yarışmalar | `Competition` CRUD + leaderboard + idempotent reward payout |
| Ajans | Mevcut ajans uçları + admin aggregate |
| Sistem sağlığı | `GET /api/admin/health` — DB, queue, webhook failures (mevcut metrikler) |

---

## G. Scroll / route state (web ağırlıklı)

- Next.js: `sessionStorage` + route state (`?tab=&page=&q=`) veya mevcut admin layout restore.
- Flutter: `admin_preferences_provider` genişlet — modül bazlı scroll offset + filter JSON (hassas veri yok).
- Backend gerekmez; yalnız liste API’lerinde tutarlı pagination.

---

## H. Yayınlama ve geri dönüş

1. Migration + backfill script (staging)
2. Diagnostics endpoint deploy
3. TTL job deploy
4. 409 response deploy (mobil uyum)
5. RBAC kademeli açılış
6. Rollback: enum genişletmesi geri alınmaz; job disable + eski create sorgusu feature flag

---

## I. Backend agent’a yapıştırılacak kısa prompt (Türkçe)

```
Canlifal.com (Next.js + Prisma) canlı backend’inde çalış.

ÖNCELİK 1: Kullanıcılar jeton satın alırken «Zaten bekleyen bir ödeme talebiniz var» alıyor
ama admin panelinde pending görünmüyor. Kök neden analizi yap:
- CfcPaymentRequest (veya üretimdeki eşdeğer tablo) üzerinde create vs admin list vs GET /api/payments/requests
  aynı userId ve status filtresini kullanıyor mu?
- JWT/mobile auth userId ile User.id eşleşmesini doğrula.
- Orphan pending, status drift, pagination, farklı endpoint handler’larını kontrol et.

Düzelt:
- Tek PaymentRequestService ile bloklayan status seti.
- POST create: pending yoksa 201; varsa 409 + existingRequest { id, status, amount, createdAt, expiresAt }.
- Admin GET pending ile create aynı WHERE.
- POST /api/payments/requests/{id}/cancel + 24h TTL job → expired/cancelled.
- PATCH approve idempotent; çift jeton yok; PaymentAuditLog.
- GET /api/admin/payment-requests/diagnostics?userId= (staff).

ÖNCELİK 2: GET /api/admin/ops/summary + ops SSE; gerçek count’lar; RBAC.

ÖNCELİK 3: Granüler permissions + requirePermission her hassas route’ta + AdminAuditLog.

ÖNCELİK 4: Test/sanal bakiye ledger; financeMode staff/test; raporlardan hariç.

Mevcut hediye, SSE, TRTC, ödeme onay akışlarını kırma. Yıkıcı DB değişikliği yapma; migration + rollback yaz.
T1–T8 integration testlerini ekle. Secret/PII loglama.

Referans mobil sözleşme: Cursor-Flutter- docs/CFC_ODEME_API.md, ApiEndpoints.paymentRequests,
adminPaymentRequestsProvider birleştirme mantığı.
```

---

## J. Flutter repo’da backend deploy sonrası yapılacaklar (checklist)

- [ ] 409 `PENDING_PAYMENT_EXISTS` UI + pending banner eşlemesi
- [ ] Admin ops summary provider + hub üst şerit
- [ ] `/api/me/permissions` ile StaffAccess hizalama
- [ ] Test bakiye seçimi (staff only) — sunucu onaylı
- [ ] Kabul testleri §16 (18 madde) — staging canlifal.com

---

**Son güncelleme:** 2026-10-11 · Backend **PR #39–#40** `full-source` merge edildi → Flutter rehber: [`CANLIFAL_YENi_ENDPOINTLER_FLUTTER_REHBER.md`](CANLIFAL_YENi_ENDPOINTLER_FLUTTER_REHBER.md)
