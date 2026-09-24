# Backend — Kritik 3 Görev (Sprint 1 — 1 Hafta)

**Güncellenme:** 2026-09-24  
**Gönderen:** Flutter API Compatibility Audit  
**Aciliyet:** 🔴 **KRITIK — 1 HAFTA**

---

## 📋 Özet

Bu 3 görev **long-lived real-time** özelliklerin ve **yayıncı listesi** performansının temelini oluşturur.

| # | Görev | Etki | Başla |
|---|-------|------|-------|
| **1** | SSE Token Refresh | Real-time kesintisi | Hemen |
| **2** | N+1 Query (FortuneTeller) | Performance -50% | Hemen |
| **3** | Cache Headers | Network +50% trafikten tasarruf | Hemen |

---

## 🔴 **KRİTİK 1: SSE Token Refresh Mekanizması**

### Sorun
SSE bağlantısı sırasında (`/api/chat/rooms/{roomId}/stream`, `/api/video-streams/{streamId}/stream`, vb.) **token geçerliliği sona ererken**, client 401 hatası alıyor ve bağlantı **otomatik olarak yenilenmemiş** oluyor.

### Senaryolar
1. **Chat odası 30+ dakika açık:** Token expire (7 gün) → SSE bağlantı kesilir
2. **Canlı yayın izleme sırasında:** Yayın başında token refresh yapılmış, 6 gün 23 saat sonra token expire → bağlantı kesilir
3. **24/7 bot:** Durmaksızın SSE açık → günde 1 kez token expire

### Teknik Gereksinim
**Endpoint:** `POST /api/auth/mobile-refresh`

```json
Request:
{
  "refreshToken": "eyJhbGc..."
}

Response:
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": { ... }
}
```

### Beklenen Davranış
```
SSE Bağlantısı Açık (30+ gün)
        ↓
    401 Hatası
        ↓
  POST /api/auth/mobile-refresh (refreshToken ile)
        ↓
  accessToken güncelle
        ↓
  SSE yeniden bağlan (yeni token ile)
        ↓
  Seamless (kullanıcı fark etmez)
```

### İmplementasyon Checklist
- [ ] `/api/auth/mobile-refresh` endpoint'i mevcut ve çalışıyor mu?
- [ ] Refresh token validation'ı güvenli mi?
- [ ] Old access token kırılıyor mu? (security)
- [ ] Response'da yeni `accessToken` + `refreshToken` döndürülüyor mu?
- [ ] Refresh başarısızsa (expired refresh token), login gerekli

### Test
```bash
# 1. SSE bağlantısı aç (curl ile)
curl -H "Authorization: Bearer $OLD_TOKEN" \
  https://canlifal.com/api/chat/rooms/room123/stream

# 2. Bekleme sırasında token manual expire et (dev ortamında)

# 3. Refresh endpoint çağır
curl -X POST https://canlifal.com/api/auth/mobile-refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "'$REFRESH_TOKEN'"}'

# 4. Yeni token'le SSE yeniden bağlan
# → Bağlantı düzgün çalışmalı
```

### Dokümantasyon
**Kılavuz:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §7.5 (Token Refresh)

---

## 🔴 **KRİTİK 2: N+1 Query — FortuneTeller Listesi**

### Sorun
`GET /api/fortune-tellers?page=1&online=true` endpoint'i çağrıldığında:

```
İstek 1: SELECT * FROM FortuneTeller WHERE online=true LIMIT 10
İstek 2-11: (Her falcı için) SELECT COUNT(*) FROM Review WHERE tellerId=?
────────────────────────
TOPLAM: 11 istek (1 + 10)
```

**Sonuç:** 10 falcı listelemek 11 database sorgusu → **2x yavaş**

### Etki
- FortuneTeller lisesi yükü: ~1.5s → ~3s
- Mobile app'te `fortuneTellers` provider timeout yapabiliyor
- User experience kötüleşiyor

### Çözüm Seçenekleri

#### **Seçenek A: Review'ları Response'a Dahil Et (Önerilen)**

**Response Şu An:**
```json
[
  {
    "id": "teller123",
    "displayName": "Melike Falcı",
    "isOnline": true,
    "rating": 4.8
  }
]
```

**Response Olması Gereken:**
```json
[
  {
    "id": "teller123",
    "displayName": "Melike Falcı",
    "isOnline": true,
    "rating": 4.8,
    "reviewCount": 245,
    "reviews": [
      {
        "id": "rev1",
        "rating": 5,
        "comment": "Çok doğru!",
        "createdAt": "2026-09-23T10:30:00Z"
      }
    ],
    "reviewStats": {
      "count": 245,
      "avgRating": 4.8,
      "lastReviewDate": "2026-09-24T08:00:00Z"
    }
  }
]
```

**SQL Query:**
```sql
SELECT 
  ft.*,
  COUNT(r.id) as reviewCount,
  AVG(r.rating) as avgRating,
  MAX(r.createdAt) as lastReviewDate
FROM FortuneTeller ft
LEFT JOIN Review r ON ft.id = r.tellerId
WHERE ft.online = true
GROUP BY ft.id
LIMIT 10;
```

**Avantaj:** 1 sorgu, N+1 yok, **performance +200%**

#### **Seçenek B: Separate Aggregation Endpoint**

```
GET /api/fortune-tellers/{tellerId}/stats
Response: { reviewCount, avgRating, ... }
```

**Dezavantaj:** Flutter'da 2 endpoint çağırılması gerekir (N+1 devam ediyor)

#### **Seçenek C: Database Index + Query Optimization**

Review count'ı cache table'da tutuş:

```sql
CREATE TABLE FortuneTellerStats (
  tellerId UUID,
  reviewCount INT,
  avgRating DECIMAL,
  lastReviewDate TIMESTAMP,
  updatedAt TIMESTAMP,
  PRIMARY KEY (tellerId)
);
```

**Trigger:** Review insert/delete → FortuneTellerStats update

### İmplementasyon Checklist
- [ ] Hangi seçeneği kullanacaksınız?
- [ ] SQL query yazılıp test edildi mi?
- [ ] Performance test yapıldı mı? (10 falcı < 200ms)
- [ ] Migration yazılıp rollback planı var mı?
- [ ] Flutter client'a bildir (response şeması değişti)

### Test
```bash
# 1. Eski sorgu zamanı ölç
time curl -H "Authorization: Bearer $TOKEN" \
  https://canlifal.com/api/fortune-tellers?page=1&online=true

# 2. Sonra database log'u kontrol et (kaç sorgu çalıştı?)
# Expected: 11 (1 + 10)

# 3. Fix uygulandıktan sonra
time curl ...
# Expected: 1 sorgu, ~100ms

# 4. Review verisi varsa doğrula
# jq '.[] | {id, displayName, reviewCount}'
```

### Dokümantasyon
**Kılavuz:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9.5 (FortuneTeller Repository)

---

## 🔴 **KRİTİK 3: Cache-Control Headers**

### Sorun
Statik veya seyrek değişen kaynaklar (`/api/gifts/types`, `/api/credit-packages`, `/api/fortune-request-types`) her istek'te **hiçbir cache** yapılmıyor.

**Sonuç:** Network trafiği %50 artık, app açılış yavaş, data kullanımı fazla

### Çözüm

Aşağıdaki endpoint'lere `Cache-Control` header ekle:

#### **1. Public — 1 Gün Cache**
```
GET /api/gifts/types
GET /api/credit-packages
GET /api/fortune-request-types
GET /api/memberships
GET /api/leaderboards
GET /api/celebrities
GET /api/blog
GET /api/site-animations/active

Response Header:
Cache-Control: public, max-age=86400
```

**Neden:** Değişmesi 1 gün arası nadir, tüm users aynı veriyi görebilir

#### **2. Private — 5 Dakika Cache**
```
GET /api/user/profile
GET /api/user/wallet
GET /api/user/credits
GET /api/notifications
GET /api/user/followers
GET /api/user/following

Response Header:
Cache-Control: private, max-age=300
```

**Neden:** User-specific veri, 5 dakika stale olabilir

#### **3. No-Cache (Per-Request)**
```
GET /api/chat/rooms/{roomId}/messages
GET /api/video-streams/{streamId}/comments
GET /api/social/posts
POST /api/messages

Response Header:
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
```

**Neden:** Real-time veri, cache yapılmamalı

#### **4. ETag Support (Opsiyonel)**
```
Response Header:
ETag: "abc123def456"
Cache-Control: private, max-age=300

Sonraki Request:
If-None-Match: "abc123def456"

Server Response (304 Not Modified):
HTTP 304
```

### HTTP Headers Tablosu

| Endpoint | Cache Type | TTL | Header |
|----------|-----------|-----|--------|
| `/api/gifts/types` | Public | 1d | `public, max-age=86400` |
| `/api/credit-packages` | Public | 1d | `public, max-age=86400` |
| `/api/user/profile` | Private | 5m | `private, max-age=300` |
| `/api/notifications` | No-Cache | - | `no-cache, no-store, must-revalidate` |
| `/api/chat/rooms/{id}/messages` | No-Cache | - | `no-cache, no-store, must-revalidate` |

### İmplementasyon Checklist (Next.js API)

```typescript
// pages/api/gifts/types.ts
export default async function handler(req, res) {
  // Public cache 1 gün
  res.setHeader('Cache-Control', 'public, max-age=86400');
  
  const gifts = await db.giftType.findMany();
  res.json(gifts);
}

// pages/api/user/profile.ts
export default async function handler(req, res) {
  // Private cache 5 dakika
  res.setHeader('Cache-Control', 'private, max-age=300');
  
  const user = await db.user.findUnique({ where: { id: req.user.id } });
  res.json(user);
}

// pages/api/chat/rooms/[roomId]/messages.ts
export default async function handler(req, res) {
  // No cache
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  
  const messages = await db.chatMessage.findMany({...});
  res.json(messages);
}
```

### Test
```bash
# 1. Header kontrol
curl -I https://canlifal.com/api/gifts/types
# Expected: Cache-Control: public, max-age=86400

# 2. Browser dev tools'de Network tab'ında kontrol
# Size sütununda "from cache" görülmeli

# 3. Android/iOS cihazda şu komutla kontrol
# Logcat/Xcode Network profiler
```

### Dokümantasyon Yeri
Yeni dosya oluştur: `docs/BACKEND_CACHE_STRATEGY.md`

```markdown
# Backend Cache Strategy

## Public Cache (1 day)
- /api/gifts/types
- /api/credit-packages
- ...

## Private Cache (5 min)
- /api/user/profile
- ...

## No-Cache
- /api/chat/rooms/{id}/messages
- ...
```

---

## 📊 **Tamamlama Kontrol Listesi**

### KRİTİK 1: SSE Token Refresh
- [ ] Endpoint `/api/auth/mobile-refresh` mevcut
- [ ] 401 hatasında token refresh logic'i
- [ ] Bağlantı yeniden kurma
- [ ] Test (30+ gün SSE açık → token refresh)
- [ ] Flutter'a bildir

### KRİTİK 2: N+1 Query
- [ ] SQL sorgusu optimize edildi
- [ ] Response şeması güncellendi
- [ ] Database migration yapılıp test edildi
- [ ] Performance test: 10 falcı < 200ms
- [ ] Flutter'a API şeması bildir

### KRİTİK 3: Cache Headers
- [ ] Tüm public endpoint'lere header eklendi
- [ ] Private endpoint'ler doğru header'la
- [ ] No-cache endpoint'ler no-store ile işaretlendi
- [ ] ETag support (opsiyonel)
- [ ] Browser/mobile cache test edildi

---

## 📞 İletişim

**Flutter Team (Bu Dosyayı Gönderdikten Sonra):**
- SSE Token Refresh uygulandı mı?
- N+1 Query düzeltildi mi? (API response şeması değişti mi?)
- Cache Headers eklendi mi?

**Test Sonrası:**
- Flutter'a pull request + release notes gönderin
- APK derleme başlat (`main` branch'e merge)
- User test ortamında doğrula

---

**Başlama Tarihi:** 2026-09-24  
**Beklenen Bitiş:** 2026-10-01  
**Aciliyet:** 🔴 KRITIK

