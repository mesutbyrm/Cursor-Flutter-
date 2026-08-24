# Tencent RTC — singleton ve imha denetimi

## Motor örnekleri

| Provider / sınıf | Kapsam | `dispose` |
|------------------|--------|-----------|
| `trtcRoomManagerProvider` | Canlı yayın / falcı video (paylaşımlı) | `ref.onDispose` → `TrtcRoomManager.dispose()` |
| `VoiceTrtcEngine` (sesli oda) | Oda başına `VoiceRoomAudioCoordinator` | `coord.dispose()` → `leave()` + engine dispose |
| `TrtcLiveRoomCoordinator` | Yayın odası sayfası | `dispose()` → `leave()` |

**Kural:** Aynı anda iki `TRTCCloud.sharedInstance()` oturumu açık olmamalı. Sesli oda sayfasından canlı yayına geçerken önce `VoiceRoomAudioCoordinator.leave()` tamamlanmalı.

## Sesli oda müzik (TRTC karışım)

- Yerel senkron: `RoomSongBloc` + IFrame mini player.
- Uzak dinleyiciler için: `VoiceRoomTrtcMusicMixer` → `TXAudioEffectManager.startPlayMusic(publish: true)` yalnızca **mikrofon yayıncısı** (koltukta / DJ) için.

## Kontrol listesi

- [ ] Route `pop` → ilgili coordinator `leave()` çağrıldı mı?
- [ ] `TrtcRoomManager.inRoom == false` sonra yeni `join`?
- [ ] Arka plana geçişte psychic: `onAppResumed()` / voice: mic durumu senkron?
- [ ] Bellek: uzun oturum sonrası `VoiceRoomDebugLog` + `LiveDebugLog` psychic raporu

## Tanılama

- Sesli oda: `voiceRoomDiagnosticProvider`
- Falcı 1:1: `PsychicRtcSessionReport.dump()` (`psychic_rtc_session_report.dart`)
