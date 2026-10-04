# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.710+763` |
| Tarih (UTC) | 2026-10-04 17:42 |
| Commit | [`30b1fb3703a3e657dcbd409efc9d92da58799103`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/30b1fb3703a3e657dcbd409efc9d92da58799103) |
| İş akışı | [Run 37220277540](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37220277540) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.710+763 (2026-10-04) — Sesli oda mockup ekranı gerçekten açılıyor · canlı yayın misafir düzeltmeleri · Google girişi

- **Sesli oda:** uygulama şimdiye kadar mockup'a göre yazılan tam sayfa yerine eski sade sayfayı (`VoiceRoomBasicPage`) açıyordu; bu yüzden «olmamış» görünüyordu. Artık varsayılan **tam sayfa**: üst bar, 4 sütun koltuk ızgarası (oda sahibi büyük, «Koltuk Aç»), sağ düğmeler (Hediye · Müzik · PK · İstek · Daha Fazla), sohbet baloncukları ve alt dock (Açık · Kapalı · Konuş · Efektler · Oda Modu). Boş koltuk halkası mockup'taki gibi düz. Hediye hedefi çubuğu ve ilk destekçi rozeti tam sayfaya da eklendi. Eski sayfa için `--dart-define=VOICE_ROOM_BASIC_UI=true`
- **Canlı yayın misafiri:** misafir (kendi isteğiyle ya da yayıncı indirince) düşünce artık tekli görünüme dönüyor — düşen misafir ikili ızgarayı görmeye devam etmiyor, yayıncı da son misafir ayrılınca tekliye geçiyor
- **Yayıncı → misafir:** misafir yönetim listesinde **mikrofonu kapat/aç** ve **kamerayı kapat/aç**; sunucuya (`/api/live/guest` mute/camera) yazılır, misafir yayıncının kapattığını kendisi açamaz, yayıncı kaldırınca tekrar açabilir
- **Google ile giriş:** CI, eski `GOOGLE_SERVICES_JSON_BASE64` secret'ı ile depodaki güncel `google-services.json`'ı eziyordu (APK eski Web client ID ile derleniyordu). Depodaki dosya artık öncelikli; giriş başarısız olursa kullanılan Web client ID ekranda gösterilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
