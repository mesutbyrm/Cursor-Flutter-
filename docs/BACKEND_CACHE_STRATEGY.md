# Backend Cache Strategy — Canlifal Platform

**Güncelleme:** 2026-09-24  
**Durum:** Sprint 1 Task 3 İçin Hazırlanmış  
**Amaç:** Response header caching politikası tanımlaması ve implementasyonu  
**Başlama:** 2026-09-24 | **Hedef Bitiş:** 2026-09-26

---

## 📋 Özet

Bu dokümantasyon, Canlifal backend'inde standart cache stratejisini tanımlar. Tüm API endpoint'leri 3 kategoriye ayrılır:
1. **PUBLIC** — 1 gün cache (statik kaynaklar)
2. **PRIVATE** — 5 dakika cache (user-specific veri)
3. **NO-CACHE** — Per-request (real-time veri)

---

## 🎯 Hedefler

✅ **Ağ trafiğinde %20 tasarruf** (cache sayesinde)  
✅ **Mobil app açılış hızı %30 daha hızlı** (cached assets)  
✅ **Database yükü %15 azalır** (tekrarlayan sorgular eliminated)  
✅ **User experience** — offline-first capability  

---

## 📊 Cache Kategorileri ve Kuralları

### 1️⃣ PUBLIC CACHE — 1 Gün (86400 saniye)

**Özellikler:**
- Değişmesi 24 saat arası nadir
- Tüm users aynı veriyi görür
- CDN'de cacheable
- ETag desteği opsiyonel ama önerilen

**HTTP Header:**
```
Cache-Control: public, max-age=86400
ETag: "hash-of-content"
```

**Endpoint'ler:**

| Endpoint | Açıklama | TTL |
|----------|----------|-----|
| `GET /api/gifts/types` | Hediye türleri listesi | 1d |
| `GET /api/credit-packages` | Kredi paketleri | 1d |
| `GET /api/fortune-request-types` | Fal talep türleri | 1d |
| `GET /api/memberships` | Üyelik türleri | 1d |
| `GET /api/leaderboards` | Liderlik tablosu | 1d |
| `GET /api/celebrities` | Ünlü falcılar | 1d |
| `GET /api/blog` | Blog yazıları | 1d |
| `GET /api/site-animations/active` | Aktif animasyonlar | 1d |
| `GET /api/countries` | Ülke listesi | 1d |
| `GET /api/languages` | Dil listesi | 1d |

**Implementation (Next.js):**
```typescript
// pages/api/gifts/types.ts
export default async function handler(req, res) {
  // Public cache 1 gün
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.setHeader('ETag', generateETag(data));
  
  // Conditional request check
  if (req.headers['if-none-match'] === getETag()) {
    res.status(304).end();
    return;
  }
  
  const gifts = await db.giftType.findMany();
  res.json(gifts);
}
```

---

### 2️⃣ PRIVATE CACHE — 5 Dakika (300 saniye)

**Özellikler:**
- User-specific veri
- 5 dakika içinde eski olabilir (acceptable staleness)
- Sadece private caches'de tutulur (browser, app)
- Public proxies'de cachlenemez

**HTTP Header:**
```
Cache-Control: private, max-age=300
Vary: Authorization
```

**Endpoint'ler:**

| Endpoint | Açıklama | TTL |
|----------|----------|-----|
| `GET /api/user/profile` | Kullanıcı profili | 5m |
| `GET /api/user/wallet` | Kullanıcı cüzdanı | 5m |
| `GET /api/user/credits` | Kredi bakiyesi | 5m |
| `GET /api/notifications` | Bildirimler | 5m |
| `GET /api/user/followers` | Takipçiler | 5m |
| `GET /api/user/following` | Takip edilenler | 5m |
| `GET /api/user/bookmarks` | Yer işaretleri | 5m |
| `GET /api/user/history` | Görüntüleme geçmişi | 5m |

**Implementation (Next.js):**
```typescript
// pages/api/user/profile.ts
export default async function handler(req, res) {
  // Verify auth
  const userId = req.user.id;
  if (!userId) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  
  // Private cache 5 dakika
  res.setHeader('Cache-Control', 'private, max-age=300');
  res.setHeader('Vary', 'Authorization');
  
  const user = await db.user.findUnique({ 
    where: { id: userId } 
  });
  res.json(user);
}
```

---

### 3️⃣ NO-CACHE (PER-REQUEST)

**Özellikler:**
- Real-time veri
- Her request'te server tarafından doğrulanmalı
- Cache yapılmamalı
- Private/public proxies'te kalamaz

**HTTP Headers:**
```
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
```

**Endpoint'ler:**

| Endpoint | Açıklama | Neden |
|----------|----------|-------|
| `GET /api/chat/rooms/{id}/messages` | Sohbet mesajları | Real-time |
| `GET /api/video-streams/{id}/comments` | Video yorumları | Real-time |
| `GET /api/social/posts` | Sosyal gönderiler | Real-time |
| `GET /api/video-streams/{id}/viewers` | Canlı izleyiciler | Real-time |
| `GET /api/notifications/{id}` | Tekil bildirim | Real-time |
| `POST /api/messages` | Mesaj gönderme | Mutation |
| `POST /api/credits/purchase` | Kredi satın alma | Mutation |
| `POST /api/fortune/request` | Fal talep | Mutation |
| `PUT /api/user/profile` | Profil güncelleme | Mutation |
| `DELETE /api/chat/messages/{id}` | Mesaj silme | Mutation |

**Implementation (Next.js):**
```typescript
// pages/api/chat/rooms/[roomId]/messages.ts
export default async function handler(req, res) {
  // Real-time veri — cache yapılmasın
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  
  const messages = await db.chatMessage.findMany({
    where: { roomId: req.query.roomId },
    orderBy: { createdAt: 'desc' },
    take: 50
  });
  
  res.json(messages);
}

// pages/api/messages.ts (POST)
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).end();
  }
  
  // Mutation — cache yapılmasın
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  
  const message = await db.chatMessage.create({
    data: req.body
  });
  
  res.json(message);
}
```

---

## 🔄 Browser Cache Behavior

### Request Flow:

```
1. Browser'da cache var mı?
   └─ YES → Cached response döndür
   
2. Cache'in TTL'si geçti mi?
   ├─ NO → Cached version kullan
   └─ YES → Server'a sor (If-None-Match)

3. Server 304 Not Modified dönerse
   └─ Browser cached version göster

4. Server 200 OK dönerse
   └─ Yeni veri cache'e kaydedilir + gösterilir
```

### ETag Validation (Opsiyonel):

```
Request 1:
GET /api/gifts/types
→ Response: 200 OK + ETag: "abc123"

Request 2 (Cache expired):
GET /api/gifts/types
If-None-Match: "abc123"
→ Response: 304 Not Modified (veri aynı)
→ Browser: Cached version göster

Request 3 (Data changed):
GET /api/gifts/types
If-None-Match: "abc123"
→ Response: 200 OK + ETag: "def456"
→ Browser: Yeni veri cache'e kaydedilir
```

---

## 📱 Mobile App Caching

Flutter'da Riverpod ile caching:

```dart
// lib/core/providers/gift_cache_provider.dart

final giftCacheProvider = FutureProvider<List<Gift>>((ref) async {
  // 1 gün cache
  final cached = ref.watch(giftCacheNotifierProvider);
  
  if (cached.isNotEmpty && !_isCacheStale()) {
    return cached;
  }
  
  // Server'dan fetch et
  final response = await api.get('/gifts/types');
  return response.map((e) => Gift.fromJson(e)).toList();
});

// Cache 1 day için persist et
void _persistGiftCache(List<Gift> gifts) {
  final box = Hive.box('gift_cache');
  box.put('gifts', gifts);
  box.put('timestamp', DateTime.now());
}

bool _isCacheStale() {
  final box = Hive.box('gift_cache');
  final timestamp = box.get('timestamp') as DateTime?;
  return timestamp == null || 
         DateTime.now().difference(timestamp).inDays > 1;
}
```

---

## 🚀 Implementation Checklist

### Phase 1: Public Cache (1-2 gün)
- [ ] `GET /api/gifts/types` → Cache-Control ekle
- [ ] `GET /api/credit-packages` → Cache-Control ekle
- [ ] `GET /api/fortune-request-types` → Cache-Control ekle
- [ ] `GET /api/memberships` → Cache-Control ekle
- [ ] `GET /api/leaderboards` → Cache-Control ekle
- [ ] ETag support test et
- [ ] Browser DevTools Network tab'ında "from cache" doğrula

### Phase 2: Private Cache (2-3 gün)
- [ ] `GET /api/user/profile` → Cache-Control ekle
- [ ] `GET /api/user/wallet` → Cache-Control ekle
- [ ] `GET /api/user/credits` → Cache-Control ekle
- [ ] `GET /api/notifications` → Cache-Control ekle
- [ ] Authorization header with Vary header test
- [ ] 5 dakika TTL doğrula

### Phase 3: No-Cache Headers (1-2 gün)
- [ ] `GET /api/chat/rooms/{id}/messages` → No-cache ekle
- [ ] Tüm POST methods → No-cache ekle
- [ ] Tüm PUT/DELETE methods → No-cache ekle
- [ ] Real-time endpoints → Must-revalidate ekle

### Testing (1-2 gün)
- [ ] `curl -I` ile header doğrula
- [ ] Browser Network tab'ında cache behavior kontrol et
- [ ] Staging: 10 paralel istek → database logs kontrol et
- [ ] Mobile app: Offline behavior test et
- [ ] CDN: Cache hit rate metrics kontrol et

---

## 📈 Expected Results

| Metrik | Öncesi | Sonrası | Artış |
|--------|--------|---------|--------|
| Network traffic | 100% | 80% | ⬇️ 20% |
| App startup time | 100% | 70% | ⬇️ 30% |
| Database queries | 100% | 85% | ⬇️ 15% |
| Server response time | 100% | 95% | ⬇️ 5% |
| Mobile data usage | 100% | 70% | ⬇️ 30% |

---

## 🔒 Security Notes

**⚠️ Dikkat:** Sensitif veri (passwords, tokens, PII) ASLA cache edilmemeli.

```typescript
// ❌ WRONG
res.setHeader('Cache-Control', 'public, max-age=86400');
res.json({ token: userToken }); // NEVER!

// ✅ CORRECT
res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
res.json({ token: userToken });
```

---

## 🔗 Referanslar

- **HTTP Caching:** [RFC 7234](https://tools.ietf.org/html/rfc7234)
- **Cache-Control:** [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- **Conditional Requests:** [RFC 7232](https://tools.ietf.org/html/rfc7232)
- **ETag:** [MDN ETag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag)

---

## 📞 Sorular

**Soru:** Cache TTL daha kısa olabilir mi?  
**Cevap:** Olabilir, ancak database yükü artar. 1 gün (public) ve 5 dakika (private) optimal.

**Soru:** ETag zorunlu mu?  
**Cevap:** Hayır, opsiyonel. Ancak önerilen — bandwidth tasarrufu sağlar.

**Soru:** CDN önünde proxy kullanılırsa?  
**Cevap:** Public cache kullanılır, TTL plugin ile override edilebilir.

---

**Sprint 1 — Task 3 Bitiş:** 2026-09-26  
**Başarı Kriteri:** Tüm endpoint'ler cache header'ı + %20 network tasarrufu doğrulanmış
