# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.126+128` |
| Tarih (UTC) | 2026-06-04 19:21 |
| Commit | [`3828353d5413f91b952f4bc67360fefbee33a51c`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3828353d5413f91b952f4bc67360fefbee33a51c) |
| İş akışı | [Run 26972975676](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26972975676) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.126+128 (2026-05-19)

### Canlı yayın ve hediye

- Yayın oluşturma: esnek `streamId` ayrıştırma, `live-started` uç sabiti, `[Live]` debug logları
- TRTC: `{ success, data }` sarmalayıcı, `sdkAppId`/`userSig` doğrulama
- Prep: kamera/mikrofon izni önce; `useMobileAuth` ile `POST /api/video-streams`
- Hediye: `senderName` / `receiverName` gönderimi; poll 4 sn
- Analiz: `docs/LIVE_STREAM_FLUTTER_ANALYSIS.md`

### Hata düzeltmeleri (sesli oda / API)

- **Müzik araması:** Popüler şarkılara `videoId` eklendi; Piped/Invidious kapalıyken de sonuç döner (ör. Müslüm Gürses)
- YouTube arama: önce JWT ile `/api/youtube/search`; 401’de net oturum mesajı
- Oda komutları UI: `/` → `!` (sunucu ile uyumlu)
- API: `prisma generate` postinstall; `/api/youtube/search` optionalAuth


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
