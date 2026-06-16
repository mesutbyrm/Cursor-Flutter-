# Canlifal Web → Mobil Parite Rehberi

Bu belge [canlifal.com](https://canlifal.com) üretim platformu ile Flutter mobil istemci (`mobile/`) arasındaki ekran akışı, API ve UX eşlemesini özetler.

**Üretim API:** `https://canlifal.com` (JWT Bearer)  
**Gerçek zamanlı sohbet:** SSE + polling (Socket.IO değil)  
**Ses:** TRTC öncelikli; LiveKit / Agora yedek  
**Push:** Firebase Cloud Messaging + OneSignal

---

## 1. Ana Sayfa (`/feed` → `HomePage`)

| Web bölümü | Mobil widget | API |
|------------|--------------|-----|
| Üst bar (logo, bildirim, mesaj, jeton) | `HomeHeader` | `/api/me`, `/api/user/credits`, `/api/notifications/unread`, `/api/messages` |
| Kampanya / banner | `HomeBannerCarousel` | `/api/banners`, `/api/social/announcements` |
| Hikayeler | `StoriesSection` | `/api/social/stories`, `/api/feed` |
| Canlı yayınlar | `LiveBroadcastSection` | `/api/video-streams` |
| Sesli sohbet odaları | `VoiceRoomSection` | `/api/chat/rooms?withCounts=true` |
| Popüler / online falcılar | `LiveFortuneTellersSection` | `/api/fortune-tellers`, `/api/advisors/online` |
| Günlük burç | `HomeHoroscopeSection` | `/fortune/yildiz-haritasi` → `burc-yorumu` |
| Fal servisleri | `FortuneSection` | `/api/homepage-fortune-cards` |
| Trend videolar | `TrendingVideoSection` | `/api/short-videos` |
| Oyunlar / günlük ödül | `HomeGamesRow` | `/api/games`, `/api/daily-rewards` |
| Üyelik / gold | `GoldSection` | `/api/membership/packages` |

**Oda aç:** `showOpenVoiceChatRoomFlow` — 100 jeton (normal) / 5000 jeton (VIP).

---

## 2. Sesli Sohbet Keşif (`/voice-rooms`, `/live` sekmesi)

| Özellik | Mobil | API |
|---------|-------|-----|
| Oda listesi | `VoiceRoomsHubPage`, `VoiceRoomsBody` | `GET /api/chat/rooms` |
| Aktif kullanıcı | Kart üzerinde `onlineCount` | `withCounts=true` |
| Odaya katıl | `openVoiceChatRoomFlow` → `/voice-room/:id` | `POST .../presence` |
| Oda oluştur | Akış içi create | `POST /api/chat/rooms/create` |

---

## 3. Sesli Sohbet Odası (`/voice-room/:id` → `VoiceRoomRtcPage`)

Web `sohbet/[roomSlug]` ekranı ile hizalı bileşenler:

| Web UI | Mobil bileşen | API / RTC |
|--------|---------------|-----------|
| Üst bar (oda adı, ID, online) | `VoiceWebRoomHeader` | presence sayısı |
| Konuşmacı grid (Admin + 2×5) | `VoiceWebOwnerStage` | `seatIndex` 1–11 |
| Sistem / sohbet mesajları | `VoiceWebChatOverlay` | SSE `messages`, `GET .../messages` |
| Müzik Aç / DJ / PK | `VoiceRoomBottomDock`, `VoiceRoomActionRow` | `/music`, `/dj`, PK uçları |
| Mesaj + hediye | `VoiceRoomSpecFooter` | `POST .../messages`, hediye |
| Mikrofon | Alt bar büyük mic | LiveKit / TRTC |
| Jeton + yükle | Footer jeton pill | `/api/user/credits` |
| El kaldırma | `requestSpeak` / `cancelSpeakRequest` | `POST/DELETE .../speak-request` |
| Mod: konuşmacı sırası | `showVoiceSpeakQueueSheet` | `POST .../seats` (Ses ver) |
| Sustur / ban / kick | `showVoiceUserModerationSheet` | `POST .../moderation` |
| DJ + `!istek` | `voice_music_sync`, DJ player | `/api/youtube/search`, `song-request` |
| Arka plan görseli | Oda wallpaper | `PATCH` oda / galeri |

**Presence heartbeat:** 30 sn (`chat_room_providers`).

**Roller (IRC):** `%` superadmin, `~` founder, `&` sop, `@` op, `+v` voice — `VoiceRoomPermissions` + `myPermissions`.

---

## 4. Falcı Profilleri (`/canli-falcilar`)

| Özellik | Mobil | API |
|---------|-------|-----|
| Liste | `LiveFortuneTellersPage` | `/api/fortune-tellers` |
| Online durum | `isOnline` badge | advisors/online |
| Profil | `LiveFortuneTellerDetailPage` | `GET .../fortune-tellers/{id}` |
| Sesli/görüntülü | TRTC seans | `POST .../session`, `RoomSignal` |
| Dakika ücreti | Jeton booking sheet | session create body |
| Yorumlar | Detay sayfası | `LiveTellerReview` (web) |

---

## 5. Kahve / Tarot Falı

| Tür | Rota | API |
|-----|------|-----|
| Kahve | `/fortune/kahve-fali` | SSE `POST /api/fortunes/kahve-fali` |
| Tarot | `/fortune/tarot` | `tarot-fali` slug |
| Geçmiş | `fortuneHistoryProvider` | `GET /api/user/fortunes` |
| Premium modül (ayrı) | `/premium/*` | Firebase + OpenAI (demo) |

---

## 6. Kullanıcı / Cüzdan

| Özellik | Rota | API |
|---------|------|-----|
| Profil | `/profile` | `/api/me` |
| Cüzdan | `/wallet` | `/api/user/credits` |
| Jeton yükle | `/profile/jeton` | `/api/jeton` |
| Bildirimler | `/notifications` | `/api/notifications` |

---

## 7. Firebase kullanımı

| Servis | Durum |
|--------|--------|
| `firebase_core` | Opsiyonel (`dart-define`) |
| `firebase_messaging` | Push token |
| `firebase_analytics` | Olay loglama |
| `firebase_auth` / Firestore | Yalnızca `/premium` modülü (ayrı ürün) |

Ana uygulama akışı **canlifal.com JWT API** ile çalışır; web ile aynı veri sözleşmesi.

---

## 8. Bilinen mobil ↔ web farkları

1. **El kaldırma kuyruğu:** Web mod paneli; mobilde dinleyici listesi + «Ses ver» (`assignSeat`).
2. **Ana sayfa yenileme:** 30 sn poll; web SSE ağırlıklı.
3. **15 koltuk API:** Layout 1–11 görsel; API 0–14 destekli.
4. **Typing emit:** SSE `typing` okunur; `POST .../typing` henüz compose’da yok.

---

## Hızlı rotalar

```
/feed              Ana sayfa
/voice-rooms        Sesli sohbet listesi
/voice-room/:id     Sesli oda (RTC)
/canli-falcilar     Canlı falcılar
/fortune            Fal hub
/premium            Premium Fortune (Firebase demo)
```

Güncel envanter: https://canlifal.com/canlifal-envanter-raporu.txt
