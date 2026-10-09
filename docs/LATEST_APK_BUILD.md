# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.747+800` |
| Tarih (UTC) | 2026-10-09 10:33 |
| Commit | [`091ba0d93ba38296802839dc22fe08df3a8cfe94`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/091ba0d93ba38296802839dc22fe08df3a8cfe94) |
| İş akışı | [Run 37916364756](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37916364756) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.747+800 (2026-10-09) — Sesli oda → Ana sayfa: presence temizlenmiyordu

- **Kök neden (log + kod):** Kapatma tuşu → `leaveWithSummary` içinde `leaveRoomSession` öncesi atılan istisna (hediye özeti) dış `catch`'e düşüyor, `leaveRoomSession` hiç çağrılmadan sayfadan çıkılıyordu (cihaz logunda `LEAVE_START` yok); sayfa dispose'u `_leaveSessionStarted` yüzünden leave'i atlıyordu
- **Düzeltme:** Özet hatası yutulur (`LEAVE_SUMMARY_SKIPPED`); sunucu leave her durumda çalışır; hata `LEAVE_FAILED` ile loglanır; `LEAVE_UI` tıklama logu
- **Route guard:** Gezinmeyi gerçekten dinliyor (önce hiç tetiklenmiyordu); yığında oda sayfası varsa (profil push) çıkmaz; `WidgetRef as Ref` çalışma anı hatası kaldırıldı; `force:false` ile devam eden leave'e katılır (çift leave yok) — `ROUTE_LEFT_VOICE_ROOM`
- **Test:** Room → Home, Room A → Room B, oda üstüne push, UI leave sonrası çift leave yok


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
