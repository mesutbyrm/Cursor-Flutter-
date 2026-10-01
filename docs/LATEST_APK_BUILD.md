# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.678+731` |
| Tarih (UTC) | 2026-10-01 21:51 |
| Commit | [`8b169aee46b2d13e2e4b70be68526150aecfca27`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8b169aee46b2d13e2e4b70be68526150aecfca27) |
| İş akışı | [Run 36927563088](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36927563088) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.678+731 (2026-10-01) — Sesli oda PK modu (kompakt panel, tek sunucu sayacı)

- **PK artık odada geçici bir mod:** koltukların üstünde kompakt neon cam panel (ekranın ~%30'u); ayrı tam ekran sayfa açılmaz, PK bitince oda eski haline döner
- **Takım ızgarası 1x1–4x4:** avatar boyutu oyuncu sayısına göre dinamik; PK oyuncuları konuşmaya devam eder (mikrofon düğmesi)
- **Tek merkezi sayaç:** `PkRoomController` — sunucu `endsAt` + `serverNow` ofseti; widget rebuild / hediye / sohbet / SSE / mikrofon sayacı sıfırlamaz; süre bitince iki cihazda aynı anda otomatik biter
- **Hediye ≠ PK daveti:** SSE olayları tipine göre yönlendirilir; skor (status'suz PK_SCORE) artık davet açmaz ve sayaç/skor durumunu bozmaz
- **Hediye gösterimi:** gönderen, hediye, miktar; ~5 sn, fade, son 3'lük kuyruk; skor yalnızca sunucudan
- **Karşı takımı sustur:** yalnızca bu cihazın TRTC oynatmasını kapatır (backend mute yok)
- **PK Bitir:** anında (iyimser), hata olursa geri alınır; sohbet girişi 💬'a basılana dek gizli
- **Yeniden bağlanma:** sunucudan güncel PK okunur (sunucu durumu kazanır, sayaç yeniden başlamaz)
- Backend değişmedi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
