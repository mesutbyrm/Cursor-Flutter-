# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.300+303` |
| Tarih (UTC) | 2026-06-19 21:06 |
| Commit | [`848899991875cad28b717cb40841d713531ea04e`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/848899991875cad28b717cb40841d713531ea04e) |
| İş akışı | [Run 27847982749](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27847982749) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.300+303 (2026-06-19)

### Canlı Falcılar — falcı kabul/red ekranı (kritik düzeltme)

- **Kırılan halka:** Push `type: psychic_request_created` mobilde tanınmıyordu → bildirim geliyor, kuyruk/dialog açılmıyordu
- **Push parse:** `psychic_request_created`, `request_created`, iç içe `request`/`session` gövdeleri
- **SSE:** Oturum açıkken profil onayı beklemeden `sessions/stream` bağlanır; `event:` satırı parse'a aktarılır
- **Poll:** Bekleyen istek kuyruğa eklenince `PsychicInviteCoordinator` ile dialog tetiklenir
- **Mount:** Push ile dolu kuyruk ilk frame'de de işlenir (listen ilk değerde ateşlenmez)
- **Falcı rolü:** `online`/`offline` başvuru durumu artık reddedilmiş sayılmaz


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
