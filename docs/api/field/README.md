# Saha API — 7 modül indeksi

**Kaynak:** `docs/api/FLUTTER_API_REFERENCE_LIVE_FIELD.md` (16 Temmuz 2026)  
**Flutter:** `mobile/lib/features/live/data/datasources/live_field/`

| # | Saha | Dosya | Endpoint'ler |
|---|------|-------|--------------|
| 1 | Oda yaşam döngüsü | `live_field_room_lifecycle_api.dart` | `create-room`, `join-room`, `leave-room`, `heartbeat` |
| 2 | Oda keşif | `live_field_room_discovery_api.dart` | `GET /api/live/rooms` |
| 3 | Koltuk | `live_field_seats_api.dart` | `POST/GET /api/live/seats` |
| 4 | Mesaj | `live_field_message_api.dart` | `POST/GET /api/live/message` |
| 5 | Hediye | `live_field_gift_api.dart` | `gift-types`, `gift/send` |
| 6 | PK | `live_field_pk_api.dart` | `GET/POST /api/live/pk`, `pk/score` |
| 7 | Çevrimiçi | `live_field_online_users_api.dart` | `GET /api/live/online-users` |

Entegrasyon: `LiveRemoteDataSource`, `ChatRoomRemoteDataSource`, `ChatRoomGiftsRemoteDataSource`, `PkBattleRemoteDataSource` — önce `/api/live/*`, yedek kılavuz §9 uçları.
