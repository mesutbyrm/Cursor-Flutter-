# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.260+263` |
| Tarih (UTC) | 2026-06-18 10:52 |
| Commit | [`f6753087671546eb5c5eebf69d0e645584dfec1d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/f6753087671546eb5c5eebf69d0e645584dfec1d) |
| İş akışı | [Run 27753875430](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27753875430) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.260+263 (2026-06-18)

### Canlı falcı — istek mobilde gelmiyor / iptal takılıyor

- **`/api/live-fal/pending`:** Sunucu tarafı filtrelenmiş istekler artık mobilde yanlışlıkla elenmiyor
- **Davet popup:** Diyalog dışına tıklanınca istek kalıcı olarak silinmiyor; tekrar gösteriliyor
- **İptal:** Onaydan önce «İptal ediliyor…» gösterilmiyor; API zaman aşımı (12 sn) eklendi
- **Falcı çevrimiçi:** Profil bulununca `toggle-online` her oturumda yeniden deneniyor

### Canlı yayın

- Yayın oluşturma `status: live` (üretim API uyumu); orphan temizliği korunuyor

### Jeton — Papara / IBAN

- **Tek dokunuş:** Papara ve havalede «Ödemeyi Bildir» doğrudan admin talebi gönderir
- **Bekleyen talep:** Aynı kullanıcıda önceki bekleyen talep varsa net hata mesajı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
