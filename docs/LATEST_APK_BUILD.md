# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.625+676` |
| Tarih (UTC) | 2026-09-28 19:30 |
| Commit | [`b0570cf0bcddca0d42292a62a79df912a9337b77`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b0570cf0bcddca0d42292a62a79df912a9337b77) |
| İş akışı | [Run 36470346529](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36470346529) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.624+675 (2026-09-28) — Kalan backend eksikleri bağlandı

- **Şikayet et** artık çalışıyor: tüm şikayetler backend'de olmayan bir uca gidiyordu → kullanıcı / içerik sahibi `POST /api/user/report`, sesli oda `/api/chat/rooms/{id}/report`
- **Kısa videoya hediye** artık çalışıyor: video sahibine `POST /api/gifts/send`; bakiye yetersizse sunucu mesajı gösterilir
- **Kozmetik:** mikrofon çerçevesi, sohbet balonu, isim efekti, giriş efekti ve avatar aksesuarı seçimleri sunucuya kaydediliyor ve sunucu kataloğu listeleniyor (önceden yalnız cihazda)
- **Haftalık yayıncı yarışması:** CFC Arena'daki aktif yayıncı yarışmasından sıralama
- **Ajans talepleri:** bekleyen çıkış talepleri listeleniyor, onay/ret çalışıyor
- **Oyunlar:** oyun sonu skoru `POST /api/games/play` ile kaydediliyor
- **Kısa video:** analitik gerçek sayaçlardan; etiket sayfası keşfet aramasından; oynatıcı artık önce ölü bir adresi denemiyor (daha hızlı açılış)
- **Yönetici:** kullanıcı 360 sekmeleri (genel, aktivite, ajans, kazanç/harcama, moderasyon, şikayetler) gerçek veriye bağlandı; **sahte "StarCraft Ajansı" / uydurma uyarı ve şikayet kayıtları kaldırıldı**; PK yasağı `canPK` alanından; moderasyon kuyruğu web panele yönlendiriyor
- **Temizlik:** 172 kullanılmayan uç sabiti ve ölü yedek istekler kaldırıldı; `backend-route-parity.py` → 0 eksik


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
