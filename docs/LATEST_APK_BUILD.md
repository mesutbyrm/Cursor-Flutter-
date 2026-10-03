# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.703+756` |
| Tarih (UTC) | 2026-10-03 19:28 |
| Commit | [`4bbae301d3582e6f91d4f436889583b29970f4e9`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/4bbae301d3582e6f91d4f436889583b29970f4e9) |
| İş akışı | [Run 37146849057](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37146849057) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.703+756 (2026-10-03) — Canlı yayın: kapatma, PK görüntüsü, hediye, beğeni, misafir; ana sayfada Ajans

- **Ana sayfa:** Keşfet · Sesli Oda · Tanış & Kaynaş · Gold yanına **Ajans** kutusu (5 kompakt kutu, metin küçülür/sığar). Onaylı ajansı olan «Ajansım» (`/ajans/dashboard`), olmayan «Ajans Ol» görür → yeni başvuru ekranı (`POST /api/agency/apply`, admin onayına düşer)
- **Canlı yayın kapatma:** çıkış, takılı kalan `_leaving` durumunda kilitlenmez (6 sn koruması, ön temizlik hataları yutulur); sunucuda yayını bitirme 3 kez denenir ve PATCH başarısızsa `/end` yedeği her hatada (401/403 hariç) denenir
- **PK görüntüsü:** canlı yayın PK'sında iki yayın ayrı TRTC odasında olduğundan karşı tarafın videosu gelmiyordu (yalnız sesli oda PK'sı cross-room kuruyordu). Challenger host artık PK aktifken karşı odayı `connectOtherRoom` ile arar, PK bitince `disconnectOtherRoom`; iki yayının izleyicileri iki tarafı da görür. Kök neden cihazda doğrulanamadı
- **Hediyeler:** hareketli (lottie/svga/rive/video) hediyeler canlı yayında ve PK'da **tam ekran** oynar (PK sahnesi altında görünür); PK'da animasyon artık video bölgesine kırpılmaz
- **Beğeni:** kalbin altındaki sayı/«Sen: n» ve sol alttaki «kim kaç beğeni yaptı» çipi kaldırıldı; beğeni sayısı yalnızca üst profilde ve **her dokunuşta anında** artar. Kalp tek dokunuşla da beğenir. PK'da beğeni puanı ekranda **anında** artar (sunucu mutlak skoru gelince esas alınır)
- **Misafir:** misafirken alt düğme **«Düş»** olur (`/api/live/guest` leave + TRTC izleyiciye dönüş); yayıncı misafir varken düğmeyle **«Misafirler»** listesini açıp **İndir** diyebilir, ızgara karesinde de «indir» düğmesi var (`kick`); son misafir inince yayıncı otomatik tekliye geçer
- Testler: PK yerel skor, «Düş» etiketi, ana sayfa Ajans kutusu (dar ekran)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
