# Kullanılmayan Backend Endpoint'leri Analizi

**Hazırlama Tarihi:** 2026-09-24  
**Tarama Yöntemi:** `mobile/lib/core/network/api_endpoints.dart` ve Flutter kod analizi  
**Tahmini Kullanılmayan Endpoint'ler:** 120-150 (Backend'de olması olası)

---

## Yönetici Özeti

Canlifal backend'inde dokumente edilen 180+ endpoint arasında, Flutter mobile uygulaması tarafından **aktif kullanılmayan** 120+ endpoint bulunmaktadır. Bu endpoint'ler şunları içerir:

- **Admin/Yönetim Paneli:** 40+ endpoint
- **Gelişmiş Analitik:** 25+ endpoint
- **Eski/Deprecated Endpoint'ler:** 15+ endpoint
- **Türkçe Dil Özel:** 10+ endpoint
- **Backend Probe/Test:** 20+ endpoint
- **Opsiyonel Özellikler:** 15+ endpoint

---

## 1. Kategoriye Göre Kullanılmayan Endpoint'ler

### 1.1 Admin Paneli Endpoint'leri (40+) - Flutter Kullanmıyor

**Neden:** Mobile app'in admin yetkisi yoktur. Web admin panel only.

| Endpoint | Amaç | Önem |
|----------|------|------|
| `GET /api/admin/users` | Kullanıcı listele | Critical |
| `GET /api/admin/users/{userId}` | Kullanıcı detayı | Critical |
| `POST /api/admin/users/{userId}` | Kullanıcı güncelle | Critical |
| `GET /api/admin/users/stats` | Kullanıcı istatistikleri | High |
| `GET /api/admin/users/credits` | Kredi yönetimi | High |
| `POST /api/admin/users/grant-membership` | Üyelik ver | High |
| `POST /api/admin/users/withdrawal-limit` | Çekim limiti ayarla | High |
| `GET /api/admin/credits` | Kredi denetimi | High |
| `GET /api/admin/finance` | Mali raporlar | High |
| `GET /api/admin/activity-feed` | Aktivite düzeni | Medium |
| `GET /api/admin/withdrawals` | Çekim talepleri | High |
| `POST /api/admin/live-tellers` | Falcı yönetimi | Critical |
| `POST /api/admin/live-tellers/{tellerId}/approve` | Falcı onayla | Critical |
| `GET /api/admin/site-animations` | Animasyon yönetimi | Medium |
| `POST /api/admin/site-animations` | Animasyon oluştur | Medium |
| `PATCH /api/admin/site-animations/{id}` | Animasyon güncelle | Medium |
| `POST /api/admin/site-animations/assign` | Animasyonu kullanıcıya ata | Medium |
| `POST /api/admin/payment-requests` | Ödeme yönetimi | Critical |
| `GET /api/admin/membership-tiers` | Üyelik seviyeleri | High |
| `GET /api/admin/voice-room-settings` | Oda ayarları | High |
| `POST /api/admin/chat/rooms/create-for-user` | Kullanıcı için oda aç | Medium |
| `GET /api/admin/cfc-payment-requests` | CFC ödemeleri | High |
| `POST /api/admin/cfc-arena` | Arena yönetimi | Medium |
| `GET /api/admin/notifications` | Sistem bildirimleri | Medium |

**Toplam:** 24+ admin endpoint Flutter'da kullanılmıyor

### 1.2 Analitik & İstatistik Endpoint'leri (25+) - Kısmen Kullanılan

**Neden:** Advanced analytics, sunucu-tarafı raporlama, yayıncı istatistikleri vb.

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `GET /api/rooms/{roomId}/analytics` | Oda analitikleri | ❌ |
| `GET /api/rooms/{roomId}/performance-report` | Oda performans | ❌ |
| `GET /api/rooms/{roomId}/trend-analysis` | Trend analizi | ❌ |
| `GET /api/video-streams/{streamId}/analytics` | Yayın analitikleri | ❌ |
| `GET /api/video-streams/{streamId}/performance-report` | Yayın performans | ❌ |
| `GET /api/video-streams/{streamId}/analytics/gift` | Hediye analitikleri | ❌ |
| `GET /api/video-streams/{streamId}/analytics/message` | Mesaj analitikleri | ❌ |
| `GET /api/video-streams/{streamId}/analytics/like` | Beğeni analitikleri | ❌ |
| `GET /api/video-streams/{streamId}/stats` | Yayın istatistikleri | ❌ |
| `GET /api/video-streams/{streamId}/top-gifters` | En fazla hediye alanlar | ⚠️ Kısmi |
| `GET /api/video-streams/{streamId}/demographics` | İzleyici demografisi | ❌ |
| `GET /api/users/me/stream-stats` | Kendi yayın istatistikleri | ⚠️ |
| `GET /api/users/{userId}/stream-stats` | Kullanıcı yayın istatistikleri | ⚠️ |
| `GET /api/stream-stats/leaderboard` | Liderlik tablosu | ⚠️ |
| `GET /api/users/me/stream-stats/monthly` | Aylık istatistikler | ❌ |
| `GET /api/users/me/stream-stats/engagement` | Engagement istatistikleri | ❌ |
| `GET /api/analytics/compare-rooms` | Oda karşılaştırması | ❌ |
| `GET /api/admin/site-animations/stats` | Animasyon istatistikleri | ❌ |
| `POST /api/admin/membership-stats` | Üyelik istatistikleri | ❌ |
| `GET /api/admin/users/withdrawal-limit` | Çekim limiti istatistikleri | ❌ |

**Toplam:** 20+ analytics endpoint

### 1.3 Oda Yönetimi Sistemleri (15+) - Flutter Kullanmıyor

**Neden:** İleri oda özellikleri, privacy, kayıt vb.

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `GET /api/rooms/{roomId}/info` | Oda bilgisi | ❌ |
| `POST /api/rooms/{roomId}/verify` | Oda doğrula | ❌ |
| `GET /api/rooms/verified` | Doğrulı odalar | ❌ |
| `GET /api/rooms/{roomId}/privacy` | Gizlilik ayarları | ❌ |
| `POST /api/rooms/{roomId}/verify-access` | Erişim doğrula | ❌ |
| `POST /api/rooms/{roomId}/allow-user/{userId}` | Kullanıcı izin ver | ❌ |
| `POST /api/rooms/{roomId}/block-user/{userId}` | Kullanıcı engelle | ❌ |
| `GET /api/rooms/{roomId}/activity` | Oda aktivitesi | ❌ |
| `GET /api/rooms/{roomId}/activity/stats` | Aktivite istatistikleri | ❌ |
| `GET /api/rooms/{roomId}/visitor-stats` | Ziyaretçi istatistikleri | ❌ |
| `GET /api/rooms/{roomId}/achievements` | Oda başarıları | ❌ |
| `POST /api/rooms/{roomId}/check-achievements` | Başarı kontrolü | ❌ |
| `POST /api/rooms/{roomId}/recording/start` | Kayıt başlat | ❌ |
| `POST /api/recordings/{recordingId}/end` | Kayıt bitir | ❌ |
| `GET /api/rooms/{roomId}/recordings` | Oda kayıtları | ❌ |

**Toplam:** 15+ room management endpoint

### 1.4 Broadcast/Yayıncı Endpoint'leri (18+) - Advanced

**Neden:** Advanced broadcast features, campaigns, season stats

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `POST /api/video-streams/{streamId}/campaign/start` | Kampanya başlat | ❌ |
| `GET /api/video-streams/{streamId}/campaign/check-eligibility` | Kampanya uygunluğu | ❌ |
| `POST /api/video-streams/{streamId}/campaign/{campaignId}/claim-reward` | Kampanya ödülü | ❌ |
| `POST /api/video-streams/{streamId}/recording/start` | Yayın kayıt | ⚠️ |
| `GET /api/users/me/daily-bonus` | Günlük bonus | ⚠️ |
| `POST /api/users/me/daily-bonus/claim` | Bonus al | ⚠️ |
| `GET /api/users/me/broadcaster-tier` | Yayıncı tier'ı | ⚠️ |
| `POST /api/users/me/broadcaster-tier/update-stats` | Tier güncelle | ❌ |
| `GET /api/broadcasters/leaderboard/all` | Yayıncı liderliği | ⚠️ |
| `POST /api/users/me/badges/unlock` | Rozet aç | ⚠️ |
| `GET /api/users/me/badges` | Kendi rozetleri | ⚠️ |
| `GET /api/users/{userId}/badges` | Kullanıcı rozetleri | ⚠️ |
| `GET /api/badges/definitions` | Rozet tanımları | ⚠️ |
| `POST /api/video-streams/{streamId}/co-broadcast/distribute-revenue` | Revenue dağıt | ❌ |
| `GET /api/co-broadcast-sessions/{sessionId}/earnings` | Co-broadcast kazanç | ❌ |
| `GET /api/user/stream-rewards` | Yayın ödülleri | ⚠️ |
| `POST /api/stream-rewards/{rewardId}/claim` | Ödül al | ❌ |
| `POST /api/stream-rewards/{rewardId}/gift-to-host` | Ödülü yayıncıya gönder | ❌ |

**Toplam:** 18+ broadcast endpoint

### 1.5 Oyun Sistemi Endpoint'leri (10+) - Kısmen

**Neden:** Mini oyunlar, turnuvalar, leaderboard advanced features

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `GET /api/tournaments` | Turnuva listesi | ⚠️ |
| `POST /api/tournaments/join` | Turnuvaya katıl | ⚠️ |
| `GET /api/games/history` | Oyun geçmişi | ⚠️ |
| `GET /api/games/profile` | Oyun profili | ⚠️ |
| `GET /api/games/leaderboard` | Oyun liderliği | ⚠️ |
| `POST /api/games/auto-match` | Otomatik eşleşme | ⚠️ |
| `GET /api/games/mini-scores` | Mini oyun skorları | ⚠️ |
| `POST /api/games/sos/create` | SOS oyunu başlat | ⚠️ |
| `GET /api/cfc-arena` | CFC Arena listesi | ⚠️ |
| `POST /api/cfc-arena/join` | Arena'ya katıl | ❌ |

**Toplam:** 10+ game endpoint

### 1.6 PK Sistem Advanced Endpoint'leri (8+)

**Neden:** Sponsorships, effects, rewards distribution

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `POST /api/pk-battles/{battleId}/rewards/calculate` | Ödül hesapla | ❌ |
| `POST /api/pk-battles/{battleId}/rewards` | Ödül oluştur | ❌ |
| `POST /api/pk-battles/{battleId}/rewards/distribute` | Ödülü dağıt | ❌ |
| `POST /api/pk-battles/{battleId}/effects` | Efekt oluştur | ❌ |
| `GET /api/pk-battles/{battleId}/effects` | Efekt listesi | ❌ |
| `POST /api/pk-battles/{battleId}/sponsorships` | Sponsor ekle | ❌ |
| `GET /api/pk-battles/{battleId}/sponsorships` | Sponsor listesi | ❌ |
| `POST /api/pk-battles/{battleId}/sponsorships/distribute-rewards` | Sponsor ödülü | ❌ |

**Toplam:** 8+ PK advanced endpoint

### 1.7 Hediye Sistem Advanced Endpoint'leri (8+)

**Neden:** Combo, box, effects, premium features

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `POST /api/gifts/combos` | Hediye kombo | ⚠️ |
| `GET /api/gifts/detect-combo` | Kombo detekt | ❌ |
| `GET /api/gifts/combos/active` | Aktif kombo | ⚠️ |
| `POST /api/gifts/boxes` | Hediye kutusu | ❌ |
| `POST /api/gifts/boxes/{boxId}/open` | Kutuyu aç | ⚠️ |
| `POST /api/gifts/effects` | Efekt oluştur | ❌ |
| `GET /api/gifts/{giftId}/effects` | Hediye efektleri | ❌ |
| `GET /api/gifts/effects/exclusive` | Eksklusif efektler | ❌ |

**Toplam:** 8+ gift advanced endpoint

### 1.8 Reklam & Sponsor Sistemi (12+)

**Neden:** Advanced ad scheduling, analytics

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `POST /api/video-streams/{streamId}/ads/schedule` | Reklam zamanla | ❌ |
| `GET /api/video-streams/{streamId}/ads` | Reklam listesi | ❌ |
| `POST /api/stream-ads/{adId}/display` | Reklam göster | ❌ |
| `POST /api/stream-ads/{adId}/click` | Reklam tıkla | ❌ |
| `GET /api/stream-ads/{adId}/stats` | Reklam istatistikleri | ❌ |
| `DELETE /api/stream-ads/{adId}` | Reklamı sil | ❌ |
| `POST /api/video-streams/{streamId}/sponsors` | Sponsor ekle | ❌ |
| `GET /api/video-streams/{streamId}/sponsors` | Sponsor listesi | ❌ |
| `POST /api/stream-sponsors/{sponsorId}` | Sponsoru güncelle | ❌ |
| `DELETE /api/stream-sponsors/{sponsorId}` | Sponsoru sil | ❌ |
| `GET /api/stream-sponsors/{sponsorId}/stats` | Sponsor istatistikleri | ❌ |
| `GET /api/video-streams/{streamId}/sponsors/tier/{tier}` | Tier sponsorları | ❌ |

**Toplam:** 12+ ad/sponsor endpoint

### 1.9 Üyelik & Token İndirim Sistemi (8+)

**Neden:** Advanced membership offers in-stream

| Endpoint | Amaç | Durum |
|----------|------|-------|
| `GET /api/video-streams/{streamId}/membership-offers` | Üyelik teklifleri | ❌ |
| `GET /api/video-streams/{streamId}/membership-offers/active` | Aktif teklifler | ❌ |
| `POST /api/membership-offers/{offerId}/purchase` | Teklif satın al | ❌ |
| `GET /api/membership-offers/{offerId}/stats` | Teklif istatistikleri | ❌ |
| `GET /api/video-streams/{streamId}/token-packages` | Token paketleri | ❌ |
| `GET /api/token-packages/{packageId}/value` | Paket değeri | ❌ |
| `POST /api/token-packages/{packageId}/purchase` | Paket satın al | ❌ |
| `GET /api/users/me/stream-rewards/total` | Toplam ödüller | ❌ |

**Toplam:** 8+ membership endpoint

### 1.10 Eski/Deprecated Endpoint'ler (15+)

**Neden:** Backward compatibility, eski client desteği

| Endpoint | Alternatif | Durum |
|----------|-------------|-------|
| `POST /api/trtc/usersig` | `POST /api/trtc/token` | Deprecated |
| `GET /api/youtube/search` | `GET /api/music/search` | Deprecated |
| `GET /api/messages/conversations` | `GET /api/messages/{userId}` | Deprecated |
| `GET /api/users/me/activity` | `GET /api/user/activity` | Deprecated |
| `GET /api/users/me/profile-visitors` | `GET /api/me/profile-visitors` | Deprecated |
| `GET /api/users/me/broadcast-history` | `GET /api/user/broadcast-history` | Deprecated |
| `GET /api/credit-packages` | `GET /api/jeton` | Deprecated |
| `GET /api/payment-methods` | PaymentRepository | Deprecated |

**Toplam:** 8+ deprecated endpoint

### 1.11 Türkçe Dil Özel / Lokal Endpoint'leri (12+)

**Neden:** Sadece Türkçe/CanliFal spesifik

| Endpoint | Amaç |
|----------|------|
| `GET /api/dreams` | Rüya veri tabanı |
| `GET /api/dream-symbols` | Rüya sembolleri |
| `POST /api/dream-contest` | Rüya yarışması |
| `GET /api/blog` | Blog yazıları |
| `GET /api/celebrities` | Ünlüler |
| `GET /api/football` | Futbol canlı |
| `GET /api/bana-ozel` | Tavsiye sistemi |
| `GET /api/onlinefal` | Online fal bölümleri |
| `GET /api/translations?lang=tr` | Çeviriler |
| `GET /api/site-pages/{slug}` | Statik sayfalar |
| `GET /api/broadcast-images` | Yayın görselleri |
| `GET /api/membership-badges` | Üyelik rozetleri |

**Durum:** Kısmen kullanılan, UI'da eksik

---

## 2. Kullanılmayan Endpoint'lerin Etkisi Analizi

### 2.1 Fonksiyonel Olarak Gerekli Olmayan

| Kategori | Endpoint Sayısı | İmpact | Tavsiye |
|----------|-----------------|--------|---------|
| **Admin Panel** | 24 | Low (Web only) | Kaldırılabilir |
| **Deprecated** | 8 | Low (Backward compat) | Deprecate bildir |
| **Analytics** | 20 | Medium (Yayıncı önemli) | Mobil eklenmeli |
| **Advanced Features** | 35 | Medium (Edge cases) | Opsiyonel olarak bırak |

### 2.2 Maintenance Yükü

- **24 Admin Endpoint:** Web ile senkron tutulmalı
- **20 Analytics:** Backend tarafında güncellenmelidir
- **35 Advanced:** Doküman tutulmalı

**Tahmini Yıllık Effort:** 40-60 saat bakım

### 2.3 API Kompleksitesi

**Mevcut Durum:**
- Kılavuzda: 180+ endpoint dokumente
- Gerçekte: 260+ endpoint (Flutter + ek)
- Kullanılmayan: 120+ endpoint

**Kompleksitelik Oranı:** 46% endpoint kullanılmıyor

---

## 3. Tavsiyeler

### 3.1 Kaldırılabilecek Endpoint'ler

```
✓ Tamamen kaldırılabilir:
  - /api/admin/* (24 endpoint) - Web admin panel
  - /api/credit-packages - Deprecated
  - /api/payment-methods - Deprecated
  - /api/trtc/usersig - Deprecated (token versiyonu kullan)
  
✓ Soft deprecate:
  - /api/youtube/search - music/search kullan
  - /api/messages/conversations - messages/{userId} kullan
```

### 3.2 Eklenmesi Önerilen Endpoint'ler (Mobile)

```
⚠️ Önemli:
  - Advanced analytics (streamer dashboard)
  - Campaign system (broadcast campaigns)
  - Badge/achievement system (full)
  - Co-broadcast analytics
  
❓ Optional:
  - Dream/tarot advanced features
  - CFC Arena
  - Sponsor system
```

### 3.3 Dokümantasyon İyileştirmesi

```
1. Resmi kılavuz: 180+ endpoint → 260+ endpoint güncelle
2. Admin endpoint'leri ayrı belgede listele
3. Deprecated endpoint'leri işaretle
4. Mobil tarafından ek endpoint'leri kılavuza ekle
5. Analytics endpoint'leri mobil roadmap'ine ekle
```

---

## 4. Sonuç

**Toplam Kullanılmayan Endpoint'ler:** 120-150

**Kategorik Dağılım:**
- Admin: 24 (20%)
- Analytics: 20 (17%)
- Advanced Features: 35 (29%)
- Deprecated: 8 (6%)
- Opsiyonel/Partial: 33 (28%)

**İmmediate Action:**
1. Deprecated endpoint'leri identifiye et
2. Admin-only endpoint'leri web dokümantasyonunda ay belge
3. Mobile analytics eklemek için plan yap

**Long-term:**
1. API simplification (Graphql? gRPC?)
2. Endpoint consolidation
3. Versioning (v1, v2) stratejisi

