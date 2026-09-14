# Live broadcast room — modül haritası

Ana sayfa: `live_broadcast_room_page.dart` (TRTC/SSE/state orchestration).

| Modül | Dosya | Sorumluluk |
|--------|--------|------------|
| Video | `live_broadcast_room_video_layer.dart` | TRTC/playback/PK split video UI |
| Chrome | `live_broadcast_room_chrome_column.dart` | Üst bar + PK yanıt + sohbet + alt bar |
| Chat | `live_broadcast_room_chat_overlay.dart` | Sohbet paneli + göster/gizle |
| Bottom | `live_broadcast_room_bottom_chrome.dart` | `LivePremiumBottomBar` + klavye padding |
| Chips | `live_broadcast_room_chips.dart` | Katılım / beğeni chip |
| Gifts | `live_broadcast_room_gift_overlays.dart` | Hediye motoru + feed |
| Gift panel | `live_broadcast_room_gift_panel_overlay.dart` | Alt hediye paneli |
| Host | `live_broadcast_room_host_overlays.dart` | Misafir + fal istek merkezi |
| Connection | `live_broadcast_room_connection_overlays.dart` | Away / reconnect / VIP |
| HUD | `live_broadcast_room_hud_overlays.dart` | Müzik, hedef, PK rail |
| Viewer rail | `live_broadcast_room_viewer_rail.dart` | Beğeni / fal yan rail |
| Host away | `live_broadcast_room_host_away_overlay.dart` | Yayıncı grace tam ekran |
| Phase | `live_session_phase.dart` | Oturum fazı enum |
| PK / moderation / lifecycle | mevcut widget’lar | PK overlay, moderation sheet, ended flow |

TRTC/SSE `ref.listen`, dispose ve navigation ana state dosyasında kalır.
