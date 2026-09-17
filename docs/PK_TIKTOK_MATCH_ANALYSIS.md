# PK TikTok Match — analiz (2026-09-17)

## Flutter

| Alan | Konum | Not |
|------|--------|-----|
| PK split UI | `live_pk_split_video_layer.dart`, `live_pk_immersive_video_pane.dart` | 50/50 video; profil chip **üstte** (spec: alt-sol) |
| Live oda | `live_broadcast_room_page.dart` | `pkImmersive`, TRTC `_ensurePkTwoWayRtc`, gift/chat |
| PK state | `live_video_pk_provider.dart`, `pk_session_notifier.dart` | Skor map backend; ended cleanup 7s |
| RTC | `trtc_live_room_coordinator.dart`, `live_pk_trtc_anchor.dart` | PK’da `twoWayVideo` + compound join |
| Chat | `live_room_providers.dart`, `live_pk_reference_chat_overlay.dart` | Hediye → `appendGiftSystemMessage` chat’e düşüyor |
| Gift | `gift_session_controller.dart`, `live_gift_controller.dart` | Session dedup var; **controller.notifications hiç doldurulmuyordu** |
| Like | `_postPkHeartScore` → `POST /api/live/pk/score` | PK aktif guard; kullanıcı limiti istemci tarafı eksik |
| Follow | `live_pk_streamer_chip.dart` → `profileRepository.follow` | Gerçek API |
| Timer | `live_pk_resolved_timer.dart` | `endsAt` + skew |
| Realtime | `GiftEventListener`, `live_gift_realtime_service`, video SSE | `sessionKey` = yayın `streamId` |

## Backend (mobil kullanım — uydurma yok)

| İş | Endpoint |
|----|----------|
| PK | `GET/POST /api/live/pk`, video-stream PK, `POST /api/live/pk/score` |
| Gift | `POST /api/video-streams/{id}/gifts` + idempotencyKey |
| Like (PK) | `live_field_pk_api.updateScore` |
| Follow | profile follow API |
| RTC | TRTC token compound join (mevcut coordinator) |
| SSE | live room + gift realtime |

## Kök sorunlar

1. **Hediye PK pane’de görünmüyor** — `LivePkPaneGiftToast` `liveGiftController.notifications` okuyor; liste hiç populate edilmiyor; asıl akış `giftSessionProvider`.
2. **Chat’te hediye/PK gürültüsü** — `GiftEventListener` → `appendGiftSystemMessage`; PK overlay tüm mesajları gösteriyor.
3. **PK hediye hedefi** — Viewer panel tek `receiverName`; iki yayıncı + self seçimi yok; `toUserId` / `pkMatchId` PK sheet’te eksik.
4. **Profil yerleşimi** — Chip üstte; PK puanı ayrı skor bandında, profil altında değil.
5. **Self-gift** — `assertReciprocalGiftAllowed` karşı taraf kontrolü; sender==receiver için atlanmalı (istemci).

## RTC

- PK split hazır olunca `_ensurePkTwoWayRtc` anchor odaya rejoin — doğru yön.
- Başarısız rejoin loglanıyor; cihaz testi şart.
- İzleyici `publishLocal: false` — iki yayıncı `publishLocal: true`.

## Realtime

- Gift: live realtime + gift session dedup (`processedEventIds`).
- PK battle: SSE ingest + `LivePkEventDedup`.
- Chat PK eventleri ayrı filtrelenmeli (istemci).

## Bu turda değişecek dosyalar

1. `live_pk_pane_profile_footer.dart` (yeni)
2. `live_pk_immersive_video_pane.dart`, `live_pk_split_video_layer.dart`
3. `live_pk_pane_gift_toast.dart`, `live_gift_controller.dart`
4. `live_pk_chat_filter.dart`, `live_pk_reference_chat_overlay.dart`
5. `live_room_providers.dart` (PK’da gift chat skip)
6. `live_pk_gift_picker_sheet.dart`, `live_broadcast_room_page.dart`
7. `live_gifts_remote_datasource.dart` (self-gift reciprocal skip)
8. `live_pk_like_budget.dart`, `_postPkHeartScore` guard
