# API endpoint matrix (parite — ADIM 1)

Kaynak: `mobile/lib/core/network/api_endpoints.dart`, `fl_ref/extra_main.json`, üretim backend route ağacı (`nextjs_space/app/api/**/route.ts`, catch-all `[...unmatched]` hariç).

## Özet (2026-09-13)

| Ölçüm | Değer |
|------|------|
| Flutter → ana backend eksik (`extra_main.json`) | **98** |
| Flutter → oyun backend (`canlifalapi.abacusai.app`) | **25** (nextjs_space kapsamı dışı) |
| Kontrol betiği | `scripts/check-extra-main-api-routes.py` |
| Hedef | `EKSİK: 0` |

Detaylı sınıflandırma: `uploads/PARITE_ANALIZI_7bee.md` (aynı 98 yol).

## Re-export / alias öncelikleri (yeni route yazmadan önce)

| Flutter yolu | Muhtemel kanonik / not |
|-------------|------------------------|
| `/api/admin/payment-requests*` | `/api/admin/cfc-payment-requests` |
| `/api/admin/payment-notifications` | CFC ödeme bildirimleri admin |
| `/api/admin/voice-room-settings` | `/api/platform/voice-room-settings` |
| `/api/admin/voice-room-finance-audit` | `/api/admin/voice-room-finance` |
| `/api/admin/voice-room-backgrounds` | `/api/admin/voice-rooms` (arka plan) |
| `/api/admin/site-animations/*` | `/api/admin/animations/*` (varsa) |
| `/api/auth/mobile/device-token` | `/api/user/device-token` |
| `/api/live/fal-request*` | `/api/video-streams/{id}/fortune-requests` |
| `/api/fortune-access/settings` | `/api/fortune-access/ip-status` (mobil tolere) |

Her faz bitiminde: `yarn tsc --noEmit`, `yarn build`, `check-extra-main-api-routes.py`.
