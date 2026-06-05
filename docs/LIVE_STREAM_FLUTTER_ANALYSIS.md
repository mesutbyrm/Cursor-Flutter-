# Canlı yayın ve hediye — Web ↔ Flutter analizi

Güncelleme: 2026-05-19 · Mobil sürüm hedefi: **1.0.126+128**

## 1. API uçları (canlifal.com)

| Adım | Metot | Yol | Auth |
|------|--------|-----|------|
| Yayın listesi | GET | `/api/video-streams?page=&limit=` | İsteğe bağlı (mobil Bearer) |
| Yayın oluştur | POST | `/api/video-streams` | **Bearer zorunlu** |
| Takipçi bildirimi | POST | `/api/video-streams/{id}/live-started` | Bearer |
| Yayın bitir | POST | `/api/video-streams/{id}/end` | Bearer |
| TRTC oda | POST | `/api/trtc/usersig` | Bearer önerilir (prod’da çoğu zaman JWT’siz de 200) |
| Hediye katalog | GET | `/api/video-streams/gifts?platform=mobile` | — |
| Hediye gönder | POST | `/api/video-streams/{id}/gifts` | Bearer (jeton düşümü) |
| Hediye listesi | GET | `/api/video-streams/{id}/gifts` | — |
| Yayın sohbeti | GET/POST | `/api/video-streams/{id}/messages` | Bearer (POST) |
| İzleyici join/leave | POST | `/api/video-streams/{id}/join` · `/leave` | Bearer |
| Socket.IO | — | `joinStream`, `streamMessage`, `viewerCount`, `streamEnded` | Mirror’da auth yok |

Web: NextAuth **çerez**. Flutter: **`Authorization: Bearer`** (`dio_provider.dart`).

## 2. Web vs Flutter akışı

### Yayın açma (yayıncı)

| | Web (beklenen) | Flutter |
|--|----------------|---------|
| 1 | POST `/api/video-streams` + body | Aynı (`createVideoStream`) |
| 2 | POST `.../live-started` | Aynı |
| 3 | TRTC `enterRoom(strRoomId = streamId)` | `TrtcRoomManager` + `TRTCAppScene.live` |
| 4 | Hediye socket `joinStream` | `LiveGiftSocketBridge` |

### İzleme

| | Web | Flutter |
|--|-----|---------|
| Liste | GET `/api/video-streams` | Aynı |
| RTC | usersig + audience | `open_live_stream.dart` / swipe |
| Oda kimliği | `streamId` | `LiveStreamEntity.id` |

## 3. Tespit edilen engeller (düzeltildi / bilinen)

| # | Sorun | Etki | Durum |
|---|--------|------|--------|
| 1 | `createVideoStream` yanıtı farklı sarmalayıcılar | streamId çıkarılamıyor → TRTC oda boş | **Düzeltildi** — `_extractStreamId` |
| 2 | TRTC yanıtı `{ success, data }` içinde | sdkAppId=0 → enterRoom başarısız | **Düzeltildi** — unwrap + doğrulama |
| 3 | Yayın açmadan önce izin yok | join sessizce başarısız | **Düzeltildi** — prep’te izin |
| 4 | `useNextAuth` / `useMobileAuth` karışıklığı | Self-hosted’da local id | Prep `useMobileAuth` kullanıyor |
| 5 | Hediye POST’ta `senderName` yok | Diğer izleyicide “Misafir” | **Düzeltildi** |
| 6 | Sayfalama 50 vs 30 | Yanlış “daha fazla” | **Düzeltildi** — limit 30 |
| 7 | Canlı sohbet API yok | Mesajlar senkron değil | **Bilinen** — yerel liste (web uç gerekir) |
| 8 | Socket auth yok | Teorik risk | Prod mirror ile aynı; poll yedek 4 sn |

## 4. Senkronizasyon

- **Aynı oda:** Web ve mobil aynı `streamId` / TRTC `strRoomId` kullanmalı — Flutter artık sunucudan dönen `id` ile bağlanıyor.
- **Hediyeler:** REST + Socket `gift` / `giftSent` + 4 sn poll — web ile uyumlu.
- **İzleyici sayısı / sohbet:** Sunucu SSE/WS uçları mobil canlı odaya bağlanmadı; prod API dokümantasyonunda canlı yorum uçu varsa ayrı entegrasyon gerekir.

## 5. Performans

- Hediye poll: 2 sn → **4 sn** (socket açıkken yeterli).
- Liste: tek sayfa **30** kayıt; gereksiz 50 limit kaldırıldı.
- TRTC usersig: prep’te bir kez; oda içinde yalnızca oda uyuşmazsa yeniden.

## 6. Debug

Debug build’de `[Live]` logları: `create.request`, `create.ok`, `usersig.request`, `usersig.ok`.

## 7. Dosya referansları

| Dosya | Rol |
|-------|-----|
| `live_broadcast_prep_page.dart` | Yayın başlat |
| `live_remote_datasource.dart` | REST video-streams |
| `trtc_remote_datasource.dart` | UserSig |
| `live_broadcast_room_page.dart` | TRTC + hediye UI |
| `live_gift_realtime_service.dart` | Socket + poll |
| `api/src/routes/video_streams.ts` | Mirror create (self-hosted) |
