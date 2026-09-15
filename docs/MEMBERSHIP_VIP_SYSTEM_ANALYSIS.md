# Üyelik / VIP capability sistemi — envanter ve uygulama planı

> **Kapsam:** Basic · Gold · Premium · Diamond · SVIP · Jeton ödül/indirim **dokunulmaz**.
> **Tek kaynak (üretim):** `canlifal.com` Next.js API + Prisma. Bu repo: Flutter istemci + `api/` mirror + `backend-reference/` şema paketi.

## Mevcut bileşenler (bu repo)

| Alan | Konum | Durum |
|------|--------|--------|
| 5 kademe UI kataloğu | `mobile/lib/features/membership/domain/membership_model.dart` | Basic→SVIP sabit tablo + API merge |
| VIP tier (rozet/oda) | `mobile/lib/features/vip_gold/domain/vip_tier.dart` | **rank düzeltildi** (Gold < Premium) |
| `/api/me/membership*` | `mobile/lib/core/me/me_entitlements_remote_datasource.dart` | Ham JSON |
| Profil üyelik özeti | `profile_membership_helpers.dart` → `profileMembershipInfoProvider` | Cüzdan + süre |
| Giriş efektleri | `vip_gold/` + `site_animation` | Admin ayar + tier |
| VIP oda şifre | `voice_room_access.dart`, `open_voice_room_vip.dart` | Tier kontrolü |
| Admin kullanıcı üyelik | `admin_membership_sheet.dart` | grant-membership |
| Prisma capability şeması | `backend-reference/.../schema.prisma` §20 | `membership_tier_defs`, `membership_features`, `membership_tier_features` |
| Admin API (OpenAPI) | `GET/PUT /api/admin/membership_tiers`, `membership_features` | Üretimde; mobil admin UI eklendi |

## Yeni / güncellenen (bu çalışma)

| Bileşen | Dosya |
|---------|--------|
| Merkezi capability çözümleyici | `mobile/lib/core/membership/membership_capabilities.dart` |
| Capability Riverpod | `mobile/lib/core/membership/membership_capability_providers.dart` |
| Admin üyelik matrisi UI | `mobile/lib/features/admin/presentation/pages/admin_membership_management_page.dart` |
| API sabitleri | `api_endpoints.dart` → `adminMembershipTiers`, `adminMembershipFeatures` |
| VIP oda kapısı | `open_voice_room_vip.dart` → `membershipCapabilitiesSyncProvider` + `vip.vip_rooms` |
| Kim Baktı kapısı | `profile_visitors_page.dart` → `vip.profile_visitors` + limit |
| Kilit CTA bileşeni | `membership_capability_gate.dart` |

## Üretimde değiştirilmesi gerekenler (canlifal.com — bu repoda değil)

1. **Prisma migrate** — `backend-reference` §20 tabloları üretim DB’de yoksa migrate + seed.
2. **GET `/api/me/membership`** — `tier`, `expiresAt`, `capabilities: { key: { enabled, limit, … } }`, `discoveryWeight`, `privacy`, `badges`.
3. **Admin CRUD** — tier/feature matrisi; cache invalidation (Redis veya in-memory + membership değişim event).
4. **Yetki middleware** — VIP oda, SVIP lounge, gizli giriş, profil ziyaretçileri: **sunucu** doğrulaması (§21).
5. **Web** — Aynı `/api/me/membership` + admin API; Flutter ile parity (§26).

## Jeton ekonomisi

`MembershipCatalogData.featureRows` içindeki aylık jeton satırları **bilgi amaçlı**; jeton ödül/indirim motoruna **bağlanmaz**.

## Test matrisi (§30)

Otomatik: `vip_tier_test.dart`, `membership_capabilities_test.dart`, mevcut `membership_features_test.dart`.

Manuel: her kademe için oda girişi, gizlilik, admin panelden özellik kapatma → uygulama yenile → UI + API 403.
