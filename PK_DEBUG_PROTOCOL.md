# PK İsteği Debugging Protokolü — B Odada mı? Kontrol

**Tarih:** 2026-09-24  
**Issue:** PK isteği gönderildi ama karşı taraf (B) almıyor  
**Error Message:** "Şu an PK yapılabilecek aktif oda yok. Rakip oda sahibinin son 2 dakikada odada olması gerekir."

---

## 📋 Adım 1: Voice Room State Doğrulaması

### Cihaz A (Initiator — PK gönderen)

**Kontrol Listesi:**

- [ ] **Voice room açık mı?** ✓ Görünüyor
- [ ] **Mikrofon açık mı?** Mic icon'ının durumunu kontrol et
- [ ] **"1 çevrimiçi" gösteriliyor mu?** (Seat panel'inde)
- [ ] **Seat card'ında B'nin ismi görünüyor mu?**
  - [ ] "Cursor Host" veya başka isim
  - [ ] CANLI badge var mı?
- [ ] **Jeton gösteriliyor mu?** (5.6K jeton görülüyor)

**Notlar:** _______________

---

### Cihaz B (Receiver — PK alan)

**Kontrol Listesi:**

- [ ] **Voice room açık mı?** (A'yı duyuyor mu?)
- [ ] **Mikrofon açık mı?**
- [ ] **"2 çevrimiçi" veya katılımcı sayısı doğru mu?**
- [ ] **Seat panel'inde A'nın ismi görünüyor mu?**
  - [ ] "Cursor Test" veya başka isim
  - [ ] CANLI badge var mı?

**Notlar:** _______________

---

## 🌐 Adım 2: Network & SSE Durumu

### Cihaz A

```bash
# Telefon ayarlarından kontrol et:
- [ ] WiFi bağlı mı? (SSID: ?)
- [ ] Signal kuvveti: ████ ████ ███░ (dört çubuk kaç dolu?)
- [ ] Ping test (isteğe bağlı):
  - Terminal: ping 8.8.8.8
  - Sonuç: <100ms ✓ / >200ms ✗
```

**SSE Connection Status:**
- [ ] Network tablet'te "Sohbet mesajları burada görünür" yazısı görülüyor mu?
  - EVET → SSE açık
  - HAYIR → SSE bağlantısı kopmuş olabilir

**Notlar:** _______________

### Cihaz B

```bash
- [ ] WiFi bağlı mı? (SSID: ?)
- [ ] Signal kuvveti: ████ ████ ███░
- [ ] SSE açık mı? ("Sohbet mesajları burada görünür" yazısı)
```

**Notlar:** _______________

---

## 📤 Adım 3: PK İsteğini Tekrar Dene

### Cihaz A — PK Gönder

**Adım Adım:**

1. [ ] PK SAVAŞI section'ı görünüyor mu?
   - Eğer EVET → devam et
   - Eğer HAYIR → Scroll aşağı, bul

2. [ ] "PK İSTEĞİ GÖNDER" butonu görülüyor mu?
   - Eğer EVET → Tıkla
   - Eğer HAYIR → Screenshot al (BUG)

3. [ ] Panel açıldı mı? (Rakip seçimi)
   - [ ] "Cursor Host" (B) listelenmiş mi?
   - [ ] B seçilebiliyor mu?

4. [ ] B'yi seç → "PK İSTEĞİ GÖNDER" (mor buton) tıkla

5. [ ] **Sonuç kontrol et:**
   - ✓ "İstek gönderildi" mesajı görüldü mü?
   - ✗ Error mesajı mı geldi?
   - ? Loading spinner döndü mü (5+ saniye)?

**Screenshot Al:** PK button'ını ve sonucu

**Notlar:** _______________

---

### Cihaz B — PK Notification Kontrol

**B'de ne oldu?**

- [ ] **Push notification geldi mi?** (Üst kısımda)
- [ ] **PK panel açıldı mı?** (Otomatik)
- [ ] **Bildirim sesiyok (suslu mod)?**
  - Suslu mod açık mı kontrol et (Settings)
- [ ] **Ekran kilitli miydi?**
  - Açmak için bildirim merkezi aç

**Eğer bildirim gelmedi:**
- [ ] Notifications enabled mi? (Settings → Notifications)
- [ ] OneSignal aktif mi? (uygulamada)

**Notlar:** _______________

---

## 🔴 Adım 4: Hata Mesajı Detayı

**Eğer A'da "Şu an PK yapılabilecek aktif oda yok" hatası geldi:**

Bu, **backend'den gelen hata**, yani:
- Backend B'yi **odada** görmüyor
- Veya B'nin **son 2 dakikada** oda aktivitesi yok

**Kontrol:**

- [ ] B gerçekten odada mı? (ekran görülüyor mü?)
- [ ] B'nin son aktivitesi: **< 2 dakika** mı?
  - Eğer > 2 dakika → B'yi tekrar odaya al (leave + rejoin)
- [ ] A-B aynı oda ID'sinde mi?
  - Oda kodu göster (A ekranının sol üstü)

**Notlar:** _______________

---

## 🖼️ Screenshot Checklist

**Alınması gereken screenshot'lar:**

1. [ ] **A: Voice room (B görülüyor)**
   - Seat card'ını göster
   - Mic status'u göster

2. [ ] **B: Voice room (A'yı duyuyor)**
   - Seat card'ını göster
   - Participants sayısı

3. [ ] **A: PK button sonrası error veya success**
   - Modal veya notification

4. [ ] **B: Notification arrival (veya eksikliği)**
   - Push bildirimi GIF

5. [ ] **Network status (her iki cihaz)**
   - WiFi bars
   - Signal strength

---

## 📊 Sonuç Tablosu

| Adım | Beklenen | Gözlenen | Durum |
|------|----------|----------|-------|
| A: Voice room açık | ✓ | ✓ | [ ] |
| B: Aynı odada | ✓ | ? | [ ] |
| A: Network OK | ✓ | ? | [ ] |
| B: Network OK | ✓ | ? | [ ] |
| A: SSE açık | ✓ | ? | [ ] |
| B: SSE açık | ✓ | ? | [ ] |
| A: PK button tıkla | ✓ | ? | [ ] |
| B: Notification | ✓ | ? | [ ] |

---

## 🔧 Logcat Toplama (İsteğe Bağlı)

**Eğer hata tekrar olursa, logcat al:**

### Android Studio veya Terminal:

```bash
adb logcat | grep -i "pk\|request\|sse\|socket" > pk_debug.log
```

**Veya Telefonda:**

1. Developer Options aç (Settings → About → Build Number 7x tıkla)
2. USB Debugging aç
3. Adb ile logcat al

---

## ✅ Rapor Başlığı

**Eğer problem devam ediyor, GitHub Issue aç:**

```
Title: P1 FAIL — PK request not delivered to opponent (v1.0.598+644)

Body:
- A odada: [Evet/Hayır]
- B odada: [Evet/Hayır]  
- Network: [WiFi signal strength]
- SSE: [Open/Closed]
- Error: "Şu an PK yapılabilecek aktif oda yok"
- Screenshots: [İçer]
- Logcat: [İçer]
```

---

**Başla:** Adım 1'den başla, her adımın sonunda notlar ekle.

**Bitir:** Tüm satırlar dolduktan sonra sonuç rapor et.

---

*Son güncelleme: 2026-09-24 20:30*
