# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.185+187` |
| Tarih (UTC) | 2026-06-11 09:28 |
| Commit | [`075c8f04678080b18d6feea670788996521a03ac`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/075c8f04678080b18d6feea670788996521a03ac) |
| İş akışı | [Run 27336045353](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27336045353) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.185+187 (2026-06-10)

### Müzik oynatma — ses + çift player + X kapat

- **Çift mini player:** Sesli odadayken global çubuk artık route değişiminde gizlenir (`ListenableBuilder`)
- **X kapat:** `dismissed` bayrağı sunucu senkronunda sıfırlanmaz; oda içi player gizlenir; yeni şarkıda otomatik açılır
- **Sessiz oynatma:** `AudioSession` `gain` + `mixWithOthers` (TRTC altında duck kaldırıldı)
- **play() doğrulama:** `waitUntilPlaying` — yalnızca `hasLoadedSource` ile başarı sayılmaz
- **Loglar:** `player.state`, `playbackEventStream` hataları, `play_not_started` teşhisi
- **Debug satırı:** Mini player altında gerçek stream URL + processing state + hata özeti


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
