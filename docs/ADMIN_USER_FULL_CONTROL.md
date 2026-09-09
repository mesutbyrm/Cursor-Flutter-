# Admin — Tam Kullanıcı Yönetimi (Komuta Merkezi)

> **Mobil sürüm:** `1.0.415+453` · **API:** `https://canlifal.com` · **Kılavuz:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`

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
| Canlı falcı | `POST /api/admin/live-tellers` | MISSING mobilde |
| Reklam izleme sayısı | kullanıcı objesi alanı veya admin endpoint | Eksik — Faz 2 |
| Hediye gönderen/alıcı + zaman | admin gift ledger | Eksik — Faz 2 |
| Yayın/oda geçmişi (liste) | admin user streams/rooms | Eksik — Faz 2 |

---

## UI sekmeleri (Faz 1 — uygulandı)

1. **Özet** — jeton, CFC, yayın/oda sayısı, üyelik süresi, son online, sosyal
2. **Finans** — geçmiş + jeton/CFC/üyelik hızlı işlemler
3. **Hediyeler** — koleksiyon + albüm (tür bazlı; zaman damgası Faz 2)
4. **Yayın/Oda** — sayılar, izin bayrakları, aktif listelere link
5. **Yetkiler** — rol formu, ban, özellik switch’leri (PATCH)
6. **Aktivite** — activity-feed’den kullanıcıya filtrelenmiş satırlar

---

## Faz 2 — Backend + mobil (önerilen sıra)

1. **`GET /api/admin/users/{id}/full`** — tek yanıt: bakiye, tenure, adsWatched, flags, stats
2. **`GET /api/admin/users/{id}/gifts`** — gönderen/alıcı, miktar, context (live/voice/short), timestamp
3. **`GET /api/admin/users/{id}/streams`** + **`/rooms`** — geçmiş + misafirlik
4. **`POST /api/admin/live-tellers`** mobil bağlantı — falcı onay
5. **`POST /api/admin/chat/rooms/create-for-user`** — adına oda açma
6. **Reklam** — `adsWatched` veya `GET /api/admin/users/{id}/ads`

---

## Faz 3 — Gelişmiş yönetim

- Inline ödeme onayı (komuta merkezinden bekleyen talep)
- Site animasyon / profil çerçevesi atama (`/api/admin/site-animations/assign`)
- Withdrawal limit (`POST /api/admin/users/withdrawal-limit`)
- PK ban/unban (`/api/pk/admin/...`)
- Audit log: kim, ne zaman, hangi alanı değiştirdi

---

## Faz 4 — Yetki yapılandırması (site ayarı)

Mobilde **salt okunur** rol önizleme var; gelecekte:

- `GET/PUT /api/admin/role-permissions` — hangi rol hangi sekneyi görür
- Kurucu UI’dan moderatöre “sadece moderasyon” profili atar
- Değişiklikler `StaffAccess` ile senkron ( `/api/user/credits` flags )

---

## Birlikte karar verilecekler

1. Faz 2’de hangi endpoint önce? (öneri: `/full` + `/gifts`)
2. Moderatör finans görebilir mi? (şu an **hayır**)
3. “Adına oda açma” yalnızca kurucu mu?
4. Hediye ledger’da gizli hediye maskesi admin’de açılsın mı?

Onayladığınız maddelerden sonra sırayla implement ederiz.
