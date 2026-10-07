# CANLIFAL — Critical Bug Matrix

> 2026-10-07 · Yalnız denetim. "Backend/Flutter" sütunları kod düzeyindedir. Gerçek cihaz sütunu tümüyle **BLOCKED**.
> Durumlar: CODE PASS / PARTIAL / BROKEN / MISMATCH / BLOCKED.

## 1. Denetim bulguları

| ID | Feature | Problem | Backend | Flutter | Root Cause | Severity | Fix (öneri) |
|---|---|---|---|---|---|---|---|
| FORTUNE-001 | Canlı fal | Çift kabul → iki farklı roomId, cihazlar farklı odada | BROKEN | CODE PASS | `sessions/[sessionId]/route.ts:54–167` okuma-kontrol-güncelle, `roomId` her kabulde yeni | CRITICAL | `updateMany(where status=pending)` + 409, deterministik roomId, tek transaction |
| FORTUNE-002 | Canlı fal | Eski istek uygulama açılınca tekrar geliyor | BROKEN | PARTIAL | `pending` sunucuda hiç sona ermiyor (`sessions/stream/route.ts:59,105`) | CRITICAL | Sunucu TTL 180 sn → `expired`; akış sorgusuna zaman filtresi |
| FORTUNE-003 | Canlı fal | Gelen-seans SSE'si yarı-açık kalırsa fark edilmiyor | CODE PASS | PARTIAL | Heartbeat bekçisi yok (`psychic_incoming_sse_service.dart`) | MEDIUM | Oda SSE'sindeki 40 sn bekçiyi ekle |
| VOICE-001 | Sesli oda | Katılırken mikrofon yakalaması açılıyor | — | BROKEN | `trtc_room_manager.dart:439–443` `audioOnly` → `startLocalAudio` + `_micOn=true` | CRITICAL | Yalnız `publishLocal` iken başlat; varsayılan kapalı |
| VOICE-002 | Sesli oda | İki TRTC yöneticisi aynı native örneği yönetiyor | — | BROKEN | `voice_trtc_engine.dart:14` ayrı örnek; `_opGate` örnek başına (`trtc_room_manager.dart:26`) | CRITICAL | Tek sahip (provider) veya statik kapı |
| VOICE-003 | Sesli oda | Mikrofon açmak = TRTC çık + yeniden gir | — | PARTIAL | `voice_trtc_engine.dart:164–185` | HIGH | `switchRole(anchor)` + `startLocalAudio` (yeniden katılım yok) |
| VOICE-004 | Sesli oda | Zorla kapanışta kullanıcı 5 dk odada görünüyor | PARTIAL | — | presence timeout 300 sn (`presence/route.ts:52,373,605`) | HIGH | 45–60 sn + istemci heartbeat ile hizalama |
| VOICE-005 | Sesli oda | Mikrofon durumu 3 yerde | — | PARTIAL | `TrtcRoomManager._micOn`, `VoiceTrtcEngine._micOn`, provider | HIGH | Tek kaynak |
| VOICE-006 | Sesli oda | Oda olayı süzgecinin 2 farklı kopyası | — | PARTIAL | `core/room/room_event_scope.dart` ↔ `voice_hub/domain/room_event_scope.dart` | MEDIUM | Tek fonksiyon |
| GIFT-001 | Hediye | Video hediye erken kapanıyor | PARTIAL | BROKEN | Backend varsayılanı 3000 ms (`gift-engine.ts:92–96`); overlay `Timer(durationMs)` (`gift_engine_overlay.dart:83–103`); clamp 12 sn (`gift_animation_policy.dart:21`) | CRITICAL | Video bitişi = `max(backend, video)`; backend süreyi probe ile zorunlu tutsun |
| GIFT-002 | Hediye | Alıcıda 0–2 sn gecikme | PARTIAL | CODE PASS | Sohbet SSE'si 2 sn'de bir DB yokluyor (`stream/route.ts:233`) | MEDIUM | Olay yolu / NOTIFY |
| GIFT-003 | Hediye | Çift oynatma riski (iki süzgeç) | — | PARTIAL | VOICE-006 ile aynı | MEDIUM | Tek süzgeç + `giftHistoryId` tekilleştirme |
| BG-001 | Arka plan | Admin mobilden arka plan yükleyemiyor | MISMATCH | — | `/api/admin/voice-room-backgrounds` → `room-themes/backgrounds` yalnız web oturumu | HIGH | `requireAdmin(req)` |
| BG-002 | Arka plan | Değişiklik diğer kullanıcılara gitmiyor | BROKEN | BROKEN | SSE olayı yok (B-H2) + Flutter yanlış anahtar (`chat_room_providers.dart:1119`) | HIGH | `room_event{type:'background', backgroundImage}` + Flutter anahtarı |
| PK-001 | PK | REST ve SSE farklı backend | — | MISMATCH | `api_backend_router.dart:26` games, `pk_match_sse_service.dart:28` main | HIGH | Tek backend (canlifal.com) |
| PK-002 | PK | PK SSE kimliksiz | PARTIAL | — | `/api/pk/[matchId]/stream` auth yok | LOW | `authenticateRequest` |
| ADMIN-001 | Admin | 30 admin işlemi mobilde 401/403 | MISMATCH | — | `getServerSession` yalnız web oturumu | CRITICAL (admin işlevi) | rbac `resolveUser` |
| ADMIN-002 | Admin | Repo dalı ≠ üretim | BROKEN (repo) | — | eksik `@/lib/admin-auth`, eksik `admin/live-stats` | HIGH | Üretim kaynağını repoya eşitle |
| CORE-001 | Genel | 395 sessiz `catch (_) {}` | 77 | 395 | SILENT FAILURE | MEDIUM | Kritik akışlarda `CfDiag.recordError` |
| CORE-002 | Genel | Çift SSE uygulaması | — | PARTIAL | `core/sse_client.dart` realtime akışları kullanılmıyor | MEDIUM | Kaldır veya tek servise bağla |

## 2. Bildirilen 38 hatanın eşlemesi

| # | Bildirilen | Eşleşen bulgu | Kanıt düzeyi | Gerçek cihaz |
|---|---|---|---|---|
| 1 | Uygulama donması | FORTUNE-001/002, VOICE-002; PR #449 yoklama birikmesi | Kısmi | BLOCKED |
| 2 | Zorla kapanma | CORE-001 (sessiz hatalar teşhisi engelliyor) | Yok | BLOCKED |
| 3 | Yetkili koltuğa geç oturuyor | VOICE-003 (mikrofon = yeniden katılım); `08a2de49` "restore admin auto-seat" | Kod | BLOCKED |
| 4 | Arka plan görünmüyor | BG-001, BG-002 | Kod | BLOCKED |
| 5 | Canlı fal seansı başlamıyor | FORTUNE-001 | Kod | BLOCKED |
| 6 | Koltuktan düşme | VOICE-004 (koltuk bayatlık 90 sn) | Kısmi | BLOCKED |
| 7 | Ana sayfada hâlâ odada görünme | VOICE-004 | Kod | BLOCKED |
| 8 | Hediye iki cihazda eşzamanlı değil | GIFT-002, GIFT-003 | Kısmi | BLOCKED |
| 9 | Video hediyenin tamamı oynamıyor | GIFT-001 | Kod | BLOCKED |
| 10 | Video hediye donuyor | GIFT-001 (zamanlayıcı ile video çatışması) | Kısmi | BLOCKED |
| 11 | Hediye animasyonu geç | GIFT-002 | Kısmi | BLOCKED |
| 12 | Koltuktan inince ses devam | VOICE-001, VOICE-002; `08a2de49` | Kod | BLOCKED |
| 13 | Çıkınca karşı ses geliyor | VOICE-002; `45a6f4e0` | Kod | BLOCKED |
| 14 | Çıkınca sesim gidiyor | VOICE-001, VOICE-002 | Kod | BLOCKED |
| 15 | Canlı yayında aynı ses sorunları | Aynı `TrtcRoomManager` | Kısmi | BLOCKED |
| 16 | Owner mikrofonu açınca benimki açılıyor | VOICE-001, VOICE-005 | Kod | BLOCKED |
| 17 | PK isteği yanlış ekrana | PK-001 | Kod | BLOCKED |
| 18 | Canlı fal isteğinde falcı donuyor | FORTUNE-002, FORTUNE-003 | Kısmi | BLOCKED |
| 19 | Yeniden açınca eski istek | FORTUNE-002 | Kod | BLOCKED |
| 20 | İstek gönderenin ekranı donuyor | PR #449 (ref/dispose, çift istek) — düzeltildi | Kod + test | BLOCKED |
| 21 | Kabulü bekliyor'da takılma | FORTUNE-001 (roomId farklı) | Kod | BLOCKED |
| 22 | Timer popup yanlış zamanda | Yerel sayım + yoklama aralığı | Kısmi | BLOCKED |
| 23 | Bir cihazda başlayıp diğerinde başlamaması | FORTUNE-001 | Kod | BLOCKED |
| 24 | 2 dk sonra bağlantı | FORTUNE-001, PR #449 (TRTC token zaman aşımı) | Kod | BLOCKED |
| 25 | Geç bağlantıda timer geriden başlıyor | Sunucu zamanı referansı yok | Kod | BLOCKED |
| 26 | Admin paneli çalışmıyor | ADMIN-001 | Kod + API (401) | BLOCKED |
| 27 | Admin işlemleri geç | ADMIN-001 (401 sonrası yeniden deneme), ölçülmedi | Kısmi | BLOCKED |
| 28 | Bazı admin işlemleri hiç çalışmıyor | ADMIN-001 | Kod + API | BLOCKED |
| 29 | Profil geç açılıyor | Ölçülmedi (oturum gerekli) | Yok | BLOCKED |
| 30 | Eski oda/seans state'i yeni ekrana taşınıyor | VOICE-002, VOICE-006; PR #449 SSE disconnect yarışı (düzeltildi) | Kod | BLOCKED |
| 31 | SSE çift bağlantı | CORE-002; PR #449 | Kısmi | BLOCKED |
| 32 | TRTC çift bağlantı | VOICE-002 | Kod | BLOCKED |
| 33 | Timer sızıntısı | PR #449 testleri: bekleme/görüşme ekranında sızıntı yok | Test (sahte) | BLOCKED |
| 34 | Polling sızıntısı | PR #449 testleri | Test (sahte) | BLOCKED |
| 35 | Listener sızıntısı | `CfResourceTracker` (Cursor) mevcut; ölçülmedi | Yok | BLOCKED |
| 36 | Bellek sızıntısı | Ölçülmedi | Yok | BLOCKED |
| 37 | Crash | CORE-001 | Yok | BLOCKED |
| 38 | ANR | Ölçülmedi | Yok | BLOCKED |
