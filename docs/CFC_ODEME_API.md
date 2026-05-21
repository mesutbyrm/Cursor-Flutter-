# CFC (CanlıFal Coin) ÖDEME SİSTEMİ API DOKÜMANTASYONU

**Base URL:** `https://canlifal.com`  
**Kimlik doğrulama:** Oturum açık kullanıcı — `Authorization: Bearer <token>` veya site çerezi (NextAuth).

Mobil uygulama ve yerel `api/` bu sözleşmeyi uygular.

---

## 1) GET `/api/user/credits`

Kullanıcının kredi, jeton ve CFC bakiyeleri.

| | |
|---|---|
| **Auth** | Gerekli |

**200 OK:**

```json
{
  "credits": 50,
  "jetonBalance": 100,
  "cfcBalance": 0,
  "jetonTlRate": 0.5,
  "withdrawalLimit": 0,
  "membership": "basic",
  "membershipExpiresAt": null
}
```

| Alan | Tip | Açıklama |
|------|-----|----------|
| `credits` | int | Kredi bakiyesi |
| `jetonBalance` | int | Jeton bakiyesi |
| `cfcBalance` | int | CFC bakiyesi |
| `jetonTlRate` | float | 1 Jeton = X TL |
| `withdrawalLimit` | int | Çekim limiti |
| `membership` | string | `basic` \| `premium` \| `gold` |
| `membershipExpiresAt` | string \| null | ISO tarih |

**Hatalar:** `401` `{ "error": "Oturum açmanız gerekiyor" }` · `404` `{ "error": "Kullanıcı bulunamadı" }`

---

## 2) GET `/api/payment/config`

CFC yükleme ödeme bilgileri (WhatsApp, Papara, banka).

| | |
|---|---|
| **Auth** | Gerekli |

**200 OK:**

```json
{
  "whatsappNumber": "+905xxxxxxxxx",
  "paparaAddress": "1234567890",
  "bankName": "Ziraat Bankası",
  "bankIban": "TR00 0000 0000 0000 0000 0000",
  "bankAccountHolder": "Ad Soyad",
  "cfcRate": 1.0,
  "minCfcAmount": 10
}
```

**NOT:** Admin ayarlamadıysa alanlar `""` olabilir.

**401:** `{ "error": "Oturum açmanız gerekiyor" }`

---

## 3) POST `/api/payment/requests`

Yeni **CFC yükleme** talebi.

| | |
|---|---|
| **Auth** | Gerekli |
| **Content-Type** | `application/json` |

**Body:**

```json
{
  "amount": 100,
  "method": "papara",
  "senderInfo": "Ali Yılmaz",
  "notes": "Papara ile gönderdim"
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `amount` | int | Evet | CFC miktarı, min 1 |
| `method` | string | Evet | `whatsapp` \| `papara` \| `bank_transfer` |
| `senderInfo` | string | Hayır | Gönderen ad/telefon |
| `notes` | string | Hayır | Ek not |

**201:** Oluşturulan `CfcPaymentRequest` (`status: pending`, `reviewedBy`/`reviewNote`: null).

**400:** `Geçersiz miktar` · `Geçersiz ödeme yöntemi` · `Zaten bekleyen bir ödeme talebiniz var`

**NOT:** Kullanıcıda aynı anda yalnızca bir `pending` talep. Talep oluşunca admin/yönetici/moderatör/destek/yardım rollerine bildirim gider.

---

## 4) GET `/api/payment/requests`

Kullanıcının kendi talepleri (son 50).

| | |
|---|---|
| **Auth** | Gerekli |

**200:** JSON dizi — her öğe 3. maddedeki yapı + `status`: `pending` \| `approved` \| `rejected`.

---

## 5) GET `/api/admin/cfc-payment-requests`

Admin paneli — tüm CFC talepleri.

| | |
|---|---|
| **Auth** | Staff: `admin`, `yonetici`, `moderator`, `destek`, `yardim` |

**Query:** `status` (`all` \| `pending` \| `approved` \| `rejected`, varsayılan `all`) · `page` (varsayılan 1) · `limit` (varsayılan 20)

**200:**

```json
{
  "requests": [
    {
      "id": "clx…",
      "userId": "clx…",
      "amount": 100,
      "method": "papara",
      "senderInfo": "Ali Yılmaz",
      "notes": null,
      "status": "pending",
      "reviewedBy": null,
      "reviewNote": null,
      "createdAt": "2026-05-21T15:00:00.000Z",
      "updatedAt": "2026-05-21T15:00:00.000Z",
      "user": {
        "id": "clx…",
        "name": "Ali Yılmaz",
        "username": "aliyilmaz",
        "email": "ali@example.com",
        "image": "https://…"
      }
    }
  ],
  "total": 45,
  "page": 1,
  "totalPages": 3
}
```

**403:** `{ "error": "Yetkiniz yok" }`

---

## 6) PATCH `/api/admin/cfc-payment-requests`

Talebi onayla veya reddet.

**Body:**

```json
{
  "requestId": "clxxxxxxxxxxxxxxxxxxxx",
  "action": "approve",
  "reviewNote": "Ödeme alındı"
}
```

| `action` | Davranış |
|----------|----------|
| `approve` | `status → approved`, `user.cfcBalance += amount`, kullanıcıya **CFC Yükleme Onaylandı** bildirimi |
| `reject` | `status → rejected`, **CFC Yükleme Reddedildi** (+ `reviewNote` sebep) |

**200:** Güncellenmiş talep.  
**400:** `Geçersiz istek` · `Bu talep zaten işlenmiş`  
**404:** `Talep bulunamadı`

---

## 7) GET `/api/admin/cfc-settings`

**200:**

```json
{
  "cfc_whatsapp_number": "+905xxxxxxxxx",
  "cfc_papara_address": "1234567890",
  "cfc_bank_name": "Ziraat Bankası",
  "cfc_bank_iban": "TR00 0000 0000 0000 0000",
  "cfc_bank_account_holder": "Ad Soyad",
  "cfc_tl_rate": "1",
  "cfc_min_amount": "10"
}
```

---

## 8) POST `/api/admin/cfc-settings`

Toplu güncelleme — gönderilen alanlar güncellenir (hepsi opsiyonel).

**200:** `{ "success": true }`

---

## Veritabanı

**User:** `cfcBalance Int @default(0)`

**CfcPaymentRequest:** `id`, `userId`, `amount`, `method`, `senderInfo?`, `notes?`, `status`, `reviewedBy?`, `reviewNote?`, `createdAt`, `updatedAt`

**CfcSettings:** `cfc_whatsapp_number`, `cfc_papara_address`, `cfc_bank_*`, `cfc_tl_rate`, `cfc_min_amount`

---

## Bildirim tipleri (`/api/notifications`)

| type | Alıcı |
|------|--------|
| `cfc_payment_request` | Admin staff (yeni talep) |
| `cfc_payment_approved` | Kullanıcı |
| `cfc_payment_rejected` | Kullanıcı |

**data (JSON string):** `{ "paymentRequestId", "amount", "method" }`

---

## Rol sistemi

**Yönetim:** `admin`, `yonetici`, `moderator`, `destek`, `yardim`  
**Kullanıcı (`user`):** credits, config, talep oluşturma, kendi talepleri listesi

---

## Premium üyelik

### `GET /api/membership/packages`

**200:** `packages`, `currentMembership`, `daysRemaining`, `jetonBalance`, `cfcBalance`

### `POST /api/membership/purchase`

**Body:** `{ "tierId": "gold" }` — jeton düşer, bonus jeton eklenir, üyelik süresi uzar.

---

## Mobil uygulama

| Ekran | Route |
|-------|--------|
| Cüzdan merkezi | `/wallet` |
| CFC yükle | `/cfc-store` |
| Jeton mağazası | `/jeton-store` |
| Gold / Premium üyelik | `/premium-membership` |
| Admin | `/admin` |

Sürüm: **1.0.28+30**
