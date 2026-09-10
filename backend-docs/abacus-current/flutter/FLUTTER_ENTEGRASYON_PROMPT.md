# CanlıFal — Flutter Entegrasyon Promptu (Para Birimi Ekonomisi)

> Bu dosyayı Flutter projesinde Cursor/Claude'a **olduğu gibi yapıştır**.
> Amaç: mobil uygulamanın backend ile **birebir aynı** para birimi kurallarını uygulaması.
> Yanındaki `mevcut_dokumanlar/` klasöründe backend'in resmi Flutter sözleşmeleri var; bu dosya onların
> **para birimi ekonomisi** bölümünü günceller ve tamamlar.

---

## 0) Bağlam

CanlıFal iki para birimi kullanır:

| Birim | Veritabanı alanı | Çevrilebilir mi? | Nerede kullanılır |
|---|---|---|---|
| **Jeton** | `User.jetonBalance` | ✅ Evet — TL'ye çekilebilen **tek** birim | Hediye, canlı yayın, sesli görüşme, misafirlik gelirleri; jeton yüklemelerindeki ajans komisyonu |
| **CFC** | `User.credits` | ❌ Hayır | Fal/Tarot, Bana Özel, oyunlar, Şanslı Hediye (hem bahis hem kazanç), referans komisyonu, günlük/görev ödülleri |

**Altın kural:** Jeton asla ödül olarak dağıtılmaz ama **gelir** jetondur. CFC ödül/harcama birimidir ve paraya çevrilemez.

`User.cfcBalance` alanı **eski (legacy)** alandır; yeni kodda kullanma, sadece raporlamada `legacyCfc` olarak görünür.

---

## 1) Kimlik doğrulama — çift mod

Backend'deki cüzdan/ekonomi uçları **iki** kimlik yöntemini birden destekler:

1. Mobil JWT → `Authorization: Bearer <token>` (mobil uygulamanın kullanacağı yöntem)
2. Web oturum çerezi (fallback)

Flutter tarafında **her zaman** `Authorization: Bearer` başlığını gönder. Kimlik yoksa uçlar `401` döner.

```dart
final headers = {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
};
```

---

## 2) `GET /api/currency-branding` — İSİMLERİ ASLA SABİT YAZMA

Para birimlerinin **adı, ikonu ve rengi yönetici panelinden değiştirilebilir.** Flutter'da `"Jeton"` / `"CFC"`
metinlerini hardcode etmek yasaktır. Uygulama açılışında bu ucu çağır, sonucu önbelleğe al (ör. `SharedPreferences`),
her ekranda oradan oku.

Kimlik gerektirmez. Yanıt:

```json
{
  "jeton": {
    "key": "jeton",
    "name": "Jeton",
    "nameEn": "Jeton",
    "icon": "/currency/jeton.svg",
    "color": "#F5C542",
    "convertible": true
  },
  "cfc": {
    "key": "cfc",
    "name": "CFC",
    "nameEn": "CFC",
    "icon": "/currency/cfc.svg",
    "color": "#A78BFA",
    "convertible": false
  },
  "rules": { "convertible": ["jeton"], "rewardCurrency": "cfc" }
}
```

Notlar:

- `icon` **göreli** bir yoldur → tam URL = `"$baseUrl" + icon`. SVG'dir, `flutter_svg` ile çiz.
- `name` Türkçe, `nameEn` İngilizce arayüz içindir; cihaz diline göre seç.
- `color` hex'tir, rozet/çip arka planı ve ikon tonu için kullan.
- Uç erişilemezse yukarıdaki varsayılanlara düş, uygulamayı kilitleme.

Önerilen Flutter modeli:

```dart
class CurrencyBrand {
  final String key, name, nameEn, icon, color;
  final bool convertible;
  const CurrencyBrand({required this.key, required this.name, required this.nameEn,
      required this.icon, required this.color, required this.convertible});
  factory CurrencyBrand.fromJson(Map<String, dynamic> j) => CurrencyBrand(
        key: j['key'], name: j['name'], nameEn: j['nameEn'],
        icon: j['icon'], color: j['color'], convertible: j['convertible'] == true,
      );
}
```

Tek bir `CurrencyAmount` widget'ı yaz (ikon + biçimli sayı + isteğe bağlı ad) ve **tüm** bakiye/ücret
gösterimlerinde onu kullan. Sayı biçimi: `tr_TR` binlik ayracı.

---

## 3) `GET /api/user/wallet` — Bakiye & Kazanç ekranının tek kaynağı

Kimlik gerekir. Sorgu parametreleri: `limit` (varsayılan 25, en fazla 100), `offset`, `currency` = `all|cfc|jeton`.

Yanıt şeması:

```json
{
  "balances": { "cfc": 55, "jeton": 0, "legacyCfc": 0 },
  "branding": { "jeton": { ... }, "cfc": { ... } },
  "rules": {
    "convertible": ["jeton"],
    "nonConvertible": ["cfc"],
    "note": "CFC paraya çevrilemez; yalnızca Jeton bakiyesi çekilebilir."
  },
  "earnings": {
    "referralCreditsEarned": 0,
    "tellerEarnings": 0
  },
  "referralCode": "ABC123",
  "withdrawal": {
    "canWithdraw": false,
    "minWithdrawal": 3000,
    "maxWithdrawal": 0,
    "jetonTlRate": 0.5,
    "estimatedTl": 0,
    "pending": null,
    "history": []
  },
  "transactions": [ { "id": "c_...", "...": "..." } ],
  "total": 3,
  "limit": 25,
  "offset": 0
}
```

Kritik detaylar:

- `transactions` iki tablonun **birleşimidir**: CFC hareketleri `c_` önekli, jeton hareketleri `j_` önekli `id` taşır.
  Tarihe göre azalan sıralıdır. Sayfalama için `offset`/`limit` kullan, `total` toplam satır sayısıdır.
- `earnings` içinde komisyon özeti + `referralCreditsEarned` + `tellerEarnings` gelir.
- `withdrawal.canWithdraw` ve `tellerEarnings` **kullanıcı kaydında değil, falcı kaydında** tutulur. Yani normal
  kullanıcıda `canWithdraw: false` gelir → mobilde para çekme panelini kilitli göster, gizleme.
- `estimatedTl = jetonBalance * jetonTlRate` (backend hesaplar, mobilde yeniden hesaplama).

Web'deki muadili `/kazanc` sayfasıdır; mobil ekranı onunla aynı bilgi mimarisinde kur:
ikili bakiye kartı → kazanç özeti → para çekme paneli → sayfalı işlem geçmişi.

---

## 4) Para çekme — yalnızca Jeton

`POST /api/withdrawals` gövdesi:

```json
{ "amount": 5000, "method": "bank_transfer", "accountDetails": "...", "currency": "jeton" }
```

- `currency` **her zaman** `"jeton"`. CFC ile çekim talebi oluşturma seçeneği arayüzde bile bulunmamalı.
- `amount` ≥ `withdrawal.minWithdrawal` olmalı; `maxWithdrawal > 0` ise onu da aşmamalı.
- `method`: `bank_transfer` veya `papara`.
- Bekleyen talep varsa (`withdrawal.pending != null`) yeni talep formunu kapat, bekleyen talebi göster.

---

## 5) Bana Özel — CFC → Jeton → Reklam zinciri

`POST /api/bana-ozel/open` bir kutu/ürün açar. Ödeme sırası backend'de sabittir:

1. CFC (`credits`) yeterliyse CFC düşülür.
2. Değilse Jeton (`jetonBalance`) düşülür.
3. İkisi de yetmiyorsa **reklam izleyerek ücretsiz** açılır.

Yetersiz bakiyede **HTTP 402** döner:

```json
{
  "error": "...",
  "required": 2,
  "current": 0,
  "cfcBalance": 0,
  "jetonBalance": 0,
  "canWatchAd": true,
  "adRemaining": -1,
  "adUnlimited": true
}
```

Flutter akışı:

- 402 + `canWatchAd == true` → reklam modalı aç, ödüllü reklam tamamlanınca **aynı isteği** `{"useAd": true}` ile tekrarla.
- `adUnlimited == true` ise `adRemaining` `-1` gelir → "sınırsız" göster, sayaç yazma.
- `adUnlimited == false` ise `adRemaining` kalan hakkı verir; 0 ise reklam seçeneğini gizle.
- Günlük reklam limiti yönetici ayarıdır (`bana_ozel_ad_daily_limit`, varsayılan `0` = sınırsız). Mobilde sabitleme.

Başarılı yanıt (200) `paymentMethod` alanı taşır: `"cfc" | "jeton" | "ad"`. Sonuç ekranındaki metni buna göre yaz:
"Reklam ile ücretsiz açıldı" / "X CFC harcandı" / "X Jeton harcandı" — birim adını **branding'den** al.

`GET /api/bana-ozel` liste yanıtı hem `cfcBalance` hem `jetonBalance` döner; üstte **iki ayrı** markalı bakiye çipi göster.

---

## 6) Oyunlar & Şanslı Hediye — CFC

- Oyun bahisleri ve kazançları **CFC** üzerinden işler.
- Şanslı Hediye'de hem bahis hem kazanç CFC'dir; yanıtta `currency: 'cfc'` gelir.
  Geriye dönük uyumluluk için `betJetons`, `wonJetons`, `newBalance` alan adları korunmuştur —
  **isimlerine aldanma, bunlar CFC değerleridir.** Arayüzde birimi `currency` alanından oku.

---

## 7) Referans & Ajans komisyonları

- **Referans komisyonu** (kullanıcı → kullanıcı daveti): her zaman **CFC**.
- **Ajans davet komisyonu**: yüklemenin para birimine bağlıdır. Jeton yüklemesi → komisyon **Jeton**;
  diğer tüm yüklemeler → komisyon **CFC**.
- Canlı yayın / sesli sohbet / misafirlik komisyonları **Jeton**.
- Komisyon bildirimlerinin hedefi `/kazanc` sayfasıdır; mobilde bu bildirime tıklanınca Bakiye & Kazanç ekranını aç.

Kazanç dökümü için: `GET /api/user/referral-earnings` ve `GET /api/agency/invite-earnings`.

---

## 8) Yükleme bonusu kademeleri

Yüklemelerde otomatik bonus uygulanır (yönetici tarafından düzenlenebilir). Varsayılan kademeler:

| Alt sınır | Bonus |
|---|---|
| 10.000 | %5 |
| 25.000 | %7 |
| 50.000 | %10 |

Bonus **backend'de** hesaplanır. Flutter yüzdeyi yeniden hesaplamaz; yükleme ekranında kademeleri bilgilendirme
amaçlı gösterecekse backend'den gelen değerleri kullanır.

---

## 9) Yapılacaklar listesi (Flutter tarafı)

- [ ] `CurrencyBrandingService` — açılışta `/api/currency-branding`, önbellek + varsayılana düşme.
- [ ] `CurrencyAmount` widget'ı (ikon + sayı + ad, renk brandingden) — tüm bakiye yüzeylerinde kullan.
- [ ] Ana ekran / profil / oyun / Bana Özel başlıklarında **iki ayrı** bakiye çipi (CFC + Jeton).
- [ ] `WalletScreen` → `/api/user/wallet`, sayfalı işlem geçmişi + `all/cfc/jeton` filtresi.
- [ ] Para çekme formu, yalnızca jeton, min/max doğrulaması, bekleyen talep durumu.
- [ ] Bana Özel açılışında 402 + reklam zinciri, `useAd: true` yeniden deneme.
- [ ] Hiçbir yerde sabit `"Jeton"` / `"CFC"` metni kalmamalı (arama yaparak doğrula).
- [ ] Çevrilebilirlik rozeti: `convertible` alanına göre "Çekilebilir" / "Çekilemez".

---

## 10) Ek kaynaklar (bu klasörde)

`mevcut_dokumanlar/` içinde:

| Dosya | İçerik |
|---|---|
| `CANLIFAL_FLUTTER_BACKEND_CONTRACT.md` | Mobil ↔ backend genel sözleşme |
| `CANLIFAL_FLUTTER_DELIVERY_CHECKLIST.md` | Mobil teslim kontrol listesi |
| `CANLIFAL_CROSS_PLATFORM.md` | Web/mobil davranış farkları |
| `CANLIFAL_FLUTTER_RESMI_SERVIS_ENTEGRASYONU.md` | Resmi servis entegrasyonları |
| `FLUTTER_INTEGRATION.md` | Temel entegrasyon rehberi |
| `FLUTTER_TAM_ENTEGRASYON_PROMPT.md` | Kapsamlı entegrasyon promptu |
| `FLUTTER_BACKEND_ENTEGRASYON_PROMPT.md` | Backend odaklı entegrasyon promptu |
| `FLUTTER_CANLI_FALCILAR_TRTC_HEDIYE_PROMPT.md` | Canlı yayın + TRTC + hediye akışı |

Uç listesinin tamamı: `../02_docs_oncelik1/ENDPOINTS.md` ve `../02_docs_oncelik1/openapi.json`
(Postman koleksiyonu: `../04_docs_oncelik3/postman_collection.json`).

> **Çelişki kuralı:** Bu dosya ile eski Flutter dokümanları para birimi konusunda çelişirse **bu dosya geçerlidir**.
