# CanliFal — Fixes Done & Remaining

**Date:** 2026-08-04  
**Branch:** `cursor/room-music-system-df6c` (PR #306)

---

## 1. ÇALIŞAN (doğrulanmış)

### Auth
- ✅ Mobil JWT login/register (`/api/auth/mobile-*`)
- ✅ Google / Apple / TikTok OAuth
- ✅ Token refresh (`mobile-refresh`) + 401 interceptor
- ✅ `flutter_secure_storage` token saklama
- ✅ Oturum restore (`AuthController` bootstrap)

### Sesli odalar
- ✅ TRTC join/leave/mute (`VoiceTrtcEngine`)
- ✅ SSE presence, mesaj, hediye (`ChatRoomSseService`)
- ✅ Koltuk sistemi, moderasyon, owner kontrolleri
- ✅ Anında oda çıkışı (dispose + PK disconnect) — v1.0.124
- ✅ Hoparlör/mikrofon gate (`VoiceRoomUiState`)

### Müzik (kısmi — yeni)
- ✅ `SongQueueService` backend (api mirror)
- ✅ `current-song`, `queue`, `skip/pause/resume` API
- ✅ SSE `song_*` olayları
- ✅ `RoomSongBloc` + `RoomSongMiniPlayer` (IFrame)
- ✅ `!istek` + song-request REST
- ⚠️ **Çift yol:** Eski `VoiceRoomDjPlayer` (just_audio) hâlâ aktif

### Hediyeler
- ✅ Gift Engine SSE router (`gift_received`, `queue_updated`, `finished`)
- ✅ Tam ekran MP4/WebM (v1.0.125 düzeltmesi)
- ✅ Prefetch beklemeden animasyon başlatma
- ✅ Thumbnail fallback (🎁 yerine)
- ✅ Backend `durationMs` parity

### Canlı yayın
- ✅ TRTC broadcast (`live_broadcast_room_page`)
- ✅ PK savaşları (voice + live)
- ✅ Video stream SSE

### Sosyal / diğer
- ✅ Social feed, stories, messages DM
- ✅ Fortune menü + AI streaming SSE
- ✅ Shorts, games, wallet, notifications SSE
- ✅ OneSignal / FCM kayıt (yapılandırma dosyası repoda yok — tolere edilir)

### CI / test
- ✅ `dart analyze` 0 ERROR
- ✅ Flutter test: **370 geçti**, 2 skipped
- ✅ API test: geçti
- ✅ PR #306 CI + CodeQL yeşil

---

## 2. ÇALIŞMAYAN / EKSİK / KISMİ

### Müzik — prod parity tam değil
| Madde | Durum |
|-------|-------|
| Tek IFrame oynatıcı (stream URL yok) | 🔴 `youtube_explode` + `music-stream` hâlâ kodda |
| `RoomSongBloc` tüm odalarda tek kaynak | 🟡 Sadece RTC sayfasında; eski DJ player paralel |
| Arka plan mini player global | 🟡 `MiniMusicPlayer` eski path kullanıyor |
| SongQueue prod (`canlifal.com`) | ⚠️ Mirror'da var; prod deploy doğrulanmadı |

### RTC — Agora temizliği
| Madde | Durum |
|-------|-------|
| Agora kodu kaldır | 🔴 ~18 dosya deprecated ama duruyor |
| LiveKit kaldır | 🔴 Modül unwired |
| Yalnızca TRTC | 🟡 Coordinator TRTC; env flag yanıltıcı |

### API bağlantı eksikleri
| Endpoint | Flutter |
|----------|---------|
| `/api/broadcast-images` | ❌ Sabit yok |
| `/api/football` | ❌ |
| `/api/online-fal` | ❌ |
| `/api/translations` | ❌ |
| `/api/user/likers` | ❌ |

### Bilinen bozuk / risk
| Sorun | Dosya | Risk |
|-------|-------|------|
| `fortuneTellerIncomingSessions` | `live_psychics_remote_datasource.dart` | Prod 405 |
| `socialPublicStats` deprecated | `platform_stats_remote_datasource.dart` | Prod drift |
| Gift admin `onError` tip | `admin_gift_management_page.dart` | Warning |
| `use_build_context_synchronously` | voice sheets | Info |

### Performans — hedefler karşılanmadı
- Cold start < 2s — ölçülmedi
- Oda < 1s — ölçülmedi
- 60 FPS garantisi — ölçülmedi

### QA — %100 değil
- 370 test geçti; **kapsam eksik** (E2E, perf, 1000 kullanıcı senkron testi yok)
- Acceptance test script (20 madde) bu oturumda çalıştırılmadı

### Build / release
- ❌ Release APK derlenmedi (kullanıcı talimatı)
- ❌ App Bundle yok
- 111 analyzer WARNING temizlenmedi

---

## 3. Bu oturumda yapılan düzeltmeler

| Tarih | Düzeltme |
|-------|----------|
| 2026-08-04 | `SongQueueService` + Prisma tabloları + SSE song events |
| 2026-08-04 | `RoomSongBloc` + IFrame mini player |
| 2026-08-04 | Hediye video gecikme + tam ekran + thumbnail |
| 2026-08-04 | CI: import path, `isVideo` sıra, `MusicLogAction` tipleri |
| 2026-08-04 | `FLUTTER_AUDIT.md`, `API_MAPPING.md` ve diğer raporlar |

---

## 4. Sonraki zorunlu adımlar (APK öncesi)

1. Müzik tek yol: IFrame-only; `youtube_explode` / `music-stream` kaldır
2. Agora + LiveKit modülü sil
3. `chat_room_providers` monolith böl
4. 5 eksik API endpoint bağla veya bilinçli olarak hariç tut
5. `fortuneTellerIncomingSessions` prod doğrula
6. 111 WARNING → 0
7. Acceptance + perf benchmark
8. **Ancak sonra** release APK/AAB
