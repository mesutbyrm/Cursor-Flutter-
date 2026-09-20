# Canlı Falcılar Bölümü — Kapsamlı Denetim Raporu

**Tarih:** 2026-09-20  
**Durum:** Kısmen Tamamlanmış (≈ 70%)  
**Toplam Dosya:** 72 Dart dosya

---

## 1️⃣ MEVCUT ÖZELLIKLER

### A. Ekranlar (9 adet)
| Ekran | Rota | Durum | Açıklama |
|-------|------|--------|----------|
| `PsychicsListScreen` | `/canli-falcilar` | ✅ Tamamlandı | Falcı listesi ve arama |
| `PsychicProfileScreen` | `/canli-falcilar/:id` | ✅ Tamamlandı | Falcı profili, puanlar, yorumlar |
| `PsychicTellerDashboardScreen` | `/canli-falcilar/dashboard` | ✅ Tamamlandı | Falcı kontrol paneli, gelen istekler |
| `PsychicVideoSessionScreen` | `/canli-falcilar/:id/session` | ✅ Tamamlandı | Video seans, RTC, gerçek zamanlı sohbet |
| `PsychicWaitingRoute` | `/canli-falcilar/:id/waiting` | ✅ Tamamlandı | Bekleme ekranı (seans başlangıcı öncesi) |
| `PsychicAdTransitionRoute` | `/canli-falcilar/:id/ad-transition` | ✅ Tamamlandı | Reklam geçişi |
| `PsychicApplyScreen` | `/canli-falcilar/apply` | ✅ Tamamlandı | Falcı başvurusu ve onay |
| `PsychicBecomeTellerPage` | `/falci-ol` | ✅ Tamamlandı | Falcı olma formu |
| `PsychicSessionRoute` | İç komponent | ✅ Tamamlandı | Video seans flow |

### B. İş Mantığı & Kontrolörler (7 adet)
- ✅ `psychics_list_controller` — Falcı listesi ve filtreleme
- ✅ `psychic_video_controller` — Video seans kontrolü
- ✅ `psychic_incoming_controller` — Gelen seans istekleri
- ✅ `psychic_invite_poll_gate` — Davet polling mekanizması
- ✅ `psychic_invite_coordinator` — Davet koordinasyonu
- ✅ `psychic_flow` — Seans akışı yönetimi
- ✅ `psychic_push_action_bridge` — Push bildirimi akışı

### C. Veri Yönetimi & Havuzlar (1 adet)
- ✅ `live_psychics_repository_impl` — 30+ API metodu:
  - Falcı listesi, profil, online durumu
  - Seans oluşturma, durumu, geçmişi
  - Gelen istekler, yanıt, iptal
  - Oda sinyalleri, mesajlar, seans uzatma
  - Zaman ekleme, hediyelendirme
  - İnceleme, favori, ödül, gift

### D. Gerçek Zamanlı (Real-time) (5 endpoint)
- ✅ SSE Event Bus — Gelen seans istekleri
- ✅ Seans iptal sinyali
- ✅ Seans bitişi bildirimi
- ✅ Video peer-left algılama
- ✅ Booking geri bildirim

### E. UI Bileşenleri (19 widget)
- ✅ `psychic_favorite_button` — Favori düğmesi
- ✅ `psychic_booking_sheet` — Seans rezervasyon formu
- ✅ `psychic_review_sheet` — Yorum gönderme
- ✅ `psychic_tip_sheet` — Bahşiş verme
- ✅ `psychic_extend_sheet` — Seans uzatma
- ✅ `psychic_incoming_call_dialog` — Gelen çağrı diyaloğu
- ✅ `psychic_video_call_layer` — Video katmanı
- ✅ `psychic_recent_sessions_panel` — Son seanslar
- ✅ `psychic_session_ended_host` — Seans bitişi ekranı
- ✅ `psychic_broadcast_side_rail` — Yayın kontrol paneli
- ✅ `psychic_admin_ad_panel` — Admin reklam yönetimi
- + 8 widget daha

### F. Veri Modelleri
- ✅ `PsychicEntity` — Falcı bilgisi
- ✅ `PsychicSessionEntity` — Seans bilgisi
- ✅ `PsychicRequestEntity` — Seans isteği
- ✅ `PsychicReviewEntity` — Yorum
- ✅ `PsychicAwardEntity` — Ödül
- ✅ `PsychicGiftEntity` — Hediye
- + 5 model daha

---

## 2️⃣ EKSİK ÖZELLIKLER & BOŞLUKLAR

### Faz 1: TEMEL BOŞLUKLAR (2-3 gün)

| # | Özellik | Rota | Kontrol | Çıktı | Öncelik |
|----|---------|------|---------|--------|---------|
| 1 | **Falcı Analitikleri** | `/canli-falcilar/analytics` | Yok | Seans sayısı, gelir, puan trendi | 🔴 P0 |
| 2 | **Kazanç Yönetimi** | `/canli-falcilar/earnings` | Yok | Cüzdan, çekme talepleri, ödeme yöntemi | 🔴 P0 |
| 3 | **Profil Düzenleme** | `/canli-falcilar/dashboard/profile-edit` | Yok | Ad, bio, avatar, kategori, fiyat düzenleme | 🔴 P0 |
| 4 | **Uygunluk Takvimi** | `/canli-falcilar/dashboard/schedule` | Yok | Haftalık/aylık takvim, açık saatler | 🟠 P1 |
| 5 | **Yorum Yönetimi** | `/canli-falcilar/dashboard/reviews` | `fetchReviews` var | Yorum listesi, yanıt, göm, düzenle | 🟠 P1 |

### Faz 2: DESTEKLEYICI ÖZELLIKLER (2-3 gün)

| # | Özellik | Rota | Kontrol | Çıktı | Öncelik |
|----|---------|------|---------|--------|---------|
| 6 | **Müşteri Yönetimi** | `/canli-falcilar/customers` | Yok | Sık müşteriler, blok listesi, notlar | 🟠 P1 |
| 7 | **Oturum Geçmişi** | `/canli-falcilar/sessions` | `fetchRecentSessions` var | Detaylı oturum kayıtları, filtreleme, dışa aktarma | 🟠 P1 |
| 8 | **Promosyon & Kampanya** | `/canli-falcilar/campaigns` | Yok | Kampanya oluştur, kod, indirim, analiz | 🟡 P2 |
| 9 | **Bildirim Ayarları** | `/canli-falcilar/settings/notifications` | Yok | Gelen istek, mesaj, inceleme, kampanya bildirimleri | 🟡 P2 |

### Faz 3: İLERİ ÖZELLİKLER (2-3 gün)

| # | Özellik | Rota | Kontrol | Çıktı | Öncelik |
|----|---------|------|---------|--------|---------|
| 10 | **Başarı Metrikleri** | `/canli-falcilar/dashboard/metrics` | Yok | Yanıt hızı, tamamlanma oranı, iptal, hizmet skoru | 🟡 P2 |
| 11 | **Sertifikalar & Rozetler** | `/canli-falcilar/dashboard/badges` | `fetchAwards` var | Başarı rozetleri, sertifikalar, milestone, ödüller | 🟡 P2 |
| 12 | **Mesajlaşma/Chat** | `/canli-falcilar/:id/message` | Yok | Falcıya özel mesajlaşma, seans öncesi haber | 🟡 P2 |

---

## 3️⃣ KÖK NEDENLER

### A. Rota Eksiklikleri
- **Falcı dashboard alt resimleri:** `profile-edit`, `schedule`, `reviews`, `metrics`, `badges` yönlendirilmiyor
- **Falcı sistemi:** `earnings`, `customers`, `campaigns`, `settings` , `analytics` yolları tanımlanmamış
- **Mesajlaşma:** Seans içi sohbet var ama seans-öncesi/sonrası chat yok

### B. Kontrol Eksiklikleri
- **Profil güncelleme:** Falcı profili salt okunur; `updateProfile()` yok
- **Ödeme/Çekme:** Seans geliri modeli var ama cüzdan/çekme mekanizması yok
- **Takvim:** Kullanılabilirlik yönetimi tamamen eksik
- **Notlar/Blok:** Falcı-müşteri ilişkisi yönetimi yok

### C. Provider Eksiklikleri
- **Falcı ayarları:** Bildirim, veri privacy vb. yok
- **Analitik:** Seans, gelir, trend analizi sağlayıcısı yok
- **Kampanya:** Promosyon/indirim yönetimi yok
- **Metric:** Performans KPI sağlayıcısı yok

### D. UI Eksiklikleri
- **Yazı tipi / Card:** Analitik panolar, detaylı liste, takvim widget yok
- **Form:** Profil editörü, ayarlar formu yok
- **Dialog:** Kampanya seçim/yönetim diyaloğu yok
- **Graph:** Kazanç/trend grafikleri yok

---

## 4️⃣ BACKEND VARSAYIMLARI

**Flutter Entegrasyon Kılavuzu (docs/)** sonrası:

```
POST /api/psychic/{id}/profile — Profil güncelle
GET  /api/psychic/{id}/earnings — Kazanç özeti
POST /api/psychic/{id}/withdraw — Çekme talebi
GET  /api/psychic/{id}/sessions?limit=20 — Oturum geçmişi (filtreleme)
GET  /api/psychic/{id}/schedule — Haftalık takvim
POST /api/psychic/{id}/schedule — Takvim güncelle
GET  /api/psychic/{id}/customers — Müşteri listesi
POST /api/psychic/{id}/customer/{cId}/block — Müşteriyi engelle
GET  /api/psychic/{id}/reviews?page=0 — İnceleme listesi
POST /api/psychic/{id}/review/{rId}/respond — İncelemeye yanıt
GET  /api/psychic/{id}/analytics — Analitik özeti
POST /api/psychic/{id}/campaign — Kampanya oluştur
GET  /api/psychic/{id}/settings/notifications — Bildirim ayarları
PATCH /api/psychic/{id}/settings — Ayarları güncelle
```

---

## 5️⃣ ÖNERİLEN UYGULAMA SIRASI

### **HEMEN (P0 cihaz bitmeden)**
1. ✅ Analitik Panosu (Faz 1-1) — Seans/gelir grafiği → Falcı motivasyonu
2. ✅ Profil Düzenleme (Faz 1-3) — Ad/bio/fiyat → Kurulum için temel

### **SONRA (P1 sprint)**
3. Kazanç Yönetimi (Faz 1-2) — Cüzdan/çekme → Ödeme akışı
4. Uygunluk Takvimi (Faz 1-4) — Açık saatler → UX iyileştirmesi
5. Müşteri Yönetimi (Faz 2-1) — Sık/blok → Spam kontrol

### **İLERİ (P2/backlog)**
6. Yorum Yönetimi (Faz 1-5) — Yanıt/göm → Güven
7. Oturum Geçmişi (Faz 2-2) — Filtreleme → Denetim
8. Promosyon & Kampanya (Faz 2-3) — Kod/indirim → Pazarlama
9. Bildirim Ayarları (Faz 2-4) — Kustomize → UX seçeneği
10. Başarı Metrikleri (Faz 3-1) — KPI → Gamification
11. Sertifikalar (Faz 3-2) → Milestone
12. Mesajlaşma (Faz 3-3) → Sosyal feature

---

## 6️⃣ İMPLEMENTASYON IPUÇLARI

### Mevcut Şablonlar (Kopyala/Uyarla)
- **Dashboard layout:** `psychic_teller_dashboard_screen.dart` (836 satır) — başlık, sekme, liste
- **Liste widget:** `psychics_list_screen.dart` — filtreleme, arama, sayfalandırma
- **Modal sheet:** `psychic_booking_sheet.dart` — form binding
- **Admin panel:** `/admin/*` sayfaları (denetim günlüğü, güvenlik, özellik) — kart tasarımları

### Mevcut Providers
```dart
// Yeniden kullanım:
ref.watch(livePsychicsRepositoryProvider) // Tüm API çağrıları
ref.watch(authControllerProvider) // Kullanıcı kimliği
ref.watch(approvedPsychicProvider) // Falcı onay durumu
ref.watch(psychicTellerDashboardProvider) // Mevcut veriler
```

### Rota Şablonu
```dart
GoRoute(
  path: '/canli-falcilar/analytics',
  pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
    key: state.pageKey,
    child: const PsychicAnalyticsScreen(),
  ),
),
```

---

## 📊ÖZETİ

| Kategori | Tamamlandı | Eksik | % |
|----------|-----------|-------|-----|
| Ekranlar | 9 | 12 | 43% |
| Rota | 9 | 12 | 43% |
| Kontrol/Logic | 7 | 8 | 47% |
| Provider | 8 | 8 | 50% |
| UI Widget | 19 | 10+ | 65% |
| API Metodu | 30+ | 10+ | 75% |
| Gerçek Zamanlı | 5 | 0 | 100% |
| **Genel** | **70** | **60+** | **≈54%** |

**Sonuç:** Çekirdek seans/video çalışıyor. Falcı-tarafı işletmesel ve analitik özellikler eksik. **2-3 haftada tamamlanabilir.**

