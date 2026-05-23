# canlifal.com — Sizin yapmanız gerekenler

Uygulama varsayılan olarak **https://canlifal.com** adresine bağlanır. Aşağıdakiler **canlifal.com sunucusundaki** web/API projesine eklenmelidir (bu Flutter repo’sundaki `api/` klasörü sadece yerel/test içindir).

## 1. Veritabanı (kullanıcı tablosu)

Her kullanıcı kaydında şu alanlar olmalı:

| Alan | Açıklama |
|------|----------|
| `cfcBalance` veya `cfc` | CFC jeton bakiyesi (sayı, varsayılan 0) |
| `role` | `user`, `admin`, `yonetici`, `moderator`, `destek`, `yardim` |

Mevcut jeton alanı genelde `coins` / `credits` — uygulama hem `jeton` hem `coins` okur.

## 2. API uçları (JSON)

Aynı oturum (NextAuth çerezi) ile çalışmalı:

| Metot | Yol | Açıklama |
|-------|-----|----------|
| GET | `/api/user/credits` | `{ jeton, cfc, cfcBalance, role, coins, credits }` |
| GET | `/api/jeton` | Oturumlu: `{ "packages": [{ "id", "title", "coins", "priceTry" }] }` — boş/eksikse uygulama varsayılan paket gösterir |
| GET | `/api/payment/config` | WhatsApp, Papara, IBAN bilgileri |
| POST | `/api/payment/requests` | CFC (`amount`) veya **jeton** (`requestType: "jeton"`, `coins`, `packageId`, `packageTitle`, `priceTry`, `method`) |
| GET | `/api/notifications` | Kullanıcı bildirimleri |
| PATCH | `/api/notifications/:id/read` | Okundu işaretle |
| GET | `/api/social/posts` | Sosyal akış (`fortuneType`, `isAutoShare`, `fortuneCount`, `viewCount`) |
| POST | `/api/social/posts` | Manuel paylaşım |
| POST | `/api/social/posts/auto-fortune` | Fal sonucu otomatik paylaşım (`fortuneSlug`, `summary`, `detail?`) |
| DELETE | `/api/social/posts/:id` | Gönderi sil (yazar veya admin) |
| GET | `/api/admin/payment-requests` | Sadece yetkili roller |
| GET | `/api/admin/notifications` | Sadece yetkili roller |

Bildirim kaydında mümkünse: `type`, `targetPath`, `targetId`, `title`, `body`, `read`.

## 3. Ödeme bilgileri (site ayarları)

Admin panelinde veya `.env` içinde tanımlayın:

- **WhatsApp numarası** (ör. `905551234567`)
- **Papara adresi**
- **Banka / IBAN / hesap sahibi** (havale/EFT)

Kullanıcı uygulamadan talep açınca:

1. Talep veritabanına yazılsın  
2. Tüm `admin`, `yonetici`, `moderator`, `destek`, `yardim` kullanıcılarına bildirim gitsin  
3. Site yönetim bildirim panelinde görünsün  

## 4. Yetkili kullanıcılar

Profilde **Yönetim** bölümünün çıkması için kullanıcının `role` alanı yukarıdaki rollerden biri olmalı (küçük harf, Türkçe isimler: `yonetici`, `moderator`, `destek`, `yardim`).

## 5. Tam API dokümantasyonu

**[CFC_ODEME_API.md](./CFC_ODEME_API.md)** — CFC (CanlıFal Coin) ödeme sistemi: tüm uçlar, JSON örnekleri, bildirim akışı.

## 6. Jeton yükleme web arayüzü

Hazır sayfalar: **`site/jeton/`** (mağaza, ödeme yöntemi, WhatsApp, Papara, Havale). Kurulum: **`docs/SITE_JETON_KURULUM.md`**.

## 7. Bu repodaki referans

Yerel/test için aynı mantık: `api/src/routes/wallet.ts`, `api/src/routes/notifications.ts`, `api/prisma/schema.prisma`.

---

**Özet:** APK’yı GitHub’dan indirmeniz yeterli; canlifal.com’a sadece yukarıdaki API + veritabanı alanlarını eklerseniz uygulama üretimde jeton/CFC, ödeme talebi ve admin paneli tam çalışır. Eklemezseniz uygulama açılır ama bu özellikler boş veya hata verebilir.
