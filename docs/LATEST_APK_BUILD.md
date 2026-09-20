# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.576+619` |
| Tarih (UTC) | 2026-09-20 03:08 |
| Commit | [`ea8152ccea0696491271c63f42e69f58c7290128`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ea8152ccea0696491271c63f42e69f58c7290128) |
| İş akışı | [Run 35484972266](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35484972266) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.580+623 (2026-09-20) — Ziyaret profili zenginleştirme

- **Ziyaret edilen profile "Bilgiler" kartı eklendi:** başka kullanıcının profilinde artık **çevrimiçi durumu, şehir, burç, favori takım, VIP seviye, günlük seri, katılma tarihi** çip/rozet olarak zengin şekilde gösteriliyor (veri varsa; hiç yoksa kart görünmez)
- Kaynak: mevcut `userProfileExtendedProvider(userId)` (per-user, doğrulanmış); yeni backend çağrısı yok
- Ziyaret profili artık: avatar/kapak + doğrulama/üyelik rozeti + istatistik + Takip/Canlı/Mesaj + Hakkında + **Bilgiler kartı** + Shorts sekmeleri + paylaşım akışı
- Not: seviye/aldığı-gönderdiği hediye/rozet listeleri şu an yalnızca kendi profilinde (self-only provider); başkası için bunlar backend'de per-user uç gerektirir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
