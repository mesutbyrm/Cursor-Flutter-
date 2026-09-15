# Backend API parite — uygulama paketi

Flutter `fl_ref/extra_main.json` (**98** yol) için hazır `app/api/**/route.ts` dosyaları.

## Durum

| Ölçüm | Değer |
|--------|--------|
| `extra_main` eşleşmesi | **98/98** (`EKSİK: 0`) |
| Paket kökü | `backend-parity/nextjs_space/` |
| Kullanıcı telefon / terminal | **Gerekmez** |
| Özet (Türkçe) | `fl_ref/docs/BACKEND_PARITY_STATUS.md` |

Cloud Agent bu repoda `scripts/check-extra-main-api-routes.py` ile doğrulamayı çalıştırır.

## Üretim Next.js’e taşıma (geliştirici ortamı)

`fortune_telling_platform` deposu aynı makinede/CI’da olduğunda `scripts/apply-backend-parity-to-nextjs.sh` eksik route dosyalarını kopyalar (mevcut dosyaları silmez). Ardından hedef `nextjs_space` içinde TypeScript build yapılır.

Bu adımlar **Cursor-Flutter** deposunda tek başına çalıştırılmaz; backend repo veya Cloud Agent backend oturumu gerekir.

## Platform hub (2026-09-15)

Admin kullanıcı 360° + ajans cüzdanı + CFC Arena listesi route’ları eklendi. Deploy: `docs/PLATFORM_PRODUCTION_DEPLOY_P0_P2.md`

## İçerik

- Faz notları: `fl_ref/docs/FAZ1_PROGRESS.md` … `FAZ4_PROGRESS.md`
- Re-export listesi: `fl_ref/reexport_map.json`
- Prisma (additive): `prisma-additive/`
- Referans: `backend-reference/canlifal_flutter_paketi/kaynak/`
