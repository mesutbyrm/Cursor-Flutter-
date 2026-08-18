# Backend Requirements To Request

**Tarih:** 2026-08-18  
**Kural:** Endpoint/alan uydurma yasak. Eksik bilgi buraya eklenir; backend sağlayınca ilgili faz devam eder.

---

## Eksik #1 — Tam MCP sunucu paketi

**Alan:** Tüm sistemler (geliştirici araçları)

**Gerekli dosya:**
- `fortune_telling_platform/mcp-server/index.mjs` (tam sürüm, `@modelcontextprotocol/sdk` ile)
- `fortune_telling_platform/mcp-server/package.json` (yüklediğiniz sürüm)
- `fortune_telling_platform/mcp-server/package-lock.json` veya `npm install` sonrası `node_modules`

**Gerekli endpoint:** Yok (araç sunucusu)

**Neden gerekiyor:**
Flutter reposundaki `mcp-server/index.mjs` yalnızca `docs/API_ENDPOINT_MATRIX.md` okuyan **stub**. Yüklediğiniz README'deki `read_source`, `list_models`, `get_model`, `search_schema` araçları **implement edilmemiş**.

**Flutter'da etkisi:**
Agent'lar canlı `route.ts` ve Prisma şemasına bakamaz; parity audit eksik kalır; endpoint tahmini riski artar.

**Öncelik:** P0

**Backend'den istenen:**
```
mcp-server/
├── index.mjs          ← EKSİK (sadece README + package.json geldi)
├── package.json       ← GELDİ
├── package-lock.json
└── (npm install)
```

**Kurulum (sizin makinenizde):**
```bash
cd fortune_telling_platform/mcp-server
npm install
node index.mjs --selftest   # "status": "OK" beklenir
```

`.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "canlifal-backend": {
      "command": "node",
      "args": ["/MUTLAK/YOL/fortune_telling_platform/mcp-server/index.mjs"]
    }
  }
}
```

---

## Eksik #2 — OpenAPI + Endpoint Index

**Durum:** ✅ **SAĞLANDI** — 2026-08-18 (`backend-docs/openapi.json`, `backend-docs/endpoints_index.json`)

**Alan:** Tüm API

**Gerekli dosya:**
- `backend-docs/openapi.json` (veya `openapi__*.json`)
- `backend-docs/endpoints_index.json`

**Gerekli endpoint:** Tüm `/api/*` (spesifikasyon olarak)

**Neden gerekiyor:**
Request/response body alan adları, auth gereksinimleri ve HTTP metodları matrix'ten daha güncel ve makine-okunur.

**Flutter'da etkisi:**
DTO/model uyumsuzluğu, sessiz parse hataları, 400/422 hataları.

**Öncelik:** P0

**Backend'den istenen:**
Üretim backend reposundan veya CI artifact'ından güncel `openapi.json` + `endpoints_index.json` export.

---

## Eksik #3 — Prisma şeması (üretim)

**Durum:** ✅ **SAĞLANDI** — 2026-08-18 (`backend-docs/schema.prisma`)

**Alan:** Tüm modeller

**Gerekli dosya:**
- `prisma/schema.prisma` (canlı backend — `fortune_telling_platform`)

**Gerekli endpoint:** Yok

**Neden gerekiyor:**
`get_model` / `search_schema` MCP araçları ve Flutter DTO alan eşlemesi.

**Flutter'da etkisi:**
Yanlış alan adı (`userId` vs `user_id`, `gcid` vs `sub`) kullanımı.

**Öncelik:** P0

**Not:** Flutter reposundaki `api/prisma/schema.prisma` yerel Express mirror; üretim şeması değil.

---

## Eksik #4 — Backend kaynak ağacı (read-only)

**Alan:** Tüm API

**Gerekli dosya:**
- `nextjs_space/app/api/**/route.ts`
- `nextjs_space/lib/**` (auth, mobile-auth, servisler)

**Gerekli endpoint:** `get_endpoint` MCP aracının okuduğu dosyalar

**Neden gerekiyor:**
MCP `get_endpoint` gerçek handler kaynağını döndürür; matrix statik kalabilir.

**Flutter'da etkisi:**
Eski matrix ile canlı backend çeliştiğinde yanlış entegrasyon.

**Öncelik:** P0

**Backend'den istenen:**
Backend repo read-only erişimi VEYA `nextjs_space/` + `lib/` zip export.

---

## Eksik #5 — SSE event şema dokümanı

**Alan:** Voice / Live / Gifts / Notifications / Fortune / PK

**Gerekli dosya:**
- `backend-docs/SSE_EVENTS.md` (veya eşdeğeri)
- Her stream için: event type, JSON örnekleri

**Gerekli endpoint (örnekler):**
- `GET /api/chat/rooms/{id}/stream` — `dj_update`, `song_started`, `presence`, …
- `GET /api/notifications/stream`
- `GET /api/room/{sessionId}/stream`
- PK SSE events

**Neden gerekiyor:**
Flutter'da event adı/alan uydurma yasak; mevcut parser'lar backend ile doğrulanmalı.

**Flutter'da etkisi:**
Müzik ANR, gift sync hataları, stale state.

**Öncelik:** P0 (Voice müzik), P1 (diğerleri)

**Backend'den istenen:**
Her SSE endpoint için en az 1 örnek payload (gerçek log veya fixture).

---

## Eksik #6 — Müzik API tam sözleşmesi

**Alan:** Voice / Music

**Gerekli dosya:**
- `backend-docs/MUSIC_API.md` (güncel)
- Örnek response: `POST /api/chat/rooms/{roomId}/music-request-by-query`
- Örnek response: `POST /api/chat/rooms/{roomId}/song-request`
- `GET /api/chat/youtube-stream?videoId=`

**Gerekli endpoint:**
- `POST /api/chat/rooms/{roomId}/music-request-by-query` body: `{ "query": "..." }`
- `POST /api/chat/rooms/{roomId}/song-request`
- SSE `dj_update` / `song_started`

**Neden gerekiyor:**
P0 ANR/çalmama bug'ı — `musicUrl` formatı (stream URL vs YouTube watch), `playing`, `queuePosition` alanları net değil.

**Flutter'da etkisi:**
`!istek` donma, ses/video gelmeme.

**Öncelik:** P0

**Backend'den istenen:**
Oda `cmoohrbr` için gerçek bir `!istek` request/response + ardından gelen SSE event dump'ı.

---

## Eksik #7 — Tencent RTC token sözleşmesi

**Alan:** Voice / Live / Video call

**Gerekli dosya:**
- `GET/POST /api/trtc/token` request + response örneği
- `userId` / `roomId` / `role` mapping dokümanı

**Neden gerekiyor:**
TRTC join fail, ses açılmama, oda geçişi sorunları.

**Flutter'da etkisi:**
`voice_trtc_engine.dart`, `trtc_remote_datasource.dart`

**Öncelik:** P1

---

## Eksik #8 — PK state machine

**Alan:** Voice PK / Live PK

**Gerekli dosya:**
- PK akış dokümanı: REQUEST → ACCEPT/REJECT → START → SCORE → END
- SSE + REST endpoint listesi

**Gerekli endpoint:** `/api/pk/*`, `/api/live/pk/*`

**Neden gerekiyor:**
Dual backend routing (main vs games API) karmaşık; canonical path backend onayı gerekir.

**Öncelik:** P1

---

## Eksik #9 — Gift realtime canonical yol

**Alan:** Gifts

**Gerekli bilgi:**
Hediye gönderimi sonrası realtime: **SSE mi, Socket.IO mu, ikisi mi?**

**Neden gerekiyor:**
Flutter'da hem SSE (`gift_sse_dispatch.dart`) hem Socket.IO (`live_gift_realtime_service.dart`) var.

**Öncelik:** P1

---

## Eksik #10 — Test hesapları ve roller

**Alan:** QA / Acceptance

**Gerekli:**
| Rol | Açıklama |
|-----|----------|
| `TEST_USER` | Normal kullanıcı + jeton |
| `TEST_ROOM_OWNER` | Oda sahibi |
| `TEST_ADMIN` | Admin yetkisi |
| `TEST_LIVE_HOST` | Canlı yayıncı |
| `TEST_FORTUNE_TELLER` | Falcı |

**Neden gerekiyor:**
Android gerçek cihaz E2E; acceptance testleri (`docs/ACCEPTANCE_TESTS.md`).

**Öncelik:** P1

**Backend'den istenen:**
Test ortamı credentials (production değil) veya `mobile-register` ile oluşturma API'si + başlangıç jetonu.

---

## Eksik #11 — `backend-docs/` klasörü

**Durum:** ✅ **SAĞLANDI** — 2026-08-18 (OpenAPI, endpoints_index, schema, B1.12, MCP registry)

**Alan:** MCP resources

**Gerekli dosya:**
- `backend-docs/*.md` (MCP `docs://<dosya>.md` URI'leri)

**Öncelik:** P1

---

## İşlem sırası (önerilen)

1. **Eksik #1 + #4** — Tam MCP + kaynak ağacı → Cursor'da bağla
2. **Eksik #2 + #3** — OpenAPI + Prisma → DTO parity
3. **Eksik #5 + #6** — SSE + müzik → P0 bug doğrulama
4. **Eksik #10** — Test hesapları → Android E2E
5. **Eksik #7–#9** — FAZ 5–7 öncesi

---

## Tamamlandığında

Her eksik karşılandığında bu dosyada ilgili madde `✅ SAĞLANDI — <tarih>` olarak işaretlenecek ve `BACKEND_FLUTTER_PARITY_AUDIT.md` güncellenecek.
