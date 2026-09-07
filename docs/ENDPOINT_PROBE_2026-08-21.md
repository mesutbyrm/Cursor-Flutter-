# Endpoint probe — 2026-08-21 (JWT auth)


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Sürüm:** 1.0.333+369  
**Base:** `https://canlifal.com`  
**Auth:** `POST /api/auth/mobile-login` test hesabı

## Sonuçlar

| HTTP | Endpoint | Mobil davranış |
|------|----------|----------------|
| 404 | `GET /api/notifications/unread` | `fetchUnreadCount()` → null → liste sayımı fallback ✅ |
| 404 | `GET /api/advisors/online` | `fetchOnlineAdvisors()` → `/api/mobile/home` veya `/api/fortune-tellers` ✅ |
| 404 | `GET /api/banners` | `fetchMobileHome()` compound; legacy path kullanılmıyor ✅ |
| 200 | `GET /api/mobile/home` | Ana sayfa birincil kaynak ✅ |
| 200 | `GET /api/fortune-request-types` | Fal türleri ✅ |
| 200 | `GET /api/bana-ozel` | Bana Özel katalog ✅ |
| 200 | `GET /api/games` | Oyun merkezi ✅ |
| 200 | `GET /api/messages` | DM konuşmalar ✅ |

## Not

404 uçlar için mobilde sahte veri gösterilmez; boş liste / gizli bölüm / alternatif API kullanılır.
