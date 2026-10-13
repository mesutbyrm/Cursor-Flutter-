# Backend ↔ Flutter tam parity denetimi

> **Tarih:** 2026-10-13 UTC  
> **Backend kaynağı:** `mesutbyrm/canlifal` → `nextjs_space`  
> **Flutter:** `Cursor-Flutter-` / `mobile/` @ `1.0.785+841`  
> **Betikler:** `scripts/backend-route-parity.py`, `scripts/backend-method-parity.py`

## Kaynak dallar

| Dal / commit | Route sayısı | Flutter `--used-only` eksik |
|--------------|-------------:|----------------------------:|
| **`main` @ `79823e6` (PR #56 merge)** | **771** | **9** satır (6 benzersiz path) |
| **`cursor/mobile-parity-apis-dfca` @ `3d155b7`** | **773** | **2** (`agency/periods`, `agency/wallet/transactions`) |

**Dal farkı (route dosyası):**

- Yalnız **parity dalında:** `test-push`, `pk/me/history|matches|stats`, `pk/stats/[userId]`
- Yalnız **PR #56 main’de:** `PATCH /api/agency`, `GET /api/agency/periods`, `PATCH /api/admin/users/grant-membership`

**Sonuç:** Tek dalda birleşik deploy yok; Flutter her iki taraftaki uçları da çağırıyor. Üretim `canlifal.com` = hangi commit ise tablo ona göre geçerli.

---

## 1. Flutter çağırıyor — backend’de route yok (kritik)

`python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only` @ **79823e6**:

| Path | Flutter | Backend main | İstemci yedek |
|------|---------|--------------|---------------|
| `GET /api/pk/me/history` | `pk_room_remote_datasource.dart` | **Yok** | 404 → boş liste |
| `GET /api/pk/me/matches` | aynı | **Yok** | 404 → `GET /api/pk/active` |
| `GET /api/pk/me/stats` | aynı | **Yok** | 404 → boş `PkStats` |
| `GET /api/pk/stats/:userId` | `pkStats()` | **Yok** | 404 → boş stats |
| `GET /api/agency/wallet/transactions` | `agency_wallet_datasource.dart` | **Yok** (yalnız `…/wallet`, `…/transfer`) | `GET /api/agency/wallet` |
| `POST /api/notifications/test-push` | tanı sayfası | **Yok** | UI mesajı |

**HTTP metot taraması** (`backend-method-parity.py`): **687 ok**, **107 unresolved** (dinamik path), **5 bad** — tamamı **NO_ROUTE** (metot uyumsuzluğu yok).

**Kullanılmayan sabitler (backend’de de yok, referans yok):**

- `/api/agency/members/invite`
- `/api/agency/members/remove`

---

## 2. Backend var — Flutter mobilde literal çağırmıyor (209 route)

Yaklaşık **209 / 771** backend route, Flutter `lib/` içinde eşleşen `/api/...` literal’i yok. Bunların çoğu **web-only admin**, SEO, webhook veya henüz mobil ekranı olmayan özellikler.

Örnek gruplar:

- `api/admin/*` — reklam ağları, yedekleme, audit, animasyon atamaları, …
- `api/chat/rooms/[roomId]/*` — mobil farklı şablon veya tek uçtan türetilmiş çağrılar
- Entegrasyon / cron / internal

**Not:** Literal yok ≠ mobil hiç kullanmıyor; `ApiEndpoints` + `$id` şablonları ve helper’lar 107 çağrıyı “unresolved” bırakır — gerçek metot eşlemesi için `--helpers` ve manuel inceleme gerekir.

---

## 3. OpenAPI / indeks vs canlı backend (cross-source)

[`CROSS_SOURCE_API_PARITY_REPORT.md`](CROSS_SOURCE_API_PARITY_REPORT.md):

- OpenAPI ~**502** path; backend clone **771** `route.ts`
- Flutter’da **161** path OpenAPI ile normalize eşleşmiyor (admin site-animations, eski pk/me şablonları, mirror path’ler)

Mobil sözleşme için öncelik: **canlı `route.ts`** > kılavuz > OpenAPI.

---

## 4. PR #56 sonrası hizalı kalan alanlar (main 79823e6)

Flutter zaten uyumlu (bu denetimde kod değişikliği gerekmedi):

- JWT + `/api/me/permissions` (Map veya List `groups`)
- `/api/social-accounts`, `/api/admin/social-accounts`
- `/api/agency/invites`, `/api/agency/periods`, `PATCH /api/agency`
- `/api/admin/complaints` (`reviewed`), `/api/admin/finance/summary`, live-stats, health
- `/api/wallet/transfer` POST, ödeme pending/cancel
- Sesli oda SSE, video-streams PK — mevcut uçlar backend’de var

---

## 5. Önerilen backend aksiyonları

1. **Parity dalını main’e merge:** PK `me/*` + `pk/stats/[userId]` + isteğe bağlı `test-push`.
2. **`GET /api/agency/wallet/transactions`** — ajans hareket listesi (veya Flutter’ı yalnız `GET /api/agency/wallet` ile sınırla ve dokümante et).
3. Deploy sonrası: `backend-route-parity.py … --used-only` → **0** hedefi.

## 6. Komutlar

```bash
git -C canlifal-backend/nextjs_space checkout 79823e6
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
python3 scripts/backend-method-parity.py canlifal-backend/nextjs_space
```
