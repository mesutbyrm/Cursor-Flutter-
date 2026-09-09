# Admin — Tam Kullanıcı Yönetimi (Komuta Merkezi)

> **Mobil sürüm:** `1.0.417+455` · **API:** `https://canlifal.com` · **Kılavuz:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`

## Amaç

Yetkili (admin / yönetici / moderatör) bir kullanıcıya tıkladığında **tek ekranda** özet, finans, hediye, yayın/oda, yetki ve aktivite görmek; izin dahilinde değiştirmek.

**Rota:** `/admin/users` → kullanıcı seç → `/admin/users/{userId}`

---

## Yetki matrisi (mobil UI — backend 403 ile korunur)

| Sekme / eylem | Kurucu | Site admin | Ödeme yöneticisi | Moderatör | Destek |
|---------------|--------|------------|------------------|-----------|--------|
| Özet görüntüle | ✅ | ✅ | ✅ | ✅ | ❌ |
| Finans geçmişi | ✅ | ✅ | ✅ | ❌ | ❌ |
| Jeton/CFC +/- | ✅ | ✅ | ✅ | ❌ | ❌ |
| Gold üyelik ver | ✅ | ✅ | ✅ | ❌ | ❌ |
| Hediye koleksiyonu | ✅ | ✅ | ✅ | ✅ | ❌ |
| Yayın/oda sayıları | ✅ | ✅ | ✅ | ✅ | ❌ |
| Aktivite akışı | ✅ | ✅ | ✅ | ✅ | ❌ |
| Rol / profil düzenle | ✅ | ✅ | ✅* | ❌ | ❌ |
| Admin atama | ✅ | ❌ | ❌ | ❌ | ❌ |
| Moderatör atama | ✅ | ✅ | ❌ | ❌ | ❌ |
| Ban / askı | ✅ | ✅ | ✅ | ✅ | ❌ |
| Özellik bayrakları (yayın/oda açma) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Kullanıcı adına oda açma | ✅ | ❌ | ❌ | ❌ | ❌ |
| Canlı falcı onayı | ✅ | ✅ | ✅ | ❌ | ❌ |
| Kullanıcı silme | ✅ | ❌ | ❌ | ❌ | ❌ |

\* Ödeme yöneticisi: `canManagePayments` + `canManageUsers` (mevcut `StaffAccess`).

Kod: `mobile/lib/features/admin/domain/admin_user_permissions.dart`

---

## Veri kaynakları (mevcut üretim uçları)

| Veri | API | Durum |
|------|-----|--------|
| Admin kullanıcı kaydı | `GET /api/admin/users/{userId}` | PARTIAL — alanlar sunucuya bağlı |
| Genel profil | `GET /api/users/{userId}` | CONNECTED |
| Jeton/CFC geçmişi | `GET /api/admin/finance?userId=` | PARTIAL |
| Jeton/CFC +/- | `PATCH /api/admin/users/credits` veya `POST /api/admin/credits` | PARTIAL |
| Üyelik | `PATCH /api/admin/users/grant-membership` | PARTIAL |
| Profil/rol | `PATCH /api/admin/users/{userId}` | PARTIAL (`role`, `membership`, `banReason`, …) |
| Hediye koleksiyon | `GET /api/gifts/insights/collection/{userId}` | CONNECTED |
| Hediye albüm | `GET /api/gifts/insights/album/{userId}` | CONNECTED |
| Site aktivite (filtre) | `GET /api/admin/activity-feed` + client filtre | PARTIAL |
| Canlı falcı | `POST /api/admin/live-tellers` + `/{id}/approve` | CONNECTED (mobil) |
| Çekim limiti | `POST /api/admin/users/withdrawal-limit` | CONNECTED |
| PK ban | `POST /api/pk/admin/ban` · unban | CONNECTED |
| Site animasyon ata | `POST /api/admin/site-animations/assign` | CONNECTED |
| Inline ödeme onayı | `PATCH /api/admin/payment-requests` | CONNECTED (komuta merkezi) |
| Reklam izleme sayısı | `GET /api/admin/users/{id}/ads` veya user alanı | PARTIAL (probe) |
| Hediye gönderen/alıcı + zaman | `GET /api/admin/users/{id}/gifts` veya voice audit | PARTIAL |
| Yayın/oda geçmişi (liste) | `GET /api/admin/users/{id}/streams|rooms` | PARTIAL (probe) |
| Adına oda açma | `POST /api/admin/chat/rooms/create-for-user` | PARTIAL (404 toleranslı) |

---

## UI sekmeleri (Faz 1 — uygulandı)

1. **Özet** — jeton, CFC, yayın/oda sayısı, üyelik süresi, son online, sosyal
2. **Finans** — geçmiş + jeton/CFC/üyelik hızlı işlemler
3. **Hediyeler** — koleksiyon + albüm (tür bazlı; zaman damgası Faz 2)
4. **Yayın/Oda** — sayılar, izin bayrakları, aktif listelere link
5. **Yetkiler** — rol formu, ban, özellik switch’leri (PATCH)
6. **Aktivite** — activity-feed’den kullanıcıya filtrelenmiş satırlar

---

## Faz 2 — Backend + mobil (uygulandı `1.0.416+454`)

1. **`GET /api/admin/users/{id}/full`** — probe; varsa özet zenginleştirilir
2. **`GET /api/admin/users/{id}/gifts`** — ledger; yoksa voice-room-finance-audit filtresi
3. **`GET /api/admin/users/{id}/streams`** + **`/rooms`** — probe listeler
4. **`POST /api/admin/live-tellers`** + approve — falcı oluştur / onayla
5. **`POST /api/admin/chat/rooms/create-for-user`** — kurucu adına oda (404 toleranslı)
6. **Reklam** — `GET /api/admin/users/{id}/ads` probe + user alanı

---

## Faz 3 — Gelişmiş yönetim (uygulandı `1.0.416+454`)

- Inline ödeme onayı (Finans sekmesi — bekleyen talepler)
- Site animasyon / profil çerçevesi atama (Yetkiler sekmesi)
- Withdrawal limit (`POST /api/admin/users/withdrawal-limit`)
- PK ban/unban (`/api/pk/admin/...`)
- Aktivite akışı — audit benzeri (mevcut activity-feed filtresi)

---

## Faz 4 — Yetki yapılandırması (kısmi — `1.0.416+454`)

- **Yetkiler** sekmesinde salt okunur **rol × eylem** matrisi (`AdminRolePermissionsMatrix`)
- Gelecek: `GET/PUT /api/admin/role-permissions`
- Kurucu UI’dan moderatöre “sadece moderasyon” profili atar
- Değişiklikler `StaffAccess` ile senkron (`/api/user/credits` flags)

---

## Kararlar (varsayılanlar uygulandı)

1. Faz 2 sırası: `/full` + `/gifts` probe önce
2. Moderatör finans: **hayır**
3. Adına oda açma: **yalnızca kurucu**
4. Hediye ledger gizli maskesi: backend API gelene kadar **mevcut veri**
