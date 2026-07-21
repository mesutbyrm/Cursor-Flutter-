# Flutter ↔ Backend Uyumluluk Raporu

> **Tarih:** 21 Temmuz 2026  
> **Sürüm:** `1.0.68+95`  
> **Tek referans:** [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) (27 Haziran 2026)  
> **Ek kaynaklar:** Kullanıcı yüklemeleri `FLUTTER_PART0`–`PART13`, `SESLI_ODA_SENKRONIZASYON_RAPORU`, `FLUTTER_API_DOCS`

Bu rapor, Flutter mobil istemcisinin canlifal.com üretim backend'i ile dokümantasyon uyumunu özetler. **Uydurma endpoint veya model yok** — eksikler açıkça listelenmiştir.

---

## 1. Yapılan değişiklikler (bu oturum — Faz 1)

| Alan | Önce | Sonra | Kaynak |
|------|------|-------|--------|
| Mobil giriş gövdesi | `emailOrUsername` + `username` | `email` **veya** `username` + `password` | Kılavuz §9.1 |
| Alınan hediyeler | `GET /api/users/me/gifts-received` | `GET /api/user/received-gifts` (+ eski yol yedek) | Kılavuz §9.2, PART3/6 |
| Presence heartbeat | 12 sn | 25 sn | PART4, PART10 |
| SSE `seat_update` | Tanınmıyordu | `room_event` → `GET /seats` yenileme | PART4 |
| SSE `pk_score` | Tanınmıyordu | `pk` olayı olarak işlenir | PART4 |
| Endpoint sabitleri | Eksik | `giftsCheckReciprocal`, `authVerifyDevice`, `authReclaimDevice` | Kılavuz §9.9, PART10 |
| GiftRepository | `checkReciprocal` yoktu | `GET /api/gifts/check-reciprocal?userId=` | Kılavuz §9.9 |

**Önceki oturumlardan (main'de mevcut):**

- Hediye senkronizasyonu: tek `GiftEventListener` + `giftSessionProvider` (`1.0.66+93`)
- Sesli oda backend senkronu: `GET /state`, `GET /seats`, SSE `room_event` (`1.0.67+94`)

---

## 2. Düzeltilen hatalar

| Hata | Düzeltme |
|------|----------|
| Giriş API'si kılavuz dışı `emailOrUsername` alanı gönderiyordu | `username` veya `email` ayrı alanlar |
| Profil hediye özeti yanlış uç kullanıyordu | Dokümante `GET /api/user/received-gifts` |
| Presence heartbeat çok sık (12 sn) — gereksiz yük | 25 sn (doküman aralığı 20–30 sn) |
| PART4 SSE `seat_update` / `pk_score` yok sayılıyordu | Alias eşlemesi + koltuk yenileme |
| `check-reciprocal` hiç bağlı değildi | Repository metodu eklendi (UI entegrasyonu bekliyor) |

---

## 3. Backend ile senkronize edilen modüller

| Modül | Durum | Notlar |
|-------|-------|--------|
| **Auth (JWT)** | ✅ Büyük ölçüde | login/register/refresh/logout kılavuz §9.1; cihaz doğrulama **eksik** |
| **Profil / kullanıcı** | ⚠️ Kısmi | `received-gifts` düzeltildi; `/api/users/me/*` yedekleri korunuyor |
| **Sesli oda (ChatRoom)** | ✅ İyi | Join → state → seats → TRTC → SSE; `room_event` tipleri |
| **Hediye (sesli/canlı)** | ✅ İyi | SSE tek kaynak; combo recent gifts; `checkReciprocal` API hazır |
| **Canlı yayın (video-streams)** | ⚠️ Kısmi | SSE + gifts entegre; bazı live/* uçları paralel kullanılıyor |
| **PK** | ⚠️ Kısmi | SSE `pk` + `pk_score`; games `/api/pk/*` ve `/api/live/pk/*` çoklu yol |
| **Fal** | ✅ İyi | Kılavuz §9.5 endpoint'leri `api_endpoints.dart`'ta |
| **Bildirim** | ✅ İyi | GET/PATCH + SSE stream |
| **Ödeme / cüzdan** | ✅ İyi | jeton, wallet, payment config |
| **Sosyal / kısa video** | ⚠️ Kısmi | Temel uçlar mevcut; tam web parity doğrulanmadı |
| **Admin / dinamik config** | ⚠️ Kısmi | Admin uçları var; mobil admin UI sınırlı |
| **Performans / güvenlik** | ⚠️ Kısmi | SSE backoff kılavuzda; verify-device uygulanmadı |

---

## 4. Doküman çelişkileri (karar gerekli)

| Konu | Kaynak A | Kaynak B | Mevcut Flutter |
|------|----------|----------|----------------|
| Sesli oda heartbeat | PART4: `POST /api/live/heartbeat` | Kılavuz §9.3: `PATCH/POST …/presence` | **Presence** (SESLI_ODA raporu öncelikli) |
| `check-reciprocal` metodu | Kılavuz §9.9: **GET** `?userId=` | FLUTTER_API_DOCS: **POST** | **GET** (kılavuz öncelikli) |
| `verify-device` metodu | PART10: **POST** | FLUTTER_API_DOCS: **GET** | **Uygulanmadı** — backend doğrulaması gerekli |
| `GET /state` | SESLI_ODA + üretim | Kılavuz §9.3'te **yok** | Kullanılıyor — kılavuz güncellenmeli |
| Heartbeat süresi | PART4: 25 sn | FLUTTER_API_REFERENCE: 10 sn (live) | Voice: 25 sn; live field: ayrı timer |

---

## 5. Eksik backend geliştirmeleri / mobilde uygulanmayanlar

Aşağıdakiler dokümanda geçer; **mobilde henüz tam bağlı değil** veya **request/response şeması yetersiz** (uydurma yapılmadı):

### 5.1 Auth & güvenlik
- `GET/POST /api/auth/verify-device` — cihaz doğrulama akışı (metot çelişkisi)
- `POST /api/auth/reclaim-device` — cihaz geri alma
- `POST /api/presence` — site geneli presence (§9.2 UserRepository)

### 5.2 Sesli oda — kılavuz dışı kullanılan uçlar
Aşağıdakiler `chat_room_remote_datasource.dart` içinde kullanılıyor; **kılavuz §9.3'te tanımlı değil**. Üretimde varsa kılavuza eklenmeli; yoksa kaldırılmalı:

- `/api/chat/rooms/{id}/join-seat`
- `/api/chat/rooms/{id}/speak-request`, `/speak-requests`
- `/api/chat/rooms/{id}/kick`, `/mute`, `/roles`, `/bans`
- `/api/chat/rooms/{id}/banned-words`
- `/api/chat/rooms/{id}/music-settings`, `/music-request-by-query`
- `/api/chat/rooms/{id}/music-queue/*` (complete, advance, reorder — kılavuzda sadece temel queue var)

### 5.3 Hediye
- `checkReciprocal` — API metodu eklendi; **UI'da karşılıklı hediye kontrolü henüz bağlanmadı**

### 5.4 Kozmetik / premium profil (PART13)
- `/api/user/cosmetics/*` — fallback zinciri var; tam şema dokümante değil

### 5.5 Kılavuz §9 eksik sabitler (api_endpoints'e eklenecek / kullanılacak)
- `GET /api/chat/rooms/{id}/music-queue` — sabit var, kullanım doğrulanmalı
- `PATCH /api/chat/rooms/{id}/settings` — kullanılıyor, sabit merkezileştirilmeli
- `POST /api/chat/rooms/{id}/transfer-ownership` — kullanılıyor

---

## 6. Manuel test edilmesi gereken alanlar

| # | Senaryo | Beklenen |
|---|---------|----------|
| 1 | Kullanıcı adı ile giriş (e-posta değil) | `username` alanı ile başarılı JWT |
| 2 | E-posta ile giriş | `email` alanı |
| 3 | Profil → alınan hediyeler | `GET /api/user/received-gifts` verisi |
| 4 | Sesli oda 25+ dk | Heartbeat sonrası düşmeme |
| 5 | İki cihaz sesli oda | Koltuk/mic/presence senkron |
| 6 | SSE `seat_update` (web'den koltuk değişimi) | Flutter koltuk grid güncellenir |
| 7 | PK skor SSE | Her iki tarafta skor barı |
| 8 | Hediye gönder (oda + canlı) | Host/guest aynı animasyon + bakiye |
| 9 | 401 → refresh → SSE yeniden bağlan | Kılavuz §1/§6 |
| 10 | Karşılıklı hediye API | `checkReciprocal` yanıtı (UI yok, curl/Postman) |

---

## 7. Riskli değişiklikler

| Değişiklik | Risk | Azaltma |
|------------|------|---------|
| Giriş `emailOrUsername` → `username` | Eski backend yalnızca `emailOrUsername` kabul ediyorsa giriş kırılır | Üretim `mobile-login` kılavuz şemasını kullanıyor |
| `received-gifts` yol değişimi | Eski uç kapanırsa | Fallback `/api/users/me/gifts-received` korundu |
| Heartbeat 12→25 sn | Redis presence TTL daha kısaysa geç düşme | Backend TTL ile uyumlu olmalı (20–30 sn bandı) |
| `seat_update` → tam seats refresh | Ek API yükü | Yalnızca SSE olayında; debounce eklenebilir |

---

## 8. Performans iyileştirmeleri

| İyileştirme | Etki |
|-------------|------|
| Heartbeat 12→25 sn | ~%52 daha az presence isteği / kullanıcı / oda |
| Backend-authoritative state | Optimistic patch + çift fetch azaltıldı (önceki oturum) |
| Tek hediye event bus | Yinelenen poll/SSE dinleyicileri birleştirildi |
| **Öneri (kalan):** `seat_update` debounce 300 ms | Ardışık SSE'de seats spam önleme |
| **Öneri:** Kullanılmayan Socket.IO yollarını temizle | Bellek + bağlantı |

---

## 9. Kalan teknik borç

1. **Kılavuz §9 tam tarama** — tüm repository metotlarının `api_endpoints.dart` + datasource ile 1:1 eşleşmesi
2. **Hardcoded path temizliği** — `chat_room_remote_datasource.dart` içindeki inline `/api/chat/rooms/...` → `ApiEndpoints`
3. **verify-device / reclaim-device** — backend şema netleşince auth akışına ekleme
4. **Koltuk UI** — `seatSlots` birincil kaynak; `presence.seatIndex` legacy birleştirme
5. **Live heartbeat** — `POST /api/live/heartbeat` vs `video-streams/join` — tek strateji
6. **Analyzer uyarıları** — `@Deprecated meGiftsReceived` kullanım yerlerini `userReceivedGifts`'e taşı
7. **E2E test** — web + Flutter aynı odada otomasyon yok
8. **PART11–13 premium özellikler** — kozmetik, 2026 premium UI — kısmi

---

## 10. Modül bazlı endpoint doğrulama özeti

### ✅ Doğrulanmış (kılavuz ile uyumlu)
- Auth: `mobile-login`, `mobile-register`, `mobile-refresh`, `logout`, `change-password`
- Chat room: `presence`, `seats`, `voice`, `messages`, `stream` (SSE), `gifts`, `pk`, `music`, `dj`, `moderation`
- Live stream: `video-streams/*`, SSE, gifts, comments, join/leave
- Gifts: `gifts/types`, `gifts/send`, `gifts/recent-big`
- Fortune: `fortunes/*`, `horoscope/daily`
- Notifications: `notifications`, `notifications/stream`

### ⚠️ Kısmi / çoklu yol
- TRTC: `/api/trtc/token` + state snapshot içi credentials
- PK: `/api/chat/rooms/.../pk`, `/api/video-streams/pk`, `/api/pk/*`, `/api/live/pk/*`
- Profil istatistik: `/api/user/stats` vs `/api/users/me/stats`

### ❌ Dokümante ama mobilde yok / eksik
- `verify-device`, `reclaim-device`
- `POST /api/presence` (site geneli)
- `check-reciprocal` UI entegrasyonu
- Admin panel tam mobil karşılığı (PART8)

---

## 11. Sonraki faz önerisi (Faz 2)

1. `chat_room_remote_datasource` — tüm path'leri `ApiEndpoints`'e taşı; kılavuz dışı uçları işaretle
2. Auth — verify/reclaim device (backend metot doğrulaması sonrası)
3. Profil — `/api/users/me/*` → `/api/user/*` birincil (activity, broadcast-history)
4. Gift UI — `checkReciprocal` hediye gönder öncesi
5. Kılavuz güncellemesi — `GET /state`, `room_event` SSE şeması
6. Analyzer sıfır uyarı + `flutter test` tam yeşil

---

## 12. Referans dosyalar

| Dosya | Rol |
|-------|-----|
| `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` | Tek API kaynağı |
| `docs/FLUTTER_VOICE_ROOM_SYNC_REPORT.md` | Sesli oda senkron detayı |
| `mobile/lib/core/network/api_endpoints.dart` | Merkezi uç sabitleri |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_room_sync.dart` | State/seats/SSE |
| `mobile/lib/features/gifts/presentation/sync/` | Hediye event bus |

---

*Bu rapor otomatik denetim + kod incelemesi ile üretilmiştir. Üretim davranışı için canlifal.com envanter raporu ve canlı API testi esas alınmalıdır.*
