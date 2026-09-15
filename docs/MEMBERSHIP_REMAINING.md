# Üyelik / VIP — kalan işler (2026-09-15)

## Flutter istemci (`mobile/`) — bu oturumda tamamlananlar

- VIP gizlilik: `GET/PUT /api/me/vip-preferences` (`vip_preferences_*`, Ayarlar)
- SVIP Lounge sayfası: `/vip-svip-lounge` + capability kapısı
- Admin: tier aktif/pasif + tier×feature matrisi `PUT /api/admin/membership_features`
- Capability bağlantıları: kozmetik, DM, fal, giriş FX, VIP hub, Kim Baktı, VIP oda, site animasyon tier

İstemci tarafında **yapılabilir** VIP işleri büyük ölçüde bitti. Yeni özellikler üretim API sözleşmesine bağlı.

## Yalnızca canlifal.com (üretim) — agent bu repoda yapamaz

1. Prisma migrate + seed (`membership_*` tabloları)
2. `GET /api/me/membership` tam `capabilities` gövdesi + cache
3. Sunucu middleware (VIP oda, ziyaretçiler, gizlilik — 403)
4. Web admin / üyelik parity
5. BÖLÜM 20B checklist: VIP XP, leaderboard, membership-history, gift membership (kısmen endpoint var; tam ürün akışı)

## Release / mağaza (kullanıcı)

- Psychic **P0** / **P1** cihaz testleri
- Play Console, keystore, AAB yükleme

## APK

Son push’lar `[skip ci]` ile yapılabilir; APK üretimi kullanıcı onayı sonrası (`main` push veya Actions manuel).
