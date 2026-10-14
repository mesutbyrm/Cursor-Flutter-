# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.788+844` |
| Tarih (UTC) | 2026-10-14 21:27 |
| Commit | [`482ded86e2aeb0660bcb6ed187b7b8a40eec8c90`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/482ded86e2aeb0660bcb6ed187b7b8a40eec8c90) |
| İş akışı | [Run 38637028121](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/38637028121) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.788+844 (2026-10-14) — Çoklu hesap (en fazla 5)

- **Hesap değiştirici:** profilde `@kullanıcı_adı ▾` — dokununca kayıtlı hesaplar, tek dokunuşla geçiş, «Hesap ekle», «Hesapları yönet»
- **Hesap ekle:** oturum açıkken yeni hesap (`/auth/add-account`; e-posta/kullanıcı adı, Google, Apple); mevcut hesap açık kalır; aktif dahil **en fazla 5 hesap**
- **Kayıtlı hesaplar kaydedilmiyordu (düzeltme):** `SavedAccountsStore` JSON yazımı `toJson` çağırmadan fonksiyon referansı kodluyordu; liste hiç kalıcı olmuyordu
- **Hesap geçişi güvenliği:** hedef hesabın oturumu sona ermişse önceki hesap geri yüklenir (ekranda bir hesap, istekte diğerinin token'ı kalmaz) ve hesap listeden çıkar
- **Başarısız ek giriş:** mevcut oturumu düşürmez (önceden `AsyncError` ile oturum kapanmış görünüyordu)
- **Çıkış:** çıkılan hesap listeden kaldırılır; kullanıcı çıkışında varsa sıradaki kayıtlı hesaba geçilir (oturum süresi dolunca geçilmez)
- **Tüm cihazlardan çıkış (düzeltme):** güvenlik sayfasındaki buton yalnız yerel çıkış yapıyordu; cihazlar sayfası ise token silip oturum durumunu güncellemiyordu — ikisi de `logoutAllDevices` ile düzeltildi
- **Çıkış sonrası rota (düzeltme):** olmayan `/auth/login` yerine `/feed`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
