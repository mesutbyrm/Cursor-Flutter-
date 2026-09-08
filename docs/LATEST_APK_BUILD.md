# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.412+450` |
| Tarih (UTC) | 2026-09-08 23:39 |
| Commit | [`b71d013759c4b46f47eb407a913641982619367d`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b71d013759c4b46f47eb407a913641982619367d) |
| İş akışı | [Run 34290413041](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34290413041) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.412+450 (2026-09-08) — Profil + Admin/Yetkili sistem yenileme

### Normal profil
- Accordion kart düzeni: Bakiye & Üyelik, İstatistikler & Sosyal, Yayın & Sesli Oda, Ayarlar & Güvenlik
- Gereksiz tekrarlar azaltıldı; mobilde katman çakışması önlenir
- Hızlı erişim: güvenlik, bildirimler, profil düzenleme chip'leri

### Admin kontrol merkezi
- Yeni `/admin/dashboard` — site istatistikleri, jeton/CFC, bildirim, oda/yayın yönetimi
- `/admin/live-streams` — aktif yayın listesi (`GET /api/video-streams`)
- `/admin/voice-rooms` — aktif sesli odalar (`GET /api/chat/rooms`)

### Yetki sistemi
- `StaffAccess` granüler yetkiler: moderasyon, finans, oda, yayın, kullanıcı, rapor
- Yetkili profil kartı — moderatör/destek için rol bazlı menü (admin panelinden ayrı)
- `profile_screen_builder` `isStaff`/`isAdmin` düzeltmesi
- Moderasyon sayfası moderatör rolüne açıldı (backend 403 ile korunur)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
