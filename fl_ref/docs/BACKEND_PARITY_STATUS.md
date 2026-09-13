# Backend parite durumu (telefon / terminal gerekmez)

**Durum: TAMAMLANDI** — `extra_main.json` içindeki **98** Flutter ana-backend yolu için `backend-parity/nextjs_space` altında `route.ts` eşleşmesi **tamam** (`EKSİK: 0`).

**Son doğrulama:** Cloud Agent workspace (`check-extra-main-api-routes.py`). CI: workflow `backend-parity-check.yml`.

## Bu repoda nerede?

| Ne | Konum |
|----|--------|
| Hazır API paketi | `backend-parity/nextjs_space/app/api/**` |
| Yardımcı lib | `backend-parity/nextjs_space/lib/*` |
| Re-export haritası | `fl_ref/reexport_map.json` |
| Faz notları | `fl_ref/docs/FAZ1_PROGRESS.md` … `FAZ4_PROGRESS.md` |
| Otomatik kontrol | `scripts/check-extra-main-api-routes.py` |

Bu **Cursor-Flutter** deposunda üretim `fortune_telling_platform/nextjs_space` ağacı yok; parite dosyaları burada paketlenmiş durumda.

## Sizin telefon üzerinden yapmanız gereken

- **Zorunlu terminal komutu yok.** Parite paketi repoda hazır.
- İsterseniz GitHub uygulamasından `main` dalındaki son commit’leri kontrol edebilirsiniz (push Cloud Agent / sizin kimlik doğrulamanızla yapılır).
- Canlı **canlifal.com** API’sine dosyaların geçmesi, **ayrı Next.js backend deposuna** merge/deploy ile olur; bu adımı buradan telefonla yapmanız gerekmez.

## Cloud Agent / geliştirici ortamının yaptığı

1. `check-extra-main-api-routes.py` ile 98/98 doğrulama (bu repoda).
2. `backend-parity` → gerçek `nextjs_space` kopyalama: `scripts/apply-backend-parity-to-nextjs.sh` (hedef repo mevcut olduğunda).
3. Hedef repoda `yarn tsc` / `yarn build` (yalnızca Next.js ağacı olan ortamda).

## Üretim notu

- **Oyun backend** (`canlifalapi.abacusai.app`, 25 yol) bu paketin kapsamı dışında.
- `apply-backend-parity` mevcut dosyaları **silmez**; yalnızca eksik dosyaları ekler.
- Prisma snippet: `backend-parity/prisma-additive/` (Faz 1b favoriler) — şema birleştirmesi üretim DB sürecinde.

## Mobil

Flutter `api_endpoints.dart` bu oturumda değiştirilmedi; APK sürümü `mobile/pubspec.yaml` → **1.0.480+518**.
