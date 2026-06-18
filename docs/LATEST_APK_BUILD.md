# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.273+276` |
| Tarih (UTC) | 2026-06-18 22:05 |
| Commit | [`e7397a8149c5fc9ec1b7c5b1eab37eecfa522825`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e7397a8149c5fc9ec1b7c5b1eab37eecfa522825) |
| İş akışı | [Run 27791664735](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27791664735) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.273+276 (2026-06-18)

### Gerçek düzeltmeler — panel, kabul ekranı, tek bildirim

- **Push `targetId`:** Sunucu `type: fortune` + `targetId` gönderdiğinde artık oturum ID okunur; mor kabul ekranı açılır (önceden yalnızca bildirim geliyordu)
- **Erken push tamponu:** Oturum açılmadan gelen davetler kaybolmaz; `PushLifecycleListener` mount olunca kuyruğa alınır
- **Falcı panel poll:** Bekleyen oturumlar `fortuneIncomingInviteProvider` kuyruğuna eklenir (yalnızca `requestPresent` değil)
- **Onay algısı:** `my-profile` / `agency/my` `profile` sarmalayıcısı; ajans `isUsable` teller ile aynı mantık; router redirect önce API’yi bekler
- **Çift bildirim:** Falcı davet tıklamasında liste yenileme atlanır; push tamponu çift işlemeyi engeller


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
