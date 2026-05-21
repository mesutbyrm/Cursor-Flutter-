# Hediye sistemi (TikTok tarzı)

## Backend (`api/`)

| Alan | Açıklama |
|------|----------|
| `Gift` | `slug`, `name`, `icon`, `animation`, `animationType`, `price`, `rarity`, `platform`, `sound` |
| `GiftEvent` | Gönderim kaydı, combo, `streamId` / `roomId` |

### Uçlar

- `GET /api/gifts?platform=mobile|web`
- `GET /api/video-streams/gifts?platform=mobile` (mobil uyumluluk)
- `POST /api/video-streams/:streamId/gifts` — `{ giftTypeId, quantity, platform }`
- `GET /api/video-streams/:streamId/gifts` — olay listesi
- `GET /api/video-streams/:streamId/gifts/leaderboard` — top gifters

### Socket.IO

- `joinStream` / `leaveStream`
- `gift` / `giftSent` olayları

Seed: `npm run db:seed:gifts` (api dizininde)

## Flutter

- `features/gifts/` — domain, cache, ses, premium panel, animasyon oynatıcı
- **Rarity:** Common → Mythic (neon glow, fullscreen süresi)
- **Animasyon:** Lottie (yerel), Rive (`.riv`), SVGA (ağ / pulse fallback)
- **Combo:** 4 sn pencere (`LiveGiftController`)
- **Performans:** `GiftCacheService`, yatay `ListView` lazy, `RepaintBoundary`

## Yerel animasyon dosyaları

| Dosya | Hediye |
|-------|--------|
| `assets/gifts/lottie/*.json` | gul, kalp, yildiz, tac, roket |
| `assets/gifts/rive/diamond.riv` | elmas (ekleyin) |
| `assets/gifts/svga/galaxy.svga` | galaksi (ekleyin) |
| `assets/gifts/sounds/*.mp3` | rarity SFX (isteğe bağlı) |
