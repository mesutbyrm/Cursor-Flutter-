# Realtime — oda oturumu sahipliği (Faz 6)

**Tarih:** 2026-10-06 · **Dal:** `main`

Bu belge duplicate sistemlerin **bilinçli ayrımını** tanımlar; kör dosya silme yapılmaz.

## Tek yazıcı kuralı

| Katman | Sahip | Sorumluluk |
|--------|--------|------------|
| Giriş / çıkış / TRTC / SSE attach | `VoiceRoomLiveController` | `join-room`, `live/heartbeat`, `live/leave-room`, presence, SSE handler'lar |
| Canonical presence/koltuk (SSE/API merge) | `RoomSessionManager` | `applyServerEvent`, durum makinesi, **delegateLifecycleToHost: true** iken API join/heartbeat **yok** |
| Idempotent leave sırası | `RoomLeaveCoordinator` | `leaveRoomSession` adımları — `VoiceRoomLeavePipelineSpec` |
| SSE lease | `SseConnectionHub` | refCount; keşif + oda içi paylaşım |
| Keşif sayaçları | `VoiceRoomsPresenceNotifier` | Aktif oda hariç SSE (`VoiceRoomDiscoverSsePolicy`) |

## RoomSessionManager + delegateLifecycleToHost

`chat_room_providers.dart` içinde manager **`delegateLifecycleToHost: true`** ile kurulur:

- Manager **join()/leave() API çağırmaz**; host `syncHostJoined` / `syncHostLeft` bildirir.
- SSE/poll ile gelen presence/koltuk manager üzerinden canonical tutulur.
- Çift heartbeat/join riski bu bayrak ile kapatıldı (CHANGELOG 1.0.598+).

## Arka plan (Spec 20)

- `SseHubLifecycleBinding` — SSE pause/resume, debounce: `VoiceRoomBackgroundRecoverySpec`.
- `VoiceRoomSessionLifecycleHost` — 45 sn arka plan sonra `app_background` leave; ön planda `resyncAfterSseReconnect`.

## Gelecek temizlik (opsiyonel)

- Manager'ı yalnızca event bus + lock facade'e indirgeme — **büyük refactor**, cihaz P0 sonrası.
- Gift Socket.IO yolu: SSE birincil (`setSocketPreferred(false)` SSE attach'te).

_Audit:_ [`REALTIME_ARCHITECTURE_AUDIT.md`](REALTIME_ARCHITECTURE_AUDIT.md)
