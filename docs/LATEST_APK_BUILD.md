# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.294+297` |
| Tarih (UTC) | 2026-06-19 16:49 |
| Commit | [`89b083ccd0712a6284a9900dd8d4ba6752bb7f32`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/89b083ccd0712a6284a9900dd8d4ba6752bb7f32) |
| İş akışı | [Run 27837679119](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27837679119) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.294+297 (2026-06-19)

### Canlı Falcılar — falcı kabul/red ekranı düzeltmesi

- **Push → dialog:** `PsychicInviteCoordinator` ile bildirim/SSE sonrası mor kabul ekranı zorla açılır
- **Falcı algısı:** `isUsable` + `my-profile` / liste yedekleri; SSE artık onaylı profil beklenmeden bağlanır
- **Poll/SSE ayrımı:** Arka plan senkronu auth yüklenirken de çalışır; dialog yalnızca uygun rotada gösterilir
- **SSE parse:** İç içe `request` / `session` gövdeleri `parsePsychicSsePayload` ile okunur
- **Gelen istek filtresi:** Teller alanı boş API yanıtları artık düşürülmez
- **VideoCall köprüsü:** Çift UI engellendi — canlı fal davetleri yalnızca `PsychicIncomingCallDialog`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
