# Live broadcast room — modül haritası

Ana sayfa: `live_broadcast_room_page.dart` (TRTC/SSE/state).

| Modül | Dosya | Sorumluluk |
|--------|--------|------------|
| Chips | `live_broadcast_room_chips.dart` | Katılım / beğeni chip |
| Gifts | `live_broadcast_room_gift_overlays.dart` | Hediye motoru + feed |
| Host | `live_broadcast_room_host_overlays.dart` | Misafir + fal istek merkezi |
| Connection | `live_broadcast_room_connection_overlays.dart` | Away / reconnect / VIP / katılım |
| HUD | `live_broadcast_room_hud_overlays.dart` | Müzik, hediye hedefi, PK rail |
| Video/PK | `live_pk_split_video_layer.dart`, `live_room_video_background.dart` | Video katmanı |
| Chat | `live_room_chat_fal_panel.dart` | Sohbet + fal paneli |
| PK | `live_pk_premium_overlay.dart`, `pk_room_live_section.dart` | PK UI |
| Moderation | `live_moderation_sheet.dart` | Moderasyon sheet |
| Lifecycle | `live_broadcast_ended_flow.dart` | Yayın bitiş akışı |

TRTC koordinasyonu ve SSE dinleyicileri ana state dosyasında kalır (davranış değişmedi).
