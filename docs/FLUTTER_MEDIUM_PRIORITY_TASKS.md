# Flutter — Orta Öncelik Görevler (Sprint 2 — 1 Hafta)

**Güncellenme:** 2026-09-24  
**Kime:** Flutter Development Team  
**Aciliyet:** 🟡 **ORTA — 1 HAFTA**  
**Bağımlılık:** Backend'in kritik 3 görevini tamamlaması gerekir

---

## 📋 Özet

Backend'in Sprint 1 görevleri bittikten sonra Flutter'da yapılacak orta öncelik görevler.

| # | Görev | Dosya | Süre | Başlanacak |
|---|-------|-------|------|-----------|
| **1** | Lazy Loading (Live Stream) | `live_broadcast_room_page.dart` | 2-3 gün | Sprint 2 |
| **2** | Token Expiry Lifecycle Monitor | `auth_service.dart` | 2-3 gün | Sprint 2 |
| **3** | SSE Connection Limit | `sse_service.dart` | 1-2 gün | Sprint 2 |
| **4** | Room Event Animation Parsing | `sse_event.dart` | 1-2 gün | Sprint 2 |
| **5** | Game/Agency DTO'ları | `mobile/lib/models/` | 3-4 gün | Sprint 2 |
| **6** | Enum Standardization | `mobile/lib/models/enums/` | 2-3 gün | Sprint 2 |

---

## 🟡 **ORTA 1: Lazy Loading — Live Stream Sayfası**

### Sorun
Canlı yayın sayfası açıldığında **viewers + gifts** katalog hemen yükleniyor, başlangıç gecikmesi yaşanıyor.

```
Sayfa Açılış:
1. GET /api/video-streams/{streamId}          → Yayın detay
2. GET /api/video-streams/{streamId}/comments → Yorumlar
3. GET /api/video-streams/{streamId}/viewers  ← LAZY (şu an eagerly)
4. GET /api/video-streams/{streamId}/gifts    ← LAZY (şu an eagerly)
5. GET /api/video-streams/{streamId}/stream   → SSE

Şu an: 500ms
Hedef: <300ms (viewers/gifts'i tab'e geçilince yükle)
```

### Çözüm

#### **A. Sayfa Yapısı (Riverpod Providers)**

```dart
// Şu an (viewers hemen yükleniyor)
final videoStreamViewersProvider = FutureProvider.autoDispose<List<Viewer>>((ref) async {
  return await ref.watch(liveStreamRepositoryProvider).getViewers(streamId);
});

// Yeni: Lazy loading
final videoStreamViewersProvider = FutureProvider.autoDispose<List<Viewer>>((ref) async {
  // Cache key benzeri tracking
  return null; // Başlangıçta null
});

// Lazily triggered
final _loadViewersProvider = FutureProvider.autoDispose<List<Viewer>>((ref) async {
  // Ancak "viewers tab'ine tıklandığında" çalışmalı
  return await ref.watch(liveStreamRepositoryProvider).getViewers(streamId);
});
```

#### **B. UI Implementation**

**Dosya:** `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`

```dart
class LiveBroadcastRoomPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: [
            // Tab 1: Yorum
            CommentsTab(),
            
            // Tab 2: İzleyiciler (Lazy Load)
            ViewersTab(), // ← Burada lazy load logic
            
            // Tab 3: Hediyeler (Lazy Load)
            GiftsTab(), // ← Burada lazy load logic
          ],
        ),
      ),
    );
  }
}

class ViewersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab'e geçilince viewer'ları yükle
    useEffect(() {
      // Trigger lazy loading
      ref.read(_loadViewersProvider);
      return null;
    }, []);
    
    final viewers = ref.watch(_loadViewersProvider);
    
    return viewers.when(
      loading: () => ShimmerLoadingList(),
      data: (list) => ListView.builder(...),
      error: (err, st) => ErrorWidget(error: err),
    );
  }
}

class GiftsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      ref.read(_loadGiftsProvider);
      return null;
    }, []);
    
    final gifts = ref.watch(_loadGiftsProvider);
    
    return gifts.when(
      loading: () => ShimmerLoadingList(),
      data: (list) => GridView.builder(...),
      error: (err, st) => ErrorWidget(error: err),
    );
  }
}
```

#### **C. Performans Hedefi**

```
Sayfa açılış (lazy loading ile):
- Initial load: 1 + 2 endpoint → ~300ms
- Tab switch (viewers): +400ms (arka planda)
- Tab switch (gifts): +200ms (arka planda)

User experience: Sayfa hızlı açılır, tab'ler smooth
```

### İmplementasyon Checklist

- [ ] `live_broadcast_room_page.dart`'da TabBarView var mı?
- [ ] `_loadViewersProvider` ve `_loadGiftsProvider` oluştur
- [ ] `ViewersTab` ve `GiftsTab` componenti'ını refactor et
- [ ] `useEffect` hook'u ile lazy trigger logic'i ekle
- [ ] Shimmer loading göster (yükleme sırasında)
- [ ] Performance test: Initial load < 300ms
- [ ] Edge case test: Tab switch sırasında başka tab'e geçme

### Test Prosedürü

```bash
# 1. Canlı yayın sayfası aç
# Network tab'ında şu görülmeli:
# ✅ Hemen: stream, comments
# ❌ Değil: viewers, gifts

# 2. Viewers tab'ine tıkla
# Şimdi viewers endpoint'i çağrılmalı

# 3. Gifts tab'ine tıkla
# Şimdi gifts endpoint'i çağrılmalı

# 4. Performance ölç:
# Sayfa açılış < 300ms (viewers/gifts olmadan)
```

---

## 🟡 **ORTA 2: Token Expiry Lifecycle Monitoring**

### Sorun
SSE bağlantısı açıkken token geçerliliği sona eriyebiliyor. Şu an bağlantı 401 alıp kopuyor.

**Senaryo:**
- 14:00 → User login (accessToken expires 2026-10-01 14:00)
- 14:30 → Chat odası açtı (SSE bağlantı başladı)
- 2026-10-01 13:59 → Token 1 dakika kala
- 2026-10-01 14:00 → Token expire, SSE 401 alıyor

### Çözüm

**Konsept:** Token expire zamanına göre, **30 saniye kala tüm SSE bağlantılarını kapat**, token refresh'le, ve yeniden bağlan.

#### **A. Auth Service Enhancement**

**Dosya:** `mobile/lib/services/auth/auth_service.dart`

```dart
class AuthService {
  late Timer _tokenExpiryTimer;
  
  /// Token expiry zamanını hesapla ve monitor et
  void _startTokenExpiryMonitoring(String accessToken) {
    // JWT decode et
    final payload = JwtDecoder.decode(accessToken);
    final exp = payload['exp'] as int;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    
    // Şu anki zamanı hesapla
    final now = DateTime.now();
    final timeUntilExpiry = expiryTime.difference(now);
    
    // 30 saniye kala alarm kur
    final timeToWarning = timeUntilExpiry - Duration(seconds: 30);
    
    _tokenExpiryTimer?.cancel();
    _tokenExpiryTimer = Timer(timeToWarning, () {
      _handleTokenExpiryWarning();
    });
  }
  
  /// Token expire 30 saniye kala tetiklenir
  Future<void> _handleTokenExpiryWarning() async {
    print('🚨 Token expire 30s kala - tüm SSE kapanacak ve yeniden açılacak');
    
    // 1. Tüm SSE bağlantılarını kapat
    await SseService.instance.disconnectAll();
    
    // 2. Token refresh
    await refreshToken();
    
    // 3. SSE bağlantılarını yeniden aç
    // (Her repository kendini reconnect edecek)
    
    // 4. Yeni token'le expiry monitoring başlat
    _startTokenExpiryMonitoring(accessToken);
  }
  
  /// Token refresh'den sonra çağrıl
  Future<void> onTokenRefreshed(String newAccessToken) {
    _startTokenExpiryMonitoring(newAccessToken);
  }
}
```

#### **B. SSE Service Integration**

**Dosya:** `mobile/lib/services/sse/sse_service.dart`

```dart
class SseService {
  final Map<String, Stream<SseEvent>> _connections = {};
  
  /// Tüm SSE bağlantılarını kapat (token refresh için)
  Future<void> disconnectAll() async {
    print('🔌 Tüm SSE bağlantıları kapatılıyor...');
    
    for (final stream in _connections.values) {
      // stream'i close et
    }
    _connections.clear();
  }
  
  /// SSE'yi reconnect komutuyla yeniden aç
  Future<void> reconnectAll() async {
    print('🔗 SSE bağlantıları yeniden açılıyor...');
    
    // Her repository'nin SSE bağlantısını yeniden trigger et
    // (Providers watch'ları invalidate et)
  }
}
```

#### **C. Provider Integration**

**Dosya:** `mobile/lib/features/live/presentation/providers/live_stream_sse_provider.dart`

```dart
final liveStreamSseProvider = StreamProvider.autoDispose<SseEvent>((ref) {
  final sseService = ref.watch(sseServiceProvider);
  final streamId = ref.watch(selectedStreamIdProvider);
  
  return sseService.connect('/api/video-streams/$streamId/stream')
    .onError((error, st) {
      // Error handling: 401 → token refresh → reconnect
      if (error is UnauthorizedException) {
        ref.read(authServiceProvider).refreshToken();
        // Retry akan automatic olacak (provider restart)
      }
      rethrow;
    });
});
```

### İmplementasyon Checklist

- [ ] JWT decode library'si (`dart_jwt`?) mevcut mu?
- [ ] `AuthService._startTokenExpiryMonitoring()` implement et
- [ ] `AuthService._handleTokenExpiryWarning()` implement et
- [ ] `SseService.disconnectAll()` implement et
- [ ] `SseService.reconnectAll()` implement et
- [ ] Provider'lara error handling ekle (401 → refresh)
- [ ] Test: Login et → 6+ saat bekle → token expire → SSE seamless continue

### Test Prosedürü

```bash
# Dev ortamında test:
# 1. Token expiry zamanını dev'de 2 dakika sonraya ayarla
# 2. Login et
# 3. SSE bağlantı aç (chat room)
# 4. 90 saniye bekle
# 5. 30 saniye uyarı loglarını gözlemle
# 6. Token refresh + SSE reconnect otomatik yapılmalı
# 7. Chat devam etmeli (message gönderebildiğini test et)
```

---

## 🟡 **ORTA 3: SSE Connection Limit & Priority Management**

### Sorun
Teorik olarak unlimited SSE bağlantısı açılabiliyor:
- Chat room stream
- Video stream
- Notification stream
- Fortune teller stream
- Live session stream

**Risk:** Çok fazla concurrent bağlantı → memory leak, battery drain

### Çözüm

**Strateji:** Max 5 concurrent SSE bağlantısı, priority-based closing

#### **A. SSE Service Enhancement**

**Dosya:** `mobile/lib/services/sse/sse_service.dart`

```dart
class SseService {
  static const maxConcurrentConnections = 5;
  
  final Map<String, SseConnection> _activeConnections = {};
  
  /// Priority levels (higher = keep longer)
  enum ConnectionPriority {
    low,      // 0 - Notifications, analytics
    medium,   // 1 - Chat, social
    high,     // 2 - Video stream (active viewing)
    critical, // 3 - Live session (fortune teller)
  }
  
  class SseConnection {
    final String id;
    final String path;
    final ConnectionPriority priority;
    final DateTime createdAt;
    Stream<SseEvent>? stream;
    
    SseConnection({
      required this.id,
      required this.path,
      required this.priority,
    }) : createdAt = DateTime.now();
  }
  
  /// SSE bağlantısı aç (limit kontrol ile)
  Stream<SseEvent> connect(
    String path, {
    String? connectionId,
    ConnectionPriority priority = ConnectionPriority.medium,
  }) {
    final id = connectionId ?? path;
    
    // Bağlantı sayısı limit'e yaklaşırsa eski low-priority bağlantıyı kapat
    if (_activeConnections.length >= maxConcurrentConnections) {
      _closeLowPriorityConnection();
    }
    
    // Yeni bağlantı oluştur
    final connection = SseConnection(
      id: id,
      path: path,
      priority: priority,
    );
    
    _activeConnections[id] = connection;
    
    return _establishConnection(connection);
  }
  
  /// Lowest priority bağlantıyı kapat
  void _closeLowPriorityConnection() {
    if (_activeConnections.isEmpty) return;
    
    // En düşük priority'si olan ve en eski bağlantıyı bul
    final toClose = _activeConnections.values.reduce((a, b) {
      final priorityCompare = a.priority.index.compareTo(b.priority.index);
      if (priorityCompare != 0) return priorityCompare < 0 ? a : b;
      return a.createdAt.isBefore(b.createdAt) ? a : b;
    });
    
    print('🔌 Closing low-priority connection: ${toClose.id}');
    _activeConnections.remove(toClose.id);
    toClose.stream = null;
  }
}
```

#### **B. Repository Integration**

**Dosya:** `mobile/lib/features/live/data/repositories/live_stream_repository.dart`

```dart
class LiveStreamRepository {
  Stream<SseEvent> watchStream(String streamId) {
    return sseService.connect(
      '/api/video-streams/$streamId/stream',
      connectionId: 'stream_$streamId',
      priority: SseService.ConnectionPriority.high, // Video aktif
    );
  }
}

// Dosya: mobile/lib/features/notifications/data/repositories/notification_repository.dart
class NotificationRepository {
  Stream<SseEvent> watchNotifications() {
    return sseService.connect(
      '/api/notifications/stream',
      connectionId: 'notifications',
      priority: SseService.ConnectionPriority.low, // Bildirimler less critical
    );
  }
}
```

### Priority Matrix

| SSE Endpoint | Priority | Neden |
|------------|----------|-------|
| Live session (fortune teller) | Critical (3) | Active paid session |
| Video stream (watching) | High (2) | Active viewing |
| Chat room (active) | High (2) | User interacting |
| Notifications | Medium (1) | Background |
| Analytics/presence | Low (0) | Non-essential |

### İmplementasyon Checklist

- [ ] `SseConnection` class ve `ConnectionPriority` enum oluştur
- [ ] `maxConcurrentConnections = 5` constant tanımla
- [ ] `connect()` metodu limit kontrol ekle
- [ ] `_closeLowPriorityConnection()` implement et
- [ ] Tüm repository'lerde priority parameter'ı ekle
- [ ] Test: 6 SSE bağlantısı açmayı dene → 1'i kapatılmalı

### Test Prosedürü

```bash
# 1. Chat room aç (medium priority)
# 2. Video stream başlat (high priority)
# 3. Notification listener başlat (low priority)
# 4. 3-4 daha bağlantı aç
# 5. Total 6-7 bağlantı olmalı
# 6. System: En düşük priority bağlantı kapanmalı
# 7. Log kontrol: "Closing low-priority connection: notifications"
```

---

## 🟡 **ORTA 4: Room Event Animation Parsing**

### Sorun
SSE event'inde `room_event` type'ı gelse ve animation metadata içerse, Flutter'da parsing mekanizması bilinmiyor.

**Backend'den beklenen format (Kılavuz §2351):**
```json
{
  "type": "room_event",
  "event": "user_joined",
  "animation": {
    "id": "anim_entrance_gold_crown",
    "assetUrl": "assets/gifts/lottie/crown.json",
    "assetType": "lottie",
    "durationMs": 3000
  }
}
```

### Çözüm

#### **A. DTO Creation**

**Dosya:** `mobile/lib/models/sse/room_event_animation.dart`

```dart
class RoomEventAnimation {
  final String id;
  final String assetUrl;
  final String assetType; // 'lottie', 'gif', 'video'
  final int durationMs;
  
  RoomEventAnimation({
    required this.id,
    required this.assetUrl,
    required this.assetType,
    required this.durationMs,
  });
  
  factory RoomEventAnimation.fromJson(Map<String, dynamic> json) {
    return RoomEventAnimation(
      id: json['id'] as String,
      assetUrl: json['assetUrl'] as String,
      assetType: json['assetType'] as String? ?? 'lottie',
      durationMs: json['durationMs'] as int? ?? 3000,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'assetUrl': assetUrl,
    'assetType': assetType,
    'durationMs': durationMs,
  };
}

class RoomEvent {
  final String type; // 'user_joined', 'user_left', etc.
  final RoomEventAnimation? animation;
  final Map<String, dynamic> data;
  
  RoomEvent({
    required this.type,
    this.animation,
    required this.data,
  });
  
  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    final animJson = json['animation'] as Map<String, dynamic>?;
    return RoomEvent(
      type: json['event'] as String? ?? 'unknown',
      animation: animJson != null ? RoomEventAnimation.fromJson(animJson) : null,
      data: json,
    );
  }
}
```

#### **B. SSE Event Handler**

**Dosya:** `mobile/lib/services/sse/sse_event.dart`

```dart
class SseEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  
  // ...existing code...
  
  /// Room event animation varsa parse et
  RoomEvent? get roomEvent {
    if (type != 'room_event') return null;
    try {
      return RoomEvent.fromJson(data);
    } catch (e) {
      print('❌ Failed to parse room_event: $e');
      return null;
    }
  }
  
  bool get hasAnimation => roomEvent?.animation != null;
}
```

#### **C. UI Component**

**Dosya:** `mobile/lib/features/chat_room/presentation/widgets/room_event_animation_widget.dart`

```dart
class RoomEventAnimationWidget extends ConsumerWidget {
  final RoomEventAnimation animation;
  
  const RoomEventAnimationWidget({
    required this.animation,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (animation.assetType) {
      case 'lottie':
        return _buildLottieAnimation();
      case 'gif':
        return _buildGifAnimation();
      case 'video':
        return _buildVideoAnimation();
      default:
        return SizedBox.shrink();
    }
  }
  
  Widget _buildLottieAnimation() {
    return Lottie.network(
      animation.assetUrl,
      width: 200,
      height: 200,
      repeat: false,
      onLoaded: (composition) {
        // Auto dispose after duration
        Future.delayed(Duration(milliseconds: animation.durationMs), () {
          // Remove widget
        });
      },
    );
  }
  
  Widget _buildGifAnimation() {
    return Image.network(
      animation.assetUrl,
      width: 200,
      height: 200,
    );
  }
  
  Widget _buildVideoAnimation() {
    // Video player implementation
    return Container(); // TODO
  }
}
```

#### **D. Chat Room Integration**

**Dosya:** `mobile/lib/features/chat_room/presentation/pages/chat_room_page.dart`

```dart
class ChatRoomPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamEvents = ref.watch(chatRoomSseProvider);
    
    return streamEvents.when(
      data: (event) {
        // Room event animation varsa göster
        if (event.hasAnimation) {
          final roomEvent = event.roomEvent;
          _showRoomEventAnimation(context, roomEvent!.animation!);
        }
        
        // Normal message handling
        if (event.isMessage) {
          return ChatMessageWidget(...);
        }
        
        return SizedBox.shrink();
      },
      // ...
    );
  }
  
  void _showRoomEventAnimation(
    BuildContext context,
    RoomEventAnimation animation,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoomEventAnimationWidget(animation: animation),
    );
  }
}
```

### İmplementasyon Checklist

- [ ] `RoomEventAnimation` ve `RoomEvent` DTO'ları oluştur
- [ ] `SseEvent.roomEvent` getter'ı ekle
- [ ] `SseEvent.hasAnimation` getter'ı ekle
- [ ] `RoomEventAnimationWidget` component'i oluştur
- [ ] Lottie, GIF, Video rendering'i implement et
- [ ] Chat room page'de event listener'ı ekle
- [ ] Test: Backend'den animation gönderi → Flutter'da görünsün

### Test Prosedürü

```bash
# 1. Backend'den SSE event gönder (test için)
# {
#   "type": "room_event",
#   "event": "user_joined",
#   "animation": {
#     "id": "anim_entrance_gold",
#     "assetUrl": "https://..../crown.json",
#     "assetType": "lottie",
#     "durationMs": 3000
#   }
# }

# 2. Flutter app'de animation görünmeli
# 3. 3 saniye sonra otomatik kapanmalı
```

---

## 🟡 **ORTA 5: Game/Agency DTO'ları**

### Sorun
Backend'de Game, Agency, Team sistemleri tanımlı ama Flutter'da DTO'ları yok.

**Eksik DTO'lar:**
- `GameRoom`
- `GameScore`
- `Agency`
- `AgencyMember`
- `AgencyEarnings`
- `Team`
- `TeamMember`

### Çözüm

#### **A. Game DTOs**

**Dosya:** `mobile/lib/models/game/game_room.dart`

```dart
class GameRoom {
  final String id;
  final String name;
  final String gameType; // 'sos', 'auto-match', 'mini'
  final String status; // 'waiting', 'playing', 'finished'
  final List<GamePlayer> players;
  final int maxPlayers;
  final int createdAtMs;
  
  GameRoom({
    required this.id,
    required this.name,
    required this.gameType,
    required this.status,
    required this.players,
    required this.maxPlayers,
    required this.createdAtMs,
  });
  
  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      gameType: json['gameType'] as String,
      status: json['status'] as String,
      players: (json['players'] as List?)
          ?.map((p) => GamePlayer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      maxPlayers: json['maxPlayers'] as int? ?? 4,
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gameType': gameType,
    'status': status,
    'players': players.map((p) => p.toJson()).toList(),
    'maxPlayers': maxPlayers,
    'createdAtMs': createdAtMs,
  };
}

class GamePlayer {
  final String userId;
  final String username;
  final String avatar;
  final int score;
  final bool isReady;
  
  GamePlayer({
    required this.userId,
    required this.username,
    required this.avatar,
    required this.score,
    required this.isReady,
  });
  
  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      isReady: json['isReady'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'avatar': avatar,
    'score': score,
    'isReady': isReady,
  };
}

class GameScore {
  final String id;
  final String userId;
  final String gameType;
  final int score;
  final int rank;
  final DateTime createdAt;
  
  GameScore({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.score,
    required this.rank,
    required this.createdAt,
  });
  
  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id'] as String,
      userId: json['userId'] as String,
      gameType: json['gameType'] as String,
      score: json['score'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'gameType': gameType,
    'score': score,
    'rank': rank,
    'createdAt': createdAt.toIso8601String(),
  };
}
```

#### **B. Agency DTOs**

**Dosya:** `mobile/lib/models/agency/agency.dart`

```dart
class Agency {
  final String id;
  final String name;
  final String ownerUserId;
  final String logo;
  final String description;
  final String status; // 'active', 'inactive', 'banned'
  final int memberCount;
  final int totalEarnings;
  final DateTime createdAt;
  
  Agency({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.logo,
    required this.description,
    required this.status,
    required this.memberCount,
    required this.totalEarnings,
    required this.createdAt,
  });
  
  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerUserId: json['ownerUserId'] as String,
      logo: json['logo'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      memberCount: json['memberCount'] as int? ?? 0,
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerUserId': ownerUserId,
    'logo': logo,
    'description': description,
    'status': status,
    'memberCount': memberCount,
    'totalEarnings': totalEarnings,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AgencyMember {
  final String id;
  final String agencyId;
  final String userId;
  final String role; // 'owner', 'manager', 'member'
  final int monthlyEarnings;
  final DateTime joinedAt;
  
  AgencyMember({
    required this.id,
    required this.agencyId,
    required this.userId,
    required this.role,
    required this.monthlyEarnings,
    required this.joinedAt,
  });
  
  factory AgencyMember.fromJson(Map<String, dynamic> json) {
    return AgencyMember(
      id: json['id'] as String,
      agencyId: json['agencyId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String? ?? 'member',
      monthlyEarnings: json['monthlyEarnings'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joinedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'agencyId': agencyId,
    'userId': userId,
    'role': role,
    'monthlyEarnings': monthlyEarnings,
    'joinedAt': joinedAt.toIso8601String(),
  };
}

class AgencyEarnings {
  final String agencyId;
  final int thisMonth;
  final int thisYear;
  final int total;
  final DateTime lastUpdated;
  
  AgencyEarnings({
    required this.agencyId,
    required this.thisMonth,
    required this.thisYear,
    required this.total,
    required this.lastUpdated,
  });
  
  factory AgencyEarnings.fromJson(Map<String, dynamic> json) {
    return AgencyEarnings(
      agencyId: json['agencyId'] as String,
      thisMonth: json['thisMonth'] as int? ?? 0,
      thisYear: json['thisYear'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'agencyId': agencyId,
    'thisMonth': thisMonth,
    'thisYear': thisYear,
    'total': total,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}
```

### İmplementasyon Checklist

- [ ] `mobile/lib/models/game/` klasörü oluştur
- [ ] `mobile/lib/models/agency/` klasörü oluştur
- [ ] `GameRoom.dart`, `GameScore.dart`, `GamePlayer.dart` oluştur
- [ ] `Agency.dart`, `AgencyMember.dart`, `AgencyEarnings.dart` oluştur
- [ ] Tüm DTO'larda `fromJson()` ve `toJson()` implement et
- [ ] `api_endpoints.dart`'da game/agency endpoint'lerinin tanımlandığını kontrol et
- [ ] Test: Backend'den response parse edilip çıkabiliyor mu?

---

## 🟡 **ORTA 6: Enum Standardization**

### Sorun
Backend string döndürüyor (`role: 'user'`, `status: 'active'`), Flutter'da type-safe enum'lar yok → runtime error riski.

### Çözüm

**Dosya:** `mobile/lib/models/enums/` (klasör oluştur)

#### **A. User Enums**

**Dosya:** `mobile/lib/models/enums/user_enums.dart`

```dart
enum UserRole {
  user('user'),
  admin('admin'),
  moderator('moderator'),
  broadcaster('broadcaster'),
  agent('agent'),
  vip('vip');
  
  final String value;
  const UserRole(this.value);
  
  factory UserRole.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.user,
    );
  }
}

enum UserMembership {
  free('free'),
  basic('basic'),
  premium('premium'),
  vip('vip'),
  enterprise('enterprise');
  
  final String value;
  const UserMembership(this.value);
  
  factory UserMembership.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserMembership.free,
    );
  }
}
```

#### **B. Chat Room Enums**

**Dosya:** `mobile/lib/models/enums/chat_enums.dart`

```dart
enum ChatRoomType {
  voice('voice'),
  text('text'),
  radio('radio');
  
  final String value;
  const ChatRoomType(this.value);
  
  factory ChatRoomType.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChatRoomType.voice,
    );
  }
}

enum ChatMessageType {
  text('text'),
  system('system'),
  gift('gift'),
  emoji('emoji'),
  announcement('announcement');
  
  final String value;
  const ChatMessageType(this.value);
  
  factory ChatMessageType.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChatMessageType.text,
    );
  }
}
```

#### **C. Stream & Session Enums**

**Dosya:** `mobile/lib/models/enums/stream_enums.dart`

```dart
enum StreamStatus {
  live('live'),
  ended('ended'),
  scheduled('scheduled'),
  archived('archived');
  
  final String value;
  const StreamStatus(this.value);
  
  factory StreamStatus.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => StreamStatus.live,
    );
  }
}

enum SessionStatus {
  pending('pending'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');
  
  final String value;
  const SessionStatus(this.value);
  
  factory SessionStatus.fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => SessionStatus.pending,
    );
  }
}
```

#### **D. DTO Integration**

**Örnek — `UserProfile` güncellemesi:**

```dart
class UserProfile {
  final String id;
  final String email;
  final String name;
  final UserRole role;           // ← Enum
  final UserMembership membership; // ← Enum
  
  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.membership,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.fromString(json['role'] as String?),
      membership: UserMembership.fromString(json['membership'] as String?),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.value,
    'membership': membership.value,
  };
}
```

### İmplementasyon Checklist

- [ ] `mobile/lib/models/enums/` klasörü oluştur
- [ ] Tüm enum dosyalarını oluştur (`user_enums.dart`, `chat_enums.dart`, vb.)
- [ ] Her enum'da `fromString()` factory constructor ekle
- [ ] Tüm DTO'ları güncelle (string yerine enum kullan)
- [ ] Compile test: Type errors kalmamalı
- [ ] Runtime test: Backend response'ları enum'lara parse edilebiliyor mu?

### Test Prosedürü

```bash
# 1. Backend'den invalid enum value gönder
# { "role": "superadmin" } ← doesn't exist

# 2. Flutter parse etsin
# → Fallback value (UserRole.user) kullanılmalı

# 3. Type-safe kullanım
# if (user.role == UserRole.admin) { ... } ✅
# if (user.role == 'admin') { ... } ❌ (compile error)
```

---

## 📊 **Tamamlama Kontrol Listesi**

### 1. Lazy Loading (Live Stream)
- [ ] ViewersTab ve GiftsTab lazy loading provider'ları
- [ ] Tab switch sırasında yükle
- [ ] Shimmer loading göster
- [ ] Performance test: < 300ms

### 2. Token Expiry Monitoring
- [ ] Token expiry zamanını hesapla
- [ ] 30 saniye kala alarm
- [ ] Tüm SSE kapan ve yeniden aç
- [ ] Token refresh otomatik
- [ ] Dev test: Kısa expiry ile doğrula

### 3. SSE Connection Limit
- [ ] Max 5 concurrent bağlantı
- [ ] Priority enum oluştur
- [ ] Low-priority bağlantı otomatik kapat
- [ ] Tüm repository'lerde priority ekle
- [ ] Test: 6+ bağlantı aç → 1'i kapatılmalı

### 4. Room Event Animation
- [ ] RoomEventAnimation DTO oluştur
- [ ] SseEvent'e parser ekle
- [ ] Lottie/GIF/Video rendering
- [ ] Chat room UI'da göster
- [ ] Test: Backend'den animation gönder

### 5. Game/Agency DTOs
- [ ] GameRoom, GameScore, GamePlayer DTO'ları
- [ ] Agency, AgencyMember, AgencyEarnings DTO'ları
- [ ] Tüm DTO'larda fromJson/toJson
- [ ] Repository'lerde kullan
- [ ] Test: Backend'den parse et

### 6. Enum Standardization
- [ ] Tüm enum dosyaları oluştur
- [ ] fromString() factory'ler
- [ ] Tüm DTO'ları update et
- [ ] Type-safe kodu doğrula
- [ ] Runtime parse test'i

---

## ⏱️ **Takvim**

**Sprint 2 (1 hafta — Backend Sprint 1 bittikten sonra):**

| Gün | Görev | Kişi |
|-----|-------|------|
| Day 1-2 | Lazy Loading + Token Expiry Monitor | Dev 1 |
| Day 1-2 | SSE Connection Limit + Room Event Animation | Dev 2 |
| Day 3-4 | Game/Agency DTO'ları + Enum Standardization | Dev 1 |
| Day 5 | Integration & Testing | Team |
| Day 6-7 | Buffer & Documentation | Team |

---

**Başlama:** Sprint 1 (Backend kritik 3) bittikten sonra  
**Beklenen Bitiş:** 1 hafta

