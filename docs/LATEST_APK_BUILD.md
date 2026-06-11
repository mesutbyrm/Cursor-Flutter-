# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.186+188` |
| Tarih (UTC) | 2026-06-11 10:53 |
| Commit | [`04aad93a6defc0c7e1d1c5d9951846150c8e93b2`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/04aad93a6defc0c7e1d1c5d9951846150c8e93b2) |
| İş akışı | [Run 27338858550](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27338858550) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.186+188 (2026-06-10)

### Sesli oda müzik — web görünümü + hızlı oynatma

- Tek kompakt **web müzik şeridi** (`VoiceRoomWebMusicBar`): dalga + «Şu an çalıyor» + turuncu pause + mor ses + kırmızı X
- Oda içinde çift mini player kaldırıldı; global bar sesli odada kesinlikle gizlenir
- googlevideo **stream-first** (Referer başlıkları); başarısızsa yerel indirme yedeği
- `!istek` sonrası anında `_playDjInBackground`; sunucu `musicUrl` prefetch
- Müzik aktifken poll 5s; presence heartbeat 20s (web/app kullanıcıları daha hızlı görünür)
- Çalarken inline kuyruk listesi gizlenir (web gibi)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
