# APK yayın kilidi — bekleyen özellikler

Yeni `apk-latest` yalnızca bu listedeki maddeler **mobil kodda tamamlandığında** yayınlanır.
CI: `scripts/apk-pending-features-gate.sh` (release gate madde 2 sonrası).

| # | Özellik | Dosya / işaret |
|---|---------|----------------|
| 1 | Sesli oda hediye panelinde hediye kutusu | `voice_premium_gift_panel_2026.dart` → `Hediye kutusu` |
| 2 | Canlı yayın hediye panelinde hediye kutusu | `premium_gift_panel.dart` → `gift_box` |
| 3 | Hediye kutusu UI + API | `gift_box_panel_section.dart` |
| 4 | SSE hediye kutusu yenileme (oda) | `chat_room_providers_room_sync.dart` → `gift_box_` |
| 5 | Tanış Kaynaş — etkileşimler sekmesi | `tanis_kaynas_page.dart` → `socialDiscoveryActionsProvider` |
| 6 | Tanış Kaynaş — hashtag & takım | `tanis_kaynas_page.dart` → `socialTrendingHashtagsProvider` |
| 7 | Tanış Kaynaş — favori aksiyonu (süper beğeni) | `tanis_discover_tab.dart` → `favorite` |

**Sürüm bump:** `mobile/pubspec.yaml` ve CHANGELOG yalnızca bu gate PASS olduktan sonra artırılır.
