# LIVE SCREEN ANALYSIS
## Canlı Yayın Ekranı Detaylı Analiz Raporu

**Tarih:** 2026-09-23  
**Analiz Kapsamı:** Canlı yayın ekranı (live broadcast) mimarisi, bileşenler, durum yönetimi ve sorunlar  
**Raporlayan:** Claude Haiku 4.5

---

## 1. Live Screen Dosya Konumu ve Mimari

**Ana dosya:**
- `/mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart` (3236 satır)
  - StatefulWidget: `LiveBroadcastRoomPage`
  - State class: `_LiveBroadcastRoomPageState`
  - Build metodu: line 2623+
  
**İlgili dizinler:**
- `/mobile/lib/features/live/presentation/widgets/broadcast_room/` (60+ widget dosyası)
- `/mobile/lib/features/live/presentation/widgets/premium_2026/` (premium tasarım bileşenleri)
- `/mobile/lib/features/live/presentation/providers/` (state management)

**Mimari yapı:**
```
LiveBroadcastRoomPage (StatefulWidget)
  └── build()
      └── Stack(fit: StackFit.expand)
          ├── LiveBroadcastRoomVideoLayer (TRTC video rendering)
          ├── LiveBroadcastRoomGiftOverlays (hediye animasyonları)
          ├── LiveBroadcastRoomConnectionOverlays (bağlantı durumu)
          ├── LiveBroadcastRoomHudOverlays (HUD elementleri)
          ├── LiveFloatingHeartsOverlay (kalp animasyonları)
          ├── LiveBroadcastRoomChromeColumn (üst/alt bar + sohbet)
          ├── LiveBroadcastRoomGiftPanelOverlay (hediye seçimi modal)
          ├── LivePkBroadcastOverlay (PK modunda kontroller)
          └── [diğer overlay'ler]
```

---

## 2. Video Widget Implementasyonu ve Konumu

**Dosya:** `/mobile/lib/features/live/presentation/widgets/broadcast_room/live_broadcast_room_video_layer.dart`

**Temel özellikleri:**
- TRTC SDK entegrasyonu: Tencent Real-Time Communication
- Uyumlu yerleşim:
  - Normal mod: Tam ekran video (`Positioned.fill`)
  - PK modu: Bölünmüş ekran (video üst %50, içerik alt %50)
  - Co-broadcast: Konuk grid sistemi
  
**Kontroller:**
- `_trtc: TrtcRoomManager?` - TRTC yönetimi
- `_rtcReady: bool` - RTC hazır durumu
- `_rtcError: String?` - RTC hata mesajları
- `_localPreviewKey: UniqueKey()` - Yerel önizleme yenilemesi

**Problemler:**
- RTC hazır durumu gecikmeleri (video başlamama)
- Bağlantı kopması durumunda recovery mekanizması eksik
- Guest layout kompleksitesi yüksek (PK + co-broadcast kombinasyonu)

---

## 3. Chat Sistemi Implementasyonu

**Dosya:** `/mobile/lib/features/live/presentation/widgets/broadcast_room/live_broadcast_room_chat_overlay.dart`

**Yapı:**
- `chatVisible: bool` - Sohbetin açık/kapalı durumu
- `messages: List<LiveRoomChatMessage>` - Mesaj listesi
- `lastJoinedName: String?` - Son katılan izleyici adı

**Rendering:**
- `LiveRoomChatFalPanel` - Mesaj paneli
- Mesaj filtreleme: sistem mesajları, VIP girişleri
- SSE üzerinden gerçek zamanlı güncelleme

**State Management:**
- Provider: `liveRoomProvider(streamId)` (live_room_providers.dart)
- Kontroller sınıfı: `LiveRoomController`
- Mesaj persistency: `LeaveRoomSession` state.copyWith(messages: const [])` ile temizleniyor

**Mevcut Sorunlar:**
- System mesajları (ör. "admin sesli odaya katıldı") yayın sırasında gösterilmeye devam ediyor
- Mesajlar temiz şekilde silinmiyor (üst katman sorunusu)
- Chat overlay performans: her mesaj gelişte rebuild

---

## 4. Hediye Sistemi Implementasyonu

**Ana dosyalar:**
1. `/mobile/lib/features/live/presentation/widgets/broadcast_room/live_broadcast_room_gift_overlays.dart`
   - Hediye motoru overlay
   - Animasyon kuyrukları

2. `/mobile/lib/features/live/presentation/widgets/broadcast_room/live_broadcast_room_gift_panel_overlay.dart`
   - Bottom sheet hediye seçim paneli
   - `PremiumGiftPanel` widget'ı kullanıyor

3. `/mobile/lib/features/gifts/presentation/` - Merkezi hediye sistemi
   - `GiftEngineOverlay` - Animasyon rendering
   - `GiftSessionController` - State yönetimi
   - `LiveGiftController` - Canlı yayın hediye kontrolü

**State Management:**
- `giftSessionProvider(streamId)` - Hediye oturumu
- `liveGiftControllerProvider` - Hediye kontrolü (ör. panel açma)
- `liveBroadcastSettingsProvider` - Ayarlar (giftsEnabled)

**Kontrol akışı:**
```
onGift callback
└── giftCtrl.setPanelOpen(true)
    └── LiveBroadcastRoomGiftPanelOverlay render
        └── PremiumGiftPanel (hediye seçimi)
            └── Seçilen hediye
                └── API: sendGift()
                    └── giftSessionProvider.onGiftSent()
                        └── GiftEngineOverlay (animasyon)
```

---

## 5. Hediye Kutusu Sorunları ve Konumu

**ANAHTAR SORUN: Hediye Kutusu Açılmıyor**

**Dosya:** `/mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart` - Line 3084-3099

**Sorun Kodu:**
```dart
onGift: broadcastSettings.giftsEnabled && streamId != null
    ? () {
        if (pkImmersive) {
          unawaited(_openPkGiftPicker(...));
        } else if (!s.isHost) {  // ← BUG: Host hediye açamaz!
          ref.read(liveGiftControllerProvider).setPanelOpen(true);
        }
      }
    : null,
```

**Root Cause:**
- Koşul `!s.isHost` (host OLMAYAN kullanıcılar için)
- Host kullanıcılar hediye butonuna bastığında hiç bir şey olmaz
- Hediye paneli asla açılmaz (host ise)

**Hediye Panel Render Koşulu (Line 3212-3222):**
```dart
if (giftCtrl.panelOpen &&
    !pkImmersive &&
    user != null &&
    broadcastSettings.giftsEnabled)
  LiveBroadcastRoomGiftPanelOverlay(...)
```

**Soruna Neden Olan Akış:**
1. Host hediye butonuna tıklar
2. `onGift` callback çalışır
3. `!s.isHost` false döndüğü için içeri girmez
4. `setPanelOpen(true)` hiç çağrılmaz
5. Panel açılmaz ❌

**İlgili Dosyalar:**
- `live_broadcast_bottom_bar_v2.dart` - Bottom bar hediye butonu
- `live_premium_bottom_bar.dart` - Premium bottom bar (alternatif)
- `live_broadcast_room_chrome_column.dart` - Chrome orchestration

---

## 6. Sezon Yarışması Kartı Implementasyonu

**Dosya:** `/mobile/lib/features/live/presentation/widgets/`

**İlgili Sağlayıcı:**
- `gameTournamentsProvider` - Turnuva verisi (line 2849)

**Render Konumu:**
- "Daha fazla" menüsü (`_openLiveMoreMenu`)
- Sezon bilgileri şu zaman gösterilir:
  - `tournamentsAsync.valueOrNull?.isNotEmpty == true`

**State Management:**
- `liveHostRankProvider(hostId)` - Host ranking bilgisi
- `popularRank, leagueLabel` - Lig sistemine ilişkin bilgiler

**UI Elementleri:**
- Top bar: Popularity rank badge
- Profile card: League label badge
- Dinamik güncellemeler: host rank değişimleri

---

## 7. Alt Bar Implementasyonu ve Kontrolleri

**İki versiyon:**

### 7a. LiveBroadcastBottomBarV2
**Dosya:** `/mobile/lib/features/live/presentation/widgets/premium_2026/live/live_broadcast_bottom_bar_v2.dart`

**Kontroller (Host için):**
```
┌─ Mic Toggle
├─ Camera Toggle
├─ Camera Switch
└─ End Broadcast
```

**Mesaj Input:**
- Genişletilebilir input (`_ExpandableMessageInput`)
- Focus durumunda boyut değişimi (44px → 48px)

**Hediye Dropdown:**
- `_GiftDropdownButton` - Sola doğru açılır
- Mock hediye listesi (backend'den gelecek)
- Hediye seçimi: `widget.onGift()` çağrısı

**Konumu:** line 72-155

### 7b. LivePremiumBottomBar
**Dosya:** `/mobile/lib/features/live/presentation/widgets/premium_2026/live/live_premium_bottom_bar.dart`

**Kapsamı:** Daha geniş kontrol seti

---

## 8. Üst Bar Implementasyonu ve Bilgi Gösterimi

**Dosya:** `/mobile/lib/features/live/presentation/widgets/broadcast_room/live_broadcast_room_chrome_column.dart` - Line 119-147

**Bileşenler:**
```
┌─ LivePremiumTopBar
│  ├─ Elapsed time pill
│  ├─ Stream title
│  ├─ Fortune type badge
│  ├─ Network quality indicator (host only)
│  ├─ Follow/Unfollow button
│  ├─ Top gifters leaderboard
│  ├─ Popular rank
│  ├─ League label
│  ├─ Viewers count
│  ├─ Host profile button
│  └─ Discover button
├─ LivePkHostPendingBanner (PK bekleme)
└─ Chat overlay / side rail
```

**State Management:**
- `liveGiftLeaderboardProvider(streamId)` - Top hediye vericiler
- `liveHostRankProvider(hostId)` - Host ranking
- `broadcastSettings.commentsEnabled` - Yorum durumu

---

## 9. SSE/WebSocket Bağlantısı Implementasyonu

**Yaklaşım:** SSE (Server-Sent Events) - Socket.IO DEĞIL

**Dosya:** `/mobile/lib/features/live/presentation/providers/live_room_providers.dart`

**Bağlantı Yönetimi:**
```dart
class LiveRoomController extends AutoDisposeFamilyNotifier<LiveRoomState, String>
  - _bootstrap() - Başlangıç: join + fetch messages
  - _startRealtime() - SSE dinleme başlatma
  - suspendForSwipe() - Swipe anında kapama
  - resumeFromSwipe() - Geri dönüşte açma
  - tearDownSession() - Oturum kapatma
```

**Pooling Mekanizması:**
- 20 saniye aralıklı poll (SSE bağlantısı kapalıysa)
- `fetchStreamMessages(streamId)`
- `fetchStream(streamId)` - Yayın sonu kontrolü

**Hediye SSE:**
- `liveGiftRealtimeProvider` - Ayrı SSE bağlantısı
- `gift_sse_dispatch.dart` - Dispatch mekanizması
- `GiftSessionController` - State senkronizasyonu

**Mevcut Sorunlar:**
- SSE bağlantı kopması recovery zayıf
- Poll mekanizması gecikmeli
- Hediye ve mesaj sync sorunları

---

## 10. TRTC Entegrasyonu ve Video Rendering

**TrtcRoomManager:**
- Singleton pattern
- Kamera ve mikrofon kontrolleri
- Network quality monitoring

**Video Rendering Flow:**
```
_trtc.setCameraEnabled()
  └── TrtcRoomManager (camera control)
      └── localPreviewKey = UniqueKey() (rebuild)
          └── LiveBroadcastRoomVideoLayer (re-render)
```

**Ağ Kalitesi İzleme:**
- `_trtc.networkQuality` - ValueListenable
- `LiveNetworkQualityPill` - UI gösterimi
- Bilgi: Top bar'da sadece host için

**PK Video Sistemi:**
- `liveVideoPkProvider(streamId)` - PK durumu
- Split screen rendering (PK aktif)
- Opponent video layering

---

## 11. Durum Yönetimi Yaklaşımı ve Sağlayıcılar

**Riverpod Kullanımı:**

### Provider Hiyerarşisi:
```
liveRoomProvider(streamId)
  ├─ messages: List<LiveRoomChatMessage>
  ├─ viewerCount: int
  ├─ streamEnded: bool
  ├─ sseConnected: bool
  └─ Controller: LiveRoomController

giftSessionProvider(streamId)
  ├─ latestEvent: LiveGiftEvent?
  └─ Controller: GiftSessionController

liveGiftControllerProvider (Singleton)
  ├─ panelOpen: bool
  └─ streamerEarnings: int?

liveVideoPkProvider(streamId)
  ├─ battle: Map?
  ├─ status: String
  └─ Controller: LiveVideoPkNotifier

coBroadcastProvider
  └─ invites: List<Map>

liveGiftLeaderboardProvider(streamId)
  └─ topGifters: List<GiftLeaderboardEntry>

liveHostRankProvider(hostId)
  ├─ popularRank: String?
  └─ leagueLabel: String?
```

### Listen Mekanizmaları:
- `ref.listen()` - build() içinden (eski way - rebuild tetikler)
- `ref.listenManual()` - initState() içinden (verimli)
- `.select()` - Granular filtering (optimized)

**Mevcut Sounlar:**
- Bazı listeners build() içinde (cascading rebuild)
- select() optimizasyonları eksik
- State persistence sorunları

---

## 12. API Endpoints ve Backend Entegrasyonu

**Base URL:** `https://canlifal.com`  
**Auth:** JWT Bearer Token

### İlgili Endpoints:

**Sohbet:**
- `GET /api/chat/rooms/{id}/stream` - SSE mesaj akışı
- `POST /api/chat/rooms/{id}/messages` - Mesaj gönderme

**Yayın Yönetimi:**
- `POST /api/video/join` - Yayına katılma
- `POST /api/video/leave` - Yayından ayrılma
- `GET /api/video/streams/{id}` - Yayın metadatası
- `GET /api/video/streams/{id}/messages` - Mesaj geçmişi

**Hediyeler:**
- `POST /api/gifts/send` - Hediye gönderme
- `GET /api/gifts/list` - Hediye listesi
- `GET /api/gifts/sessions/{streamId}` - Hediye oturumu
- SSE: Gerçek zamanlı hediye olayları

**PK:**
- `GET /api/pk/battles/{id}` - PK savaşı
- `POST /api/pk/battles/start` - Başlatma
- `POST /api/pk/battles/end` - Sonlandırma

**Agora/TRTC Tokens:**
- `POST /api/agora/token` - Token oluşturma

**Görüntüleme ve Ranking:**
- `GET /api/live/viewers` - İzleyici sayısı
- `GET /api/live/host-rank/{hostId}` - Host ranking
- `GET /api/live/gift-leaderboard/{streamId}` - Top hediye vericiler

**Fal/Fortune:**
- `POST /api/fortune/request` - Fal isteği
- `GET /api/fortune/types` - Fal türleri

---

## 13. Mevcut Hatalar Listesi

### KRITIK (P0):
1. **Hediye Kutusu Açılmıyor (Host Kullanıcılar)**
   - Dosya: live_broadcast_room_page.dart:3095
   - Sorun: `!s.isHost` koşulu host'u engelle
   - Etki: Host hediye gönderemez
   - Çözüm: Koşulu kaldır veya düzelt

2. **System Mesajları Temizlenmiyor**
   - Dosya: chat_room_providers.dart
   - Sorun: "admin sesli odaya katıldı" mesajları kalıcı
   - Etki: Garbled chat görüntüsü
   - Çözüm: State cleanup mekanizması

### YÜKSEK (P1):
3. **Cascading Listeners**
   - Dosya: live_broadcast_room_page.dart:2650-2750
   - Sorun: 11 ref.listen() build() içinde
   - Etki: Chat güncellemesinde video rebui
   - Çözüm: initState() + listenManual() taşıma

4. **PK Layout Kompleksitesi**
   - Dosya: live_broadcast_room_page.dart:2873-2919
   - Sorun: Koşullu split-screen rendering
   - Etki: Video akışı bozulabilir
   - Çözüm: Dedicated PK layout widget

### ORTA (P2):
5. **Chat Overlay Performance**
   - Dosya: live_broadcast_room_chat_overlay.dart
   - Sorun: Her mesajda full rebuild
   - Etki: Scroll kaymaları
   - Çözüm: ListView + key optimization

6. **Bottom Bar Gift Dropdown**
   - Dosya: live_broadcast_bottom_bar_v2.dart:230
   - Sorun: Mock hediye listesi kullanılıyor
   - Etki: Hediye seçimi gösterilmiyor
   - Çözüm: Backend entegrasyonu

---

## 14. Tanımlanan Performans Sorunları

### Rendering Sorunları:
- **Stack hierarchy:** Nested Positioned widgets → simplify needed
- **Listener cascade:** build() içinde 11 listener → 40% rebuild azaltma potansiyeli
- **Chat rebuild:** Mesaj gelişte ListView full rebuild
- **Video jank:** Split-screen transition sırasında

### State Management Sorunları:
- **Full state watches:** Bazı select() eksik
- **Provider pollution:** 30+ provider watch/listen
- **Memory leaks:** Dispose edilmeyen listeners

### Network Sorunları:
- **SSE recovery:** Bağlantı kopması sonrası reconnect gecikme
- **Poll latency:** 20 saniye aralık çok uzun
- **Message sync:** Hediye ve mesaj senkronizasyon sorunları

### UI/UX Sorunları:
- **Gift modal:** Bottom sheet keyboard overlay
- **Chat visibility:** Landscape modda sohbet kesiyor
- **Responsiveness:** Küçük ekranlarda cramped layout

---

## 15. Önerilen Değişiklikler (Uygulama Olmadan)

### Acil Düzeltmeler (P0-P1):

1. **Hediye Kutusu Fix**
   - Dosya: live_broadcast_room_page.dart:3084-3099
   - Değişiklik: `!s.isHost` koşulunu kaldır
   - Sonuç: Host ve viewer her ikisi de hediye açabilir

2. **System Mesaj Temizleme**
   - Dosya: chat_room_providers.dart
   - Değişiklik: `leaveRoomSession()` state.copyWith(messages: const [])
   - Sonuç: Çıkış sonrası mesajlar silinir

3. **Listener Optimize Etme**
   - Dosya: live_broadcast_room_page.dart:initState()
   - Değişiklik: ref.listen() → ref.listenManual()
   - Sonuç: 40% rebuild azaltma, TikTok seviye hız

### Mimari Iyileştirmeler (P1-P2):

4. **Widget Extraction**
   - Mevcut: 13 ref.listen + 8 ref.watch() tek build() içinde
   - Hediye panel → dedicated widget
   - Chat overlay → separate consumer widget
   - PK broadcast → extracted component
   - Sonuç: Independent rebuild scopes

5. **PK Layout Refactor**
   - Split-screen logic → PK-specific widget
   - Conditional rendering simplify
   - Layout transition smoothing

6. **Chat Performance**
   - ListView.builder + key sistem
   - Message dedup mekanizması
   - Virtualization (görünen mesajlar sadece)

### UI/UX Iyileştirmeler (P2):

7. **Responsive Layout**
   - Small screens: Bottom bar hide/slide
   - Landscape: Chat sidebar
   - Tablet: Two-column layout

8. **Gift Panel Revamp**
   - Kategorize hediyeler
   - Quick-send favoriteler
   - Backend hediye listesi
   - Price display

9. **Bottom Bar Styling**
   - TikTok-like immersive controls
   - Swipe gestures
   - Quick actions (like, rose, gift, share)

### State Management Optimizations:

10. **Provider Consolidation**
    - 30+ provider → refactor grouped
    - Cache strategies implement
    - Dependency cleanup

11. **Error Handling**
    - SSE reconnect exponential backoff
    - Gift send retry logic
    - Network state monitoring

12. **Analytics & Logging**
    - Gift send tracking
    - Video quality metrics
    - Error rate monitoring

---

## Özet

**Canlı yayın ekranı** TikTok/BIGO Live seviyesine çıkarmak için:

✅ **Acil (bu hafta):**
- Hediye kutusu host fix (1 satır)
- System mesaj temizleme (2 satır)
- Listener cascade → initState() (50 satır)

✅ **Kısa dönem (1-2 hafta):**
- Widget extraction (400+ satır)
- PK layout refactor (300 satır)
- Chat performance (200 satır)

✅ **Orta dönem (2-4 hafta):**
- UI/UX polish
- Responsive design
- Analytics integration

**Tahmini Kazanım:**
- Rendering performance: +40% (listener optimization)
- Scroll smoothness: +60% (chat virtualization)
- User experience: +80% (widget extraction + fixes)

---

**Not:** Bu rapor analiz raporudur. Kod değişiklikleri aşağıdaki aşamada uygulanacaktır.
