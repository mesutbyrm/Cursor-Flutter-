# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.245+248` |
| Tarih (UTC) | 2026-06-17 14:23 |
| Commit | [`3fb6fcbf69446e706de726a9707e4bba1cca303a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3fb6fcbf69446e706de726a9707e4bba1cca303a) |
| İş akışı | [Run 27695292152](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27695292152) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.245+248 (2026-06-12)

### Sesli oda performans + otomatik koltuk

- **Sohbet:** `ChatMessageWidget`, `GiftWidget`, `UserAvatarWidget`; `RepaintBoundary`; `ShaderMask` ve müzik satırı animasyonları kaldırıldı
- **Mesajlar:** SSE ile tek tek ekleme korundu; poll aralığı SSE açıkken 30 sn
- **Otomatik koltuk:** Owner/admin/mod/DJ odaya girince `POST join-seat` (yedek `seats`); öncelik Owner > Admin > Moderator > DJ
- **Yetki:** RTC sayfasında `serverPermissions` ile `VoiceRoomPermissions` düzeltmesi
- **Oda listesi:** `AutomaticKeepAliveClientMixin`; ana sayfa / canlı sekme 30 sn yenileme
- **Avatar:** `CachedNetworkImage` max 128×128 önbellek
- **Android:** `hardwareAccelerated` + Impeller meta-data

### Canlı Falcılar — görüşme

- **TRTC:** Kabul sonrası oturum durumundan `trtcRoomId` alınır
- **Çıkış:** Seans bitişinde sunucuya `end`/`leave` bildirimi; WebRTC sinyal durdurulur
- **Sohbet:** Daha yüksek panel, `RepaintBoundary`, blur azaltıldı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
