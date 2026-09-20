# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.581+624` |
| Tarih (UTC) | 2026-09-20 03:50 |
| Commit | [`e4b7f763b7b9fa3866e926eb638186b9bc5d6223`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/e4b7f763b7b9fa3866e926eb638186b9bc5d6223) |
| İş akışı | [Run 35486370417](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35486370417) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.581+624 (2026-09-20) — Profil: üyelik upsell + kurucu/admin onur şeridi

- **Gold/ücretli üyenin profilinde üyelik çağrısı:** ziyaretçi (kendisi değilse) ücretli üyeye (Gold/Diamond/SVIP) sahip bir profile girince "Sen de {tier} üye ol" kartı görünür → `/premium-membership`. Üyesiz profillerde ve kendi profilinde görünmez
- **Kurucu / Admin onur şeridi:** ziyaret edilen profilde ad altında gradient onur şeridi (👑 KURUCU / 🛡️ ADMİN) — kurucu>admin önceliği; ikisi de değilse görünmez
- Kaynak: mevcut `userProfileExtendedProvider(userId)` (vipLevel) + `StaffRoles` rol tespiti; yeni backend çağrısı yok
- Ziyaret profili düzeni: ad + onur şeridi → istatistik → aksiyonlar → Hakkında → Bilgiler kartı → **üyelik upsell** → Shorts → paylaşımlar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
