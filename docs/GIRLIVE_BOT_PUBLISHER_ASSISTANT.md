# GirLive Bot — Yayıncı Asistanı (§37–50)

## Flutter (bu repo)

| Bileşen | Konum |
|---------|--------|
| Panel «🤖 GirLive — Yayıncı Asistanım» | `mobile/lib/features/voice_hub/girlive/presentation/sheets/girlive_publisher_assistant_sheet.dart` |
| Oturum metrikleri (cihaz) | `girlive/presentation/providers/girlive_publisher_session_provider.dart` |
| Özel SSE `girlive_publisher` | `chat_room_providers_room_sync.dart` |
| Patron hitap kuralı (istemci) | `girlive/girlive_patron_address.dart` — sunucu selamları için aynı kural deploy edilmeli |
| Sohbet sızıntı filtresi | `voice_chat_message_filters.dart` → `isPublisherPrivateLeak` |

Oda yönetimi → **Yayıncı Asistanım** (yalnızca oda sahibi).

## Backend (canlifal.com — deploy gerekli)

Şablon: `backend-parity/girlive-publisher-assistant/README.md`

Üretim uçları kılavuz §9.3.2 ile tanımlı. Deploy öncesi mobil panel yerel oturum verisi + 404 toleransı kullanır.

## Kabul testleri (§50)

| Madde | Durum |
|-------|--------|
| Yayıncı oda süresini görür | ✅ yerel oturum |
| Açılış/kapanış sunucudan | ⏳ backend `end-report` |
| Hediye özeti gerçek işlem | ⚠️ oturum leaderboard; net cüzdan `VoiceRoomOwnerSummaryPage` |
| PK kazan/kaybet | ✅ yalnız backend doğrulanmış `winnerId` ile oturum |
| Başka yayıncı verisi görünmez | ✅ hedefli SSE + owner UI |
| Gün sonu mükerrer rapor | ⏳ backend idempotent `end-report` |
| Tavsiyeler veri destekli | ✅ `GirLivePublisherAdvice` |
| Jeton/PK herkese açık mesajlar | ⏳ admin `girlive-bot` + sunucu scheduler |
| Patron yalnız admin/yönetici | ✅ istemci kural + test; selam sunucuda doğrulanmalı |

**Not:** Repo içi PR #19 (Navbar) GirLive ile ilgili değildir; entegrasyon §9.3.2 + bu dokümandır.
