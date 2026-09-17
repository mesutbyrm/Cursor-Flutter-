# CanlıFal — Canlı PK / Battle sistem analizi

> Oluşturulma: 2026-09-17 · Kod tabanı: `mobile/` · Üretim API: `https://canlifal.com`

## Özet

Canlı 1v1 PK için **tek ana yüzey** `LivePkSplitVideoLayer` + `liveVideoPkProvider` + `PkSessionNotifier` / `PkService` üçlüsüdür. Sesli oda PK ayrı sayfa (`voice_pk_battle_page.dart`) ve aynı `PkService` / `pk_session_notifier` ailesini paylaşır. Yeni paralel PK motoru **yazılmamalı**; mevcut provider ve lock katmanları genişletilir.

## PK ile ilgili dosyalar (canlı yayın)

| Alan | Dosyalar |
|------|----------|
| Split UI | `live_pk_split_video_layer.dart`, `live_pk_immersive_video_pane.dart`, `live_pk_reference_score_bar.dart`, `live_pk_broadcast_overlay.dart` |
| Davet | `pk_start_sheet.dart`, `live_pk_invite_flow.dart`, `live_pk_invite_listener.dart`, `pk_invite_dialog.dart` |
| State | `live_video_pk_provider.dart`, `pk_session_notifier.dart`, `pk_session_phase_provider.dart`, `pk_session_phase.dart` |
| Kilit / dedup | `live_pk_action_lock_provider.dart`, `live_pk_ended_lock_provider.dart`, `live_invite_dedup_provider.dart` |
| Timer | `live_pk_resolved_timer.dart`, `PkBattle.remainingBattle` + `serverNow` skew (`pk_service.dart`) |
| Skor / ingest | `live_pk_ingest.dart`, `live_pk_side_resolver.dart`, `pk_status_helper.dart` |
| TRTC | `live_broadcast_room_page.dart` (`_ensurePkTwoWayRtc`), `live_pk_trtc_anchor.dart`, `trtc_room_manager.dart` |
| Sonuç UI | `live_pk_pane_outcome_overlay.dart`, `live_pk_outcome_latch.dart`, `pk_status_pill.dart` |
| Sohbet | `live_pk_chat_stream.dart`, `live_pk_reference_chat_overlay.dart` |

## Backend endpointleri (mobil — değiştirilmez)

| İşlem | Endpoint / yöntem |
|--------|-------------------|
| PK state / aksiyonlar | `GET/POST` `ApiEndpoints.livePk` → `/api/live/pk` (`action`: create, accept, reject, cancel, end) |
| Video stream PK | `live_field_pk_api.dart`, `pk_battle_remote_datasource.dart` → `/api/video-streams/pk`, `pk-battle`, `/api/pk/me/invites` |
| Oda PK (sesli) | `POST /api/chat/rooms/{roomId}/pk` |
| Skor (like hediye vb.) | Mevcut live PK score POST — kılavuz §9 `LiveStream` grubu |

Yeni endpoint **uydurulmaz**; eksik backend özelliği ürün notu olarak raporlanır.

## Eventler ve gerçek zamanlı

- **SSE:** `chat_room_providers_sse.dart`, `live_pk_owned_streams_socket_provider.dart` — battle map ingest → `liveVideoPkProvider.applyRemoteBattle` / `PkSessionNotifier.ingestFromSse`
- **Gift:** `gift_session_controller` — PK pane toast + gifter strip
- **Davet dedup:** `live_invite_dedup_provider` + `livePkInviteDedupKey`

## State modelleri

- `PkBattle` / `PkStatus` — `pk_models.dart`
- `LiveVideoPkState` — ham `Map` battle + `unifiedMatchId`
- `PkSessionPhase` — istemci faz makinesi (`pk_session_phase.dart`)

### Spec fazları → mevcut eşleme

| Spec | Mevcut |
|------|--------|
| IDLE | `PkSessionPhase.idle` |
| INVITE_SENT | `PkSessionPhase.requesting` + `PkStatus.pending` (gönderen) |
| INVITE_RECEIVED | `PkSessionPhase.incoming` |
| INVITE_ACCEPTED / PK_PREPARING | `PkSessionPhase.accepting` / `connecting` + `PkStatus.starting` |
| PK_COUNTDOWN | `LivePkPreparingOverlay` + `starting` status |
| PK_ACTIVE | `PkSessionPhase.active` + `isLivePkActiveStatus` |
| PK_FINISHING / PK_RESULT | `ending` → `ended` + pane outcome / result flash |
| PK_CLEANUP | `livePkEndedLock` + `refresh` → split kapanır, cohost TRTC kalır |
| INVITE_REJECTED / CANCELLED / TIMEOUT | `rejected`, `cancelled`, `expired` |

## Timer sistemi

- Sunucu: `endsAt`, `expiresAt`, `serverNow` → `PkService._clockSkew`
- UI: `LivePkResolvedTimer` — tek `Timer.periodic` owner, `onExpired` idempotent flag

## Gift / skor

- Skor **yalnızca** battle map (`score1`/`score2`, `leftScore`/`rightScore`) ve backend eventlerinden
- `livePkBattleIngestFingerprint` — REST tekrarlarını azaltır
- Skor artış animasyonu: `live_pk_score_burst_provider.dart` + `LivePkScorePopOverlay`

## TRTC

- PK aktif: iki yönlü oda, izleyici `publishLocal: false`
- Layout değişimi **rejoin tetiklemez** (`liveActiveBroadcastStreamIdProvider`, anchor resolve)

## Navigation

- `pkImmersive` = `isLivePkBroadcastStage` — tekli video chrome gizlenir, split kalır
- Like: `_onDoubleTapHeart` → PK skor POST, layout değişmez

## Bilinen buglar (durum)

| Bug | Durum |
|-----|--------|
| Like → tekli ekran | `inPk` guard eklendi — regression test önerilir |
| Timer çift / donma | `LivePkResolvedTimer` tek owner |
| Berabere → tam ekran yayın | `PkStatusPillMode.endedDraw` + draw flash |
| PK bitince TRTC kopması | Cleanup yalnızca PK state; RTC ayrı lifecycle |
| Rakip video kaybı | `preferRemoteUserId`, PK RTC tüm rollerde dinleniyor |

## Duplicate / çakışan sistemler

- `live_pk_battle_page.dart` — eski/alternatif rota; broadcast içi split **birincil**
- `live_pk_premium_overlay.dart` — legacy; broadcast `LivePkSplitVideoLayer` tercih
- `PkWinnerCelebration` — sesli hub / `pk_result_page`; canlı split’te kullanılmıyor

## Kalan backend doğrulama

- Ortak PK sohbet: rakip yayıncının host stream chat odasına yazma izni
- `room1`/`room2` sesli PK yanıtı

## İstemci (1.0.550+591)

- `resolveLivePkAuthoritativeOutcome` — `winnerId` / `isDraw` sonra skor
- `LivePkEventDedup` — `eventId` / `transactionId` tekrarları
- PK bitiş: 7 sn gecikmeli battle cleanup (`liveVideoPkProvider`)
- Foreground: `refresh()`; reconnect banner PK metni
