# Site Animation — CDN asset pipeline

Production animasyonlar `https://cdn.canlifal.com/animations/` altında yayınlanır.

## Dizin yapısı

| Path | Açıklama | Örnek |
|------|----------|--------|
| `production/{id}.lottie` | DotLottie / Lottie üretim dosyası | `production/anim_entrance_gold_crown.lottie` |
| `production/{id}.riv` | Rive (gelecek) | `production/anim_entrance_diamond_burst.riv` |
| `preview/{id}.mp4` | Admin önizleme videosu | `preview/gold_uye_girisi.mp4` |
| `sounds/{id}.mp3` | Giriş/çıkış SFX | `sounds/anim_entrance_gold_crown.mp3` |

Mobil `SiteAnimationCdnAssets` bundle URL yoksa otomatik `production/{id}.lottie` dener.

## Admin panel

Animasyon editöründe **CDN doldur** chip'leri ilgili alanları bu path'lere göre doldurur (kayıt `id` gerekir).

## Flutter

- Asset önbellek: `SiteAnimationCache.preload`
- Ses: `SiteAnimationSoundPlayer` + `soundUrl` katalog alanı
- Native FX: CDN/Lottie başarısız olursa tier kartları devreye girer

## Yükleme (manuel)

1. Asset'i hazırla (`.lottie` önerilir, max ~360×110 panel)
2. `production/anim_<kategori>_<tier>.lottie` olarak CDN'e yükle
3. Admin → Site Animations → ilgili kayıt → Asset URL veya CDN doldur
4. Önizleme → Sesli Oda → tier chip ile WYSIWYG doğrula

GitHub Actions APK derlemesi asset yüklemez; yalnızca mobil kod + seed güncellenir.
