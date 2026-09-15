# Tanış Kaynaş — üretim API (canlifal.com)

Mobil sürüm **1.0.527+568** ile hizalı.

## Kullanılan uçlar

| Metot | Path | Amaç |
|--------|------|------|
| GET | `/api/social/discovery` | Keşif adayları (`data.users`, `page`, `limit`, `total`) |
| GET | `/api/social/actions` | Etkileşim geçmişi |
| GET | `/api/social/actions?filter=matches` | Karşılıklı beğeni / eşleşme listesi |
| GET | `/api/social/actions?scope=sent` | Gönderilen aksiyonlar (yedek) |
| POST | `/api/social/actions` | `{ type, targetId }` — `like`, `favorite`, `friend_request`, `block` |
| GET/POST | `/api/user/location` | Konum paylaşımı |
| GET | `/api/social/profile?userId=` | Profil detayı |
| DM | `/chat/{userId}` | Mevcut mesajlaşma (yeni chat sistemi yok) |

## POST `type` (probe 2026-09-15)

- **Geçerli:** `like`, `favorite`, `friend_request`, `block`, `report` (sebep gerekli)
- **Geçersiz (VALIDATION):** `skip`, `pass`, `super_like`, `rewind`, `undo`, `dislike`

## Mobil davranış

- **Geç:** yalnızca istemci kuyruğu (sunucuya `skip` gönderilmez)
- **Süper beğeni:** `favorite` + Gold üyelik kontrolü
- **Geri al:** Gold; son kartı geri getirir; `like`/`favorite` ise toggle ile API
- **Eşleşme:** yanıtta `matched` yoksa `filter=matches` ile doğrulama
- **Filtreler:** sorgu parametreleri + istemci yedek (yaş, şehir, online, gold, ilgi, max km)
- **Profil sheet:** `GET /api/social/profile?userId=` (uyum %, ortak hobiler, arkadaşlık durumu)
- **Eşleşme:** diyalog sonrası Eşleşmeler sekmesi; rozet sayısı

## Eksik / sınırlı (backend)

- Günlük beğeni kotası: üretim yanıtında standart alan yok (429/limit mesajı gözlenmedi)
- `super_like` / `rewind` ayrı uç yok
- Karşılıklı beğenide push/SSE eşleşme olayı mobilde ayrı dinlenmiyor (genel bildirim kanalı)
- `GET /api/social/discovery` yaş/şehir filtreleri sunucuda zayıf; istemci filtre uygular
