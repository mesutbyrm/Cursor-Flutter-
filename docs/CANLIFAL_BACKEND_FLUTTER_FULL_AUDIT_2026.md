# CANLIFAL — BACKEND ↔ FLUTTER FULL SYSTEM AUDIT 2026

> **Tarih:** 2026-10-07 · **Aşama:** yalnız denetim (kod değişikliği YOK)
> **Flutter:** `mesutbyrm/Cursor-Flutter-` `main` @ `45a6f4e0` (1.0.731+784)
> **Backend:** `mesutbyrm/canlifal` dalı `full-source` @ `f084f3a` (`nextjs_space/app/api`, 729 `route.ts`)
> **Üretim:** `https://canlifal.com` (yalnız salt-okunur GET + yetkisiz admin GET ile yoklandı)

Bağlı raporlar:
[API mismatch](CANLIFAL_API_MISMATCH_REPORT.md) ·
[Realtime state machine](CANLIFAL_REALTIME_STATE_MACHINE_AUDIT.md) ·
[Critical bug matrix](CANLIFAL_CRITICAL_BUG_MATRIX.md) ·
[Gerçek cihaz test planı](CANLIFAL_REAL_DEVICE_TEST_PLAN_2026.md) ·
[Diagnostic spec](CANLIFAL_DIAGNOSTIC_SYSTEM_SPEC.md)

---

## 0. ÖZET

```
BACKEND:
CRITICAL = 2
HIGH     = 4
MEDIUM   = 3
LOW      = 2

FLUTTER:
CRITICAL = 3
HIGH     = 4
MEDIUM   = 4
LOW      = 2

CONTRACT MISMATCH: 34
  (30 admin rota+metot çifti yalnız web oturumu kabul ediyor, mobil JWT reddediliyor
   + 2 PK REST/SSE farklı backend + 1 arka plan olayı + 1 hediye süresi sözleşmesi)

REALTIME (9 akış):  PASS = 1   PARTIAL = 4   BROKEN = 4
TRTC     (6 akış):  PASS = 1   PARTIAL = 3   BROKEN = 2
SSE      (7 uç):    PASS = 4   PARTIAL = 2   BROKEN = 1

REAL DEVICE: BLOCKED (hiçbir senaryo gerçek cihazda koşulmadı)
```

### Durum etiketleri — sahte PASS yok

| Etiket | Anlamı |
|---|---|
| **CODE PASS** | Kod okundu, mantık doğru görünüyor |
| **API PASS** | Üretim ucu yanıt verdi (yalnız salt-okunur GET) |
| **INTEGRATION PASS** | Flutter + backend birlikte otomatik testte doğrulandı |
| **REAL DEVICE PASS** | İki gerçek cihazda doğrulandı — **bu raporda hiç yok** |
| **BLOCKED** | Gerçek cihaz/oturum gerektiriyor, yapılmadı |

Bu rapordaki "PASS" ifadeleri en fazla **CODE PASS** düzeyindedir. Tüm realtime/ses/hediye/PK senaryoları için gerçek cihaz durumu **BLOCKED**'dur.

### Önemli uyarı — kaynak sapması

Backend reposundaki `full-source` dalı üretimle **birebir aynı değil**:
- `app/api/admin/withdrawals/route.ts` ve `app/api/admin/jeton-pricing/route.ts`, repoda **bulunmayan** `@/lib/admin-auth` modülünü import ediyor. Bu dal olduğu gibi derlenemez. Üretimde aynı uçlar `401` dönüyor, yani üretim farklı bir koddan derlenmiş.
- `/api/admin/live-stats` üretimde var (`401`), repoda yok.

Bu yüzden backend bulguları **repo koduna** dayanır. Üretimde aynı satırların çalıştığı varsayılmıştır ama doğrulanmamıştır.

---

## 1. CRITICAL BLOCKERS

### B-C1 · Canlı fal "kabul" atomik değil — çift kabul iki farklı oda üretir (BACKEND)
- **Dosya:** `nextjs_space/app/api/fortune-tellers/sessions/[sessionId]/route.ts`
  - satır 33–56: `findUnique` → `if (status !== 'pending')` (okuma-kontrol)
  - satır 68: `roomId = \`room_${id}_${Date.now()}\`` (her kabulde **farklı** oda)
  - satır 80 civarı: `tellerChatSession.create` (her kabulde yeni kayıt)
  - satır 164–167: `prisma.liveSession.update({ where: { id } })` — **koşulsuz** güncelleme
- **Sonuç:** Aynı seansa eşzamanlı iki `accept` (falcının iki cihazı, çift dokunuş, ağ tekrarı) ikisi de geçer. İki `roomId`, iki sohbet oturumu, iki bildirim oluşur ve son yazan kazanır. Danışan bir odaya, falcı diğerine girebilir.
- **İlişkili bildirilen hatalar:** #5, #21, #23, #24, #25
- **Öneri:** `updateMany({ where: { id, status: 'pending' } })` + `count === 0 → 409`; `roomId` deterministik (`room_${id}`); create işlemleri aynı `$transaction` içinde.

### B-C2 · Bekleyen (`pending`) canlı fal seansı sunucuda hiç sona ermiyor (BACKEND)
- **Dosya:** `nextjs_space/app/api/fortune-tellers/sessions/stream/route.ts:59, :105`: `where: { tellerId, status: 'pending' }`; zaman sınırı yok.
- `fortune-tellers/session*` rotalarında `status: 'expired'` atayan kod yok. 3 dakikalık sınır yalnız istemcide var: `psychic_waiting_screen.dart` `_onExpired`.
- **Sonuç:** Danışan uygulamayı zorla kapatırsa seans sonsuza dek `pending` kalır. Falcı uygulamayı her açtığında aynı istek popup olarak tekrar gelir.
- **İlişkili:** #19, #18, #20
- **Öneri:** Sunucu tarafı TTL: `createdAt < now-180s` olan `pending` kayıtlar → `expired`. Akış sorgusuna `createdAt >= now-180s` filtresi eklenmeli.

### F-C1 · Sesli oda dinleyicisi katılırken mikrofon yakalaması açılıyor (FLUTTER)
- **Dosya:** `mobile/lib/features/trtc/presentation/trtc_room_manager.dart:439–443`: `if (audioOnly) { _startLocalAudio(); … _micOn = true; }`, koltuk/rol durumundan **bağımsız**.
- `mobile/lib/features/voice_hub/presentation/audio/voice_trtc_engine.dart:126–140`: önce `join(audioOnly: true)`, **sonra** `if (!publishMic) setMicEnabled(false)`.
- **Sonuç:** Koltuksuz her katılımda kısa bir pencere boyunca yerel mikrofon yakalanıyor ve `_micOn=true` görünüyor. Rol `audience` olduğu için yayın gitmemeli, ama sonraki rol/yeniden katılım geçişlerinde yanlış durum taşınabilir. Bu, "koltuksuz ses gidiyor" ve "owner mikrofonu açınca benimki açıldı" belirtileriyle uyumlu.
- **İlişkili:** #12, #14, #16
- **Öneri:** `join` içinde `audioOnly` dalı yalnız `publishLocal == true` iken `startLocalAudio` yapmalı. Varsayılan `_micOn=false` olmalı.

### F-C2 · Aynı native TRTC örneğini iki ayrı `TrtcRoomManager` yönetiyor (FLUTTER)
- **Dosya:** `voice_trtc_engine.dart:14`: `_manager = TrtcRoomManager()` (sesli oda kendi örneğini yaratıyor). Canlı yayın, canlı fal ve DM ise `trtcRoomManagerProvider` tekilini kullanıyor.
- `trtc_room_manager.dart:25–26`: `_activeSession` **statik**, ama işlem kapısı `_opGate` **örnek başına**. İki yönetici aynı `TRTCCloud.sharedInstance()` üzerinde `enterRoom`/`exitRoom` çağrısını **serileştirmiyor**.
- **Sonuç:** Odalar arası hızlı geçişte (sesli oda → canlı → falcı) aynı native motor üzerinde yarış oluşabiliyor. Belirtiler: TRTC iki kez katılım, eski oda sesi, "çıkınca hâlâ ses".
- **İlişkili:** #13, #30, #32
- **Öneri:** Tek TRTC sahibi: tüm modüller `trtcRoomManagerProvider` kullanmalı veya `TrtcOperationGate` statik/global olmalı.

### F-C3 · Video hediye, backend süresi dolunca kesiliyor (FLUTTER + BACKEND sözleşmesi)
- **Backend:** `nextjs_space/lib/gift-engine.ts:92–96`: `resolveDurationMs`, hediye türünde `animationDurationMs`/`displayDurationMs` yoksa **3000 ms** döndürüyor.
- **Flutter:**
  - `gift_engine_overlay.dart:83, :99`: overlay `Timer(durationMs)` ile kapanıyor; video süresine bakılmıyor.
  - `gift_engine_parser.dart:182`: `clamp(500, 30000)`.
  - `gift_animation_policy.dart:21`: `clamp(3000, 12000)`.
  - `gift_render_meta.dart:44–47`: `clamp(800, 20000)` ve `(1500, 12000)`.
- **Sonuç:** Süresi tanımsız video hediye 3 sn'de kapanıyor. 12 sn'den uzun videolar politika sınırında kesiliyor.
- **İlişkili:** #9, #10
- **Öneri:** Video türünde bitiş = `max(backendDuration, videoDuration)` (video `completed` olayı), üst sınır 30 sn. Backend'de süre, yüklemede probe ile hesaplanıp zorunlu tutulmalı.

---

## 2. HIGH

| ID | Taraf | Bulgu | Dosya:satır |
|---|---|---|---|
| B-H1 | Backend | Presence zaman aşımı **5 dk**: zorla kapatılan kullanıcı ana sayfada 5 dk'ya kadar odada görünüyor. Koltuk bayatlık süresi 90 sn. | `app/api/chat/rooms/[roomId]/presence/route.ts:52, :373, :605` (`Date.now() - 300000`); `lib/voice-room-constants.ts:22` |
| B-H2 | Backend | Arka plan değişince sohbet SSE'si **hiçbir olay göndermiyor**. Akıştaki tipler: connected/messages/system/gift/pk/gift_box/room_event/presence/typing. | `app/api/chat/rooms/[roomId]/stream/route.ts:66–222`; `settings/route.ts:124`, `background/route.ts:50` olay yaymıyor |
| B-H3 | Backend | Hediye süresinin varsayılanı 3000 ms (F-C3'ün backend yarısı) | `lib/gift-engine.ts:92–96` |
| B-H4 | Backend | Repo dalı ≠ üretim (eksik `@/lib/admin-auth`, eksik `/api/admin/live-stats`) | `app/api/admin/withdrawals/route.ts:2`, `app/api/admin/jeton-pricing/route.ts` |
| F-H1 | Flutter | Koltukta mikrofon açmak = TRTC'den **çık + yeni host token + yeniden gir**. Ses kesintisi ve "koltuğa geç oturma" nedeni olabilir. | `voice_trtc_engine.dart:164–185` |
| F-H2 | Flutter | PK REST `/api/pk/*` **games backend'e** (`canlifalapi.abacusai.app`), PK SSE `/api/pk/{id}/stream` **canlifal.com**'a gidiyor. Aynı `matchId` iki ayrı backend'e soruluyor. | `core/network/api_backend_router.dart:26, :66–69`; `core/config/env.dart:24`; `features/live/data/pk/pk_match_sse_service.dart:28–31` |
| F-H3 | Flutter | Arka plan SSE işleyicisi `backgroundImageUrl`/`backgroundUrl` anahtarlarını bekliyor; backend `backgroundImage` kullanıyor ve olay da yaymıyor. İşleyici fiilen ölü. | `voice_hub/presentation/providers/chat_room_providers.dart:1119–1122` |
| F-H4 | Flutter | **CRITICAL STATE DUPLICATION:** mikrofon durumu 3 yerde tutuluyor: `TrtcRoomManager._micOn`, `VoiceTrtcEngine._micOn`, `chat_room_providers_room_sync` (isMicOn). `seatIndex` 28 alan tanımında, `sseConnected` 6 alanda. | `trtc_room_manager.dart:37`, `voice_trtc_engine.dart`, `chat_room_providers_room_sync.dart` |

## 3. MEDIUM

| ID | Taraf | Bulgu | Dosya |
|---|---|---|---|
| B-M1 | Backend | Sohbet SSE her bağlantı için 2 sn'de bir DB yokluyor. Hediye/presence gecikmesi 2 sn'ye kadar çıkabiliyor, bağlantı sayısıyla DB yükü artıyor. | `chat/rooms/[roomId]/stream/route.ts:233` |
| B-M2 | Backend | "Yazıyor" olayı bellek içi olay yolunda. Çoklu instance'ta kaybolur (Redis/olay yolu yok). | `lib/chat-events.ts` (`getTypingUsers`) |
| B-M3 | Backend | 77 sessiz `catch {}` (SILENT FAILURE) | `app/api/**`, `lib/**` |
| F-M1 | Flutter | **395 sessiz `catch (_) {}`**, 171 dosyada: voice_hub 109, live 59, live_psychics 26, gifts 14, trtc 11 | `mobile/lib/**` |
| F-M2 | Flutter | Gelen-seans SSE'sinde heartbeat bekçisi yok (yarı-açık bağlantı fark edilmez) | `live_psychics/data/services/psychic_incoming_sse_service.dart` |
| F-M3 | Flutter | Çift SSE uygulaması: `core/sse_client.dart` beş realtime akış tanımlıyor (chatRoom/videoStream/fortuneSession/fortuneTellerRequests/notifications). Aynı uçlar için ayrı servisler de var (`ChatRoomSseService` vb.). `sseClientProvider` yalnız kendi dosyasında referanslı. | `core/sse_client.dart:100–160`, `core/sse_client_provider.dart` |
| F-M4 | Flutter | Oda olayı süzgecinin **iki farklı kopyası** var: hediye tarafı `core/room/room_event_scope.dart` (34 satır), oda tarafı `voice_hub/domain/room_event_scope.dart` (48 satır). Mantıkları farklı, bir olay birinde kabul edilip diğerinde reddedilebilir. | iki dosya |

## 4. LOW

| ID | Taraf | Bulgu |
|---|---|---|
| B-L1 | Backend | `/api/pk/{matchId}/stream` kimlik doğrulamasız (herkese açık SSE) |
| B-L2 | Backend | 115 rota yalnız web oturumu kullanıyor; Flutter'ın çağırmadıkları tasarım borcu |
| F-L1 | Flutter | Agora artıkları: `VoiceAgoraException` typedef, `audio.agora.*` log anahtarları, yorum satırı. Çalışma zamanı yolu yok. |
| F-L2 | Flutter | `GAMES_API_BASE_URL` varsayılanı `canlifalapi.abacusai.app` (tek base URL kuralına aykırı; bkz. F-H2) |

---

## 5. Uç noktası özeti (ayrıntı: [API mismatch raporu](CANLIFAL_API_MISMATCH_REPORT.md))

| Ölçüm | Sayı |
|---|---|
| Backend rota dosyası | 729 |
| Flutter'da yolu çözülen HTTP çağrısı | 637 |
| Benzersiz rota+metot çifti | 478 |
| PASS (JWT veya oturum kabul eden rota) | 354 |
| PASS* (public/proxy, auth'u elle doğrulanmalı) | 94 |
| **MISMATCH** (yalnız web oturumu: Flutter JWT ile **401/403**) | **30** |
| MISSING (repoda yok, üretimde var) | 1 |
| Dinamik yol, statik çözülemedi (UNVERIFIED) | 100 |
| Metot uyuşmazlığı | 0 |

Bu turda yalnız rota, metot ve auth karşılaştırıldı. Request/response **gövde alanları** her uç için ayrı ayrı karşılaştırılmadı. Ayrıntıları kritik akışlar için state machine raporunda verdim, gerisi bir sonraki turun işi.

## 6. Tek base URL

| Kaynak | Değer | Durum |
|---|---|---|
| `Env.apiBaseUrl` | `https://canlifal.com` | PASS |
| `Env.webOrigin` | `https://canlifal.com` | PASS |
| `Env.gamesApiBaseUrl` | `https://canlifalapi.abacusai.app` | **Üretim çalışma zamanında kullanılıyor** (`/api/pk/*` REST) → F-H2 |
| `localhost` / `127.0.0.1` | Yalnız yerel geliştirme dalları (`env.dart:44`, `chat_room_remote_datasource.dart:47`, `youtube_stream_resolver.dart:37`) | LEGACY (yalnız dev) |
| Sabit IP | Yok | PASS |

## 7. Auth / JWT

| Kontrol | Sonuç | Kanıt |
|---|---|---|
| Eşzamanlı 401'de tek refresh | **CODE PASS**: `Completer` kuyruğu | `core/network/auth_token_refresh_coordinator.dart:84–120` |
| SSE yeniden bağlanırken güncel token | **CODE PASS**: her `_openStream` token'ı yeniden okuyor; 401'de koordinatörlü refresh | `psychic_room_sse_service.dart`, `base_sse_service.dart` |
| TRTC token | Her join'de `POST /api/trtc/token` | `trtc_remote_datasource.dart:26–56` |
| Admin uçları | **MISMATCH** (30 çift web oturumu) | §5 |
| Arka plan → ön plan | **BLOCKED** (cihaz gerekir) | — |

## 8. Bildirilen 38 hatanın eşlemesi

Tam tablo [Critical bug matrix](CANLIFAL_CRITICAL_BUG_MATRIX.md) içinde. Kısaca:
- **Kodda kök nedeni bulunan:** #4, #9, #10, #12–#14, #16, #17, #19, #21, #23–#28, #30, #32.
- **Kısmi kanıt:** #3, #6, #7, #8, #11, #18, #20, #22, #31, #33–#36.
- **Cihaz gerektiren (BLOCKED):** #1, #2, #15, #29, #37, #38.

## 9. Ölçülen gecikmeler (üretim, salt-okunur GET, 3 deneme)

| Uç | Süreler | Sınıf |
|---|---|---|
| `/api/public/jeton-price` | 809 / 757 / 492 ms | 500–1000 ms |
| `/api/chat/rooms` | 295 / 240 / 579 ms | <500 ms (çoğunlukla) |
| `/api/fortune-tellers` | 609 / 497 / 570 ms | 500–1000 ms |
| `/api/gifts/types` | 502 / 508 / 286 ms | ~500 ms |
| `/api/mobile/config` | 550 / 477 / 522 ms | ~500 ms |
| `/api/homepage-buttons` | 511 / 296 / 231 ms | <500 ms (çoğunlukla) |

Kimlik doğrulamalı uçlar (profil, admin, seans) ölçülmedi, oturum gerekir → **BLOCKED**.

## 10. Düzeltme sırası (önerilen — henüz kod değişikliği yok)

1. **PHASE 1 — Kritik realtime:** F-C1, F-C2, F-H1, F-H4, B-H1
2. **PHASE 2 — Canlı fal:** B-C1, B-C2, F-M2
3. **PHASE 3 — PK:** F-H2, B-L1
4. **PHASE 4 — Hediye:** F-C3, B-H3, F-M4, B-M1
5. **PHASE 5 — Canlı yayın:** cihaz bulgularına göre
6. **PHASE 6 — Profil:** cihaz/ölçüm sonrası
7. **PHASE 7 — Admin:** 30 MISMATCH. Backend'de `getServerSession` yerine `requireAdmin` (rbac `resolveUser`: JWT + oturum) kullanılmalı.
8. **PHASE 8 — Performans/bellek/ANR:** F-M1, F-M3, B-M1, B-M2

Her fazdan sonra `flutter analyze` + `flutter test` çalışacak. Backend için `tsc`/lint/test.
