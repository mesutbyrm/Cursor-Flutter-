# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.183+185` |
| Tarih (UTC) | 2026-06-10 18:35 |
| Commit | [`0410ca5ccf4e78174412dc534f0c22b28953076e`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/0410ca5ccf4e78174412dc534f0c22b28953076e) |
| İş akışı | [Run 27296494363](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27296494363) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.183+185 (2026-06-10)

### Sesli oda müzik oynatıcı — tam medya kontrolü

- Yığın: `just_audio` + `audio_service` (bildirim çubuğu / kilit ekranı medya kontrolleri)
- Mini player: Oynat, Duraklat, Durdur, Önceki (başa sar), Sonraki, Ses aç/kapat, Kapat (X)
- Android bildiriminde önceki / oynat-duraklat / sonraki / durdur kontrolleri
- Odadan çıkınca müzik durmaz; global mini player diğer sayfalarda görünür
- Mini player kapatılınca `player.stop()` + oturum temizliği
- Uygulama kapanınca `audio_service` temizlenir
- Sessize alma artık akışı öldürmez (ses seviyesi 0); ses açılınca devam eder
- DJ `updateDj` / kuyruk uçlarında `alternateKey` (slug) yedeklenir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
