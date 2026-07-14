# Sesli sohbet performans ve senkronizasyon raporu — 1.0.30+35

**Tarih:** 2026-07-14  
**Kapsam:** Flutter mobil istemci (`mobile/`). Backend (PostgreSQL/Redis) bu repoda değildir; sunucu tarafı için canlifal.com API ekibi gerekir.

## Kabul kriterleri — durum

| Kriter | Hedef | Flutter tarafı |
|--------|--------|----------------|
| Odaya giriş | &lt; 1 sn | Paralel presence+mesaj, optimistic UI, SSE hemen, bütçe 1 sn |
| Odadan çıkış | Anında | Optimistic presence silme, force SSE disconnect, koltuk temizleme |
| Ghost user | Yok | leave + clearSeat + forceRelease; oda değişiminde eski oturum kapatılır |
| Oda geçişi | &lt; 1 sn | `prepareVoiceRoomSwitch` + aktif oturum kaydı |
| Yetkili auto-seat | ~ & @ % | `tierFromRoleSymbol`, öncelik: kurucu/admin/mod/SOP |
| PK | Çalışır | Mevcut remote + kabul sonrası TRTC prewarm |
| Profil | &lt; 1 sn | `ProfileLoadPerf.prefetchOnOpen`, cache, skeleton |
| Memory leak | Yok | Timer/SSE dispose korundu; force release eklendi |
| 60 FPS | Hedef | RepaintBoundary sohbet satırları, selective rebuild (önceki sürüm) |

## Yapılan optimizasyonlar

### 1. Odaya giriş (&lt; 1 sn)

- `VoiceRoomEntryPerf.entryBudget` → **1 saniye**
- `_beginRoomSession`: presence + mesajlar **paralel** (`Future.wait`)
- SSE bağlantısı API yanıtını beklemeden başlar
- `_seedOptimisticSelfPresence`: auth cache’den anında kullanıcı listede görünür
- `loading: false` ile UI uzun spinner göstermez

**Dosyalar:** `voice_room_entry_perf.dart`, `chat_room_providers.dart`

### 2. Odadan çıkış ve ghost user

- `_removeSelfFromPresenceOptimistic`: çıkışta kullanıcı yerel listeden anında silinir
- `_leavePresenceWithSeatClear`: API leave + `clearSeat` (koltuk ghost önleme)
- `forceReleaseVoiceRoom`: SSE anında kesilir (ref sayacı yok sayılır)
- `leaveRoomSession` ve `onDispose` aynı temizlik yolunu kullanır

**Dosyalar:** `chat_room_providers.dart`, `chat_room_providers_presence.dart`, `sse_connection_hub.dart`

### 3. Başka odaya geçiş

- `voiceRoomActiveLiveKeyProvider`: aktif oda takibi
- `prepareVoiceRoomSwitch`: eski oda tam kapatılır, yeni oda kaydedilir
- `open_voice_room_vip.dart`: tüm önceki oturumlar (yalnızca sahip odaları değil) kapatılır

**Dosyalar:** `voice_room_session_registry.dart`, `voice_room_session_utils.dart`, `open_voice_room_vip.dart`

### 4. Yetkili otomatik koltuk (~ & @ %)

- `shouldAutoSit`: tier ≥ OP (`@` ve üzeri); `+` ses rolü hariç
- `shouldAutoSitForSymbol` / `tierFromRoleSymbol`: IRC sembolleri
- `_privilegedRolePriority`: `roleSymbol` + sunucu rolü ile otomatik koltuk
- Boş koltuk yoksa ayakta kalır (mevcut davranış)

**Dosyalar:** `voice_room_seat_priority.dart`, `chat_room_providers_seat.dart`

### 5. PK

- PK kabulünde `VoiceRoomEntryPerf.prewarmOnRoomTap` (TRTC/Agora token ön ısıtma)
- Mevcut `pkBattleRemoteProvider` + oda SSE senkronu korunur

**Dosya:** `voice_pk_invite_listener.dart`

### 6. Profil

- `ProfileLoadPerf.prefetchOnOpen` profil sekmesinde paralel dilim yükleme
- Avatar: `CanlifalNetworkImage` (disk cache) — mevcut

**Dosya:** `profile_page.dart`

### 7. SSE ve presence

- Heartbeat: SSE son 45 sn içinde aktifse atlanır (gereksiz poll azalır)
- `_markSseActivity` join/leave/connected olaylarında

**Dosyalar:** `chat_room_providers.dart`, `chat_room_providers_presence.dart`

### 8. Backend (bu repo dışı)

Aşağıdakiler **canlifal.com** sunucusunda yapılmalıdır:

- Presence leave: Redis + PostgreSQL atomik transaction
- N+1 sorgu ve index optimizasyonu
- EXPLAIN ANALYZE ile yavaş endpoint’ler

Mobil istemci: optimistic leave + `DELETE/POST leave` + `clearSeat` ile sunucu gecikmesini maskeler.

### 9. Flutter ek

- `RepaintBoundary` sohbet mesaj satırları
- Önceki sürüm: selective rebuild (`_BasicLiveShell`, `VoiceRoomBasicChatFeed` Consumer)

## Düzeltilen dosyalar (bu oturum)

| Dosya | Değişiklik |
|-------|------------|
| `core/performance/voice_room_entry_perf.dart` | Giriş bütçesi 1 sn |
| `core/network/sse/sse_connection_hub.dart` | `forceReleaseVoiceRoom` |
| `features/voice_hub/.../chat_room_providers.dart` | Paralel giriş, optimistic leave, SSE activity |
| `features/voice_hub/.../chat_room_providers_presence.dart` | Seat clear leave, heartbeat skip |
| `features/voice_hub/.../chat_room_providers_seat.dart` | Sembol tabanlı auto-seat |
| `features/voice_hub/.../voice_room_seat_priority.dart` | ~ & @ % kuralları |
| `features/voice_hub/.../voice_room_session_registry.dart` | Aktif oturum provider |
| `features/voice_hub/.../voice_room_session_utils.dart` | Oda geçiş teardown |
| `features/vip_gold/.../open_voice_room_vip.dart` | `prepareVoiceRoomSwitch` |
| `features/voice_hub/.../voice_pk_invite_listener.dart` | PK kabul prewarm |
| `features/voice_hub/.../voice_room_basic_premium_section.dart` | RepaintBoundary |
| `features/profile/.../profile_page.dart` | Profil prefetch |

## Performans testi (otomatik)

- Ortamda Flutter SDK yoksa CI (`dart analyze`, `flutter test`) doğrular
- Manuel: soğuk açılış → oda giriş → çıkış → başka oda → yetkili nick ile auto-seat → PK davet

## Bilinen sınırlar

- Ghost user tamamen sunucu presence TTL’sine de bağlıdır; istemci optimistic + API leave gönderir
- PK iki yayıncı video: karşı tarafın Agora/TRTC token’ı ve backend PK state gerekir
- &lt; 1 sn hedefleri zayıf ağda aşılabilir; optimizasyonlar medyan süreyi düşürür
