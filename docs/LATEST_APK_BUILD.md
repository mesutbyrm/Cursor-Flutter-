# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.579+622` |
| Tarih (UTC) | 2026-09-20 03:30 |
| Commit | [`48d2d77a6b6c14983a248d4bd15e29c180bc293a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/48d2d77a6b6c14983a248d4bd15e29c180bc293a) |
| İş akışı | [Run 35485821186](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35485821186) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.581+624 (2026-09-20) — Profil: üyelik upsell + kurucu/admin onur şeridi

- **Gold/ücretli üyenin profilinde üyelik çağrısı:** ziyaretçi (kendisi değilse) ücretli üyeye (Gold/Diamond/SVIP) sahip bir profile girince "Sen de {tier} üye ol" kartı görünür → `/premium-membership`. Üyesiz profillerde ve kendi profilinde görünmez
- **Kurucu / Admin onur şeridi:** ziyaret edilen profilde ad altında gradient onur şeridi (👑 KURUCU / 🛡️ ADMİN) — kurucu>admin önceliği; ikisi de değilse görünmez
- Kaynak: mevcut `userProfileExtendedProvider(userId)` (vipLevel) + `StaffRoles` rol tespiti; yeni backend çağrısı yok
- Ziyaret profili düzeni: ad + onur şeridi → istatistik → aksiyonlar → Hakkında → Bilgiler kartı → **üyelik upsell** → Shorts → paylaşımlar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
