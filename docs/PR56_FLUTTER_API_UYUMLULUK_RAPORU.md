# PR #56 — Flutter API uyumluluk raporu

> **Tarih:** 2026-10-13 (UTC)  
> **Backend referans:** `mesutbyrm/canlifal` `main` @ **`79823e6`** (merge PR #56)  
> **Flutter:** `Cursor-Flutter-` `main` → sürüm **`1.0.785+841`**  
> **Base URL:** `https://canlifal.com`  
> **Kanonik mobil sözleşme:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md)

## Özet

Canlifal web deposunda **PR #56** ile `main`’e taşınan admin, ajans, sosyal hesap, cüzdan transferi, ödeme talepleri ve `GET /api/me/permissions` davranışları Flutter tarafında incelendi. Üretim şeması yerel `canlifal-backend/nextjs_space` (771 route) üzerinden doğrulandı.

**Bu oturumda yapılan Flutter düzeltmeleri:** izin grupları (PR #56 yanıt şekli), ajans profil `PATCH` önceliği, admin şikayet durum filtresi (`reviewed`). Diğer PR #56 alanları önceki sürümlerde (782–784) zaten hizalıydı.

**Parity:** `python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only` → **9** kullanılan yol backend’de yok (PR #56 kapsamı dışı; aşağıda §3).

---

## 1. Doğrulanan endpoint’ler (PR #56 kapsamı)

Kaynak: `canlifal-backend/nextjs_space/app/api/**/route.ts` @ `79823e6`.

| Alan | Endpoint | Metot | Auth | Backend (PR #56) | Flutter |
|------|----------|-------|------|------------------|---------|
| JWT / oturum | `/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `/api/me` | POST/GET | Bearer | Var | `AuthRepository` — değişiklik yok |
| Yetkiler | `/api/me/permissions` | GET | Bearer / web session | `{ role, isSuper, permissions[], groups{} }` — `groups` izin anahtarından türetilir | `MePermissions.fromJson` — **List `groups` yedek gruplama eklendi** |
| Admin canlı | `/api/admin/live-stats` | GET | Staff + Bearer | Var | `AdminRemoteDataSource` |
| Admin sağlık | `/api/admin/health` | GET | Staff | Var | Aynı |
| Admin şikayet | `/api/admin/complaints` | GET/PATCH | `moderation.report.handle` | `status`: `pending` \| `reviewed` \| `dismissed` \| `all`; aksiyon `review`/`resolve`/`dismiss` | **Query mapper + UI `reviewed`** |
| Admin finans özet | `/api/admin/finance/summary` | GET | Staff | `revenue.totalTL` vb. | `AdminFinanceSummary.fromJson` — uyumlu |
| Admin üyelik | `/api/admin/users/grant-membership` | PATCH | Staff | Var | PATCH + body mevcut |
| Sosyal (public) | `/api/social-accounts` | GET | Opsiyonel | Var | 404 → boş liste |
| Sosyal (admin) | `/api/admin/social-accounts` | GET/POST/PATCH/DELETE | Staff | Var | Repository mevcut |
| Ajans profil | `/api/agency` | PATCH | Ajans yetkisi | PR #56 birincil | **`patchAgencyProfile` önce `agencyRoot`, sonra `agencyMy`** |
| Ajans dönem | `/api/agency/periods` | GET | Ajans | Var | Birincil path (784+) |
| Ajans davet | `/api/agency/invites` | GET/POST | Ajans | `{ inviteId, action }` | Mevcut body |
| Cüzdan transfer | `/api/wallet/transfer` | POST | Bearer | `{ recipient, currency, amount }` | Idempotency + sunucu yanıtı; **GET kuralları yok** — istemci hata/404’te varsayılan kurallar |
| Ödeme talebi | `/api/payments/requests/pending`, `…/cancel` | GET/POST | Bearer | PR #56 | Mevcut datasource |
| Cüzdan / jeton | `/api/wallet`, hediye POST uçları | Çeşitli | Bearer | Var | Bakiye yalnız sunucu yanıtı / SSE sonrası yenileme — istemci tek taraflı düşürme yok |
| Sesli oda / SSE | `/api/chat/rooms/{id}/stream`, presence, voice join | GET/POST | Bearer | Değişmedi | Dokunulmadı |
| Canlı yayın | `/api/video-streams/*` | Çeşitli | Bearer | Değişmedi | Dokunulmadı |

### Alan bazlı kısa notlar

- **JWT:** PR #56 admin uçlarında `authenticateRequest` + web session yedek; mobil Bearer ile uyumlu.
- **Rol/yetki:** UI `MePermissions.can()` yalnız görünürlük; her admin çağrısı 403 ile sunucuda kesilir.
- **Ajans:** Oluşturma / katılma / davet akışları önceki parity commit’lerinde hizalandı; PR #56 `PATCH /api/agency` ve `periods` eklentisi.
- **Yönetici istatistikleri:** `live-stats`, `finance/summary`, `health` — Flutter sabitleri ve modeller mevcut.
- **Ödeme durumları:** Pending/cancel uçları PR #56 ile; mobil `payments/requests` hattı kullanılıyor.

---

## 2. Flutter’da değiştirilen dosyalar (PR #56 hizası)

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/features/auth/domain/me_permissions.dart` | `groups` JSON **List** (katalog) gelince izinleri `group` önekine göre haritalama |
| `mobile/lib/features/agency/data/datasources/agency_management_datasource.dart` | `patchAgencyProfile`: deneme sırası `[agencyRoot, agencyMy]` |
| `mobile/lib/features/admin/domain/admin_complaint.dart` | `complaintStatusQueryForApi()` — `reviewing`/`resolved` → `reviewed` |
| `mobile/lib/features/admin/data/admin_remote_datasource.dart` | Şikayet listesi query param mapper kullanımı |
| `mobile/lib/features/admin/presentation/pages/admin_complaints_page.dart` | Filtreler: `pending`, `reviewed`, `dismissed`, `all` |
| `mobile/test/features/auth/me_permissions_pr56_test.dart` | Yeni birim test |
| `mobile/test/features/admin/admin_complaint_status_pr56_test.dart` | Yeni birim test |
| `mobile/pubspec.yaml` | `1.0.785+841` |
| `mobile/CHANGELOG.md` | Sürüm notu |
| `docs/BACKEND_FLUTTER_PARITY_2026-09_STATUS.md` | PR #56 / `79823e6` notu |

**Yapılandırma:** Base URL tek kaynak `mobile/lib/core/config/env.dart` → `https://canlifal.com`. Token: `flutter_secure_storage` + Dio interceptor (401 → refresh).

---

## 3. Eksik veya uyumsuz API’ler

### 3.1 Backend’de henüz yok (771 route @ PR #56; Flutter `--used-only`)

| Path | Flutter | Beklenen davranış |
|------|---------|-------------------|
| `GET /api/agency/wallet/transactions` | `ApiEndpoints.agencyWalletTransactions` | 404’te `wallet` / accruals yedekleri |
| `POST /api/notifications/test-push` | Tanı sayfası tanı | 404 açıklaması; prod’da opsiyonel |
| `GET /api/pk/me/history` | PK geçmişi | Router ana site; route yoksa boş/hata UI |
| `GET /api/pk/me/stats` | PK istatistik | Aynı |
| `GET /api/pk/me/matches` | Aktif maçlar | Aynı |
| `GET /api/pk/stats/:id` | PK skor özeti | Aynı |

**Backend önerisi:** Bu 5 aile için ayrı deploy/PR (parity dalındaki route’lar) veya Flutter’ın yedek uçlarına kalıcı yönlendirme.

### 3.2 Bilinen sözleşme farkları (PR #56 ile çözüldü / izleniyor)

| Konu | Durum |
|------|--------|
| Admin şikayet `reviewing` / `resolved` query | **Düzeltildi** → API `reviewed` |
| `MePermissions.groups` List vs Map | **Düzeltildi** — her iki şekil desteklenir |
| `GET /api/wallet/transfer` (kurallar) | Backend yalnız POST; Flutter varsayılan kurallar |
| OpenAPI indeks vs canlı route sayısı | Cross-source rapor: indeks 780, canlı clone 771 — envanter drift |

PR #56 **dışında** kalan özelliklerin çalıştığı varsayılmaz; cihaz/P0 testleri ayrı kapı.

---

## 4. Çalıştırılan testler ve sonuçları

| Komut | Sonuç |
|-------|--------|
| `flutter test test/features/auth/me_permissions_pr56_test.dart` | **PASS** (1) |
| `flutter test test/features/admin/admin_complaint_status_pr56_test.dart` | **PASS** (1) |
| `flutter test test/core/network/agency_endpoint_parity_test.dart` | **PASS** (2) |
| `flutter test test/core/network/api_backend_router_test.dart` | **PASS** (14) |
| **Toplam (PR #56 paketi)** | **16 test, 0 failure** |
| `dart analyze` (auth/admin/agency datasource) | **0 error** (yalnız info seviyesi uyarılar) |

Üretim API’sine karşı canlı bakiye/transfer/hediye denemesi **yapılmadı** (mock/birim test).

---

## 5. Backend’de ayrıca yapılması gerekenler

1. **PK `me/*` ve `pk/stats/:id` route’larını** `main`’e taşımak (Flutter zaten çağırıyor; 404 kullanıcı etkisi).
2. **`GET /api/agency/wallet/transactions`** — ajans cüzdan hareketleri birincil path (yedekler geçici).
3. **`POST /api/notifications/test-push`** — yalnız tanı/staging; prod’da bilinçli kapalı olabilir (dokümante edin).
4. **Deploy doğrulama:** `79823e6` (PR #56) canlifal.com’da aktif mi — route sayısı / smoke (`/api/warmup`, admin health).
5. **`FLUTTER_BACKEND_GAP_REPORT.md`** (backend repo) ile mobil CHANGELOG çapraz referans güncel tutulsun.

---

## 6. Üretime çıkmadan önce manuel test adımları

1. **Mobil giriş:** JWT refresh sonrası `/api/me` ve `/api/me/permissions` — staff hesapta `permissions` dolu, gruplar UI’da görünür.
2. **Admin şikayetler:** Filtre `İncelendi` (`reviewed`) liste döner; `review` / `dismiss` aksiyonları 200 ve liste yenilenir.
3. **Ajans sahibi:** Profil düzenle → `PATCH /api/agency` (network log); başarı mesajı.
4. **Sosyal hesaplar:** Public liste + admin CRUD (yetkili staff).
5. **Cüzdan transfer:** Küçük test jetonu, çift gönderim engeli (idempotency); bakiye yalnız sunucu sonrası güncellenir.
6. **Sesli oda / canlı:** Kısa smoke — SSE bağlanır, hediye sonrası bakiye yenileme (regression).
7. **PK geçmişi:** Backend route yoksa boş/hata mesajı kabul edilebilir; route deploy sonrası tekrar.

---

## Ek: parity komutları

```bash
git -C canlifal-backend/nextjs_space log -1 --oneline   # 79823e6
python3 scripts/backend-route-parity.py canlifal-backend/nextjs_space --used-only
python3 scripts/backend-method-parity.py canlifal-backend/nextjs_space
```

**RELEASE READY:** Agent kapısı hâlâ **Psychic P0 cihaz** — bkz. [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md).
