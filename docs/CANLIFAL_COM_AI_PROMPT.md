# canlifal.com — kopyalanabilir AI / geliştirici prompt’u

Aşağıdaki metni olduğu gibi canlifal.com projesine yapıştırın.

---

```
# Görev: canlifal.com — anlık OneSignal push bildirimleri (Flutter mobil ile uyumlu)

## Bağlam

- Mobil uygulama: Flutter, API tabanı `https://canlifal.com`, Android paket `com.mesutbyrm.canlifal`
- Push SDK: OneSignal (istemci). Girişte `OneSignal.login(kullaniciId)` — `kullaniciId` = sitedeki kullanıcı primary id (cuid / Mongo id / Prisma User.id, hangisi mobil `/api/me` ve profilde dönüyorsa AYNI string)
- REST API Key yalnızca sunucuda; APK veya frontend’e KONMAZ
- Mobil bildirime tıklayınca `additionalData` içindeki `targetPath`, `targetId`, `type` ile yönlendirme yapıyor

## OneSignal kimlik bilgileri (sunucu .env)

ONESIGNAL_APP_ID=578518ed-7b16-46a9-a1e6-7692d3ba55d8
ONESIGNAL_REST_API_KEY=<Dashboard → Settings → Keys & IDs → App API Key, os_v2_app_...>

Firebase: OneSignal panelinde Google Android (FCM) bağlı olmalı; paket adı `com.mesutbyrm.canlifal`

## Yapılacaklar

1. Sunucuda tek bir `sendPushToUser(userId, { title, body, type, targetPath, targetId, urgent })` helper yaz (OneSignal REST POST `https://api.onesignal.com/notifications`)
2. Aşağıdaki API olaylarından SONRA (DB kaydı başarılıysa) push tetikle — uygulama kapalıyken de gelsin (`priority: 10`, `android_channel_id: "canlifal_urgent"`, `ios_interruption_level: "active"` urgent için)
3. İsteğe bağlı: mevcut uygulama içi bildirim tablosuna da kayıt (mobil `GET /api/notifications` ile uyumlu)
4. Hata durumunda ana işlemi bozma; push fire-and-forget, logla

## Tetiklenecek olaylar

### A) Yeni direkt mesaj
- **Ne zaman:** `POST /api/messages/conversations/:id/messages` (veya sitedeki eşdeğer DM endpoint) başarılı, alıcı ≠ gönderen
- **Kime:** mesajın alıcısı (`recipientId`)
- **Push:**
  - title: gönderen adı veya "Yeni mesaj"
  - body: mesaj önizlemesi (max 120 karakter)
  - type: `message`
  - targetPath: `/chat/{conversationId}`
  - targetId: conversationId
  - urgent: true

### B) Jeton veya CFC ödeme talebi (admin onayı)
- **Ne zaman:** `POST /api/payment/requests` — talep `pending` oluşturuldu
- **Kime:** rolü şunlardan biri olan TÜM kullanıcılar: `admin`, `yonetici`, `moderator`, `destek`, `yardim` (ve mobilde admin paneli açılan hesaplar)
- **Push:**
  - jeton: title `Jeton ödemesi — onay bekliyor`, type `jeton_payment_request`
  - cfc: title `CFC ödemesi — onay bekliyor`, type `cfc_payment_request`
  - body: örn. `1000 Jeton · papara` veya `50 CFC · whatsapp`
  - targetPath: `/admin`
  - targetId: paymentRequestId
  - urgent: true

### C) Ödeme onay / red (kullanıcıya)
- **Ne zaman:** admin `PATCH /api/admin/cfc-payment-requests` (veya eşdeğeri) `approve` / `reject`
- **Kime:** talep sahibi `userId`
- **Push onay:**
  - jeton: title `Jeton Yükleme Onaylandı`, body `{coins} jeton hesabınıza eklendi.`, type `jeton_payment_approved`, targetPath `/jeton-yukle`
  - cfc: title `CFC Yükleme Onaylandı`, type `cfc_payment_approved`, targetPath `/cfc-store`
- **Push red:** title `Jeton/CFC Yükleme Reddedildi`, type `*_rejected`, targetPath uygun mağaza
- targetId: paymentRequestId, urgent: true

### D) Canlı yayın başladı
- **Ne zaman:** yayıncı yayını başlattı (`POST /api/video-streams` veya yayın status `live` oldu)
- **Kime:** yayıncıyı takip eden kullanıcılar (Follow tablosu / eşdeğeri), max 500 kişi batch
- **Push:**
  - title: `{yayıncıAdı} canlı yayında`
  - body: yayın başlığı
  - type: `live`
  - targetPath: `/live`
  - targetId: streamId
  - urgent: true
- **Mobil uyum:** Flutter yayın oluşturduktan sonra `POST /api/video-streams/:streamId/live-started` çağırıyor; bu uç yoksa ekle veya yayın create içinde takipçi push’unu tetikle

## OneSignal REST gövde şablonu

```json
{
  "app_id": "<ONESIGNAL_APP_ID>",
  "target_channel": "push",
  "include_aliases": { "external_id": ["<siteUserId>"] },
  "headings": { "en": "<title>", "tr": "<title>" },
  "contents": { "en": "<body>", "tr": "<body>" },
  "priority": 10,
  "android_channel_id": "canlifal_urgent",
  "ios_interruption_level": "active",
  "data": {
    "type": "<type>",
    "targetPath": "<targetPath>",
    "targetId": "<targetId>",
    "title": "<title>",
    "body": "<body>"
  }
}
```

Authorization header: `Key <ONESIGNAL_REST_API_KEY>` (Bearer değil)

## Mobil ile uyum kontrol listesi

- [ ] `/api/me` dönen `id` = OneSignal `external_id` (mobil login aynı id)
- [ ] Staff rolleri mobil `staff_access` ile aynı (`admin`, `yonetici`, …)
- [ ] `GET /api/notifications` liste uçuğu çalışıyor (push yanında in-app liste)
- [ ] Ödeme talebi: `requestType` jeton/cfc ayrımı mobil ile uyumlu

## Referans implementasyon (self-hosted API, aynı mantık)

GitHub repo `mesutbyrm/Cursor-Flutter-` içinde:
- `api/src/lib/onesignal.ts` — REST client
- `api/src/lib/push_events.ts` — mesaj / ödeme / canlı
- `api/src/routes/messages.ts`, `wallet.ts`, `video_streams.ts` — hook noktaları
- `docs/CANLIFAL_COM_PUSH.md`

## Teslim

- Değişen dosyaların listesi
- Hangi endpoint’lere hook eklendiği
- `.env.example` güncellemesi
- Manuel test adımları (mesaj, jeton talebi admin’e, onay kullanıcıya, canlı takipçiye)
```

---

_Üretim API anahtarını bu dosyaya veya repoya yazmayın._
