# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.575+618` |
| Tarih (UTC) | 2026-09-19 21:48 |
| Commit | [`893b0e82e3000347382935d07a54e6b8581d6d30`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/893b0e82e3000347382935d07a54e6b8581d6d30) |
| İş akışı | [Run 35469957545](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35469957545) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.575+618 (2026-09-19) — Jeton talebi: admin banner → onay alanına yönlendirme

- **Jeton/CFC satın alma talebi admine anında banner olarak düşer:** uygulama içi banner artık ödeme-talebi bildirimlerini (`jeton_payment_request`/`cfc_payment_request`/`payment_request`) de gösteriyor; admin hangi ekranda olursa olsun üstten iner
- **Tıklayınca doğru alana gider:** banner artık kanonik `navigateFromNotification` yönlendirmesini kullanıyor → ödeme talebi admin için **`/admin?focusRequest={id}`** (AdminHubPage ilgili talebi vurgular); mesajlar sohbete, diğerleri kendi hedefine
- Onay→yükleme akışı zaten mobil admin panelinde mevcut: `admin_credit_sheet` jeton/CFC yükler, bekleyen ödemeler + onay/red mevcut. Banner bu akışı gerçek zamanlı tetikler
- **Sunucu tarafı (mobil dışı):** ödeme-talebi bildiriminin admine gönderilmesi, telefon kilitliyken **sesli push** (OneSignal kanal/ses) ve onayda bakiyenin **sunucuda** alıcıya işlenmesi canlifal.com tarafındadır; mobil istemci bildirimi gösterir, onay alanına götürür ve kredi ucunu çağırır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
