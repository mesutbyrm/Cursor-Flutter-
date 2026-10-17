# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.822+878` |
| Tarih (UTC) | 2026-10-17 16:48 |
| Commit | [`b8edccf50ad782b99ec4fa360c4935bb2256390a`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b8edccf50ad782b99ec4fa360c4935bb2256390a) |
| İş akışı | [Run 39049149545](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/39049149545) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.822+878 (2026-10-17) — Müzik istekleri: kontrol sonrası düzeltmeler

- **!istek açılır penceresi DJ'lere de gidiyor:** Sunucu, odadan çıkmış oda sahibini hâlâ «odada» sayıyordu; bu yüzden pencere DJ'lere hiç gitmiyordu. Artık yalnız gerçekten odada olanlar sayılıyor.
- **Kuyruk panelinden «Çal»:** Dosya seçildikten sonra şarkı hiç çalmıyordu; düzeltildi.
- **Jeton güvenliği:**
  - Dosya açılamazsa (desteklenmeyen biçim vb.) jeton kesilmiyor; istek beklemede kalıyor.
  - Uzun süre yanıtlanmayan istekler de iade ediliyor.
  - İade, istek durumuyla birlikte tek işlemde yapılıyor; yarıda kalıp kaybolmuyor.
- **DJ mikrofonu:**
  - Koltukta ama mikrofonu kapalı DJ de müziği yayına verebiliyor.
  - Müzik çalarken mikrofon kapatılınca müzik kesilmiyor.
  - Odadan çıkınca istek «çalıyor» olarak takılı kalmıyor.
- **Panelden istek kutusu:**
  - Şarkı başlayınca kutu hemen çıkıyor, bitince iki koltuk geri geliyor.
  - Kutuyu «Kapat»tan sonra gelen yeni şarkılar yine duyuluyor.
- **Fiyat ve hatalar:**
  - Videolu istek de 10 jeton olarak kontrol ediliyor; öne geçerken 20 jeton bakiyesi kontrol ediliyor.
  - «Yetersiz jeton» gibi hatalar artık «yetkiniz yok» diye gizlenmiyor.
  - Ücretsiz odalarda «10 jeton» yazmıyor.
- **Bulut dosyası:** Seçilen dosya açılamazsa (bulut dosyası) uyarı gösteriliyor.


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
