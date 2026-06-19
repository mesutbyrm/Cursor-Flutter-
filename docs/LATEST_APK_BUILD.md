# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.292+295` |
| Tarih (UTC) | 2026-06-19 14:38 |
| Commit | [`47208d301cd5c56e8025795583cce19547234b5d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/47208d301cd5c56e8025795583cce19547234b5d) |
| İş akışı | [Run 27831451986](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27831451986) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.292+295 (2026-06-19)

### Canlı falcı — web falcı + mobil danışan TRTC düzeltmesi

- **TRTC sahne:** `videoCall` yerine üretim web ile aynı `live` sahnesi — karşı taraf görüntüsü artık eşleşir
- **Oda kimliği:** `GET /api/room/{id}` → `roomId` / `trtcRoomId` öncelikli; usersig yanıtındaki oda kullanılır
- **Peer eşlemesi:** Danışan/falcı rolüne göre `peerId`, `tellerUserId`, `clientId` birleşimi (`remotePeerIdFor`)
- **İzin sonrası çıkış:** Oturum `SharedPreferences` ile kalıcı; izin diyaloğu / process restore sonrası seans ekranına dönüş
- **İzin ön isteği:** Reklam geçiş ekranında kamera/mikrofon izni (seans açılmadan önce)
- **Yaşam döngüsü:** Uygulama ön plana gelince bağlantı yeniden denenir; bekleme/geçiş/seans sırasında `resumeActiveSessions` çakışması engellendi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
