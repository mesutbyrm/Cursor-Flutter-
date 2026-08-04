# CanliFal — Fixes Done & Remaining

**Date:** 2026-08-04  
**Branch:** `cursor/backend-flutter-sync-df6c`  
**Sürüm:** `1.0.128+162`

---

## 1. ÇALIŞAN (doğrulanmış)

### Auth
- ✅ Mobil JWT login/register, refresh, secure storage

### Sesli odalar
- ✅ TRTC join/leave/mute (tek ses motoru)
- ✅ SSE presence, mesaj, hediye, koltuk, moderasyon
- ✅ `lockSeat` / `kickFromSeat` API (kılavuz §9.3)

### Canlı yayın
- ✅ `TrtcLiveRoomCoordinator` — heartbeat + TRTC reconnect
- ✅ Moderasyon unmute / unban UI

### Müzik
- ✅ `RoomSongBloc` + IFrame tek yol

### Hediyeler
- ✅ Backend `durationMs` tam süre animasyon

### Sosyal
- ✅ `fetchPost` + `postDetailProvider`

### RTC temizlik
- ✅ `flutter_webrtc` kaldırıldı
- ✅ `agoraToken` / `livekitToken` sabitleri silindi

### CI / test
- ✅ Flutter test: **366** geçti

---

## 2. KALAN (APK öncesi)

| Madde | Durum |
|-------|--------|
| Stories backend + Flutter UI | ❌ Stub |
| Shorts explore/hashtag (üretim doğrulama) | 🟡 |
| Sosyal tek post detay sayfası UI | 🟡 API hazır |
| Voice lock/kick koltuk UI | 🟡 API hazır |
| `chat_room_providers.dart` tam bölme | 🟡 |
| Performans profili | 🟡 |

Detay: `docs/BACKEND_FLUTTER_SYNC_REPORT.md`

---

## 3. Önceki oturum (1.0.127+161)

1. ✅ Müzik IFrame-only  
2. ✅ Agora/LiveKit kaldır  
3. ✅ `chat_room_providers_dj_sync` mixin  
4. ✅ 5 eksik API endpoint  
5. ✅ Acceptance + APK (main)

---

## 4. APK

- **İndir:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
- **CI:** https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml
- **Detay:** `docs/LATEST_APK_BUILD.md`
