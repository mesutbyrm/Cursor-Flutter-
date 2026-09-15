# Platform sosyal — kalan işler (2026-09-15)

> Tamamlananlar: `mobile/CHANGELOG.md` · Parity: `docs/PLATFORM_PRODUCTION_DEPLOY_P0_P2.md`

## Üretim deploy (zorunlu sıra)

1. `bash scripts/apply-backend-parity-to-nextjs.sh <nextjs_space>`
2. `backend-reference/.../admin-mutation.ts` → üretim `lib/` (parity kopyası ile hizala)
3. Prisma migrate: agency wallet, CFC contest, `hiddenFromDiscovery` alanları canlıda doğrula

## P0 — Güvenlik / ledger

| Durum | İş |
|--------|-----|
| Parity | `lib/admin-mutation.ts` + ajans transfer / başvuru onayında audit |
| Üretim | Tüm admin jeton/CFC/ban/VIP POST’larına `guardAdminMutation` |

## P1–P3 — Admin hub API

| Durum | İş |
|--------|-----|
| ✅ Parity | overview, activity, earnings, spending, agency, moderation, reports |
| Kısmi | Activity timeline — audit dışı oda/yayın/fal birleşik aggregator |
| Üretim | Web `UserCommandCenterModal` — `docs/WEB_ADMIN_USER_COMMAND_CENTER_SPEC.md` |

## P4 — CFC Arena

| Durum | İş |
|--------|-----|
| ✅ | join + `CfcScoreLog` join_bonus, GET scores |
| Kalan | Metrik motoru (yayın dk, hediye, izleyici) — cron veya event hook |
| Kalan | Admin CFC yönetim UI (web) |

## P5 — Tanış & keşif

| Durum | İş |
|--------|-----|
| ✅ Mobil | Profil sheet, mesafe bandı, admin keşfet flags |
| ✅ Parity | `social-discovery` + `user/location` stub, `voice-room-distance-enrich` |
| Kalan | Üretim discovery sıralaması (`discoveryPriority`, `discoveryWeight`) |
| ✅ | Etkileşimler sekmesi staff hub (bu sprint) |
| ✅ Mobil | Swipe keşif, eşleşme, beğeniler (gelen/giden), hashtag→filtre, DM önizleme |

## P6 — Web admin

| Durum | İş |
|--------|-----|
| Spec | `WEB_ADMIN_USER_COMMAND_CENTER_SPEC.md` |
| Kalan | `UserCommandCenterModal.tsx` + global arama → modal |
| Parity | `components/admin/UserCommandCenterModal.tsx` iskelet (referans) |

## Mobil hub (staff uzun basış)

| Durum | Yüzey |
|--------|--------|
| ✅ | Keşif kartı, admin arama, canlı izleyici, oda koltuk, sıralama sahibi, ses listesi |
| ✅ | Konuşmacı/dinleyici listesi (bu sprint) |
| ✅ | PK sıralama, hediye liderlik (staff uzun basış) |
| ✅ Mobil | Sosyal takım detay + üye listesi staff hub (`/teams/:id`) |

## Ajans

| Durum | İş |
|--------|-----|
| ✅ | Wallet, transfer, presence, çıkış talebi liste/onay |
| Kalan | Üyelik **katılım** başvurusu (şema/API üretimde doğrula) |
| Kalan | Başvuru skoru + komisyon/bonus admin config UI |

## RELEASE READY

Psychic P0 cihaz PASS olmadan mobil özellik freeze — hotfix only (`AGENTS.md`).
