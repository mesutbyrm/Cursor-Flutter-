# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.642+693` |
| Tarih (UTC) | 2026-09-29 19:21 |
| Commit | [`0ae2f22191685661eef12d9328a6c3b81ffc0874`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/0ae2f22191685661eef12d9328a6c3b81ffc0874) |
| İş akışı | [Run 36614610876](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36614610876) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.644+695 (2026-09-29) — PK battle poll hafifletme

- **Canlı PK davet poll:** yayın odasında SSE varken `fetchStreamBattle` yedek atlanır; davet poll hafif mod (`finalizeExpired: false`, 6 sn önbellek)
- **Sesli PK poll:** SSE defer yalnızca diğer sahip odalar turunu atlar; aktif oda + `/pk/me/invites` sürer (sinyalde `force`)
- **Oda PK GET:** 6 sn poll önbelleği; aktif `loadRoomBattle` / davet hazırlığı `forceRefresh`
- **`invalidatePkPollCaches`** — PK aksiyonlarında oda/yayın/davet poll önbelleği temizlenir
- Backend değişikliği yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
