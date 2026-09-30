# Backend (mesutbyrm/canlifal) ↔ Flutter uyumluluk denetimi

> **Tarih:** 2026-09-30 (UTC)  
> **Flutter sürüm:** `1.0.657+708`  
> **Backend kaynak (salt okuma):** `canlifal-backend/nextjs_space` (669 `route.ts`)  
> **Yöntem:** PR #410 ile aynı — route envanteri + öncelik modüllerde yol/metot/gövde/yanıt alanı karşılaştırması  
> **Otomatik envanter:** [`BACKEND_FRONTEND_UYUMLULUK_ENVANTER.md`](BACKEND_FRONTEND_UYUMLULUK_ENVANTER.md) (`scripts/generate_backend_frontend_uyumluluk_report.py`)

## Özet

| Metrik | Değer |
|--------|------|
| Backend route dosyası | 669 |
| Flutter `/api/` literal | 460 |
| Bu turda tespit edilen **uyumsuzluk** (öncelik + A) | **8** |
| **Flutter ile düzeltildi** | **5** |
| **Backend bekliyor** | **3** |

---

## Öncelik modülleri (detay)

| Modül | Endpoint | Sorun | Kategori | Düzeltme | Kim düzeltmeli |
|-------|----------|-------|----------|----------|----------------|
| PK | `GET /api/pk/me/invites` | Yanıt `PkMatch`: `hostStreamId`/`guestStreamId`, `status: live` — Flutter `stream1Id`/`active` bekliyordu | C | `normalizeWireMap`: host/guest stream → oda id; `live`→`active` | **Flutter** ✅ |
| PK | PK sonuç / bitiş | Backend `winnerSide: 1\|2`, `result: host\|guest\|draw`; Flutter yalnız `challenger\|opponent\|tie` string | C | `PkResultRemote.fromJson` normalizasyonu; `pk_battle_provider` winner fallback | **Flutter** ✅ |
| PK | `GET /api/pk/me/invites` | `challengerRoomId`/`opponentRoomId` zaten map'leniyordu; `hostStreamId` eksikti | C | `hostStreamId`/`guestStreamId` alias | **Flutter** ✅ |
| PK | Birleşik PK status | `mapPkStatus`: `active`→`live`; `isLivePkActiveStatus` `live` içermiyordu | C | `pk_status_helper`: `live` aktif sayılır | **Flutter** ✅ |
| PK | `POST /api/chat/rooms/{id}/pk` | `action`, `battleId`, `targetRoomId`, `duration` — Flutter ile backend uyumlu (2026-09 doğrulama) | — | Değişiklik yok | — |
| PK | `GET /api/pk/me/history` · `…/stats` · `…/matches` | Flutter ana siteye yönlendiriyor; **canlifal** snapshot'ta route yok | A | Games backend veya ana site route eklenmeli | **Backend** |
| Presence | `GET/POST /api/chat/rooms/{id}/presence` | Backend gövde: `nickname`, `seatIndex`, `password`; `action: join` zorunlu değil. Flutter çoklu gövde fallback | — | Uyumlu | — |
| Presence | `DELETE …/presence?leave=1` | Backend `leave` query ile koltuk sıfırlama — Flutter kullanıyor | — | Uyumlu | — |
| Presence | Debug log | Geçersiz map literal (`?seatIndex`) derleme/analyze riski | B | Log map düzeltildi | **Flutter** ✅ |
| Canlı misafir | `GET/POST /api/live/guest` | PR #410: `invite`+`respond`+`inviteId`; Flutter `guestInvitesForMeFromSync` / `guestJoinRequestsFromSync` | — | Güncel (2026-09-30 doğrulama) | — |
| Hediye | `POST /api/live/gift/send` vb. | Mobil kılavuz §9; envelope `success`+`data` unwrap mevcut | — | Bu turda sapma yok | — |
| Auth | `POST /api/auth/mobile-login` | `email`/`username`+`password`; yanıt token alanları mevcut unwrap | — | Uyumlu | — |

---

## Kategori A — Flutter çağırıyor, ana backend snapshot'ta route yok

| Path | Not |
|------|-----|
| `/api/pk/me/history` | Router ana site; **route.ts yok** — games veya yeni route |
| `/api/pk/me/stats` | Aynı |
| `/api/pk/me/matches` | Aynı |

*(Tam liste: envanter dosyası.)*

---

## Kategori B — İstek gövdesi / alan adı (düzeltilenler)

| Modül | Endpoint | Sorun | Kim |
|-------|----------|-------|-----|
| Presence | `POST …/presence` | İstemci debug map sözdizimi | Flutter ✅ |

---

## Kategori C — Yanıt modeli (düzeltilenler)

| Modül | Alan | Sorun | Kim |
|-------|------|-------|-----|
| PK | `status` | `live` aktif sayılmıyordu | Flutter ✅ |
| PK | `hostStreamId` / `guestStreamId` | Oda PK eşlemesi | Flutter ✅ |
| PK | `winnerSide` / `result` | Sayısal / host-guest | Flutter ✅ |

---

## Doğrulanmış uyumlu akışlar (özet)

- Sesli PK: `POST /api/chat/rooms/{roomId}/pk` — `create`/`accept`/`reject`/`end`, `battleId`, `targetRoomId`, `duration`
- PK poll: `GET /api/pk/me/invites?direction=incoming` — `invites[]`, `challengerRoomId`, `opponentRoomId`
- Canlı PK: `POST /api/video-streams/pk` — `action`, `streamId`, `targetStreamId`, `duration`
- Canlı misafir: `POST /api/live/guest` — `action: invite|respond|request|approve|reject`, davet `inviteId`
- Auth: `/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `/api/me`

---

## Test / analyze

- `flutter test` — `pk_result_remote_wire_test.dart`, `pk_status_helper_test.dart`
- `dart analyze` — değişen PK/presence dosyaları (yalnız mevcut info/warning)

---

## Referans

- [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) §9  
- Önceki tur: CHANGELOG `1.0.653+704`, PR #410  
- Backend yapılacaklar: [`BACKEND_YAPILACAKLAR.md`](BACKEND_YAPILACAKLAR.md)
