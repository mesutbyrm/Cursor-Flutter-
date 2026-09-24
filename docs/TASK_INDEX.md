# 📋 Canlifal Development — Master Task Index

**Güncelleme:** 2026-09-24  
**Durum:** 🔴 Sprint 1 — Başlama (1 Hafta)  
**Hedef:** Platform Performance & Real-time Optimization

---

## 📍 Quick Navigation

### 🔴 **Acil (KRITIK) — Sprint 1**
📄 [`docs/BACKEND_CRITICAL_3_TASKS.md`](BACKEND_CRITICAL_3_TASKS.md)  
⏱️ **1 Hafta | Backend Team**  
🎯 **Başlama:** Hemen | **Bitiş:** 2026-10-01

| # | Görev | Dosya | Süre | Aksiyon |
|---|-------|-------|------|--------|
| **1.1** | SSE Token Refresh | `auth_service.dart` | 2-3 gün | Backend dev |
| **1.2** | N+1 Query (FortuneTeller) | Backend DB | 3-4 gün | Backend dev |
| **1.3** | Cache-Control Headers | Backend API | 2-3 gün | Backend dev |

---

### 🟡 **Orta Öncelik — Sprint 2**
📄 [`docs/FLUTTER_MEDIUM_PRIORITY_TASKS.md`](FLUTTER_MEDIUM_PRIORITY_TASKS.md)  
⏱️ **1 Hafta | Flutter Team**  
🎯 **Başlama:** Sprint 1 bittikten sonra | **Bitiş:** 2026-10-08

| # | Görev | Dosya | Süre | Aksiyon |
|---|-------|-------|------|--------|
| **2.1** | Lazy Loading (Live Stream) | `live_broadcast_room_page.dart` | 2-3 gün | Flutter dev |
| **2.2** | Token Expiry Lifecycle | `auth_service.dart` | 2-3 gün | Flutter dev |
| **2.3** | SSE Connection Limit | `sse_service.dart` | 1-2 gün | Flutter dev |
| **2.4** | Room Event Animation | `sse_event.dart` | 1-2 gün | Flutter dev |
| **2.5** | Game/Agency DTO'ları | `mobile/lib/models/` | 3-4 gün | Flutter dev |
| **2.6** | Enum Standardization | `mobile/lib/models/enums/` | 2-3 gün | Flutter dev |

---

### 🟢 **Düşük Öncelik — Sprint 3+**
📄 [`docs/LOW_PRIORITY_TASKS.md`](LOW_PRIORITY_TASKS.md)  
⏱️ **3+ Ay | Backend & Infrastructure**  
🎯 **Başlama:** Q4 2026 (Ekim) | **Bitiş:** 2027+

| # | Görev | Kime | Süre | Q |
|---|-------|------|------|---|
| **3.1** | Cursor-based Pagination | Backend | 1 w | Q4 |
| **3.2** | API Versioning Strategy | Backend | 1-2 d | Q4 |
| **3.3** | Cache Strategy Documentation | Backend | 1 d | Q4 |
| **3.4** | Database Index Optimization | Backend/DBA | 1-2 w | Q4 |
| **3.5** | Stream Recording & Replay | Backend | 2-3 w | Q1 |
| **3.6** | Compression (gzip/brotli) | Backend | 3-5 d | Q1 |
| **3.7** | Advanced CDN Caching | Infrastructure | 1-2 w | Q1 |
| **3.8** | GraphQL Gateway | Backend/Arch | 4-6 w | Q2 |

---

## 🎯 **Executive Summary**

### 📊 **Toplam Efor**

```
Sprint 1 (Kritik):      1 hafta (Backend)
Sprint 2 (Orta):        1 hafta (Flutter)
Sprint 3+ (Düşük):      8+ hafta (Backend/Infra, paralel)
─────────────────────────────────────
TOPLAM:                 10-16 hafta
```

### 🚀 **Beklenen Sonuç**

**Sprint 1 Sonrası:**
- ✅ SSE stabil (long-lived connections)
- ✅ FortuneTeller listesi 2x hızlı
- ✅ Network trafiği azalmaya başladı

**Sprint 2 Sonrası:**
- ✅ Live stream sayfası 300ms'de açılır
- ✅ Token refresh otomatik
- ✅ Type-safe API responses
- ✅ APK 1.0.600+ ready

**Sprint 3+ Sonrası:**
- ✅ Database queries 10x hızlı
- ✅ API v1/v2 versioning
- ✅ Stream recording feature
- ✅ GraphQL gateway (optional)

---

## 📅 **Timeline & Milestones**

### 🔴 **HAFTA 1 (2026-09-24 → 2026-10-01)**

**SPRINT 1 — Backend Kritik 3**

```
Mon 09-24: Backend team başla
├─ SSE Token Refresh
├─ N+1 Query FortuneTeller
└─ Cache-Control Headers

Wed 09-26: 50% tamamlandı (checkpoint)
Thu 09-27: 75% tamamlandı
Fri 09-28: Integration & testing
Mon 10-01: COMPLETE & TEST
```

**Checkpoint'ler:**
- [ ] Gün 1: Teknik design doc'lar hazır
- [ ] Gün 2: SSE token refresh implementasyonu başladı
- [ ] Gün 3: N+1 query SQL optimizasyonu bitti
- [ ] Gün 4: Cache headers tüm endpoint'lere eklendi
- [ ] Gün 5: End-to-end test, staging'te doğrulandı

**Çıkaran:**
- Stabilize SSE
- Optimize FortuneTeller listesi
- Network trafiği azalma

---

### 🟡 **HAFTA 2-3 (2026-10-01 → 2026-10-15)**

**SPRINT 2 — Flutter Orta 6**

```
Tue 10-01: Sprint 1 bitmiş, Sprint 2 başla

Paralel çalışmalar:
├─ Dev 1: Lazy loading + Token lifecycle (3-4 gün)
├─ Dev 2: SSE limit + Animation (3-4 gün)
└─ Dev 3: DTO'lar + Enum'lar (4-5 gün)

Thu 10-10: 75% tamamlandı (checkpoint)
Tue 10-15: COMPLETE & BUILD APK
```

**Checkpoint'ler:**
- [ ] Gün 1: Flutter provider refactor design
- [ ] Gün 2: Lazy loading sayfa açılış < 300ms
- [ ] Gün 3: Token lifecycle monitoring
- [ ] Gün 4: SSE connection limit
- [ ] Gün 5: Animation parsing
- [ ] Gün 6: DTO'lar + enum'lar
- [ ] Gün 7: Integration test + APK build

**Çıkaran:**
- Flutter APK 1.0.600+
- Sayfa açılış performansı iyileşti
- Type-safe API handling

---

### 🟢 **Q4 2026 (Ekim - Aralık)**

**SPRINT 3 — Backend Düşük (Quick Wins)**

```
Oct:  Cursor pagination + API versioning
Nov:  Database index optimization
Dec:  Cache strategy documentation
```

**Paralel:** Lightning quick tasks
- Compression enable (3-5 gün)
- CDN caching setup (2 hafta)

---

### 🟢 **Q1 2027 (Ocak - Mart)**

**SPRINT 4 — Backend Feature**

```
Jan:  Stream recording & replay
Feb:  Advanced CDN optimization
Mar:  Testing & stabilization
```

---

### 🟢 **Q2 2027 (Nisan - Haziran)**

**SPRINT 5 — Architecture**

```
Apr:  GraphQL gateway (preview)
May:  Gradual REST → GraphQL migration (50%)
Jun:  Performance benchmarking
```

---

## 🎬 **Getting Started**

### **Backend Team — Sprint 1 (YÖNETİCİ)**

1. **Dosyayı Oku:**
   ```bash
   cat docs/BACKEND_CRITICAL_3_TASKS.md
   ```

2. **3 Görev Paralel Başla:**
   - Dev 1: SSE Token Refresh
   - Dev 2: N+1 Query Optimization
   - Dev 3: Cache-Control Headers

3. **Günlük Checkpoint'ler:**
   ```
   09:00 → Daily standup
   12:00 → Mid-day sync
   17:00 → EOD status
   ```

4. **Test & Validate:**
   ```bash
   bash scripts/test-weekly-competition-endpoint.sh https://canlifal.com $JWT_TOKEN
   ```

5. **Merge to Main:**
   - Staging test'leri pass et
   - Code review
   - Main'e merge

---

### **Flutter Team — Sprint 2 (YÖNETİCİ)**

1. **Dosyayı Oku:**
   ```bash
   cat docs/FLUTTER_MEDIUM_PRIORITY_TASKS.md
   ```

2. **Backend Sprint 1 Bitişini Bekle:**
   ```bash
   # Sprint 1 bitiş kontrolü
   git log --oneline | grep -i "critical\|sse\|n+1\|cache"
   ```

3. **6 Görev Paralel Başla:**
   - Dev 1: Lazy loading + Token lifecycle
   - Dev 2: SSE limit + Animation
   - Dev 3: DTO'lar + Enum'lar

4. **APK Build & Test:**
   ```bash
   cd mobile
   flutter pub get
   flutter build apk --release
   ```

5. **Test & Validate:**
   - Live stream: Sayfa açılış < 300ms
   - SSE: 30+ dakika bağlantı stabil
   - Token: Refresh otomatik

---

### **Infrastructure Team — Sprint 3+ (YÖNETİCİ)**

1. **Quick Wins (Ekim):**
   ```bash
   # Compression enable
   # CDN setup başla
   ```

2. **Database Optimization:**
   ```bash
   # Slow query analysis
   # Index creation
   ```

3. **Long-term Planning:**
   - Recording service architecture
   - GraphQL schema design

---

## 📊 **Dependency Graph**

```
┌─────────────────────────────────────┐
│  Sprint 1: BACKEND KRITIK (1 w)     │
│  ├─ SSE Token Refresh               │
│  ├─ N+1 Query Fix                   │
│  └─ Cache Headers                   │
└──────────────┬──────────────────────┘
               │
               ▼ (Sprint 1 Complete)
┌─────────────────────────────────────┐
│  Sprint 2: FLUTTER ORTA (1 w)       │
│  ├─ Lazy Loading                    │
│  ├─ Token Lifecycle                 │
│  ├─ SSE Connection Limit            │
│  ├─ Animation Parsing               │
│  ├─ Game/Agency DTO'ları            │
│  └─ Enum Standardization            │
└──────────────┬──────────────────────┘
               │
               ▼ (Paralel: Sprint 3 başlayabilir)
┌─────────────────────────────────────┐
│  Sprint 3: BACKEND DÜŞÜK (3+ w)     │
│  ├─ Cursor Pagination               │
│  ├─ API Versioning                  │
│  ├─ Database Index Opt.             │
│  ├─ Compression                     │
│  └─ CDN Caching                     │
└─────────────────────────────────────┘
               │
               ▼ (Long-term)
┌─────────────────────────────────────┐
│  Sprint 4-5: FEATURES + ARCH         │
│  ├─ Recording/Replay                │
│  └─ GraphQL Gateway                 │
└─────────────────────────────────────┘
```

---

## ✅ **Tamamlama Kriterleri**

### **Sprint 1 Done (Backend)**

```
[ ] SSE Token Refresh 401'de automatic retry yapıyor
[ ] N+1 Query FortuneTeller 11 → 1 sorgu
[ ] Cache-Control headers tüm public endpoint'lerde
[ ] Staging test'ler pass
[ ] Code review tamamlandı
[ ] Main'e merge
[ ] APK derlemeye hazır
```

### **Sprint 2 Done (Flutter)**

```
[ ] Lazy loading: Live stream sayfa açılış < 300ms
[ ] Token lifecycle: 30+ saat seamless SSE
[ ] SSE limit: Max 5 concurrent bağlantı
[ ] Animation: Backend event'leri render ediliyor
[ ] DTO'lar: Game, Agency model'leri
[ ] Enum'lar: Type-safe response parsing
[ ] APK 1.0.600+ build başarılı
[ ] Device test pass
[ ] Play Store yüklemeye hazır
```

### **Sprint 3+ Done (Backend/Infra)**

```
[ ] Cursor pagination: 10x hızlı query'ler
[ ] API versioning: v1/v2 endpoint'leri
[ ] Database index'leri: Missing index'ler eklendi
[ ] Compression: gzip/brotli enabled
[ ] CDN: Global edge caching 90% hit ratio
[ ] Recording: RTMP/transcoding pipeline
[ ] GraphQL: Preview schema & resolver'lar
```

---

## 📞 **İletişim & Koordinasyon**

### **Daily Standups**

```
🕘 09:00 — Sprint Daily (15 min)
├─ Blocker'lar
├─ Progress update
└─ Today's focus

🕕 17:00 — EOD Sync (5 min)
└─ Status update
```

### **Weekly Reviews**

```
🕐 Friday 16:00 — Sprint Review (1 hour)
├─ Demo completed work
├─ Test results
├─ Next week planning
└─ Risk assessment
```

### **Communication Channels**

- **GitHub:** Code review, PR's, issues
- **Slack:** Quick questions, blocking issues
- **Docs:** This index + individual sprint docs

---

## 🎓 **Documentation Index**

### **Audit Reports (Completed)**
📄 `CANLIFAL_BACKEND_ENVANTER.md` — 180+ endpoint inventory  
📄 `WEB_FLUTTER_API_KARSILASTIRMA.md` — %100 API compatibility  
📄 `KULLANILMAYAN_ENDPOINTLER.md` — 120+ unused endpoint'ler  
📄 `VERI_MODELI_UYUM_RAPORU.md` — Backend vs Flutter models  
📄 `GERCEK_ZAMANLI_SISTEM_ANALIZI.md` — SSE %95 uyum  
📄 `PERFORMANS_ANALIZI.md` — Performance bottlenecks

### **Task Documentation (Active)**
📄 `BACKEND_CRITICAL_3_TASKS.md` — Sprint 1 tasks  
📄 `FLUTTER_MEDIUM_PRIORITY_TASKS.md` — Sprint 2 tasks  
📄 `LOW_PRIORITY_TASKS.md` — Sprint 3+ tasks  
📄 `TASK_INDEX.md` — **Bu dokümantasyon**

### **Reference Docs**
📄 `FLUTTER_ENTegrasyon_KILAVUZU.md` — API integration guide  
📄 `APK_DOWNLOAD.md` — APK release notes  
📄 `DOCS_RELEASE_INDEX.md` — Release status

---

## 📈 **Success Metrics**

### **Performance**

```
Sprint 1:
✓ SSE availability: 99%+ (was 95% at token refresh)
✓ FortuneTeller list: 1.5s → 750ms (-50%)
✓ Network traffic: -20% (cache headers)

Sprint 2:
✓ Live stream page: 500ms → 300ms (-40%)
✓ APK startup: -15%
✓ Type errors: 0 (type-safe enums)

Sprint 3+:
✓ Database queries: 10-20x faster (cursor + index)
✓ Response compression: 90%+ (gzip/brotli)
✓ CDN cache hit: 90%+
```

### **Quality**

```
✓ Test coverage: 85%+
✓ Code review: 100%
✓ Staging pass rate: 100%
✓ Production bugs: < 1%
```

### **Timeline**

```
✓ Sprint 1: On time (±2 days)
✓ Sprint 2: On time (±2 days)
✓ Sprint 3+: Best effort (dependencies)
```

---

## 🚀 **Launch Checklist**

### **Pre-Launch (Sprint 1-2 Complete)**

```
[ ] APK 1.0.600+ ready
[ ] Staging all tests pass
[ ] Performance benchmarks hit target
[ ] Security review passed
[ ] User documentation updated
[ ] Release notes written
```

### **Launch Day**

```
[ ] APK published to Play Store
[ ] Release notes posted
[ ] Monitoring active
[ ] Support team briefed
[ ] Hotfix team on standby
```

### **Post-Launch (First 48 hours)**

```
[ ] Crash analytics monitored
[ ] User feedback collected
[ ] Performance metrics checked
[ ] Any critical bugs fixed
[ ] Success declared
```

---

## 📝 **Notes & Lessons Learned**

### **From Sprint 1 Audit:**
- SSE token refresh is critical for long-lived connections
- N+1 queries are high impact (50% performance)
- Cache headers overlooked but important

### **Key Insights:**
- API compatibility is 100% ✅
- Real-time systems mostly good (95%) — token refresh needed
- Performance has low-hanging fruit (cursor pagination, indexing)

### **Recommendations:**
1. Start small (critical 3 tasks)
2. Run tests frequently
3. Communicate daily
4. Don't skip documentation
5. Plan for 10% buffer time

---

## 🔗 **Quick Links**

| Document | Purpose | Read Time |
|----------|---------|-----------|
| [Backend Critical 3](BACKEND_CRITICAL_3_TASKS.md) | Sprint 1 tasks | 20 min |
| [Flutter Medium 6](FLUTTER_MEDIUM_PRIORITY_TASKS.md) | Sprint 2 tasks | 30 min |
| [Low Priority 8](LOW_PRIORITY_TASKS.md) | Sprint 3+ tasks | 25 min |
| [API Integration Guide](FLUTTER_ENTegrasyon_KILAVUZU.md) | Reference | 15 min |
| [Performance Report](PERFORMANS_ANALIZI.md) | Context | 10 min |

---

## 📊 **Project Statistics**

```
Total Tasks:           20 görev
Estimated Effort:      10-16 hafta
Team Size:             4-6 dev
Documentation Pages:   8 (extensive)
Code Examples:         100+
Test Procedures:       25+

Performance Gains:
- Sayfa açılış:        -40%
- Database queries:    -50% to -90%
- Network traffic:     -20% to -90%
- SSE stability:       95% → 99%+

Quality Improvements:
- Type safety:         0 → 100% enums
- Code review:         100%
- Test coverage:       85%+
```

---

**Last Updated:** 2026-09-24  
**Status:** 🔴 Sprint 1 Ready (Backend team, başla!)  
**Next Update:** Weekly (every Friday)

---

## 🎯 **Action Items (Right Now)**

### **Backend Team (Immediately)**

1. ✅ Read [`BACKEND_CRITICAL_3_TASKS.md`](BACKEND_CRITICAL_3_TASKS.md)
2. ✅ Setup 3 parallel development tracks
3. ✅ Daily standup 09:00 tomorrow
4. ✅ Target: Ready for Flutter Sprint 2 (Oct 1)

### **Flutter Team (Standby)**

1. ✅ Read [`FLUTTER_MEDIUM_PRIORITY_TASKS.md`](FLUTTER_MEDIUM_PRIORITY_TASKS.md)
2. ✅ Prepare environment & dependencies
3. ✅ Ready to start Oct 1 (after Sprint 1)
4. ✅ Target: APK 1.0.600+ by Oct 15

### **Infrastructure Team (Planning)**

1. ✅ Read [`LOW_PRIORITY_TASKS.md`](LOW_PRIORITY_TASKS.md)
2. ✅ Prepare for Q4 2026 (Ekim)
3. ✅ Quick wins planning (cursor, compression)
4. ✅ CDN & monitoring setup (paralel)

---

**Let's ship it! 🚀**

