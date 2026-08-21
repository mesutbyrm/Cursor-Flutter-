# Canlifal — Oyun Merkezi + Tüm Oyunlar V2

**Sürüm:** 1.0.329+365  
**Dal:** `cursor/games-v2-premium-5ac6`  
**Tarih:** 2026-08-21

## Özet

Oyun Merkezi ve çok oyunculu oda akışları production kurallarına yaklaştırıldı: backend canonical state, doğru `gameType` ile hamle, sahte liderlik verisi kaldırıldı, oda izolasyonu / event dedup / reconnect eklendi, premium oyun kartları ve XOX tahta UI (backend board alanı varsa) uygulandı.

---

## GAME CENTER

| Öğe | Durum |
|-----|--------|
| `/games-hub` → `GamesHubPage` | API katalog + odalar + premium kartlar |
| `/games-hub/lobby` → `GameCenterPage` | Jeton, katalog, Okey 101 CTA, liderlik |
| Ana sayfa **Oyun Merkezi** CTA | `/games-hub` — çalışır |
| Katalog boşsa | `GameCatalogFallback.all` (mevcut sistem) |
| Sahte liderlik (Merve/Yiğit/Ece) | **Kaldırıldı** — boş state |

---

## Games (Hub)

- Backend `GET /api/games` listesi; fallback katalog
- Premium `GameCatalogCard`: görsel URL → gradient fallback, jeton, oda/oyuncu sayısı
- Oda oluştur / otomatik eşleş → `/games-room/:id?game=<gameId>`
- Açık oda yoksa: **"Şu anda açık oyun odası yok."**

---

## XOX

| Konu | Uygulama |
|------|-----------|
| State | Backend `raw` canonical; Flutter board üretmez |
| Board | `board` / `grid` / `cells` parse |
| Hamle | `POST` move API; optimistic UI yok |
| Sıra | `currentTurn` / `player1Id` eşlemesi |
| Kazanan | Backend `winner` / `result` |
| UI | 3×3 tahta, min ~72px hücre (touch) |

**Not:** Tam iki cihaz senkronu backend board + polling ile; native XOX sunucu kuralları backend’e bağlı.

---

## Tombala / Tavla / Pişti / Okey

| Oyun | Flutter |
|------|---------|
| **Okey 101** | Tam native tahta (`Okey101RoomPage`) |
| **Okey (klasik)** | Backend varsa generic oda + JSON state; fake okey yok |
| **XOX** | Board UI (state varsa) |
| **Tombala, Tavla, Pişti** | Generic oda ekranı — backend state gösterimi; client random yok |

---

## Game State / Turn / Score / Winner

- `GameStateParser`: status, turn, scores, winner, players (dedupe id)
- `GameRoomController`: polling 5s, roomId eşleşmesi, `eventId`/`moveId` dedup
- Oyun bitişi: backend status/winner; Flutter karar vermez

---

## Real-time

- **HTTP polling (5s)** — mevcut mimari korundu
- Socket.IO **eklenmedi**
- Oyun chat: `POST /api/games/room/{id}/chat`

---

## Reconnect

- `GameRoomLifecycleMixin`: foreground → `reconcileOnResume()` → state yeniden çekilir
- Provider `autoDispose`: odadan çıkınca listener/timer kapanır
- Yanlış oda eventi: `GameStateParser.roomMatches` ile filtre

---

## Multi-device / Multi-room

- Her oda `gameRoomControllerProvider(roomId)` — ayrı family
- Oda A eventleri Oda B provider’ına gitmez (family + roomId guard)
- Hamle dedup: aynı `moveId` iki kez state güncellemez

---

## Performance

- Board widget’ı ayrı; tahta dışı blur yok
- `GameCatalogCard` cached network image
- Gereksiz full-app spinner yerine oda skeleton

---

## Tests

```bash
cd mobile && dart analyze
cd mobile && flutter test test/features/games/
```

- `game_move_dedupe_test.dart`
- `game_state_parser_test.dart`
- Mevcut: `okey101_engine_test.dart`, `okey101_models_test.dart`

**Manuel (üretim hesap + 2 cihaz):** XOX oda → A hamle → B polling ile görür → winner eşleşmesi.

---

## Backend Eksikleri

1. **`GET/POST /api/games/rooms`**, **`/api/games/auto-match`** — prod’da 404 olabilir; oda listesi/eşleşme boş veya hata
2. **XOX / Tombala / Tavla / Pişti** — çoğu odada yalnızca generic JSON state; oyuna özel sunucu kuralları/board alanları dokümante değil
3. **Klasik Okey** — Okey 101 dışında tam tahta UI yok; backend okey state şeması net değil
4. **Oyun SSE** — envanterde yok; polling dışında push yok (gecikme ~5s)
5. **`/api/games/room/{id}/join`** legacy path prod’da farklı olabilir

---

## Fake / Hardcoded Data (temizlenen)

| Önceki | Sonra |
|--------|--------|
| `_demoLeaderboard()` (Merve, Yiğit, …) | Boş liste + empty UI |
| Leaderboard teaser hardcoded top-3 | Empty state |
| `sendMove` → her zaman `gameType: okey101` | Odadan gelen gerçek `gameType` |
| Router loading → `Okey101RoomPage` | `GameRoomLoadingPage` |
| Otomatik eşleş → `createLiveRoom` | `autoMatchLiveRoom` → `autoMatch` |
| `okey101_local_session.dart` (fake local rooms) | **Silindi** |

Mini oyunlar (çark, zar, hazine): client random + skor POST — mevcut API sözleşmesi; jeton maliyeti backend’den (`GameCatalogItem.jetonCost`).

---

## Değişen Dosyalar

**Yeni**

- `mobile/lib/features/games/domain/game_move_dedupe.dart`
- `mobile/lib/features/games/domain/game_state_parser.dart`
- `mobile/lib/features/games/presentation/widgets/game_catalog_card.dart`
- `mobile/lib/features/games/presentation/widgets/game_catalog_assets.dart`
- `mobile/lib/features/games/presentation/widgets/game_board_widgets.dart`
- `mobile/lib/features/games/presentation/pages/game_room_loading_page.dart`
- `mobile/test/features/games/game_move_dedupe_test.dart`
- `mobile/test/features/games/game_state_parser_test.dart`
- `docs/GAMES_V2.md`

**Güncellenen**

- `game_remote_datasource.dart`, `game_providers.dart`, `game_models.dart`
- `game_center_repository_impl.dart`, `game_center_repository.dart`
- `game_center_page.dart`, `game_center_leaderboard_page.dart`, `game_play_pages.dart`
- `games_hub_page.dart`, `game_room_page.dart`, `game_room_router_page.dart`
- `game_center_providers.dart`, `mobile/pubspec.yaml`, `mobile/CHANGELOG.md`

**Silinen**

- `mobile/lib/features/games/data/okey101_local_session.dart`

---

## Sonraki adım (11. aşama)

Bildirimler + Mesajlar + Ayarlar + uygulama içi genel navigasyon.
