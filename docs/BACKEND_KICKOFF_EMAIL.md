# 🚀 Backend Team — Sprint 1 Kickoff Email

---

**TO:** Backend Development Team  
**FROM:** Platform Architecture  
**DATE:** 2026-09-24  
**SUBJECT:** 🔴 **CRITICAL: Sprint 1 Kickoff — Real-time & Performance Optimization (1 Week)**

---

## 🎯 Mission

Canlifal backend'in **long-lived real-time connections** stabilizasyonu ve **database performance** optimizasyonu.

**Timeline:** 1 Week (2026-09-24 → 2026-10-01)  
**Team Size:** 3 developers (paralel görevler)  
**Success Metric:** 100% staging pass + performance targets

---

## 🎬 What's Happening

We just completed a **comprehensive backend-Flutter API audit** (6 detailed reports) and identified **3 critical bottlenecks** that need immediate attention:

1. ✗ **SSE Token Refresh** — Long-lived connections break at token expiry
2. ✗ **N+1 Query (FortuneTeller)** — 10 falcı listelemek = 11 database sorgusu
3. ✗ **Cache Headers** — Statik kaynaklar cache yapılmıyor

**These 3 fixes = 40% performance improvement + 99%+ SSE uptime.**

---

## 📋 The 3 Tasks

### **TASK 1: SSE Token Refresh Mechanism**

**Assigned to:** Backend Dev #1  
**Duration:** 2-3 days  
**Priority:** 🔴 CRITICAL

**Problem:**
```
User logs in → Token expires in 7 days
User keeps chat room open for 30+ days
Day 7 at token expiry → SSE bağlantısı 401 hatası → Bağlantı kesilir
Result: Real-time features stop working
```

**Expected Solution:**
- SSE bağlantısında 401 alınca → `POST /api/auth/mobile-refresh` çağır
- Yeni `accessToken` al
- SSE'ye yeniden bağlan (seamless)
- User bunu fark etmesin

**Files to Modify:**
- `api/routes/auth.ts` — Mobile refresh endpoint
- `api/middleware/sse.ts` — SSE 401 handler

**Test Criteria:**
```bash
✓ 30+ day SSE connection test pass
✓ Token refresh sırasında message loss yok
✓ Staging test: OK
```

**Reference:** [`docs/BACKEND_CRITICAL_3_TASKS.md` §KRİTİK 1](BACKEND_CRITICAL_3_TASKS.md)

---

### **TASK 2: N+1 Query Optimization (FortuneTeller)**

**Assigned to:** Backend Dev #2  
**Duration:** 3-4 days  
**Priority:** 🔴 CRITICAL

**Problem:**
```
Query 1: SELECT * FROM FortuneTeller WHERE online=true LIMIT 10
Query 2-11: (Her falcı için) SELECT COUNT(*) FROM Review WHERE tellerId=?
─────────────
TOTAL: 11 queries → 10 falcı listesi 1500ms → 3000ms
```

**Expected Solution (SQL'de):**
```sql
SELECT 
  ft.*,
  COUNT(r.id) as reviewCount,
  AVG(r.rating) as avgRating
FROM FortuneTeller ft
LEFT JOIN Review r ON ft.id = r.tellerId
WHERE ft.online = true
GROUP BY ft.id
LIMIT 10;
```

**API Response (Yeni Format):**
```json
[
  {
    "id": "teller123",
    "displayName": "Melike Falcı",
    "isOnline": true,
    "rating": 4.8,
    "reviewCount": 245,      // ← Yeni
    "avgRating": 4.8,         // ← Yeni
    "reviews": [              // ← Yeni (optional)
      { "id": "rev1", "rating": 5, "comment": "..." }
    ]
  }
]
```

**Files to Modify:**
- `api/repositories/fortune-teller.ts` — Query optimization
- `api/schemas/fortune-teller.ts` — Response schema update

**Test Criteria:**
```bash
✓ 10 falcı listesi: 1 query (was 11)
✓ Performance: < 200ms (was 500ms)
✓ Staging test: OK
✓ Flutter client bilgilendirildi (API schema changed)
```

**Reference:** [`docs/BACKEND_CRITICAL_3_TASKS.md` §KRİTİK 2](BACKEND_CRITICAL_3_TASKS.md)

---

### **TASK 3: Cache-Control Headers**

**Assigned to:** Backend Dev #3  
**Duration:** 2-3 days  
**Priority:** 🔴 CRITICAL

**Problem:**
```
GET /api/gifts/types → Her istek yeni query
GET /api/credit-packages → Her istek yeni query
GET /api/user/profile → Her istek yeni query
Result: Network trafiği 50%+ fazla
```

**Expected Solution:**

Add `Cache-Control` headers to responses:

**Endpointler:**

```
🟢 PUBLIC — 1 Day Cache
GET /api/gifts/types
GET /api/credit-packages
GET /api/fortune-request-types
GET /api/memberships
GET /api/leaderboards
→ Response header: Cache-Control: public, max-age=86400

🔵 PRIVATE — 5 Minutes Cache
GET /api/user/profile
GET /api/user/wallet
GET /api/user/credits
GET /api/notifications
→ Response header: Cache-Control: private, max-age=300

🔴 NO-CACHE (Per-Request)
GET /api/chat/rooms/{roomId}/messages
POST /api/messages (all POST's)
→ Response header: Cache-Control: no-cache, no-store, must-revalidate
```

**Implementation (Next.js):**
```typescript
// pages/api/gifts/types.ts
export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'public, max-age=86400');
  const gifts = await db.giftType.findMany();
  res.json(gifts);
}

// pages/api/user/profile.ts
export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'private, max-age=300');
  const user = await db.user.findUnique({ where: { id: req.user.id } });
  res.json(user);
}
```

**Files to Modify:**
- `api/middleware/cache.ts` — Cache middleware
- `api/routes/*.ts` — Add headers to routes

**Test Criteria:**
```bash
✓ Public endpoint'ler 1 day cache header dönüyor
✓ Private endpoint'ler 5 min cache header dönüyor
✓ No-cache endpoint'ler no-store header dönüyor
✓ Browser DevTools Network tab'ında "from cache" görülüyor
✓ Staging test: OK
```

**Reference:** [`docs/BACKEND_CRITICAL_3_TASKS.md` §KRİTİK 3](BACKEND_CRITICAL_3_TASKS.md)

---

## 📅 Timeline & Checkpoints

```
MON 09-24 (Day 1):
├─ 09:00 — Team kickoff (this email)
├─ 10:00 — Assign tasks & setup
├─ 14:00 — First checkpoint (tech design)
└─ 17:00 — EOD sync

TUE 09-25 (Day 2):
├─ 09:00 — Daily standup
├─ 12:00 — Mid-day checkpoint (50% progress expected)
└─ 17:00 — EOD sync

WED 09-26 (Day 3):
├─ 09:00 — Daily standup
├─ 12:00 — Mid-day checkpoint
└─ 17:00 — EOD sync

THU 09-27 (Day 4):
├─ 09:00 — Daily standup
├─ 12:00 — Integration test checkpoint
└─ 17:00 — EOD sync

FRI 09-28 (Day 5):
├─ 09:00 — Daily standup
├─ 11:00 — Testing & validation
├─ 14:00 — Code review & merge
└─ 16:00 — Sprint review

MON 10-01 (Day 8):
├─ 09:00 — Final verification
└─ 10:00 — 🎉 SPRINT 1 COMPLETE
```

---

## 🎯 Daily Standup Format

**Time:** 09:00-09:15 (15 minutes)  
**Location:** Slack #backend-sprint1

**Report:**
```
Dev #1 (SSE Token Refresh):
- Yesterday: X completed
- Today: Y working on
- Blockers: None / [list]

Dev #2 (N+1 Query):
- Yesterday: X completed
- Today: Y working on
- Blockers: None / [list]

Dev #3 (Cache Headers):
- Yesterday: X completed
- Today: Y working on
- Blockers: None / [list]
```

---

## 📊 Success Criteria

### **For Each Task:**

**SSE Token Refresh:**
- ✅ 401 response'da automatic token refresh
- ✅ Yeni token ile seamless reconnect
- ✅ 30+ day test pass (simulated)
- ✅ Staging: OK
- ✅ Code review: approved

**N+1 Query Fix:**
- ✅ SQL query 11 → 1 sorgu
- ✅ Response time 500ms → <200ms
- ✅ API response schema updated
- ✅ Staging: OK
- ✅ Flutter team notified (API changed)

**Cache Headers:**
- ✅ Public endpoint'ler Cache-Control header dönüyor
- ✅ Private endpoint'ler 5-min cache
- ✅ No-cache endpoint'ler no-store
- ✅ Browser cache test: OK
- ✅ Staging: OK

### **Overall Sprint 1:**

```
Performance:
✓ FortuneTeller list: 1500ms → 750ms (-50%)
✓ Network traffic: -20% (cache)
✓ SSE availability: 95% → 99%+

Quality:
✓ All tests pass (staging)
✓ Code review 100%
✓ No new bugs introduced
✓ Documentation updated

Deliverable:
✓ Production-ready code
✓ Merged to main
✓ Ready for Flutter Sprint 2
```

---

## 📚 Documentation

**START HERE:** [`docs/TASK_INDEX.md`](TASK_INDEX.md) — Master index (5 min read)

**THEN READ:** [`docs/BACKEND_CRITICAL_3_TASKS.md`](BACKEND_CRITICAL_3_TASKS.md) — Detailed tasks (20 min read)

**REFERENCE:** 
- [`docs/PERFORMANS_ANALIZI.md`](PERFORMANS_ANALIZI.md) — Performance context
- [`docs/GERCEK_ZAMANLI_SISTEM_ANALIZI.md`](GERCEK_ZAMANLI_SISTEM_ANALIZI.md) — SSE context
- [`docs/BACKEND_CACHE_STRATEGY.md`](BACKEND_CACHE_STRATEGY.md) — Cache policy (coming soon)

---

## 🛠️ Tools & Setup

**Repository:** https://github.com/mesutbyrm/Cursor-Flutter-

**Branch:** `main` (develop directly)

**Tech Stack:**
- Backend: Next.js 14 + Prisma
- Database: PostgreSQL
- Testing: Jest

**Setup:**
```bash
# Clone repo
git clone https://github.com/mesutbyrm/Cursor-Flutter-.git
cd Cursor-Flutter-

# Install deps
npm install

# Setup env
cp .env.example .env.local

# Run tests
npm test

# Run dev server
npm run dev
```

---

## 🚨 Blockers & Support

**If you get stuck:**
1. Check [`BACKEND_CRITICAL_3_TASKS.md`](BACKEND_CRITICAL_3_TASKS.md) for solutions
2. Slack #backend-sprint1 → Quick question
3. Daily standup → Technical blocker discussion
4. Code review → Design feedback

**Known Challenges:**
- SSE token refresh requires middleware update (not trivial)
- N+1 query needs SQL optimization + schema migration
- Cache headers need consistency across all endpoints

**We have solutions for all 3 — see detailed docs.**

---

## 🎁 What You Get

**When Sprint 1 is complete:**
- ✅ Real-time features rock-solid (99%+ uptime)
- ✅ 50% faster FortuneTeller list
- ✅ 20% less network traffic
- ✅ Flutter team can start Sprint 2 (Oct 1)
- ✅ Platform ready for scale

**Recognition:**
- Public thank you in release notes
- Sprint 1 completion badge
- Next sprints prioritize your requests

---

## 🚀 Ready? Let's Go!

1. **Read** [`docs/TASK_INDEX.md`](TASK_INDEX.md) (5 min)
2. **Read** [`docs/BACKEND_CRITICAL_3_TASKS.md`](BACKEND_CRITICAL_3_TASKS.md) (20 min)
3. **Assign** tasks to Dev #1, #2, #3
4. **Setup** dev environment
5. **First standup** 09:00 tomorrow

---

## 📞 Questions?

**Slack:** #backend-sprint1  
**Email:** platform-architecture@canlifal.com  
**Daily Sync:** 09:00

---

## 🎯 Bottom Line

**We have 3 critical tasks. We have 1 week. We have everything we need to succeed.**

Let's ship it. 🚀

---

**Sprint 1 Official Start:** Tuesday, September 24, 2026, 09:00  
**Sprint 1 Target End:** Tuesday, October 1, 2026, 17:00  

**Status:** 🟢 GO

