# Flutter-aktif uçlar — B1.12 MISSING_BACKEND_ENDPOINT çapraz kontrol

**Tarih:** 2026-08-18  
**Kaynak:** `backend-docs/B1_12_API_MCP_FLUTTER_PARITY.md` §8 (68 uç) + `mobile/lib` referansları + canlifal.com HTTP probe (anonim GET, auth uçları POST gövdesiz).

> B1.12 raporu iki host üzerinde GET+POST ile “yok” demişti. Aşağıdaki **Ağu 2026 canlı probe** bazı uçların artık var olduğunu veya farklı HTTP davranışı gösterdiğini ortaya koyuyor.

---

## Özet

| Kategori | Adet | Açıklama |
|----------|------|----------|
| B1.12 MISSING listesi | 68 | İki backend’de yok raporu |
| Flutter `api_endpoints.dart` / lib referansı | 66 | 2 uç kodda yok (`live-fal-request/create`, `live-fal-requests`) |
| Probe: **404** (anon GET) | 18 | Aşağıdaki P0 tablo |
| Probe: **200** (anon GET) | 2 | gifts insights/missions — B1.12 güncel değil |
| Probe: **400** (anon GET) | 6 | Muhtemelen **var** — JWT/body gerekli |

---

## P0 — Flutter çağırıyor, üretimde 404 (anon GET)

Bu uçlar mobilde aktif kullanılıyor; üretimde yoksa UI yedek/fallback ile çalışır veya özellik kısmi kalır.

| Uç | Flutter kullanımı | Probe | Öneri |
|----|-------------------|-------|-------|
| `GET /api/banners` | Ana sayfa banner | 404 | `GET /api/mobile/home` veya mevcut yedek |
| `GET /api/homepage` | Eski vitrin | 404 | `homepage-fortune-cards`, `mobile/home` |
| `GET /api/advisors/online` | Danışman şeridi | 404 | Boş liste yedeği |
| `GET /api/fan-clubs` | Fan kulüp bölümü | 404 | Boş kart yedeği |
| `GET /api/daily-rewards` | Günlük ödül | 404 | Özellik gizle / backend ekle |
| `GET /api/chat/music/popular` | Müzik paneli popüler | 404 | Yerel liste yedeği (kodda var) |
| `GET /api/pk/battles` | PK geçmişi | 404 | `live/pk/*` yollarına hizala |
| `GET /api/live-fal/pending` | Canlı falcı kuyruk | 404 | `fortune-tellers/sessions` ile doğrula |
| `GET /api/user/cosmetics` | Profil kozmetik | 404 | Ürün kararı / backend |
| `GET /api/social/public-stats` | Sosyal istatistik | 404 | `public-stats` alternatifi |
| `GET /api/notifications/unread` | Okunmamış sayı | 404 | `notifications` listesinden türet |
| `GET /api/fortune-access/consume` | Fal erişim | 404 | Backend veya kaldır |
| `GET /api/users/me/stats` | Profil istatistik | 404 | `user/stats` yedeği |
| `GET /api/users/me/gifts-received` | Alınan hediyeler | 404 | `user/received-gifts` (kılavuz §9) |
| `GET /api/short-videos/music/recommend` | Kısa video müzik | 404 | Boş öneri |
| `GET /api/games/history` | Oyun geçmişi | 404 | Games API host |
| `GET /api/tournaments/join` | Turnuva | 404 | Backend |

---

## P1 — B1.12 “MISSING” ama probe farklı (muhtemelen VAR)

| Uç | Probe (anon GET) | Not |
|----|------------------|-----|
| `GET /api/gifts/insights/feed` | **200** | B1.12 WRONG_HOST/MISSING güncel değil |
| `GET /api/gifts/missions` | **200** | Aynı |
| `GET /api/auth/mobile-send-verification` | **400** | Body yok → endpoint var |
| `GET /api/auth/mobile-verify-email` | **400** | Aynı |
| `GET /api/auth/mobile-sessions` | **400** | Aynı |
| `GET /api/auth/mobile/device-token` | **400** | Aynı |
| `GET /api/chat/youtube-audio` | **400** | `videoId`/`url` parametresi gerekli; `?url=` proxy kırık |

---

## P2 — Yönetim paneli (mobilde tanımlı, normal kullanıcı akışı dışı)

`/api/admin/mobile-auth`, `/api/admin/payment-*`, `/api/admin/payments/stream`, `/api/admin/voice-room-*` — admin rolü; mobilde yalnızca yetkili ekranlar.

---

## Müzik / !istek (P0 kod tarafı — Ağu 2026)

| Uç | Durum | Flutter davranışı |
|----|--------|-------------------|
| `POST …/music-request-by-query` | **404** üretim | Atlanır → `song-request` (`1.0.258+`) |
| `POST …/song-request` | 401 (var) | Kanonik istek yolu |
| `GET /api/chat/youtube-stream?videoId=` | 200 `mode:embed` | IFrame oynatıcı |
| `GET /api/youtube/search` | Arama | `!istek` yedek arama |
| İstemci `youtube_explode` | Kapalı üretimde | `1.0.259+` |
| Piped/Invidious resolve | Kapalı üretimde | `1.0.260+` |

Detay: [`MUSIC_API_PRODUCTION_PROBE.md`](MUSIC_API_PRODUCTION_PROBE.md)

---

## Sonraki adımlar

1. Backend: P0 404 uçları için ya route deploy ya da resmi “mobil alternatif path” tablosu.
2. B1.12 raporunu gifts + auth probe sonuçlarıyla yeniden üret.
3. Flutter: her P0 uç için mevcut fallback’i `api_endpoints.dart` yorumunda belgele (kılavuz §9 ile çelişme yok).

**İlgili:** [`REMAINING_WORK.md`](REMAINING_WORK.md) B2, [`BACKEND_REQUIREMENTS_TO_REQUEST.md`](BACKEND_REQUIREMENTS_TO_REQUEST.md)
