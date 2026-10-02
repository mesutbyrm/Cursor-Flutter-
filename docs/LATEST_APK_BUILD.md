# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.697+750` |
| Tarih (UTC) | 2026-10-02 21:39 |
| Commit | [`10666058064655c3b65c25a947f0ea29d3d3a438`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/10666058064655c3b65c25a947f0ea29d3d3a438) |
| İş akışı | [Run 37065990750](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37065990750) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.697+750 (2026-10-02) — Falcı gecikmesi, canlı yayın senkronu, ayarlar kutucukları

- **Falcı isteği:** sunucu istek olayını artık bildirim/push'u BEKLEMEDEN yayınlıyor (uygulamanın kullandığı `/{tellerId}/session` yolunda hiç yayınlanmıyordu → istek yalnızca yoklamayla/15 sn yedekle ulaşıyordu); DB yedeği 6 sn; kabul yanıtı push'u beklemiyor. İstemci: sunucunun süresiz tuttuğu bayat bekleyen talepler (>175 sn) yeni talebin önüne geçmiyor, en yeni talep önce gösteriliyor; seçilen süre (`maxMinutes`) artık sunucuca da okunuyor
- **Canlı yayın beğeni:** beğeni artık yayındaki herkese SSE ile anında yayılıyor (eskiden yalnızca DB sayacı artıyordu; başkaları kendileri beğenene dek görmüyordu). Başkasının beğenisi yerel toplamdan bağımsız olarak ekleniyor, kendi beğeni yankısı çift sayılmıyor
- **Hediye / PK puanı:** PK skoru ve hediye motoru para akışından hemen sonra paralel çalışıyor; skor olayı ledger yazımlarından ÖNCE yayınlanıyor; hediye yanıtındaki skor gönderen ekranına anında uygulanıyor
- **Misafir (çoklu yayın):** 2 kişi düzeni yan yana; son misafir ayrılınca/indirilince çoklu mod kapanıp tekli yayına otomatik dönülüyor (yayıncı ve izleyicide)
- **Ayarlar:** ayarlar ana sayfası ve bağlı ekranlar (bildirim, ses, cihazlar, hesap güvenliği, yardım, hakkımızda, VIP gizlilik) ortak kutucuk bileşenleriyle yeniden tasarlandı (`core/widgets/settings_kit.dart`)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
