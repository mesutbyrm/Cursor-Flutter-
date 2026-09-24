# P1 Platform Test Checklist — 2026-09-24

**APK Version:** 1.0.598+644  
**Build:** Success (#1703)  
**Commit:** f6e0b252 (Flutter analyze fixes) + 18fd520d (Comprehensive audit)  
**Download:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

---

## 📋 Test Setup

### Test Accounts (2 Cihaz Gerekli)

| Cihaz | E-mail | Şifre | Role |
|-------|--------|-------|------|
| **A** (Initiator) | cursor.test.1786235468@mailinator.com | CursorTest!1786235468 | User |
| **B** (Receiver) | cursor.host.1786235468@mailinator.com | CursorTest!1786235468 | Host |

### Kurulum Adımları

1. APK'yı iki cihaza yükle
2. Her cihazda uygulamayı aç ve giriş yap
3. Her iki cihaz aynı ağda olmalı
4. Push notification'ları etkinleştir

---

## ✅ Test Cases

### 1. Voice Room Join/Leave/Rejoin (2 Cihaz Aynı Oda)

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 1.1 | A: Sesli oda başlat | Oda oluşturuldu, kod gösterildi | [ ] |
| 1.2 | B: Kodu gir ve katıl | B odaya katıldı, A'da B görüldü | [ ] |
| 1.3 | A: Mikrofon aç | Ses akışı başladı, B'de işitildi | [ ] |
| 1.4 | B: Çıkış yap | B listeden kaldırıldı | [ ] |
| 1.5 | B: Aynı odaya tekrar katıl | B tekrar odaya katıldı | [ ] |

**Notlar:** _________________

---

### 2. Seat Sync (Koltuk Senkronizasyonu)

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 2.1 | A & B odada | Koltuk bilgileri görünüyor | [ ] |
| 2.2 | A: Koltuk konumunu değiştir | B'de A'nın konumu değişti | [ ] |
| 2.3 | B: Hava tarafını seç | A'da B'nin konumu güncelendi | [ ] |
| 2.4 | Network kesme/restore | Koltuk durumu senkronize | [ ] |

**Notlar:** _________________

---

### 3. PK Request/Accept/Score (⭐ Önemli — Bu Haftanın Hotfix'i)

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 3.1 | A: Sesli odada "PK İSTEĞİ GÖNDERİ" | PK panel açıldı | [ ] |
| 3.2 | A: B'yi rakip seç | B seçildi, "GÖNDER" butonu aktif | [ ] |
| 3.3 | A: İsteği gönder | A'da "İstek gönderildi" mesajı | [ ] |
| 3.4 | B: Bildirim/Panel | B'de PK daveti görüldü | [ ] |
| 3.5 | B: İsteği kabul et | PK başladı, sayaç 3:00'den başladı | [ ] |
| 3.6 | A & B: PK sırasında skor | Her action'da skor güncellendi | [ ] |
| 3.7 | PK sona erdi | Skor kaydedildi, leaderboard güncelendi | [ ] |

**Notlar:** _________________

**🔴 Kritik:** Adım 3.3'te "PK İSTEĞİ GÖNDERİLDİ" mesajı görülmeli. Eğer sessiz kalırsa, PK bug tekrar ortaya çıkmıştır.

---

### 4. Gift + Wallet + Ranking

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 4.1 | A: Cüzdan bakiyesi | Jetonlar görüldü | [ ] |
| 4.2 | A: Hediye seç ve B'ye gönder | Hediye panel'ı açıldı | [ ] |
| 4.3 | A: Hediye gönder | A'nın tokenleri azaldı | [ ] |
| 4.4 | B: Hediye bildirimi | B'de hediye bildirimi/animasyon | [ ] |
| 4.5 | B: Cüzdan | B'nin tokenleri arttı | [ ] |
| 4.6 | Leaderboard | Ranking güncellemeleri görüldü | [ ] |

**Notlar:** _________________

---

### 5. Music Room Change (Müzik Odası Değişimi)

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 5.1 | A: Müzik odası 1'de başla | Müzik çalıyor | [ ] |
| 5.2 | A: Başka odaya taşın | Müzik 1 durdu, Müzik 2 başladı | [ ] |
| 5.3 | Geri dön | Müzik 1 sürüdüğü yerden devam etti | [ ] |

**Notlar:** _________________

---

### 6. DM + Notification + Unread

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 6.1 | A: B'ye DM gönder | B'de push notification | [ ] |
| 6.2 | B: Gelen kutu | Unread count azaldı | [ ] |
| 6.3 | B: DM'i oku | Okundu işareti | [ ] |

**Notlar:** _________________

---

### 7. Logout A → Login B (Cache İzolasyonu)

| # | Adım | Beklenen | Durum |
|---|------|----------|--------|
| 7.1 | A: Çıkış yap | Home/Login ekranına gitti | [ ] |
| 7.2 | B: Giriş yap (aynı cihaz) | B'nin profili yüklendi, A'nın değil | [ ] |
| 7.3 | A'nın cüzdanı görenebil mi? | Göünemez (cache izole) | [ ] |

**Notlar:** _________________

---

## 📊 Özet

### Genel Durum

| Kategori | PASS | FAIL | Not Tested | Notlar |
|----------|------|------|-----------|--------|
| Voice (1) | [ ] | [ ] | [ ] |  |
| Seat Sync (2) | [ ] | [ ] | [ ] |  |
| PK (3) | [ ] | [ ] | [ ] |  |
| Gift/Wallet (4) | [ ] | [ ] | [ ] |  |
| Music (5) | [ ] | [ ] | [ ] |  |
| DM/Notif (6) | [ ] | [ ] | [ ] |  |
| Auth (7) | [ ] | [ ] | [ ] |  |

### Sonuç

- [ ] **P1 PASS** — Tüm kritik işlevler çalışıyor
- [ ] **P1 FAIL** — Hatalar bulundu (hangileri?)
- [ ] **P1 BLOCKED** — Test yapılamadı (neden?)

### Tespit Edilen Hatalar

```
Hata 1: ___________________________________
Durum: [ ] Reproducible  [ ] Random  [ ] One-time
Sıklık: [ ] Her zaman  [ ] Bazen  [ ] Enderdir
Çözüm: ____________________________________

Hata 2: ___________________________________
...
```

---

## 🔄 Hata Raporlama Prosedürü

Hata bulunursa:

1. **Detay:** Adım adım tekrar et, replicat'ı doğrula
2. **Log:** `Logcat` veya `Console` log'larını topla
3. **Screenshot:** Hata ekranının SS'ini al
4. **Report:** Issues → "P1 FAIL — [Error Name]" başlığıyla rapor et

---

## 📝 Notlar ve Gözlemler

```
(Test sırasında yazılacak)

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

---

**Test Tarihi:** ___________  
**Test Yapan:** ___________  
**Cihazlar:** Android _____ (Cihaz A) × _____ (Cihaz B)  
**Network:** WiFi [ ] LTE [ ] Other [ ]  

---

**İlk Sonuç:** [ ] PASS [ ] FAIL [ ] INCOMPLETE

**Final Rapor:** `/home/user/Cursor-Flutter-/P1_TEST_RESULT_[TARIH].md`
