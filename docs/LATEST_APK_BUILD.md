# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.717+770` |
| Tarih (UTC) | 2026-10-05 19:40 |
| Commit | [`67f562b0e82f32677bf1a7279a0b52d549d27eae`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/67f562b0e82f32677bf1a7279a0b52d549d27eae) |
| İş akışı | [Run 37362541843](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37362541843) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.717+770 (2026-10-05) — Para çekme düzeltmesi + kesinti önizleme + ajans davetleri

- **Para çekme (hata düzeltmesi):** istek `details` gönderiyordu, sunucu `accountDetails` bekliyor → talep hep «Yöntem ve hesap bilgileri gerekli» ile reddediliyordu; tutar TL gidiyordu, sunucu JETON bekliyor. Artık jeton adedi + `accountDetails`
- **Kesinti önizleme:** `GET /api/withdrawals/quote` — «Toplam kazandığınız / Kesinti (%x) / Elinize geçecek tahmini tutar» sunucudan; bakiye ve minimum çekim jeton olarak
- **Ajans davetleri:** `GET/POST /api/agency/invites` — onayınız olmadan ajansa eklenmezsiniz; Davetlerim ekranı (`/ajans/davetler`), Kabul/Reddet


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
