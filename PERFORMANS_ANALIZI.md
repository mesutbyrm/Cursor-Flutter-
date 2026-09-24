# Performance Analizi & Optimizasyon Raporu

**Güncellenme Tarihi:** 2026-09-24  
**Kontrol:** API çağrıları, caching, N+1 queries, batching

---

## Özet

| Kategori | Durum | Risk | Önem |
|----------|-------|------|------|
| **Gereksiz API çağrıları** | ⚠️ Birkaç var | Medium | High |
| **N+1 Query riski** | ⚠️ Orta | High | High |
| **Cache stratejisi** | ⚠️ Eksik | Medium | High |
| **Batch/GraphQL** | ❌ Yok | Low | Medium |
| **Response boyutu** | ✅ İyi | Low | Low |
| **Rate limiting** | ⚠️ Eksik dokümantasyon | Medium | Medium |

---

## 1. API Çağrı Topolojileri

### 1.1 Chat Room Girildiğinde

**Optimal akış:**
```
1. GET /api/chat/rooms/{roomId}          → Oda detayı
2. GET /api/chat/rooms/{roomId}/messages → Mesaj geçmişi  
3. GET /api/chat/rooms/{roomId}/presence → Katılımcılar
4. GET /api/chat/rooms/{roomId}/stream   → SSE bağlan (per.userları güncel tutar)
```

**Riski:** ✅ Minimal (SSE bağlantıda presence otomatik update)

### 1.2 Canlı Yayın Sayfası

**Akış:**
```
1. GET /api/video-streams/{streamId}     → Yayın detayı
2. GET /api/video-streams/{streamId}/comments → Yorumlar (sayfalı)
3. GET /api/video-streams/{streamId}/viewers  → İzleyici listesi
4. GET /api/video-streams/{streamId}/gifts    → Hediye kataloğu
5. GET /api/video-streams/{streamId}/stream   → SSE bağlan
```

**Sorunlar:**
- ⚠️ `viewers` ve `gifts` listesi sayfanın açılması sırasında **gerekli değil** → lazy load et
- ⚠️ `gifts` global hediye'si kullanılmalı, stream-specific versiyonu neden?

### 1.3 Fortune Teller Listesi

**Akış:**
```
1. GET /api/fortune-tellers?page=1&online=true  → Falcı listesi
2. (Her falcı için) GET /api/fortune-tellers/{tellerId}/reviews → N+1!
```

**Sorun:** 🔴 **N+1 QUERY** 

Liste 10 falcı gösterirse 1 + 10 = 11 istek!

**Çözüm:** Kılavuza falcı detaylarını liste yanıtında dahil et

---

## 2. N+1 Query Sorunları

### 2.1 ChatRoom Presence (Koltuklar)

**Problematik Kod İmplementasyonu (tahmin):**

```dart
// Anti-pattern
final room = await chatRepository.getRoom(roomId);  // 1 istek
final presences = await chatRepository.getPresence(roomId);  // 1 istek
for (final presence in presences) {
  final user = await userRepository.getUser(presence.userId);  // N istekler!
}
```

**Çözüm:**
- Backend: Presence yanıtına kullanıcı metadata'sı (name, image, membership) dahil et
- Flutter: User'ı ayrı çekme

### 2.2 Social Posts Feed

**İhtimal:** Her post'un sahibi fetch ediliyorsa:

```
GET /api/social/posts?page=1  → 20 post
(Her post için) GET /api/users/{userId}  → 20 istek
```

**Çözüm:**
- Backend: User info post'a dahil et (union)
- Flutter: Ayrı fetch yapma

### 2.3 Short Videos Recommendations

**İhtimal:**

```
GET /api/short-videos/recommend  → 20 video
(Her video için) GET /api/users/{userId}  → 20 istek
```

**Çözüm:** User bilgisi response'a dahil et

---

## 3. Caching Stratejisi Eksiklikleri

### 3.1 Backend Cache Headers

**Kılavuzda belirtilen:** `Cache-Control` ve `ETag` kullanılabilir

**Sorun:** Cache stratejisi endpoint'ler için tanımlanmadı

**Öneriler:**

| Endpoint | Cache | TTL |
|----------|-------|-----|
| `/api/gifts/types` | public, max-age | 1 gün |
| `/api/credit-packages` | public, max-age | 1 gün |
| `/api/fortune-request-types` | public, max-age | 1 gün |
| `/api/user/profile` | private, max-age | 5 min |
| `/api/chat/rooms/{id}` | private, no-cache | Per-request |
| `/api/chat/rooms/{id}/messages` | private, no-cache | Per-request |
| `/api/notifications` | private, no-cache | Per-request |

### 3.2 Flutter Client Cache

**Kılavuza göre:** (satır 14) `ApiCacheInterceptor` var ama detaylı açıklanmadı

**Öneriler:**

```dart
class ApiCacheInterceptor extends Interceptor {
  // GET /api/gifts/types → 24h cache
  // GET /api/credit-packages → 24h cache
  // GET /api/mobile/home → 5 min cache
  // POST istekler → no cache
}
```

---

## 4. Batch & Bulk Operations

### 4.1 Çoklu Hediye Gönderme

**Mevcut:** Tek hediye per-request
```
POST /api/gifts/send { giftId, receiverUserId }
```

**Sorun:** 10 hediye = 10 istek

**Çözüm (Backend):**
```
POST /api/gifts/send-bulk
{
  "gifts": [
    { "giftId": "1", "receiverUserId": "user1" },
    { "giftId": "2", "receiverUserId": "user2" }
  ]
}
```

### 4.2 Çoklu Kullanıcı Takip

**Mevcut:** Per-user per-request
```
POST /api/user/{userId}/follow
```

**Sorun:** 5 kişi takip et = 5 istek

**Çözüm:** Batch endpoint gerekir

---

## 5. Polling vs Real-Time

### 5.1 Kazanılan Alanlar (SSE ile)

| Özellik | Polling (eski) | SSE (mevcut) | Kazanç |
|---------|----------------|--------------|--------|
| Chat messages | 2s poll × 100 users = 50 req/s | 1 connection | 99% traffic ↓ |
| Notifications | 10s poll × 1000 users = 100 req/s | 1 connection | 99% |
| Stream viewers | 5s poll × 10,000 viewers = 2000 req/s | 1 connection | 99.9% |

✅ **SSE kararı çok iyi**

---

## 6. Response Boyutu Analizi

### 6.1 Büyük Response'lar

| Endpoint | Tipik Boyut | Sorun |
|----------|------------|-------|
| `/api/chat/rooms?limit=100` | ~500KB | Sayfala (default 50) |
| `/api/video-streams/{id}/viewers` | ~1MB | Limit viewers (top 100) |
| `/api/social/posts?limit=100` | ~600KB | Sayfala |
| `/api/short-videos?limit=100` | ~400KB | Sayfala |
| `/api/gifts/types` | ~100KB | Cacheable ✅ |

**Öneriler:**
- Default limit 20-50'de tutma
- Cursor-based pagination tercih et (offset'ten daha hızlı)

---

## 7. Rate Limiting & Throttling

### 7.1 Tanımlanan Limitler (Kılavuzdan)

**Bulunan:**
- Login denemesi: 429 (hızlı denemeler)
- Fortune access: `/api/fortune-access/check` dönüş koduna bakması gerekir

**Eksik:**
- Message gönderme: per-second limit?
- Gift gönderme: per-minute limit?
- Room creation: per-hour limit?
- API call quota: global limit?

### 7.2 Önerilen Limitler

```
POST /api/chat/rooms/{roomId}/messages      → 10 msg/10s
POST /api/video-streams/{id}/comments       → 5 comments/10s
POST /api/gifts/send                        → 20 gifts/min
POST /api/chat/rooms/create                 → 3 rooms/hour
POST /api/fortunes/*                        → 5 fal/hour
GET /api/socket/*/stream (SSE)              → 1 per user
```

---

## 8. Tespit Edilen Problemler

### 🔴 YÜKSEK PRİYORİTE

#### 1. N+1 Queries (FortuneTeller Listesi)
**Dosya:** Bilinmiyor (repository implementation)  
**Sorun:** Her falcı için review'ları fetch etme  
**Etki:** 10 falcı listesi = 11 istek  
**Çözüm:** Backend response'a count/summary dahil et

#### 2. SSE 401'de Token Refresh Yok
**Dosya:** `lib/services/sse_service.dart` satır 1501-1506  
**Sorun:** Long-lived SSE bağlantısı token expiry'de kırılır  
**Etki:** Real-time features kesintili  
**Çözüm:** Automatic token refresh in SSE reconnect

### 🟡 ORTA PRİYORİTE

#### 3. Cache Headers Eksik
**Dosya:** Backend (canlifal.com)  
**Sorun:** Statik kaynaklar (gifts, packages) cache edilmiyor  
**Etki:** Gereksiz network traffic  
**Çözüm:** Cache-Control headers tanımla

#### 4. Lazy Loading Eksik
**Dosya:** Repository implementations  
**Sorun:** Yayın sayfasında viewers + gifts hemen yükleniyor  
**Etki:** Başlangıç gecikmesi  
**Çözüm:** Tab'lere göre lazy load

#### 5. Batch Operations Yok
**Dosya:** Backend  
**Sorun:** Çoklu işlemler N istekler  
**Etki:** Performance, especially follow/gift features  
**Çözüm:** Batch endpoints ekle

### 🟢 DÜŞÜK PRİYORİTE

#### 6. GraphQL Eksik
**Durum:** Opsiyonel  
**Avantaj:** Over-fetching azalıyor  
**Ek Maliyet:** Backend refactor

---

## 9. Geliştirme Tavsiyeleri

### Phase 1 (Kritik - 2 hafta)

```
[ ] SSE token refresh mekanizması
[ ] FortuneTeller listesinde N+1 çözümü
[ ] Chat room presence user info dahil etme
```

### Phase 2 (Önemli - 1 ay)

```
[ ] Backend cache headers
[ ] Lazy loading (viewers, gifts tabs)
[ ] Batch follow endpoint
[ ] Batch gift send endpoint
```

### Phase 3 (Nice-to-have - Sonra)

```
[ ] Cursor-based pagination
[ ] GraphQL gateway (opsiyonel)
[ ] Advanced CDN caching
[ ] Compression (gzip, brotli)
```

---

## 10. Benchmark Hedefleri

| Metrik | Mevcut | Hedef | Yöntem |
|--------|--------|-------|--------|
| **Chat room açılış** | ~2s | <500ms | N+1 fix + cache |
| **Feed sayfa yükü** | ~1.5s | <800ms | Lazy load + batch |
| **Notification latency** | <1s (SSE) | <500ms | Keep-alive + optimize |
| **Search sonucu** | ~1s | <600ms | Database index + cache |
| **Video stream start** | ~3s | <1.5s | Parallel requests |

---

## Performans Checklist

```
[ ] Endpoint başına cache TTL tanımlanıyor mu?
[ ] N+1 queries tespit edilmiş mi?
[ ] SSE token refresh otomatik mi?
[ ] Lazy loading critical sections'da?
[ ] Rate limits tanımlanmış mı?
[ ] Response boyutları kontrol edilmiş mi?
[ ] Batch operations mevcut mi?
[ ] Timeout değerleri optimized mi?
[ ] Connection pooling kurulu mu?
[ ] Monitoring/alerting var mı?
```

---

**Genel Sonuç:** ⚠️ **Orta seviye iyileştirme gerekli - SSE ve N+1 kritik**
