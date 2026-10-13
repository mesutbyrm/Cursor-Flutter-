# Backend PR #57 — Flutter deploy handoff

> **Backend:** [canlifal PR #57](https://github.com/mesutbyrm/canlifal/pull/57) **merged** @ `cb2fdec`  
> **Gap raporu (backend repo):** `docs/FLUTTER_BACKEND_GAP_REPORT.md`  
> **Flutter kod değişikliği gerekmez** — uçlar zaten `1.0.784+` / `1.0.785+` ile hizalı; yedekler (404 → `pk/active`, `agency/wallet`) deploy sonrası birincil uçları kullanır.

## Parity (Flutter repo kökü)

```bash
git clone https://github.com/mesutbyrm/canlifal canlifal-backend
git -C canlifal-backend pull origin main   # cb2fdec+
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
python3 scripts/backend-method-parity.py canlifal-backend/nextjs_space
```

Beklenen: **0** used-only eksik, **bad=0**.

## Build / prod

- Yerel `yarn build`: Abacus `schema.prisma` / `yarn.lock` symlink’leri gerekir; **CI/Abacus build** merge sonrası referans.
- **Deploy öncesi** `canlifal.com`: yeni uçlar `ENDPOINT_NOT_FOUND` (404) normal; `GET /api/me/permissions` token yoksa **401** normal.

## Deploy sonrası smoke (Bearer JWT, okuma)

1. `GET /api/me/permissions`
2. `GET /api/agency/periods` (ajans hesabı)
3. `PATCH /api/agency` (küçük profil alanı — yetkili ajans)
4. `GET /api/pk/me/matches`, `GET /api/pk/me/history`
5. `GET /api/agency/wallet/transactions`

## Mobil doğrulama (cihaz)

- PK geçmişi / istatistik artık boş değil (hesapta veri varsa).
- Ajans cüzdan hareketleri birincil path’ten dolar.
- Tanı: `POST /api/notifications/test-push` (yetkili kullanıcı).

**RELEASE READY** hâlâ Psychic P0 cihaz kapısına bağlı — bkz. [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md).
