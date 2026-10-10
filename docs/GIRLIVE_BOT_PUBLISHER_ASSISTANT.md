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

## Backend (canlifal.com)

**Merge:** [canlifal PR #36](https://github.com/mesutbyrm/canlifal/pull/36) (API + bot çekirdeği) · [PR #37](https://github.com/mesutbyrm/canlifal/pull/37) (leave + PK tetikleyiciler) · `full-source` → `dcdc156e73`.

Şablon: `backend-parity/girlive-publisher-assistant/README.md`

Mobil: deploy sonrası oda sahibi → **Yenile** → `GET …/publisher-assistant` **200** + isteğe bağlı SSE `girlive_publisher`. 404 ise henüz canlıya alınmamış dal/commit.

## Kabul testleri (§50)

| Madde | Durum |
|-------|--------|
| Yayıncı oda süresini görür | ✅ yerel oturum |
| Açılış/kapanış sunucudan | ✅ canlifal PR #36 — cihazda doğrula |
| Hediye özeti gerçek işlem | ✅ backend rapor + mobil oturum; cihazda brüt/net eşleştir |
| PK kazan/kaybet | ✅ backend + oturum; PK bot mesajları PR #37 |
| Başka yayıncı verisi görünmez | ✅ hedefli SSE + owner-only GET |
| Gün sonu mükerrer rapor | ✅ PR #36 idempotent `end-report` — cihazda tekrar dene |
| Tavsiyeler veri destekli | ✅ sunucu `tips[]` veya mobil `GirLivePublisherAdvice` |
| Jeton/PK herkese açık mesajlar | ✅ PR #36–#37 — admin `publicMessages` + PK/leave hook |
| Patron yalnız admin/yönetici | ✅ `resolveGreetingName` (backend) + mobil kural |

**Not:** Repo içi PR #19 (Navbar) GirLive ile ilgili değildir; entegrasyon §9.3.2 + bu dokümandır.
