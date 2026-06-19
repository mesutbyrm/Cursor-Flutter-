# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.293+296` |
| Tarih (UTC) | 2026-06-19 15:44 |
| Commit | [`24abf0697c8e884b89124606e529d106e6885d35`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/24abf0697c8e884b89124606e529d106e6885d35) |
| İş akışı | [Run 27834738437](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27834738437) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.293+296 (2026-06-19)

### Canlı Falcılar — sıfırdan yeniden yazım (`live_psychics`)

- **Yeni mimari:** `lib/features/live_psychics/` — domain / data / presentation (Riverpod, setState yok)
- **Liste:** Çevrimiçi falcılar, pull-to-refresh, infinite scroll
- **Profil & randevu:** Fotoğraf, uzmanlık, puan, online durumu, fal türü + süre seçimi
- **SSE:** Falcı gelen çağrı + oda güncellemeleri (web ile aynı uçlar)
- **Durumlar:** Bekliyor / Kabul / Red / Süre doldu
- **Falcı paneli:** Bekleyen çağrılar, çevrimiçi anahtarı, kabul/red
- **Tam ekran gelen çağrı popup'ı** + video görüşme (TRTC `live` sahnesi)
- **Hata / boş / offline:** Async view bileşenleri, retry, loading state
- **Eski modül kaldırıldı:** `home/live_fortune_*` dosyaları silindi; router, shell, push, ana sayfa yeni modüle bağlandı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
