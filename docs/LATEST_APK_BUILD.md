# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.286+322` |
| Tarih (UTC) | 2026-08-19 21:46 |
| Commit | [`3c411a78d39d87c3d347becfb5b1858c22a78034`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/3c411a78d39d87c3d347becfb5b1858c22a78034) |
| İş akışı | [Run 32303849715](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/32303849715) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.286+322 (2026-08-19) — Push/bildirim oda geçişi presence

- **Push/PK bildirimi:** `/voice-room/*` yönlendirmeden önce `prepareVoiceRoomSwitch`
- **Bildirim listesi:** async teardown (`navigateFromNotificationAsync`)
- **Derin bağlantı:** `VoiceRoomGatedEntry` teardown bitene kadar yükleme

## 1.0.285+321 (2026-08-19) — PK daveti + oda geçişi düzeltmeleri

- **PK bildirimi:** `targetPath: /` artık `GoException` vermez → `/feed` veya PK/oda rotası
- **PK daveti:** Sesli oda + canlı yayın isteği UI donmasını azaltır; kabul/red microtask'e alındı
- **PK alıcı:** Davet poll sıklaştı; SSE + bildirim sinyali `VoicePkInviteListener`'ı uyandırır
- **Oda değişimi:** Eski odada presence/koltuk backend leave beklenir (oturma hatası)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
