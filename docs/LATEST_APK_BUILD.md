# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.259+262` |
| Tarih (UTC) | 2026-06-18 09:27 |
| Commit | [`a811bba43244a9dc1fe248e9b38cc14951eeca13`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a811bba43244a9dc1fe248e9b38cc14951eeca13) |
| İş akışı | [Run 27749367908](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27749367908) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.259+262 (2026-06-18)

### Canlı yayın — kamera ve durum düzeltmeleri

- **Kamera önizleme:** İzin / desteklenmeyen cihaz hataları artık ekranda gösterilir; «Kamera açılıyor…» yükleme durumu eklendi
- **Yanlış «yayında» durumu:** Yayın `preparing` ile oluşturulur; geri dönüş veya Agora hatasında sunucuda otomatik `end` çağrılır
- **Kamera aç/kapa:** Önizlemede `startPreview` / `stopPreview` kullanılır

### Canlı falcı — istek ve iptal

- **Yayıncıya istek:** Video yayın SSE üzerinden `fal_request` olayları; falcı poll 2 sn; aktif yayın odası SSE önceliği
- **İptal:** `declined` / `cancelled` durumları; iptal API başarısızsa kullanıcıya uyarı; bekleme ekranında yükleme durumu

### Jeton Al — WhatsApp

- **WhatsApp seçimi:** Yöntem ekranında WhatsApp seçilince sohbet otomatik açılır (jeton, kullanıcı adı, ödeme türü ile)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
