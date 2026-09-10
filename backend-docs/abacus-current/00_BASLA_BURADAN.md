# CanlıFal — Devir Paketi · BURADAN BAŞLA

Bu paket, projeyi **Cursor**'a (ve mobil taraf için **Flutter**'a) devretmek için gereken her şeyi
12 numaralı klasöre ayırarak içerir. Tek tek dosya aramana gerek yok.

---

## EN KOLAY YOL (önerilen)

Cursor zaten **tüm depoyu** açtığı için dosyaları tek tek taşımana gerek yoktur. Gerçekte yapman gereken:

1. Projeyi Cursor'da aç.
2. `mcp-server/` klasöründe bir kez `npm install` çalıştır.
3. `.cursor/mcp.json` içindeki **mutlak yolu** kendi bilgisayarındaki proje yoluna göre düzelt.
4. Cursor'u yeniden başlat → MCP sunucusu bağlanır, Cursor 731 uç, 468 OpenAPI yolu, 193 model ve
   58 servis üzerinde doğrudan arama yapabilir.
5. `CURSOR_DEVIR_PROMPT.md` dosyasını Cursor sohbetine yapıştır.

Bu paket ise; depoyu taşıyamadığın, parça parça paylaşmak istediğin ya da Flutter ekibine
sadece ilgili dosyaları vermek istediğin durumlar için hazırlandı.

---

## KLASÖR HARİTASI

| Klasör | İçerik | Ne zaman gerekir |
|---|---|---|
| `01_mcp-server/` | MCP sunucusu (`index.mjs`, `lib.mjs`, `package.json`, README, örnek ayar), `_cursor_ayari/mcp.json`, `.project_instructions.md` | **İlk kurulum.** Cursor'un projeyi tanımasını sağlar |
| `02_docs_oncelik1/` | Veri modeli, uç standardı, API, hata kodları, yetkiler, feature flag, güvenlik + `ENDPOINTS.md`, `openapi.json`, `schema.prisma`, `DATABASE_REFERENCE.md` | **Her zaman.** Cursor'a verilecek ilk döküman seti |
| `03_docs_oncelik2/` | Ajans, gerçek zamanlı olaylar, backend mimarisi, performans, remote config, WebRTC, hediye sistemi, müzik API | Yayın/hediye/ajans ile ilgili iş yaparken |
| `04_docs_oncelik3/` | Test planları, release gate, yük testi, turnuva + `postman_collection.json`, `endpoints_index.json`, `database_schema.sql`, denetim raporu | Test/dağıtım aşamasında |
| `05_para_birimi_cekirdek/` | `currency-branding.ts`, `currency-branding-context.tsx`, `referral-commission.ts`, `agency-commission.ts`, `currency-amount.tsx`, `jeton.svg`/`cfc.svg`, `schema.prisma`, `seed.ts` | Para birimi ekonomisine dokunan **her** iş |
| `06_destek_lib/` | `ledger.ts`, `rate-limit-guard.ts`, `cache.ts`, `mobile-auth.ts`, `auth-options.ts`, `check-feature.ts` | Yeni uç yazarken |
| `07_public_api/` | `currency-branding`, `user/wallet`, `user/referral-earnings`, `agency/invite-earnings`, `bana-ozel`, `bana-ozel/open`, `withdrawals`, `daily-login`, `gifts/lucky/send`, `games/room`, `games/sos` | Mobil/web istemci akışları |
| `08_admin_api/` | `currency-settings`, `topup-bonus-tiers` (+`[id]`), `referral-commission` (+`settings`), `credits`, `cfc-payment-requests`, `settings`, `currency-config` | Yönetici paneli işleri |
| `09_kullanici_sayfalari/` | `bana-ozel`, `oyunlar`, `jeton`, `kazanc`, `davet` sayfaları + kök `layout.tsx` | Kullanıcı arayüzü değişiklikleri |
| `10_admin_sayfalari/` | `admin`, `admin/currency-settings`, `admin/referral-commission`, `admin/settings` sayfaları + iki yönetici bileşeni | Yönetici arayüzü değişiklikleri |
| `11_gorunum_bilesenleri/` | `theme-aware-chrome`, `canlidark-home`, `navbar`, `fortune-access-gate`, `game-shell`, `floating-profile`, `bana-ozel-section`, `bana-ozel-popup` | Bakiye gösteren yüzeyler / menü değişiklikleri |
| `12_flutter/` | **`FLUTTER_ENTEGRASYON_PROMPT.md`** (yeni, para birimi ekonomisi) + `mevcut_dokumanlar/` (8 resmi Flutter dökümanı) | Mobil uygulamanın backend ile birebir çalışması için |

Kökteki iki rehber:

- **`CURSOR_DEVIR_PROMPT.md`** — Cursor sohbetine olduğu gibi yapıştırılacak devir promptu.
- **`CURSOR_DOSYA_YOLLARI.md`** — tüm dosyaların depo içindeki gerçek yolları ve açıklamaları.

---

## KURULUM SIRASI

1. `01_mcp-server/` → MCP kurulumu + `.project_instructions.md` okutulur.
2. `CURSOR_DEVIR_PROMPT.md` → Cursor sohbetine yapıştırılır.
3. `02_docs_oncelik1/` → bağlam olarak eklenir.
4. Yapılacak işe göre `05`–`11` arasından ilgili klasör eklenir.
5. Mobil taraf için `12_flutter/FLUTTER_ENTEGRASYON_PROMPT.md` Flutter projesinde ayrıca yapıştırılır.

---

## PARA BİRİMİ KURALI (özet)

| Birim | Alan | Çevrilebilir | Kullanım |
|---|---|---|---|
| **Jeton** | `User.jetonBalance` | ✅ | Hediye, yayın, sesli görüşme, misafirlik gelirleri; jeton yüklemelerinin ajans komisyonu |
| **CFC** | `User.credits` | ❌ | Fal/Tarot, Bana Özel, oyunlar, Şanslı Hediye, referans komisyonu, günlük ödüller |

Jeton asla ödül olarak verilmez; ama gelir jetondur. CFC paraya çevrilemez.
Para birimi **isimleri, ikonları ve renkleri yönetici panelinden değiştirilebilir** — hiçbir yerde sabit yazma.

---

## DİKKAT EDİLECEK TUZAKLAR

- **"Bana Özel" üç kopya halinde var.** Gerçekte `/bana-ozel` adresinde render edilen dosya
  `app/[lang]/bana-ozel/page.tsx`'tir; diğer ikisi (`bana-ozel-section.tsx`, `bana-ozel-popup.tsx`)
  başka yüzeylerde kullanılır. Değişiklik yaparken **üçünü birden** güncelle.
- **Aktif tema `canlidark` iken üst menü `navbar.tsx` değildir.** `theme-aware-chrome.tsx` bu temada `null`
  döndürür; menü `canlidark-home.tsx` içindedir. Yeni menü öğesi **her ikisine** eklenmelidir.
- `prisma/schema.prisma` bir **sembolik bağlantı**dır; silme/yeniden oluşturma. Bu pakete içeriği kopyalanmıştır.
- Veritabanı geliştirme ve canlı ortam tarafından **paylaşılır**; yalnızca ekleme yönünde şema değişikliği yap.
- Paket **eskimiş** dökümanları bilinçli olarak içermez (`CANLIFAL_PHASE*_REPORT.md`, `B1_*`, `STAGE*`,
  `API_PARITY_*`) — Cursor'a verme, yanlış yönlendirir.
- `mcp-server/` klasöründe bağımlılıklar **yoktur**; bir kez `npm install` gerekir
  (projenin geri kalanı yarn kullanır, bu klasör tek istisnadır).