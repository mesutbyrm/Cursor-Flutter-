# Flutter Backend Uyumluluk Raporu — 1.0.72+99

Tarih: 2026-07-23

## Özet

Flutter uygulaması mevcut `https://canlifal.com` API'leri ve web davranışı ile hizalandı. Yeni endpoint icat edilmedi; sahte/mock veri kullanılmadı.

---

## Düzeltilen dosyalar

| Alan | Dosyalar |
|------|----------|
| Açılış performansı | `home_bootstrap.dart`, `shell_prefetch.dart`, `home_feed_marquee.dart` |
| Trend video thumbnail | `shorts_ai_helper.dart`, `studio_publish_page.dart` |
| Ana sayfa falcı kartı | `home_approved_design.dart`, `psychics_home_section.dart` |
| Canlı fal TRTC / bahşiş | `psychic_video_controller.dart`, `psychic_room_sse_service.dart` |
| Sesli PK davet | `voice_pk_invite_listener.dart` |

---

## Performans optimizasyonları

- Ana sayfa API'leri **3 dalga** halinde yüklenir (banner/trend/live → voice/psychics → fortune/stories).
- Kabuk prefetch'te cüzdan/bildirim **çift istek** kaldırıldı (HomeHeader zaten yüklüyor).
- Marquee ticker + büyük hediyeler **T+4s** gecikmeyle başlar (`homeRealtimeBridgeDelay`).
- TRTC dispose'da `leave()` çağrısı eklendi (bellek/bağlantı sızıntısı önleme).

---

## Thumbnail sistemi

- `video_thumbnail` ile **5 kare**: %10, %25, %40, %60, %80.
- Süre `video_player` ile gerçek videodan okunur (sabit 12s heuristic kaldırıldı).
- Kapak seçilmeden **Video Yükle** engellenir; seçilen görsel `thumbnailKey` ile backend'e gider (mevcut presigned/register akışı).

---

## Canlı fal düzeltmeleri

- SSE: `gift` / `tip` event adları ve alias'lar genişletildi.
- Falcı bahşiş popup: `tellerUserId` zinciri + sinyal poll dedup; yalnızca falcı rolü popup alır (danışan kendi teşekkür banner'ını görür).
- `dispose`: TRTC coordinator `leave()` + engine `leave()` — oturum kopması/bellek sızıntısı azaltıldı.

---

## Hediye sistemi düzeltmeleri

- Canlı fal seansı: backend `POST /api/room/{id}/tip` + `GET/POST /api/room/signal` + SSE `/api/room/{id}/stream` (kılavuz §9.7).
- Canlı yayın / sesli oda: önceki oturumda `GiftEventListener` + SSE `gift` event yolu korundu; sender `publishLocal` + remote dedup.

---

## PK sistemi düzeltmeleri

- PK davet dinleyici: sahip olunan oda + `opponentVoiceRoomId` + `opponentId` eşleşmesi birleştirildi.
- Karşı oda sahibi `ownerId` eksik olsa bile kullanıcı kimliği ile dialog gösterilir.

---

## Backend ile birebir uyumluluk kontrolü

| Endpoint | Kullanım |
|----------|----------|
| `GET /api/short-videos/upload-url` + `POST register` | Thumbnail + video yükleme |
| `GET /api/fortune-tellers?online=true` | Ana sayfa falcılar |
| `GET /api/room/{id}/stream` | Canlı fal SSE |
| `GET/POST /api/room/signal` | Bahşiş yedek kanal |
| `POST /api/chat/rooms/{id}/pk` | Sesli PK davet |
| `GET /api/video-streams/{id}/stream` | Canlı yayın hediye SSE |

**Not:** Gelir paylaşımı, admin oranları ve web-only paneller backend/web tarafında kalır; Flutter salt okunur API değerlerini gösterir.
