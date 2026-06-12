# Canlifal Flutter — Gap analizi (2026-06-11)

Kaynak: kullanıcı analiz raporu + `FLUTTER_API_DOCS.md` + üretim envanteri.

## Özet

| Alan | Durum |
|------|--------|
| Tamamlanan modüller | Auth JWT, profil, sosyal, DM (REST), bildirim, sesli oda, TRTC, DJ, canlı yayın (temel), hediye, cüzdan |
| Kritik eksik | Fal LLM/SSE streaming, production smoke (FCM, membership, PK) |
| Yüksek eksik | Oyun odası UI, ajans, rüya servisleri, achievements API bağlantısı |
| Web–mobil fark | Fal (SSE vs yerel), oyunlar (liste vs oda), ajans (yok), DM (polling vs Socket.IO) |

## Bu oturumda ele alınanlar

- `docs/FLUTTER_API_DOCS.md` — tam API referansı repoya eklendi
- `api_endpoints.dart` — auth reset/change, ajans, blog, teller gifts, fortune pin/rate
- **Fortune SSE** — `FortuneSseService` + oturumlu fal akışı
- **Reset password** — `/auth/reset-password?token=` native sayfa
- **Achievements** — `AchievementsRemoteDataSource` + Growth Hub rozet listesi
- `.gitignore` — `curl-*.json`, `t-*.json`, `ci-runs.json`

## Kalan görevler (öncelik)

### Kritik
- Production smoke: `/api/membership/packages`, `/api/devices/fcm`, `/api/pk/*`, YouTube stream
- Ajans modülü (5 ekran + `AgencyRemoteDataSource`)

### Yüksek
- Oyun odası native UI (`GamesRemoteDataSource` genişletme)
- Rüya modülü (`DreamRemoteDataSource` — diary, contest, weekly report)
- Sesli oda 15 koltuk (üretim şu an 11; web envanterinde 15 — ürün kararı gerekli)

### Orta
- DM Socket.IO realtime
- Blog native detay (yorum/beğeni)
- Video TikTok dikey akış
- Change-password: `POST /api/auth/change-password` (şu an `PATCH /api/me`)

Detaylı görev listesi: analiz raporu `gorev_listesi` (K1–D4).
