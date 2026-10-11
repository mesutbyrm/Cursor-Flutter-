# CanlıFal — Yeni Endpoint'ler Flutter Entegrasyon Rehberi

> **Tarih:** 11 Ekim 2026  
> **Kapsam:** PR #30, #31, #33 (Ajans), PR #35 (Presence), PR #36-#37 (GirLive Bot), PR #38 (Hediye Doğrulama), PR #39 (P1-P3 Ödeme), PR #40 (P4-P14 Admin)

---

## İçindekiler
1. [Kimlik Doğrulama](#1-kimlik-doğrulama)
2. [Yetki Sistemi — /api/me/permissions](#2-yetki-sistemi)
3. [Bekleyen Ödeme Talebi — /api/payments/requests/pending](#3-bekleyen-ödeme-talebi)
4. [Hediye clientPrice Doğrulaması](#4-hediye-clientprice-doğrulaması)
5. [Çevrimiçi / Son Görülme (Presence)](#5-çevrimiçi--son-görülme)
6. [GirLive Yayıncı Asistanı](#6-girlive-yayıncı-asistanı)
7. [GirLive Herkese Açık Bot (SSE)](#7-girlive-herkese-açık-bot)
8. [Admin — Sistem Sağlığı](#8-admin-sistem-sağlığı)
9. [Admin — Şikâyet Yönetimi](#9-admin-şikâyet-yönetimi)
10. [Admin — Finans Özeti](#10-admin-finans-özeti)
11. [Admin — Bekleyen İş Sayıları](#11-admin-bekleyen-iş-sayıları)
12. [Ajans Yönetimi (PR #33)](#12-ajans-yönetimi)
13. [SSE Event Referansı](#13-sse-event-referansı)

---

## 1. Kimlik Doğrulama

Tüm endpoint'ler JWT Bearer token ile çalışır:

```dart
final headers = {
  'Authorization': 'Bearer $jwtToken',
  'Content-Type': 'application/json',
};
```

Admin endpoint'leri (`/api/admin/*`) web session (cookie) kullanır. Mobil admin panelinde JWT ile erişim desteklenir — `authenticateRequest()` önce JWT kontrol eder.

---

## 2. Yetki Sistemi

### `GET /api/me/permissions`

Kullanıcının efektif yetki listesini döner. Flutter'da buton/menü görünürlüğü buna göre ayarlanır.

**Auth:** JWT Bearer veya Web Session

**Response 200:**
```json
{
  "success": true,
  "data": {
    "role": "admin",
    "isSuper": true,
    "permissions": [
      "user.profile.view",
      "user.profile.edit",
      "moderation.chat.view",
      "moderation.report.handle",
      "finance.report.view",
      "system.audit.view"
    ],
    "groups": {
      "Kullanıcı Yönetimi": ["user.profile.view", "user.profile.edit"],
      "Moderasyon": ["moderation.chat.view", "moderation.report.handle"]
    }
  }
}
```

**Response 401:**
```json
{"success": false, "error": "Oturum açmanız gerekiyor"}
```

**Flutter Kullanımı:**
```dart
class PermissionService {
  Set<String> _permissions = {};
  bool _isSuper = false;
  String _role = 'user';

  Future<void> load() async {
    final res = await dio.get('/api/me/permissions');
    if (res.data['success'] == true) {
      final data = res.data['data'];
      _role = data['role'];
      _isSuper = data['isSuper'] == true;
      _permissions = Set<String>.from(data['permissions'] ?? []);
    }
  }

  bool can(String permission) => _isSuper || _permissions.contains(permission);
  bool get isAdmin => _role == 'admin' || _role == 'yonetici';
}
```

**Yetki kontrolü örnekleri:**
```dart
// Admin paneli göster
if (permissionService.can('system.audit.view')) showAdminHealth();

// Şikâyet yönetimi
if (permissionService.can('moderation.report.handle')) showComplaints();

// Finans özeti
if (permissionService.can('finance.report.view')) showFinanceSummary();
```

---

## 3. Bekleyen Ödeme Talebi

### `GET /api/payments/requests/pending`

Kullanıcının aktif bekleyen CFC ödeme talebini kontrol eder. 24 saatten eski pending talepler otomatik `expired` yapılır.

**Auth:** JWT Bearer

**Response (bekleyen var):**
```json
{
  "hasPending": true,
  "request": {
    "id": "clx1abc...",
    "amount": 500,
    "method": "bank_transfer",
    "createdAt": "2026-10-11T10:00:00.000Z",
    "senderInfo": "Ahmet Y. / Garanti 1234",
    "notes": null,
    "cancelUrl": "/api/payments/requests/clx1abc.../cancel",
    "ageMinutes": 45
  }
}
```

**Response (bekleyen yok):**
```json
{"hasPending": false, "request": null}
```

### `POST /api/payments/requests/{id}/cancel`

Bekleyen talebi iptal eder. Sadece `pending` durumundaki kendi talebini iptal edebilir.

**Auth:** JWT Bearer

**Response 200:**
```json
{"success": true, "message": "Talep iptal edildi"}
```

**Response 409:**
```json
{"error": "Bu talep zaten işlenmiş", "currentStatus": "approved"}
```

### `POST /api/payments/requests` — 409 Hatası

Yeni talep oluştururken zaten pending varsa:
```json
{
  "error": "Zaten bekleyen bir ödeme talebiniz var",
  "existingRequest": {
    "id": "clx1abc...",
    "amount": 500,
    "method": "bank_transfer",
    "createdAt": "2026-10-11T10:00:00.000Z",
    "cancelUrl": "/api/payments/requests/clx1abc.../cancel"
  }
}
```

**Flutter Akışı:**
```dart
// CFC ödeme talebi oluşturmadan önce:
Future<void> createCfcRequest(CfcPaymentData data) async {
  try {
    final res = await dio.post('/api/payments/requests', data: data.toJson());
    // Başarılı
  } on DioException catch (e) {
    if (e.response?.statusCode == 409) {
      final existing = e.response?.data['existingRequest'];
      // Dialog göster: "Zaten bekleyen talebiniz var. İptal edip yeni mi oluşturmak istersiniz?"
      showPendingRequestDialog(
        amount: existing['amount'],
        cancelUrl: existing['cancelUrl'],
      );
    }
  }
}
```

---

## 4. Hediye clientPrice Doğrulaması

3 hediye gönderim endpoint'ine opsiyonel `clientPrice` parametresi eklendi.

**Endpoint'ler:**
- `POST /api/gifts/send` (doğrudan)
- `POST /api/chat/rooms/{roomId}/gifts` (sesli oda)
- `POST /api/video-streams/{streamId}/gifts` (canlı yayın)

**İstek (ek alan):**
```json
{
  "giftTypeId": "clx...",
  "recipientId": "user123",
  "quantity": 1,
  "clientPrice": 150
}
```

**409 — Fiyat Uyumsuzluğu:**
```json
{
  "error": "PRICE_MISMATCH",
  "serverPrice": 200,
  "clientPrice": 150
}
```

**Flutter Kullanımı:**
```dart
Future<void> sendGift(String giftTypeId, String recipientId, int localPrice) async {
  try {
    await dio.post('/api/gifts/send', data: {
      'giftTypeId': giftTypeId,
      'recipientId': recipientId,
      'quantity': 1,
      'clientPrice': localPrice, // Sunucu doğrulaması için
    });
  } on DioException catch (e) {
    if (e.response?.statusCode == 409) {
      final data = e.response?.data;
      if (data['error'] == 'PRICE_MISMATCH') {
        // Katalog güncelle
        await giftCatalogService.refresh();
        showSnackbar('Hediye fiyatı güncellendi. Lütfen tekrar deneyin.');
      }
    }
  }
}
```

### Katalog Senkronizasyonu

Admin hediye CRUD işlemlerinden sonra cache otomatik temizlenir. Flutter tarafında:

```dart
class GiftCatalogService {
  List<GiftType> _catalog = [];
  int _version = 0;

  Future<void> refresh() async {
    final res = await dio.get('/api/gifts/catalog');
    _catalog = (res.data['data'] as List).map((e) => GiftType.fromJson(e)).toList();
    _version = res.data['contentVersion'] ?? 0;
  }

  /// Periyodik versiyon kontrolü (ör. 5 dk)
  Future<bool> checkForUpdates() async {
    final res = await dio.get('/api/gifts/version-check?v=$_version');
    return res.data['hasUpdate'] == true;
  }
}
```

---

## 5. Çevrimiçi / Son Görülme

Mesajlaşma endpoint'leri artık `isOnline` ve `lastSeenAt` alanlarını döner.

### `GET /api/messages`

**Response (her konuşma):**
```json
{
  "conversations": [
    {
      "id": "conv123",
      "otherUser": {
        "id": "user456",
        "name": "Ayşe",
        "image": "https://..."
      },
      "isOnline": true,
      "lastSeenAt": null,
      "lastMessage": { ... }
    },
    {
      "id": "conv789",
      "otherUser": { ... },
      "isOnline": false,
      "lastSeenAt": "2026-10-11T14:30:00.000Z",
      "lastMessage": { ... }
    }
  ]
}
```

**Kurallar:**
- `isOnline: true` → yeşil nokta göster, `lastSeenAt` null olur
- `isOnline: false` + `lastSeenAt` dolu → "Son görülme: 14:30" göster
- `isOnline: false` + `lastSeenAt: null` → kullanıcı gizlilik ayarı açık (Premium+), hiçbir şey gösterme
- Premium+ kullanıcılar `hideOnlineStatus` ve `hideLastSeen` tercihlerini açabilir
- Üyelik süresi dolmuşsa gizlilik iptal olur (basic'e düşer)

### `POST /api/presence` — action: 'leave'

Uygulama arka plana geçtiğinde veya kapatıldığında:
```dart
Future<void> onAppPaused() async {
  try {
    await dio.post('/api/presence', data: {'action': 'leave'});
  } catch (_) {}
}
```

**Flutter Widget:**
```dart
Widget buildOnlineIndicator(bool? isOnline, String? lastSeenAt) {
  if (isOnline == true) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
    );
  }
  if (lastSeenAt != null) {
    final dt = DateTime.parse(lastSeenAt).toLocal();
    return Text('Son: ${DateFormat.Hm().format(dt)}',
      style: TextStyle(fontSize: 11, color: Colors.grey));
  }
  return SizedBox.shrink(); // Gizlilik açık
}
```

---

## 6. GirLive Yayıncı Asistanı

### `GET /api/chat/rooms/{roomId}/girlive/publisher-assistant`

Oda sahibine özel performans raporu.

**Auth:** JWT Bearer (oda sahibi veya admin/yonetici)

**Query Params:**
| Param | Tip | Açıklama |
|---|---|---|
| `scope` | string | `session` \| `day` \| `week` \| `month` |
| `sessionId` | string? | Belirli oturum ID'si |

**Response 200:**
```json
{
  "success": true,
  "report": {
    "sessionId": "sess123",
    "startedAt": "2026-10-11T10:00:00.000Z",
    "endedAt": null,
    "totalVisits": 42,
    "uniqueVisitors": 35,
    "returnVisitors": 7,
    "avgDwellSeconds": 320,
    "peakHourLocal": null,
    "grossGiftJeton": 15000,
    "netOwnerJeton": 12000,
    "giftCount": 28,
    "topGifts": [
      {"giftId": "g1", "name": "Gül", "count": 10, "jetonTotal": 5000}
    ],
    "topGifters": [
      {"userId": "u1", "displayName": "Ali", "giftCount": 8, "jetonTotal": 4000}
    ],
    "pkCompleted": 3,
    "pkWon": 2,
    "pkLost": 0,
    "pkDraw": 1,
    "tips": [
      "En çok hediye gönderen: Ali (4000 jeton)",
      "PK performansınız güçlü! 2/3 galibiyet."
    ],
    "comparePrevious": null
  }
}
```

### `GET /api/chat/rooms/{roomId}/girlive/publisher-assistant/end-report`

Oda kapanışında gün sonu özeti + SSE yayını.

**Query Params:**
| Param | Tip | Açıklama |
|---|---|---|
| `sessionId` | string? | Boşsa `end-{roomId}-{YYYY-MM-DD}` oluşur (idempotent) |

**Response:** Aynı `PublisherReport` yapısı. Ek olarak SSE event gönderir:

```
event: girlive_publisher
data: {
  "event": "girlive_publisher",
  "roomId": "room123",
  "targetUserId": "owner456",
  "kind": "end_report",
  "text": "📊 Gün sonu: 15000 brüt jeton, 35 ziyaretçi, 3 PK",
  "sessionId": "end-room123-2026-10-11",
  "report": { ... }
}
```

**Flutter:**
```dart
/// Oda kapanışında çağır
Future<PublisherReport?> fetchEndReport(String roomId) async {
  final res = await dio.get(
    '/api/chat/rooms/$roomId/girlive/publisher-assistant/end-report',
  );
  if (res.data['success'] == true) {
    return PublisherReport.fromJson(res.data['report']);
  }
  return null;
}
```

---

## 7. GirLive Herkese Açık Bot

Bot, tetikleyicilere bağlı olarak sohbete otomatik mesaj yazar.

### Tetikleyiciler (sunucu taraflı, Flutter müdahalesi gerekmez)

| Tetikleyici | Fonksiyon | Zaman |
|---|---|---|
| PK başlangıcı | `onPkStart()` | `startPkBattle()` sonrası |
| PK bitişi | `onPkEnd()` | `finishPkBattle()` sonrası |
| Kullanıcı ayrılma | `onUserLeave()` | Odadan çıkış, kick, stream leave |
| Kullanıcı giriş | `welcomeUser()` | Odaya/yayına katılma (mevcut) |

### SSE Event: `girlive_publisher`

Yalnız oda sahibine gönderilir (genel sohbete yazılmaz).

```dart
void handleSseEvent(Map<String, dynamic> event) {
  if (event['event'] == 'girlive_publisher') {
    final kind = event['kind']; // 'live_status' | 'tip' | 'end_report'
    final text = event['text'];
    final targetUserId = event['targetUserId'];

    // Yalnız oda sahibiyseniz gösterin
    if (targetUserId == currentUserId) {
      switch (kind) {
        case 'end_report':
          showEndReportOverlay(event['report']);
          break;
        case 'tip':
          showFloatingTip(text);
          break;
        case 'live_status':
          updateLiveStatusBanner(text);
          break;
      }
    }
  }
}
```

### Patron Kuralı

Sunucu taraflı hitap: admin/yonetici/isFounder kullanıcılarına "Patron @username" denir.

```dart
// Bot mesajındaki "Patron" hitabını özel göster (opsiyonel)
Widget buildBotMessage(String text) {
  if (text.contains('Patron')) {
    return RichText(/* Patron kelimesini altın renkli yap */);
  }
  return Text(text);
}
```

### Admin Bot Ayarları

`GET /api/admin/girlive-bot` → `publicMessages` alanı:
```json
{
  "publicMessages": {
    "jetonPromoEnabled": true,
    "pkStartEnabled": true,
    "pkMidReminderEnabled": false,
    "pkEndEnabled": true,
    "pastPkMotivationEnabled": false,
    "welcomeLeaveEnabled": true,
    "minMessageIntervalSec": 30,
    "templates": {
      "pk_start": "⚔️ PK başladı! {hostName} vs {guestName} — hediye göndererek destekleyin!",
      "pk_end": "🏆 PK bitti! Kazanan: {winnerName} ({winnerScore} - {loserScore} jeton)",
      "pk_draw": "🤝 PK berabere! Her iki tarafı da tebrik edelim!",
      "jeton_promo": "💎 Jeton almak için profil → Jeton bölümüne göz atın!",
      "welcome": "👋 Hoş geldin {name}!",
      "leave": "👋 Görüşmek üzere {name}!"
    }
  }
}
```

`PUT /api/admin/girlive-bot` → `publicMessages` objesi ile güncelle.

---

## 8. Admin — Sistem Sağlığı

### `GET /api/admin/health`

**Auth:** Web Session, `system.audit.view` yetkisi gerekli

**Response 200:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2026-10-11T15:00:00.000Z",
    "database": {
      "connected": true,
      "latencyMs": 12
    },
    "users": {
      "total": 15420,
      "activeLastHour": 342,
      "activeLastDay": 2150
    },
    "payments": {
      "total": 8500,
      "pending": 12,
      "failedToday": 0
    },
    "live": {
      "activeSessions": 5,
      "activeStreams": 3,
      "activeRooms": 8
    },
    "moderation": {
      "pendingReports": 4,
      "pendingWithdrawals": 2
    },
    "operations": {
      "recentAuditActions": 150,
      "failedNotificationsToday": 0,
      "stalePresence": 3
    },
    "sessions": {
      "total": 45000,
      "active": 5
    }
  }
}
```

**Flutter Dashboard Widget:**
```dart
class HealthDashboard extends StatelessWidget {
  final HealthData data;

  Widget build(BuildContext context) {
    return Column(children: [
      _statusBanner(data.status), // healthy | degraded
      _metric('DB Gecikme', '${data.database.latencyMs}ms'),
      _metric('Aktif Kullanıcı (1s)', '${data.users.activeLastHour}'),
      _metric('Canlı Yayın', '${data.live.activeStreams}'),
      _metric('Bekleyen Şikâyet', '${data.moderation.pendingReports}'),
    ]);
  }
}
```

---

## 9. Admin — Şikâyet Yönetimi

### `GET /api/admin/complaints`

**Auth:** Web Session, `moderation.report.handle` yetkisi

**Query Params:**
| Param | Tip | Varsayılan | Açıklama |
|---|---|---|---|
| `status` | string | `all` | `pending` \| `reviewing` \| `resolved` \| `dismissed` \| `escalated` \| `all` |
| `page` | int | 1 | Sayfa numarası |
| `limit` | int | 50 | Sayfa boyutu (max 100) |
| `search` | string | — | Neden, detay, kullanıcı adı arama |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "reports": [
      {
        "id": "rpt123",
        "reason": "Hakaret",
        "details": "Sesli odada küfür etti",
        "status": "pending",
        "createdAt": "2026-10-11T12:00:00.000Z",
        "reporter": {
          "id": "u1", "name": "Ali", "username": "ali123",
          "image": null, "role": "user"
        },
        "reported": {
          "id": "u2", "name": "Mehmet", "username": "mehmet456",
          "image": null, "role": "user", "isBanned": false
        }
      }
    ],
    "total": 45,
    "page": 1,
    "totalPages": 1,
    "statusCounts": {
      "pending": 12,
      "reviewing": 3,
      "resolved": 25,
      "dismissed": 5
    }
  }
}
```

### `PATCH /api/admin/complaints`

**Body:**
```json
{
  "reportId": "rpt123",
  "action": "review",
  "reason": "İncelemeye alındı"
}
```

**action değerleri:**
| Action | Sonuç | Bildirim |
|---|---|---|
| `review` | → `reviewing` | — |
| `resolve` | → `resolved` | Şikâyetçiye bildirim: "Şikâyetiniz incelendi" |
| `dismiss` | → `dismissed` | Şikâyetçiye bildirim: "Ek işlem gerekmedi" |
| `escalate` | → `escalated` | — |

**Response 200:**
```json
{"success": true, "data": {"id": "rpt123", "status": "reviewing", ...}}
```

**409 — Zaten İşleniyor:**
```json
{"error": "Bu şikâyet zaten inceleniyor", "currentStatus": "reviewing"}
```

---

## 10. Admin — Finans Özeti

### `GET /api/admin/finance/summary`

**Auth:** Web Session, `finance.report.view` yetkisi

**Query Params:**
| Param | Tip | Varsayılan | Açıklama |
|---|---|---|---|
| `period` | string | `monthly` | `daily` \| `weekly` \| `monthly` \| `yearly` \| `custom` |
| `from` | ISO date | — | Custom dönem başlangıcı |
| `to` | ISO date | — | Custom dönem bitişi |
| `excludeTest` | bool | `true` | Test kullanıcı işlemlerini hariç tut |

**Response 200:**
```json
{
  "success": true,
  "data": {
    "period": "monthly",
    "dateRange": {
      "from": "2026-10-01T00:00:00.000Z",
      "to": "2026-10-11T15:00:00.000Z"
    },
    "excludeTestTransactions": true,
    "revenue": {
      "totalTL": 125000,
      "creditsAwarded": 450000,
      "transactionCount": 320
    },
    "spending": {
      "gifts": {
        "total": 380000,
        "stream": 200000,
        "chatRoom": 150000,
        "teller": 30000,
        "count": 1200
      },
      "sessions": {
        "total": 50000,
        "count": 800
      },
      "memberships": {
        "total": 25000,
        "count": 50
      }
    },
    "commission": {
      "fromGifts": 76000
    },
    "withdrawals": {
      "totalTL": 45000,
      "count": 15
    },
    "refunds": {
      "totalTL": 2000,
      "count": 3
    },
    "net": {
      "revenueTL": 78000
    }
  }
}
```

**Flutter:**
```dart
Future<FinanceSummary> fetchFinanceSummary({String period = 'monthly'}) async {
  final res = await dio.get('/api/admin/finance/summary', queryParameters: {
    'period': period,
    'excludeTest': 'true',
  });
  return FinanceSummary.fromJson(res.data['data']);
}
```

---

## 11. Admin — Bekleyen İş Sayıları

### `GET /api/admin/pending-counts`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "pendingPayments": 5,
    "cfcPaymentRequests": 3,
    "pendingWithdrawals": 2,
    "pendingTellerApplications": 1,
    "pendingAgencyApplications": 0,
    "pendingVerifications": 4,
    "pendingReports": 12
  }
}
```

**Flutter — Bekleyen İş Barı:**
```dart
Widget buildPendingBar(PendingCounts counts) {
  final items = <Widget>[];
  if (counts.pendingPayments > 0)
    items.add(_badge('Jeton/CFC', counts.pendingPayments, '/admin/payments'));
  if (counts.cfcPaymentRequests > 0)
    items.add(_badge('CFC Talep', counts.cfcPaymentRequests, '/admin/cfc-requests'));
  if (counts.pendingWithdrawals > 0)
    items.add(_badge('Çekim', counts.pendingWithdrawals, '/admin/withdrawals'));
  if (counts.pendingReports > 0)
    items.add(_badge('Şikâyet', counts.pendingReports, '/admin/complaints'));
  if (items.isEmpty) return SizedBox.shrink();
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: items));
}
```

---

## 12. Ajans Yönetimi

PR #33 ile gelen ajans endpoint'leri:

### Endpoint Listesi

| Method | Endpoint | Açıklama |
|---|---|---|
| GET | `/api/agency` | Kullanıcının ajansı |
| POST | `/api/agency` | Yeni ajans başvurusu |
| PATCH | `/api/agency` | Ajans bilgi güncelleme |
| GET | `/api/agency/members` | Üye listesi |
| POST | `/api/agency/members/invite` | Üye davet et |
| POST | `/api/agency/members/remove` | Üye çıkar |
| GET | `/api/agency/earnings` | Kazanç geçmişi |
| GET | `/api/agency/wallet` | Ajans cüzdanı |
| POST | `/api/agency/wallet/transfer` | Jeton transferi |
| GET | `/api/agency/wallet/transactions` | İşlem geçmişi |
| POST/GET/DELETE | `/api/agency/blocks` | Üye engelleme |
| GET | `/api/agency/roster` | Kadro (aktif/pasif/bekleyen/ayrılmış/engelli) |
| POST | `/api/agency/purchase` | Toplu jeton satın alma |
| GET | `/api/agency/periods` | Dönem geçmişi |
| POST | `/api/cron/agency-accruals` | Otomatik dönem kapanışı |

### Ajans Başvurusu

```dart
Future<void> applyForAgency(AgencyApplication app) async {
  final res = await dio.post('/api/agency', data: app.toJson());
  // 403 → Engellenmiş (isBlockedByAgency)
  // 409 → Zaten ajans var / başvuru beklemede
}
```

### Üye Engelleme

```dart
// Engelle
await dio.post('/api/agency/blocks', data: {'userId': targetId, 'reason': 'Kural ihlali'});
// 409 → Zaten engelli

// Engel kaldır
await dio.delete('/api/agency/blocks', data: {'userId': targetId});

// Engel listesi
final res = await dio.get('/api/agency/blocks');
```

### Kadro

```dart
final res = await dio.get('/api/agency/roster');
// {
//   "active": [...],
//   "inactive": [...],
//   "pending": [...],
//   "left": [...],
//   "blocked": [...]
// }
```

### Günlük Limitler
- **Günlük transfer limiti:** `agency.wallet.daily_transfer_limit` (platform ayarı)
- **Günlük satın alma limiti:** `agency.purchase.daily_max_jeton`
- Aşıldığında `429` döner

---

## 13. SSE Event Referansı

### Yeni Event Tipleri

| Event | Scope | Açıklama |
|---|---|---|
| `girlive_publisher` | room | Yayıncı asistanı bildirimi (yalnız oda sahibi) |
| `girlive_bot` | room / stream | Bot sohbet mesajı (PK, karşılama, uğurlama) |

### Event Yapısı: `girlive_publisher`

```json
{
  "event": "girlive_publisher",
  "eventId": 42,
  "roomId": "room123",
  "targetUserId": "owner456",
  "kind": "end_report",
  "text": "📊 Gün sonu: 15000 brüt jeton...",
  "sessionId": "end-room123-2026-10-11",
  "report": { /* PublisherReport */ }
}
```

**kind değerleri:**
- `live_status` → Anlık durum güncellemesi (ziyaretçi sayısı vb.)
- `tip` → Performans ipucu
- `end_report` → Gün sonu raporu (report alanı dolu)

### SSE Dedup

Her event'te `eventId` (int, artan) bulunur. Flutter istemcisi:
```dart
int _lastEventId = 0;

void onSseMessage(Map<String, dynamic> data) {
  final eventId = data['eventId'] as int? ?? 0;
  if (eventId <= _lastEventId) return; // Duplicate
  _lastEventId = eventId;
  // İşle...
}
```

---

## Hızlı Referans — Tüm Yeni HTTP Durum Kodları

| Kod | Anlamı | Endpoint'ler |
|---|---|---|
| 401 | Oturum gerekli | Tümü |
| 403 | Yetki yok / Engellenmiş | admin/*, agency/apply |
| 404 | Kaynak bulunamadı | complaints, rooms |
| 409 | Çakışma (duplicate/stale) | payments/requests, complaints PATCH, blocks, clientPrice |
| 429 | Günlük limit aşıldı | agency/wallet/transfer, agency/purchase |

---

*Bu doküman CanlıFal backend episode 29 kapsamında üretilmiştir. Mevcut hediye sistemi rehberi: `CANLIFAL_HEDIYE_SISTEMI_FLUTTER_REHBER.md`, genel Flutter rehberi: `CANLIFAL_FLUTTER_PROMPT.md`.*
