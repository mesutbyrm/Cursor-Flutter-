# Canlifal Flutter — Faz Planı (Master Prompt)

**Tarih:** 2026-08-18  
**Kural:** Bir faz **PASS** olmadan sonrakine geçilmez.  
**Test:** Android gerçek cihaz zorunlu.

---

## Faz durumu özeti

| Faz | Ad | Durum | Bloker |
|-----|-----|-------|--------|
| **0** | Backend + Flutter Audit | 🔄 **DEVAM** | Backend MCP/OpenAPI eksik |
| 1 | Core + Auth + API Architecture | ⏸ Bekliyor | FAZ 0 PASS |
| 2 | Profile | ⏸ | FAZ 1 |
| 3 | Social | ⏸ | FAZ 2 |
| 4 | Fal + Tarot | ⏸ | FAZ 3 |
| 5 | Live Stream | ⏸ | FAZ 4 |
| 6 | Voice Chat Rooms | ⏸ | FAZ 5 |
| 7 | Gifts + Jeton + PK | ⏸ | FAZ 6 |
| 8 | Trending / Shorts | ⏸ | FAZ 7 |
| 9 | Messages + Notifications | ⏸ | FAZ 8 |
| 10 | Global Performance | ⏸ | FAZ 9 |
| 11 | Security + Error Handling | ⏸ | FAZ 10 |
| 12 | Full E2E QA | ⏸ | FAZ 11 |
| 13 | Release Build | ⏸ | FAZ 12 |

---

## FAZ 0 — Backend + Flutter Audit

**Hedef:** Kod değiştirmeden tam envanter ve parity haritası.

**Çıktılar:**
- [x] `docs/FLUTTER_PROJECT_AUDIT.md`
- [x] `docs/BACKEND_FLUTTER_PARITY_AUDIT.md`
- [x] `docs/MISSING_BACKEND_REQUIREMENTS.md`
- [x] `docs/BACKEND_REQUIREMENTS_TO_REQUEST.md`
- [x] `docs/PHASE_PLAN.md` (bu dosya)

**Kabul kriterleri:**
- [x] Flutter yapısı belgelendi
- [x] Parity haritası oluşturuldu
- [ ] Backend MCP tam paket sağlandı
- [ ] OpenAPI + Prisma + SSE şemaları sağlandı
- [ ] P0 müzik ANR Android'de PASS

**FAZ 0 sonucu:** **INCOMPLETE** (backend dosyaları bekleniyor)

---

## FAZ 1 — Core + Auth + API Architecture

**Kapsam:**
- Merkezi `ApiClient` / Dio interceptor zinciri
- JWT refresh tek yolu
- Error envelope parsing (`{error}` vs `{success:false,error:{code,message}}`)
- Repository standardizasyonu
- God-file parçalama planı (değişiklik bu fazda başlar)

**Mevcut durum:** Büyük ölçüde mevcut; refactor + test.

**Bloker:** OpenAPI ile error format tablosu.

---

## FAZ 2 — Profile

**Kapsam:** Avatar, bio, followers, jeton, CFC, üyelik, rozetler, ayarlar.

**Mevcut:** `features/profile/` (~101 dosya) — geniş implementasyon.

**İş:** Backend parity doğrulama, gereksiz paralel API çağrılarını azaltma, skeleton UI.

---

## FAZ 3 — Social

**Kapsam:** Feed, post, story, like, comment, pagination.

**Mevcut:** `features/social/` + Instagram-style widgets.

---

## FAZ 4 — Fal + Tarot

**Kapsam:** Tüm fal türleri, SSE streaming, geçmiş, ödeme.

**Mevcut:** `features/fortune/` (~107 dosya).

---

## FAZ 5 — Live Stream

**Kapsam:** TRTC, chat, gift, viewer, PK, anında çıkış UI.

**Mevcut:** `features/live/` + `features/trtc/`.

**Risk:** Socket.IO gift path — FAZ 7 ile koordinasyon.

---

## FAZ 6 — Voice Chat Rooms

**Kapsam:** Oda, koltuk, müzik, SSE, TRTC, PK, çıkış.

**Mevcut:** `features/voice_hub/` (~312 dosya).

**P0 açık:** Müzik `!istek` ANR — bu faz PASS olamaz ta ki çözülene kadar.

---

## FAZ 7 — Gifts + Jeton + PK

**Kapsam:** Gift pipeline, bakiye (backend authoritative), PK state machine.

**Bloker:** Gift realtime canonical yol (SSE vs Socket.IO).

---

## FAZ 8 — Shorts / Trending

**Kapsam:** Dikey video, preload, pagination, like/comment/share.

**Mevcut:** `features/shorts/`.

---

## FAZ 9 — Messages + Notifications

**Kapsam:** DM, SSE, push, unread.

**Mevcut:** `features/messages/`, `features/notifications/`.

---

## FAZ 10 — Global Performance

**Kapsam:** Rebuild, memory leak, cache, SSE/RTC cleanup, ANR önleme.

**Not:** Voice müzik ANR bu fazın ön koşulu değil ama FAZ 6 bloker'ı.

---

## FAZ 11 — Security + Error Handling

**Kapsam:** Secret scan, auth edge cases, HTML response guard.

---

## FAZ 12 — Full E2E QA

25 senaryo (master prompt §33) — Android gerçek cihaz.

**Çıktı:** `docs/PHASE_12_ACCEPTANCE.md`, `docs/FINAL_CANLIFAL_FLUTTER_REPORT.md`

---

## FAZ 13 — Release Build

APK, signing, debug URL kontrolü, `docs/LATEST_APK_BUILD.md`.

---

## MCP entegrasyon planı

1. Backend'den tam `mcp-server/index.mjs` + kaynak ağacı al
2. Flutter repo `mcp-server/` stub'ını backend sürümüyle değiştir *(FAZ 1 öncesi tooling)*
3. `.cursor/mcp.json` path'ini düzelt
4. Cursor → Settings → MCP → `canlifal-backend` connected doğrula
5. Her faz başında ilgili endpoint'leri MCP `get_endpoint` ile doğrula

---

## Commit stratejisi (FAZ 1+)

```
phase-01-core-auth
phase-01-api-client
phase-02-profile
...
```

Büyük tek commit yasak.

---

## Şu an ne yapılmalı?

1. **Siz:** `BACKEND_REQUIREMENTS_TO_REQUEST.md` Eksik #1–#6 dosyalarını sağlayın
2. **Agent:** MCP bağlandıktan sonra parity audit güncelle
3. **Siz:** Android'de `1.0.256+292` ile müzik `!istek` test edin
4. P0 PASS olunca FAZ 0 kapatılır → FAZ 1 başlar

**FAZ 1'e geçiş:** ❌ Henüz uygun değil
