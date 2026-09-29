# Backend ↔ Flutter parity durumu (2026-09 dalı)

> **Hedef kaynak:** [`mesutbyrm/canlifal`](https://github.com/mesutbyrm/canlifal/tree/docs/backend-flutter-parity-2026-09) — dal `docs/backend-flutter-parity-2026-09` (714 route, PR #1).  
> **Flutter sürümü (kaynak):** `mobile/pubspec.yaml` → güncel `main`.  
> **Tek entegrasyon kaynağı:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md)

## Ortam notu (2026-09-29)

`canlifal-backend/` — dal `docs/backend-flutter-parity-2026-09` (714 route). Son script:

| Script | Sonuç |
|--------|--------|
| `backend-route-parity.py --used-only` | **0** eksik kullanım |
| `backend-method-parity.py` | **607+** ok, **0 bad** (fortune slug şablonu düzeltildi) |

```bash
git clone -b docs/backend-flutter-parity-2026-09 https://github.com/mesutbyrm/canlifal canlifal-backend
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
python3 scripts/backend-method-parity.py canlifal-backend/nextjs_space
```

---

## Özet matris — sesli oda / canlı yayın / canlı falcı

| Alan | Flutter modül | Kanonik backend ailesi | Durum | Not |
|------|---------------|------------------------|-------|-----|
| **Sesli oda** | `voice_hub/` | `/api/chat/rooms/*` | **Hizalı (646+)** | PK REST ana origin + SSE; presence, POST pk + action |
| **Sesli PK davet** | `pk_battle_remote_datasource.dart` | `POST …/pk` `{action, battleId}` | **Düzeltildi (645+)** | `…/pk/{id}/respond` artık çağrılmıyor |
| **Sesli PK poll** | invite listener + remote provider | GET pk, GET me/invites | **İyileştirildi (644)** | Önbellek, SSE defer, lite stream battle |
| **Canlı yayın** | `live/` | `/api/video-streams/*` | **Hizalı** | join POST, leave POST (+ DELETE join yedek), SSE, pk-battle |
| **Canlı fal isteği (yayında)** | `live_fortune_request_datasource.dart` | `…/fortune-requests` | **Birincil doğru** | Yedek: `/api/live/fal-requests*` (parity paketinde var) |
| **Canlı falcı seans** | `live_psychics/` | `/api/fortune-tellers/sessions/*`, `/api/room/{sessionId}/*` | **Hizalı** | PATCH session `{action}`, GET/POST room messages, SSE sessions/stream |
| **Yayın misafir/PK** | `co_broadcast`, `live_video_pk` | `/api/live/guest`, `/api/video-streams/pk` | **Hizalı** | requestId, stream battle finalize |

---

## Sesli odalar — parity 2026-09 kontrol listesi

| Konu | Beklenen (backend dok.) | Flutter |
|------|-------------------------|---------|
| Giriş/çıkış | `POST` / `DELETE …/presence` | `chat_room_remote_datasource.dart` |
| Heartbeat | 15–30 sn `POST …/presence` | 15 sn; `seatIndex` gönderilir (koltuk stabilitesi) |
| PK create | `POST …/pk` `{action:create, targetRoomId\|guestUserId}` | `inviteVoiceRoom` çoklu body |
| PK accept/reject/cancel | `POST …/pk` `{action, battleId}` | `_postPkAction` (**respond yolu kaldırıldı**) |
| PK skor | Sunucu/hediye; admin score POST yok | UI score POST yok |
| SSE davet | `room_event` pk_invite / pk_requested + dedup | `chat_room_providers_room_sync.dart` |
| Aday liste | `GET …/pk/candidates?roomId=` | pk session candidates |
| Hayalet üye | Backend SSE penceresi ~5 dk | Mobil leave/guard; **sunucu TTL gerekir** |

---

## Canlı odalar (video stream)

| Konu | Flutter | Not |
|------|---------|-----|
| İzleyici join/leave | POST join, DELETE join → POST leave yedek | Kılavuz uyumlu |
| Mesaj / hediye / signal | `live_remote_datasource.dart` | §9 LiveStreamRepository |
| PK | `pk_battle_remote` + `live_video_pk_provider` | finalize `GET /api/video-streams/pk` aktif PK bitişi |
| Misafir | `GET /api/live/guest?view=sync`, requestId kabul | 635+ düzeltmeleri |
| Co-broadcast | PATCH co-broadcast | In-flight refresh |

---

## Canlı falcılar (Psychic / TRTC seans)

| Konu | Flutter | Not |
|------|---------|-----|
| Seans kabul/red | `PATCH /api/fortune-tellers/sessions/{id}` | `respondSession` |
| Oda mesajları | `GET/POST /api/room/{sessionId}/messages` | `fetchMessages` / `sendMessage` |
| SSE gelen istek | `GET /api/fortune-tellers/sessions/stream` | `psychic_incoming_sse_service` |
| TRTC | `/api/trtc/token` | P0 cihaz testi **OPEN** |

---

## Bilinen açık uçlar (mobil veya backend)

1. **Backend presence TTL** — hayalet katılımcı (mobil mitigasyon var).  
2. **P0/P1 cihaz** — PK davet E2E, hediye→PK skor, Psychic TRTC.

---

## Bu repoda yapılan son parity düzeltmesi

- **649+:** `live_pk_create_body_test` + ölü `join-seat` endpoint sabiti kaldırıldı.
- **648+:** Canlı PK create gövdesi üretim sözleşmesi; CI `pk_session_keep_alive` imza düzeltmesi.
- **647+:** Ölü PK uçları (`…/respond`, istemci `live/pk/score`, `postLivePkScore`); davet gövdesi sadeleştirme; parity script fortune slug.
- **646+:** `ApiBackendRouter` — sesli oda PK REST → `canlifal.com`; STAGE16 §1.
- **645+:** Sesli PK accept/reject/cancel — yalnızca `POST /api/chat/rooms/{roomId}/pk`.

Önceki oturumlar (636–644): presence guard, PK poll, auto-seat, canlı PK refresh, davet cache — `mobile/CHANGELOG.md`.

---

## İlgili dosyalar

- [`BACKEND_DOCS_ESLESME.md`](BACKEND_DOCS_ESLESME.md)  
- [`BACKEND_FLUTTER_AUDIT_2026-09-28.md`](BACKEND_FLUTTER_AUDIT_2026-09-28.md)  
- [`../backend-reference/canlifal_flutter_paketi/voice_room_api.md`](../backend-reference/canlifal_flutter_paketi/voice_room_api.md)  
- [`../.cursor/rules/flutter-integration-guide.mdc`](../.cursor/rules/flutter-integration-guide.mdc)
