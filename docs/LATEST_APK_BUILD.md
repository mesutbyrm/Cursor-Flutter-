# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.570+613` |
| Tarih (UTC) | 2026-09-19 17:16 |
| Commit | [`43932bb68351169cb84010c7a54a75ca2f85f277`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/43932bb68351169cb84010c7a54a75ca2f85f277) |
| İş akışı | [Run 35455726744](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35455726744) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.570+613 (2026-09-19) — Canlı falcı: T+5s uzak render takılması yedeği (C1)

- **T+5s donması için güvenli istemci yedeği:** falcı 1:1 görüşmesinde karşı taraf odaya girdiği hâlde uzak video hâlâ gelmiyorsa, **odadan çıkış / yeniden giriş YAPMADAN** uzak view en fazla iki kez yeniden abone ediliyor (`resubscribeRemoteView`) — donmuş yüzey yeniden bağlanıyor
- Watchdog yalnızca `live_psychics` oturumunda çalışır; uzak video görülünce/ayrılışta durur; alias-drift yeniden giriş bug'ını (1.0.371'de düzeltildi) geri getirmez
- Kök neden (SSE/oda `roomId` alias'ında yeniden giriş) zaten kapalı; bu ekleme render takılmasına karşı ek emniyet — **P0 kapanışı için iki cihazda `Psychic P0 PASS` doğrulaması gerekir**
- Unit: `psychic_trtc_freeze_test` (+5 vaka: yeniden abone kararı, cap, reconnect/leave/dispose koruması)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
