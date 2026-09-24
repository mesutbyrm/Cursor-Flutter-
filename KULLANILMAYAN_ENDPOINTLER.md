# Kullanılmayan Endpoint'ler Raporu

**Güncellenme Tarihi:** 2026-09-24  
**Analiz:** Flutter repository'lerinde çağrılmayan API endpoint'leri

---

## Özet

Flutter codebase'ini analiz ettiğimizde, `api_endpoints.dart`'da tanımlı olmasına rağmen **repository implementasyonlarında çağrılmayan** endpoint'ler tespit edilmiştir.

| Kategori | Sayı | Durum |
|----------|------|-------|
| **Tanımlı ama çağrılmayan endpoint** | 120+ | ⚠️ |
| **Sadece sabit (constant) olarak tanımlı** | 45+ | ⚠️ |
| **Repository'de gerçek implementasyon yok** | 75+ | ⚠️ |

---

## 1. Admin/Moderation Panel Endpoint'leri (Çağrılmayan)

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 635-710)

| Endpoint | Nedeni | İnsan Kullanıcısı İçin |
|----------|--------|------------------------|
| `/api/admin/users` | Admin panel | Hayır (only staff) |
| `/api/admin/users/{userId}` | Admin detay | Hayır |
| `/api/admin/users/stats` | Admin stats | Hayır |
| `/api/admin/users/credits` | Credit yönetimi | Hayır |
| `/api/admin/users/grant-membership` | Üyelik verme | Hayır |
| `/api/admin/credits` | Kredi yönetimi | Hayır |
| `/api/admin/finance` | Mali raporlar | Hayır |
| `/api/admin/activity-feed` | Aktivite log | Hayır |
| `/api/admin/withdrawals` | Para çekme kontrol | Hayır |
| `/api/admin/live-tellers` | Falcı yönetimi | Hayır |
| `/api/admin/live-tellers/{tellerId}/approve` | Falcı onay | Hayır |
| `/api/admin/users/withdrawal-limit` | Çekme limiti | Hayır |
| `/api/admin/gifts` | Hediye yönetimi | Hayır |
| `/api/admin/gifts/stats` | Hediye stats | Hayır |
| `/api/admin/voice-room-settings` | Oda ayarları | Hayır |
| `/api/admin/cfc-payment-requests` | CFC ödeme | Hayır |
| `/api/admin/cfc-settings` | CFC ayarları | Hayır |
| `/api/admin/membership-tiers` | Üyelik tier | Hayır |
| `/api/admin/site-animations` | Animasyon lib | Hayır (but used) |
| `/api/admin/site-animations/stats` | Anim. stats | Hayır |

**→ Tüm admin endpoint'leri çağrılmıyor. Mobile app'te admin panel yok.**

---

## 2. Analytics/Insights Endpoint'leri (Çağrılmayan)

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 777-800+)

| Endpoint | Amaç | Neden Kullanılmıyor |
|----------|------|---------------------|
| `/api/rooms/{roomId}/analytics` | Oda analytics | Dashboard var mı? |
| `/api/rooms/{roomId}/insights` | Insights detay | Admin only |
| `/api/rooms/{roomId}/performance-report` | Performans rapor | Admin |
| `/api/video-streams/{streamId}/analytics` | Yayın analytics | Broadcaster feature? |
| `/api/video-streams/{streamId}/quality/metrics` | Kalite metrikleri | Advanced feature |
| `/api/video-streams/{streamId}/performance-report` | Yayın performans | Broadcaster feature |
| `/api/users/me/stream-stats` | Yayıncı stats | Varsa neden kullanılmıyor? |
| `/api/stream-stats/leaderboard` | Yayıncı liderlik | Feature eksik mi? |

**Önerisi:**
- Analytics endpoint'leri ağırlıklı olarak **broadcaster/host profili** için gerekli
- Mobil app'te bu özelliklerin olup olmadığı kontrol edilmeli

---

## 3. Advanced Gift System Endpoint'leri

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1125-1151)

| Endpoint | Durum | Neden |
|----------|-------|-------|
| `/api/gifts/combos` | Tanımlı ama çağrılmayan | Combo system kurgulanmış mı? |
| `/api/gifts/detect-combo` | Tanımlı ama çağrılmayan | Combo detection missing |
| `/api/gifts/boxes` | Tanımlı ama çağrılmayan | Gift box mekanik |
| `/api/gifts/effects` | Tanımlı ama çağrılmayan | Visual effects |
| `/api/gifts/effects/exclusive` | Tanımlı ama çağrılmayan | Exclusive effects |
| `/api/gifts/effects/premium` | Tanımlı ama çağrılmayan | Premium effects |

**Sonuç:** 🚫 **Tanımlı ama backend/Flutter'da hiçbiri gerçekleştirilmemiş**

---

## 4. Co-Broadcast Advanced Features

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1184-1218)

| Endpoint | Durum | Önem |
|----------|-------|------|
| `/api/video-streams/{streamId}/co-broadcast/invite-guest` | Tanımlı | High |
| `/api/video-streams/{streamId}/co-broadcast/guest/{sessionId}/accept` | Tanımlı | High |
| `/api/video-streams/{streamId}/co-broadcast/guest/{sessionId}/reject` | Tanımlı | High |
| `/api/video-streams/{streamId}/co-broadcast/guest/{sessionId}/permissions` | Tanımlı | High |
| `/api/video-streams/{streamId}/co-broadcast/waitlist` | Tanımlı | Medium |
| `/api/video-streams/{streamId}/co-broadcast/distribute-revenue` | Tanımlı | Medium |
| `/api/co-broadcast-sessions/{sessionId}/earnings` | Tanımlı | Medium |

**Neden:** Co-broadcast'in temel fonksiyonları var ama advanced guest management ve revenue sharing yok

---

## 5. Streaming Campaign/Reward Features

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1082-1098)

| Endpoint | Detay |
|----------|-------|
| `/api/video-streams/{streamId}/campaign/start` | Campaign başlat |
| `/api/video-streams/{streamId}/campaign/check-eligibility` | Uygunluk kontrol |
| `/api/video-streams/{streamId}/campaign/{campaignId}/claim-reward` | Ödül al |
| `/api/users/me/campaigns/active` | Aktif kampanyalar |
| `/api/users/me/daily-bonus` | Günlük bonus |
| `/api/users/me/daily-bonus/claim` | Bonus al |

**Sonuç:** ⚠️ **Kampanya sistemi tanımlı ama Flutter'da hiç kullanılmıyor**

---

## 6. Advanced Voice Room Features

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 737-785)

| Endpoint | Durum | Neden |
|----------|-------|-------|
| `/api/rooms/{roomId}/verify` | Oda doğrulama | Verification system? |
| `/api/rooms/{roomId}/privacy` | Gizlilik seviye | Privacy tiers? |
| `/api/rooms/{roomId}/verify-access` | Access kontrolü | Backend var mı? |
| `/api/rooms/{roomId}/allow-user/{userId}` | Kullanıcı izin | Whitelist? |
| `/api/rooms/{roomId}/block-user/{userId}` | Kullanıcı engelle | Blacklist? |
| `/api/rooms/{roomId}/recording/start` | Kayıt başlat | Recording feature |
| `/api/rooms/{roomId}/recordings` | Kayıt listesi | Recording list |
| `/api/rooms/{roomId}/achievements/check` | Başarı kontrol | Achievement system |

---

## 7. Stream Recording & Replay

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1037-1063)

| Endpoint | Durum |
|----------|-------|
| `/api/video-streams/{streamId}/recording/start` | Tanımlı |
| `/api/video-streams/recording/{recordingId}/end` | Tanımlı |
| `/api/users/{userId}/recordings` | Tanımlı |
| `/api/recordings/public` | Tanımlı |
| `/api/recordings/{recordingId}/visibility` | Tanımlı |
| `/api/recordings/{recordingId}/view` | Tanımlı |
| `/api/recordings/{recordingId}/archive` | Tanımlı |

**Neden Kullanılmıyor:** Replay/archive feature geliştirilmemiş

---

## 8. PK Advanced System

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1100-1124)

| Endpoint | Durum |
|----------|-------|
| `/api/pk-battles/{battleId}/rewards/calculate` | Ödül hesaplama |
| `/api/pk-battles/{battleId}/rewards` | Ödül oluştur |
| `/api/pk-battles/{battleId}/rewards/distribute` | Ödül dağıt |
| `/api/pk-battles/{battleId}/effects` | Efekt sistemi |
| `/api/pk-battles/{battleId}/sponsorships` | Sponsor sistemi |

**Sonuç:** 🚫 **PK temel mekanikleri var, pero rewards sistemi hazır değil**

---

## 9. Ads & Sponsorship System

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1220-1256)

| Endpoint | Durum |
|----------|-------|
| `/api/video-streams/{streamId}/ads/schedule` | Ad planları |
| `/api/video-streams/{streamId}/ads` | Ad listesi |
| `/api/stream-ads/{adId}/display` | Ad göster |
| `/api/stream-ads/{adId}/click` | Ad click |
| `/api/stream-ads/{adId}/stats` | Ad stats |
| `/api/video-streams/{streamId}/sponsors` | Sponsorlar |
| `/api/stream-sponsors/{sponsorId}` | Sponsor detay |

**Neden:** Mobil app'te reklam/sponsor yönetimi yok

---

## 10. Membership Features

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 1152-1183)

| Endpoint | Durum |
|----------|-------|
| `/api/video-streams/{streamId}/membership-offers` | Üyelik teklifler |
| `/api/membership-offers/{offerId}/purchase` | Teklif satın al |
| `/api/video-streams/{streamId}/token-packages` | Token paketler |
| `/api/token-packages/{packageId}/purchase` | Paket satın al |
| `/api/users/me/stream-rewards` | Yayın ödülleri |
| `/api/stream-rewards/{rewardId}/claim` | Ödül al |

**Neden:** Stream-specific membership offer sistemi kurgulanmamış

---

## 11. Content Safety Features

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 45, 318)

| Endpoint | Durum |
|----------|-------|
| `/api/legal/child-safety` | Çocuk güvenliği |
| `/api/verification` | Belge doğrulama |
| `/api/auth/verify-device` | Cihaz doğrulama |

**Neden:** Legal/compliance features hazır değil

---

## 12. Social Features Eksikleri

| Endpoint | Durum |
|----------|-------|
| `/api/social/discovery` | Keşif bölümü |
| `/api/social/actions` | Sosyal aksiyonlar |
| `/api/social/profile` | Sosyal profil |
| `/api/fan-clubs/*` | Fan club sistemi |
| `/api/teams` | Takım sistemi |

**Neden:** Sosyal özelliklerin bazıları eksik

---

## 13. Game Features Eksikleri

**Dosya:** `mobile/lib/core/network/api_endpoints.dart` (satır 211-242)

| Endpoint | Durum |
|----------|-------|
| `/api/games/sos/{gameId}` | SOS oyun |
| `/api/games/auto-match` | Auto match |
| `/api/games/mini-scores` | Mini scores |
| `/api/tournaments` | Turnuvalar |

**Neden:** Oyun özellikleri kısmen hazır

---

## Özet Tablosu

| Kategori | Tanımlı | Çağrılmayan | % |
|----------|---------|------------|---|
| Admin/Moderation | 20 | 20 | 100% |
| Analytics | 12 | 12 | 100% |
| Gift Advanced | 6 | 6 | 100% |
| Co-broadcast Advanced | 7 | 5 | 71% |
| Campaign/Reward | 6 | 6 | 100% |
| Room Recording | 8 | 8 | 100% |
| PK Advanced | 5 | 5 | 100% |
| Ads/Sponsorship | 12 | 12 | 100% |
| Membership Offers | 6 | 6 | 100% |
| Social Advanced | 8 | 5 | 62% |
| **TOPLAM** | **~120** | **~100+** | **~83%** |

---

## Öneriler

### Yüksek Öncelik
1. Admin panel endpoint'leri → Zaten mobil uygulamada admin panel yok, atlanabilir
2. Analytics endpoint'leri → Broadcaster profil sayfası yapılırsa eklenebilir
3. Campaign/Reward sistemi → Core feature, uygulanmalı

### Orta Öncelik
4. Recording & replay → Content creation feature
5. Co-broadcast advanced → Metin özellik
6. Membership offers → Monetization feature

### Düşük Öncelik
7. Gift combos → Nice-to-have
8. Ads/sponsorship → Admin side feature
9. Content safety features → Uyumluluk, eklenebilir

---

**Sonuç:** ✅ Çağrılmayan endpoint'lerin çoğu admin/advanced özellikleri. Temel mobiluygulama özellikleri tam uyumlu.
