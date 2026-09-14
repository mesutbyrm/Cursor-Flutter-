# Live broadcast room — modül haritası

Ana sayfa: `live_broadcast_room_page.dart` (TRTC/SSE/state orchestration).

| Modül | Dosya | Sorumluluk |
|--------|--------|------------|
| Chips | `live_broadcast_room_chips.dart` | Katılım / beğeni chip |
| Gifts | `live_broadcast_room_gift_overlays.dart` | Hediye motoru + feed |
| Gift panel | `live_broadcast_room_gift_panel_overlay.dart` | Alt hediye paneli |
| Host | `live_broadcast_room_host_overlays.dart` | Misafir + fal istek merkezi |
| Connection | `live_broadcast_room_connection_overlays.dart` | Away / reconnect / VIP |
| HUD | `live_broadcast_room_hud_overlays.dart` | Müzik, hedef, PK rail |
| Viewer rail | `live_broadcast_room_viewer_rail.dart` | Beğeni / fal yan rail |
| Host away | `live_broadcast_room_host_away_overlay.dart` | Yayıncı grace tam ekran |
| Video/PK | `live_pk_split_video_layer.dart`, `live_room_video_background.dart`, `_videoLayer` (state) | TRTC video katmanı |
| Chat | `live_room_chat_fal_panel.dart` + ana sayfa chrome | Sohbet + fal form |
| PK | `live_pk_premium_overlay.dart`, `pk_room_live_section.dart` | PK UI |
| Moderation | `live_moderation_sheet.dart` | Moderasyon sheet |
| Lifecycle | `live_broadcast_ended_flow.dart` | Yayın bitiş akışı |

TRTC koordinasyonu, SSE `ref.listen` ve chat chrome düzeni ana state dosyasında kalır (davranış değişmedi).
