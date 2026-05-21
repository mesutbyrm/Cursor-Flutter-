# canlifal.com — Jeton yükleme sayfaları

Mobil uygulamadaki jeton ödeme ekranlarının web karşılığı bu repoda hazır: **`site/jeton/`**

## Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `site/jeton/index.html` | Tüm ekranlar (mağaza, ödeme yöntemi, WhatsApp, Papara, Havale) |
| `site/jeton/assets/jeton.css` | Koyu mor tema (mockup ile uyumlu) |
| `site/jeton/assets/jeton.js` | API: `/api/jeton`, `/api/payment/config`, `/api/payment/requests` |

## canlifal.com’a ekleme

### Seçenek A — Statik yayın

1. `site/jeton/` klasörünü sunucuya kopyalayın (ör. `public/jeton-yukle/`).
2. URL: `https://canlifal.com/jeton-yukle/` → `index.html`
3. `index.html` içinde `<meta name="api-base" content="https://canlifal.com" />` doğru olsun.

### Seçenek B — Next.js sayfa

`app/jeton-yukle/page.tsx`:

```tsx
export default function JetonYuklePage() {
  return (
    <iframe
      src="/jeton/index.html"
      title="Jeton Yükle"
      style={{ width: '100%', minHeight: '100vh', border: 'none' }}
    />
  );
}
```

Veya `jeton.css` + `jeton.js` import edip HTML yapısını JSX’e çevirin.

## Gerekli API (sunucuda)

| Metot | Yol |
|-------|-----|
| GET | `/api/jeton` — paket listesi |
| GET | `/api/payment/config` — WhatsApp, Papara, IBAN |
| POST | `/api/payment/requests` — jeton talebi |
| GET | `/api/user/credits` — bakiye (oturum) |
| GET | `/api/auth/session` veya `/api/user/profile` — kullanıcı adı |

### Jeton talebi body

```json
{
  "requestType": "jeton",
  "method": "papara",
  "packageId": "p1000",
  "packageTitle": "1000 Jeton",
  "coins": 1000,
  "priceTry": 500,
  "notes": "Jeton yükleme · papara"
}
```

Admin onayında `user.coins` artmalı (`requestType === "jeton"`).

## Veritabanı

`CfcPaymentRequest` tablosuna alanlar: `requestType`, `packageId`, `packageTitle`, `coins`, `priceTry` (repodaki `api/prisma/schema.prisma`).

## Ödeme ayarları

Admin veya `.env`:

- `CFC_WHATSAPP` / `PAYMENT_WHATSAPP`
- `CFC_PAPARA` / `PAYMENT_PAPARA`
- `CFC_IBAN`, `CFC_BANK`, `CFC_HOLDER`

`GET /api/payment/config` bu değerleri döner.

## Mobil ile uyum

Flutter `/jeton-store` aynı API’yi kullanır. Web ve mobil aynı pending talep kuralını paylaşır (kullanıcı başına tek `pending`).
