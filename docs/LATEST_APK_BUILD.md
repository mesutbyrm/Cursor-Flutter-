# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.357+395` |
| Tarih (UTC) | 2026-08-24 21:35 |
| Commit | [`01ec8e1b`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/01ec8e1b) |
| İş akışı | [Run 32779034964](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32779034964) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.357+395 (2026-08-24) — Müzik arama sheet geçişi

- **Müzik arama:** Şarkı seçiminden sonra mod seçici sheet'i 150ms gecikmeyle açılır (üst üste sheet animasyonu ANR riski azalır)

## 1.0.356+394 (2026-08-24) — Müzik isteği ANR düzeltmesi

- **Müzik isteği:** Sheet kapanışından sonra 320ms gecikmeli gönderim; aynı frame'de provider/WebView güncellemesi engellendi
- **Flash mesajları:** İstek durumu (⏳/✅) artık yalnızca üst banner'da — sohbet listesine çift sistem satırı eklenmez
- **WebView:** Ses modu oynatıcı başlatma 280ms gecikmeli (soğuk başlangıç ANR önleme)
- **SnackBar:** Kuyruğa ekleme vs çalmaya başlama mesajı doğru gösterilir

_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
