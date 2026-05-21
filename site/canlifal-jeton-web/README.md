# canlifal.com — Jeton yükleme sayfaları (mockup)

Bu klasör, attığınız **görsellerdeki** jeton ödeme ekranlarının canlifal.com Next.js sitesine **birebir** eklenmesi içindir.

## Neden sitede görünmüyordu?

- **canlifal.com kaynak kodu bu Flutter reposunda değil.** `site/jeton/` sadece statik HTML referansıydı; sunucuya yüklenmedi.
- https://canlifal.com/jeton-yukle şu an **404** veriyor.

## canlifal.com’a ekleme (5 dakika)

1. canlifal.com **web projesini** açın (Next.js App Router).
2. Şu dosyaları kopyalayın:

| Buradan | canlifal.com projesine |
|---------|-------------------------|
| `app/jeton-yukle/page.tsx` | `app/jeton-yukle/page.tsx` |
| `components/JetonCheckout.tsx` | `components/jeton/JetonCheckout.tsx` (veya aynı yol) |
| `lib/jeton-api.ts` | `lib/jeton-api.ts` |
| `app/globals.css` içindeki jeton stilleri | `globals.css` veya `jeton.module.css` |

3. `JetonCheckout.tsx` import yolunu güncelleyin: `@/lib/jeton-api`
4. Menüde / profilde link ekleyin: `/jeton-yukle`
5. Deploy edin.

## Yerel önizleme

```bash
cd site/canlifal-jeton-web
npm install
NEXT_PUBLIC_SITE_URL=https://canlifal.com npm run dev
```

http://localhost:3100/jeton-yukle

## Gerekli API (canlifal.com sunucusunda)

- `GET /api/jeton`
- `GET /api/payment/config`
- `GET /api/user/credits` (oturum)
- `POST /api/payment/requests` (`requestType: "jeton"`)

Referans backend: repo kökündeki `api/src/routes/wallet.ts`
