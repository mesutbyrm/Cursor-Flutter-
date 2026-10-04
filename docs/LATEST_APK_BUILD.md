# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.706+759` |
| Tarih (UTC) | 2026-10-04 00:41 |
| Commit | [`d2fde7ce9de2105f63eab3ec85a45bfbafcd9dcd`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d2fde7ce9de2105f63eab3ec85a45bfbafcd9dcd) |
| İş akışı | [Run 37164664377](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37164664377) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.706+759 (2026-10-03) — Fal: reklam bulunamazsa «Reklam tamamlanmadan fal açılamaz» ile engellenmez

- **Hata:** gösterilecek reklam hiç yüklenemediğinde (yeni birimin envanteri henüz dolmamış, ağ/AdMob hatası) fal «Reklam tamamlanmadan fal açılamaz» diyerek açılmıyordu; kullanıcı reklamı reddetmemiş olduğu halde engelleniyordu
- **Düzeltme:** `RewardedAdService.lastShowUnavailable` ile «reklam yok» ile «reklam yarıda kapatıldı» ayrıldı. Reklam bulunamazsa fal **açılır** («Şu an reklam bulunamadı; falın açılıyor.»), ödül/kutlama gösterilmez. Reklam yarıda kapatılırsa eski davranış (fal açılmaz) sürer
- Not: yeni AdMob biriminin reklam göstermeye başlaması 1 saate kadar sürebilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
