# Premium Özellikler — Eksiklik Tespiti (19 Temmuz 2026)

> **Mobil sürüm:** `1.0.57+84`  
> **Kılavuz:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](./FLUTTER_ENTegrasyon_KILAVUZU.md)  
> **Önemli:** Bu repo yalnızca Flutter istemcisidir. Aşağıdaki **Backend gerekli** satırlar `canlifal.com` deploy’u olmadan tamamlanamaz.

---

## Özet tablo

| Alan | Mobil | Backend API | Üretimde API | Bloker |
|------|-------|-------------|--------------|--------|
| Giriş efektleri (ejderha, meteor…) | ✅ | — | — | Başkaları için SSE `entranceEffectId` |
| Sohbet balonu / mikrofon skin / emoji | ✅ | — | — | Emoji paketi slot roadmap |
| Hediye kombo / global bildirim | ✅ Kısmen | `/api/gifts/insights/leaderboard` | ✅ | Global şerit eşiği |
| Rozet (Kurucu, İlk 100…) | ✅ | `/api/user/achievements`, `/api/membership-badges` | ✅ | Başarım + üyelik şeridi |
| Admin GIF/Lottie yükleme | 🔵 Web admin | `/api/admin/*` | ✅ | Mobil WebView SSO |
| Kozmetik equip (cihazlar arası) | 🟡 Yerel + push | **YOK** | **404** | `POST equip` endpoint |
| Web admin SSO | 🟡 Bootstrap | **YOK** | **404** | `web-session` endpoint |
| XP / görevler / başarım | ✅ | `/api/user/xp`, `/api/daily-missions`, `/api/user/achievements` | ✅ | Growth hub mevcut |
| Ziyaretçi defteri | ✅ | `/api/users/me/profile-visitors` | ✅ | Sayfa mevcut |
| 3D avatar | ❌ | — | — | Roadmap |

---

## 1. Giriş efektleri

| Bileşen | Durum | Dosya / API |
|---------|-------|-------------|
| Katalog (altın yağmuru, havai fişek, galaksi, taç) | ✅ | `cosmetic_catalog_defaults.dart` |
| Ejderha / meteor / kanat katalog | 📋 | Eklenecek |
| Gold seçim UI | ❌ | `profile_cosmetics_page` — giriş sekmesi yok |
| `resolvedEntranceProvider` | ❌ | — |
| Odaya girişte tam ekran animasyon | 🟡 | `VipEntranceOverlay` yalnızca VIP tier; kozmetik bağlı değil |
| Başkalarının giriş efektini görme | ❌ | SSE/presence’te `entranceId` alanı yok (backend) |

**Backend gerekli (ileride):** Presence veya chat SSE olayında `entranceEffectId` / `cosmeticLoadout` alanı.

---

## 2. Sohbet balonu / mikrofon / emoji

| Slot | Enum | Katalog | UI seçim | Uygulama |
|------|------|---------|----------|----------|
| `chatBubble` | ✅ | ❌ | ❌ | Sohbet balonu render yok |
| `microphoneFrame` | ✅ | ❌ | ❌ | Koltuk mic çerçevesi yok |
| Emoji paketi | ❌ slot yok | — | — | `CosmeticSlot` genişletilmeli |

---

## 3. Hediye sistemi

| Özellik | Mobil | API |
|---------|-------|-----|
| Tam ekran Lottie/SVGA | ✅ | `/api/gifts` katalog |
| Combo sayacı | ✅ | `voice_gift_combo_tracker`, `LiveGiftEvent.combo` |
| Global duyuru (1000+ jeton) | ✅ | `staff_entrance_marquee_provider` |
| Günlük/haftalık/aylık sıralama | ✅ | `/gifts/leaderboard`, `gift_leaderboard_hub_page` |
| Hediye koleksiyonu | ✅ | `/api/gifts/insights/collection/{userId}` |
| Zincir / kombo admin flag | ✅ | `comboEnabled` admin hediye editörü |

**Eksik:** Tüm odalarda otomatik global toast (şu an büyük hediyeler marquee ile).

---

## 4. Rozet sistemi

| Tür | API | Mobil gösterim |
|-----|-----|----------------|
| Üyelik rozeti (Gold, Premium…) | `GET /api/membership-badges` | 🟡 Yalnızca tier chip profil başlığında |
| Başarım rozeti (Founder, İlk 100…) | `GET /api/user/achievements` | ✅ `ProfileHubBadgesSection` |
| Admin atanan özel rozet | Admin web | ❌ Mobil parse/gösterim yok |
| Profilde rozet şeridi (tümü) | — | ❌ |

---

## 5. Admin paneli & dinamik içerik

| Özellik | Durum |
|---------|-------|
| Web admin (GIF/Lottie/kampanya) | 🔵 `canlifal.com/admin` |
| Mobil WebView admin | ✅ `/admin/web` |
| JWT → NextAuth SSO | ❌ `GET /api/mobile/auth/web-session` → **404** |
| `GET /api/profile-frames` | ✅ Auth gerekli; mobil merge + cache |
| Kozmetik equip sunucuya kayıt | ❌ Tüm equip path’leri **404** |

### Backend’de oluşturulması gereken uçlar (öneri)

```
POST /api/user/cosmetics/equip     { "slot": "profileFrame", "itemId": "..." }
GET  /api/user/cosmetics/loadout   → { "equipped": { ... } }
POST /api/mobile/auth/web-session  { "accessToken" } → Set-Cookie veya redirect URL
```

Kılavuzda henüz tanımlı değil — backend eklenmeden mobil yalnızca `SharedPreferences` kullanır.

---

## 6. XP, görevler, ziyaretçi, 3D

| Özellik | Mobil | API |
|---------|-------|-----|
| XP / Level | ✅ | `GET /api/user/xp` — `GrowthHubPage` |
| Günlük görevler | ✅ | `GET /api/daily-missions` |
| Başarımlar | ✅ | `GET /api/user/achievements` |
| Ziyaretçi listesi | ✅ | `GET /api/users/me/profile-visitors` |
| Ziyaretçi defteri (yorum) | ❌ | API kılavuzda yok |
| 3D avatar | ❌ | — |

---

## 7. Bu oturumda mobilde yapılacaklar (backend beklemeden)

1. Giriş efekti seçim sekmesi + `resolvedEntranceEffectProvider`
2. `CosmeticEntranceOverlay` + sesli oda girişine bağlama
3. Sohbet balonu / mikrofon varsayılan katalog + seçim sekmesi
4. Üyelik rozetleri profil şeridi (`membership-badges` API)
5. Katalog genişletme (ejderha, meteor, kanat giriş efektleri)
6. Equip: yerel + **hazır** remote sync denemesi (404’te sessiz fallback)

---

## 8. Backend ekibi için öncelik sırası

1. `POST /api/user/cosmetics/equip` + `GET loadout`
2. `POST /api/mobile/auth/web-session` (WebView admin SSO)
3. Presence/SSE: kullanıcı `entranceEffectId` (diğerlerinin giriş FX’ini görmek için)
4. Admin: kozmetik asset upload (GIF/Lottie/APNG) → `profile-frames` API’ye `assetUrl`

---

*Son güncelleme: otomatik tespit + kod taraması.*
