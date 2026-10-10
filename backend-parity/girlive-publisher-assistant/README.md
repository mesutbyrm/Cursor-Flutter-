# canlifal.com — GirLive Yayıncı Asistanı handoff

Mobil sözleşme: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9.3.2.

## canlifal repo (deploy edildi / merge)

| PR | Dal | İçerik |
|----|-----|--------|
| [#36](https://github.com/mesutbyrm/canlifal/pull/36) | `feat/girlive-publisher-bot-2026-10-11` | `girlive-publisher.ts`, `girlive-public-bot.ts`, `GET …/publisher-assistant`, `end-report`, admin `publicMessages`, SSE `girlive_publisher` |
| [#37](https://github.com/mesutbyrm/canlifal/pull/37) | `feat/girlive-triggers-2026-10-11` | `onUserLeave`, `notifyPkBot` (PK start/end) → presence / stream leave / `pk-state` |

Squash merge **full-source:** `dcdc156e73` (PR #37; #36 → `943ab81cd0`).

Üretim doğrulama: `GET https://canlifal.com/api/chat/rooms/{id}/girlive/publisher-assistant` → **401** (route var; sahip JWT ile **200** beklenir).

## Yapılacaklar (üretim — çoğu PR #36–#37 ile kapandı)

1. **Oturum kaydı** — oda açılış/kapanış, ziyaret giriş/çıkış, mükerrer TRTC/SSE koruması.
2. **GET publisher-assistant** — scope `session|day|week|month`; yalnızca oda sahibi (JWT + ownerId).
3. **GET end-report** — idempotent `sessionId`; kapanış başarısız olsa kayıt korunur.
4. **SSE `girlive_publisher`** — `targetUserId` zorunlu; kazanç/ziyaret metni genel chat'e POST edilmez.
5. **Admin `PUT /api/admin/girlive-bot`** — `publicMessages`: Jeton promos, PK start/mid/end, geçmiş PK motivasyon, minInterval, şablonlar, oda/yayın bazlı aç/kapa.
6. **Patron selamı** — hoş geldin/çıkış: rol `admin|yonetici` → Patron; aksi halde profil adı / @username.

## Prisma

Mevcut modelleri tercih et: hediye işlemleri, PK battle sonuçları, presence/oturum. Gerekirse `GirLiveBotMessageLog` + `VoiceRoomSessionAggregate` — yeni tablo eklemeden önce envanterde ara.

## Mobil doğrulama

Deploy sonrası: sesli oda sahibi → Oda yönetimi → Yayıncı Asistanım → «Yenile» sunucu raporunu doldurmalı.
