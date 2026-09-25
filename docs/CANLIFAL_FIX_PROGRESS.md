# Canlifal — tam sistem düzeltme ilerlemesi

Güncelleme: 2026-09-25 · Dal: `main` (henüz **APK istenmedi** — CI yeşil olunca sizin onayınızla derlenir)

## Backend erişimi

| Kaynak | Durum |
|--------|--------|
| GitHub `mesutbyrm/canlifal` | **404** (bu ortamda private / erişim yok) |
| `backend-reference/canlifal_flutter_paketi/` | **Tek sözleşme kaynağı** (`voice_room_api.md`, `pk-state.ts`, `presence-engine.ts`, OpenAPI) |
| Üretim | `https://canlifal.com` — kılavuz §9 |

Backend kodu repoda değiştirilmedi (mobil istemci repo).

---

## Aşama 1 — Sesli oda (2. dalga, backend hizalı)

### Kök nedenler (kullanıcı “Aşama 1 olmadı” geri bildirimi sonrası)

| Belirti | Kök neden |
|---------|-----------|
| Uygulama açılışında odadayım | Sunucuda kalan presence; istemci `GET /state` ile `selfInRoom=true` yapıyordu |
| Ana sayfada oda / PK hedefi | Aktif oda kaydı join öncesi (648’de kısmen düzeltildi) |
| Sahip TRTC kopması | TRTC, `backendSyncReady` beklemeden (1,5 sn) bağlanıyordu |
| Leave sonrası hayalet | Leave sırası: backend **DELETE** `/presence` önce değildi |
| Heartbeat → koltuk zıplama | 648: rejoin without seat |

### Yapılan değişiklikler (650 dalı)

- `resolveSelfInRoomFromBackend` — `selfInRoom` yalnızca `_presenceJoined && listede`
- `GET /state` snapshot artık join onayı olmadan `selfInRoom` açmıyor
- `leavePresence`: **DELETE** → POST `action: leave` (voice_room_api.md §2)
- `VoiceRoomPresencePersistence` + `clearStaleVoicePresenceOnAuth` — girişte sunucuda kalan oda leave
- TRTC bekleme: 8 sn (`voice_room_rtc_page.dart`)
- Önceki 648: delegateLifecycle, rejoin, registry zamanlaması

### Test

- `voice_room_presence_self_sync_test.dart` — 4 test PASS
- `voice_hub/` — 210+ test PASS (yerel)

### Cihazda doğrulanmadı

- Gerçek oda sahibi TRTC, cross-room PK, arka plan 45 sn leave — **P0 cihaz gerekli**

---

## Aşama 2 — PK (mevcut kod + backend)

- Sözleşme: `pk-state.ts`, `POST/GET .../pk`, SSE `room_event` / `pk_invite`
- Mobil: `pk_battle_remote_*`, `voice_pk_invite_listener`, poll 2 sn
- **Eksik doğrulama:** iki cihaz / iki oda ile uçtan uca (CI yok)

---

## Aşama 2 — Canlı fal

- Süre: `psychic_video_controller` → `room.remainingSeconds` (backend) öncelikli
- Mesaj / istek: `livePsychicsRepository` + SSE — cihaz testi yok

---

## Aşama 3 — Finans / Gold

- Oturum özeti: `SessionGiftSummaryBuilder` — provider verisi; tam muhasebe için backend özet uçları (`/api/room/.../summary` vb.) kullanılmalı
- Gold jeton: `membership_page.dart` — yeterli jeton → `POST /memberships/purchase` (paymentMethod opsiyonel); CFC → `paymentMethod: cfc`

---

## Aşama 4 — Hediye kutusu / sezon

- Backend ref: `gift-box.ts`, `BOLUM22_*` — mobil modüller var; UI/backend probe ile hizalanmadı (bu oturumda kod taraması yapıldı, tam UI rewrite yok)

---

## Aşama 5 — Performans

- `StartupPerf`, deferred bootstrap mevcut; yeni profil ölçümü bu oturumda koşturulmadı

---

## Sonraki adımlar (önerilen sıra)

1. Cihazda Aşama 1 checklist (sahip oda, leave, cold start)
2. İki telefon PK davet zinciri
3. Falcı seans süre eşleşmesi
4. Backend repo erişimi açılırsa route.ts ile otomatik diff
