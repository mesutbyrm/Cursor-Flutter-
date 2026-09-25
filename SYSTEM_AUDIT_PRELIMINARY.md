# CANLIFAL FLUTTER HATA ANALİZİ - ÖN RAPOR

**Tarih:** 2026-09-25  
**Durum:** Analiz aşaması  
**Amaç:** Aşama 1-5'deki tüm sorunları belirlemek ve düzeltmek

---

## KRİTİK BULGU LISTESI

### AŞAMA 1: SESLİ ODA BAĞLANTISI (Kritiklik: ÇOKYÜKSEK)

#### A. Presence State Management
**Sorun:** RoomSessionManager ile chat_room_providers'daki state duplikasyonu
- **Location:** `chat_room_providers.dart` (_canonicalPresence, _knownPresenceIds)
- **Root Cause:** RoomSessionManager'daki canonical state ile Notifier'daki state senkronize değil
- **Etki:** Presence güncellemelerinin gecikmesi, yanlış görünüm
- **Fix:** RoomSessionManager'ı single source of truth yap

#### B. SSE Stream Lifecycle
**Sorun:** chat/rooms/{id}/stream SSE bağlantısının kapatılmadığında tekrar açılması
- **Location:** chat_room_providers_sse.dart (multiple listeners)
- **Root Cause:** _subscribeToSseStream() idempotent değil, listener cleanup yapılmıyor
- **Etki:** Duplicate events, memory leak, aynı presence 2x gösterilmesi
- **Fix:** StreamController.broadcast yerine single subscription + cleanup

#### C. Join/Leave Race Condition
**Sorun:** Concurrent join/leave işlemlerinde lock mekanizması yetersiz
- **Location:** RoomSessionManager (_RoomSessionLock)
- **Root Cause:** _lock.release() sırasında _locked=true, waiter complete önce
- **Etki:** İkinci join iptal olabiliyor, state inconsistency
- **Fix:** Queue-based locking + FIFO guarantee

#### D. Host Offline Detection
**Sorun:** Oda sahibi çevrim dışı olduğunda host koltuğu boşalmıyor
- **Location:** chat_room_providers_seat.dart (_confirmPendingSeatFromSnapshot)
- **Root Cause:** Presence'da "çevrim dışı" durumu koltuk state'e yansımıyor
- **Etki:** Çevrim dışı host hâlâ host koltuğunda görünüyor
- **Fix:** Presence isOnline=false → host seat auto-clear

#### E. Session Initialization Order
**Sorun:** Uygulama açılışında eski session'dan kalıntılar
- **Location:** chat_room_providers.dart (build method'unda)
- **Root Cause:** clearVoiceRoomLiveSession() çağrılmıyor, _sessionActive reset değil
- **Etki:** İlk açılışta ghost room görünüyor
- **Fix:** App init → clearAllSessions() + validate active sessions

---

### AŞAMA 2: PK SİSTEMİ (Kritiklik: ÇOKYÜKSEK)

#### A. Davet Teslim Garantisi  
**Sorun:** Farklı odalar arasında gönderilen PK daveti karşı tarafa ulaşmıyor
- **Location:** pk_delivery_manager.dart (mevcut sistemde iyi, ama not integrated everywhere)
- **Root Cause:** SSE haber alamıyorsa polling timeout yapıyor, retry limit 3
- **Etki:** 30 saniye sonra "davet gönderilemedi" dönüyor
- **Status:** Önceki commit'te eklendi ✓ (5s retry, 30s timeout)

#### B. Takım PK Hataları
**Sorun:** Aynı odadaki takım üyeleriyle PK başlatılamıyor
- **Location:** pk_session_notifier.dart (_createVoiceInvite)
- **Root Cause:** Aynı roomId → backend API error (self vs opponent farklı olmalı)
- **Etki:** "Bu yayıncıya zaten davet gönderildi" yanlış mesajı
- **Fix:** Opponent validation kodu kontrol et

---

### AŞAMA 3: CANLI FALCİLAR (Kritiklik: YÜKSEK)

#### A. Session İstek Teslimi
**Sorun:** Falcı isteği görülmüyor veya çok geç görülüyor
- **Location:** live_fortune_session_manager.dart (SSE + 10s polling)
- **Root Cause:** PsychicIncomingSseService ile live_fortune_session_manager duplikasyon
- **Etki:** İstek teslim gecikmesi
- **Status:** Önceki commit'te eklendi ✓

#### B. Mesaj Senkronizasyonu
**Sorun:** İki tarafta farklı mesaj sayısı
- **Location:** psychic_room_sse_service.dart
- **Root Cause:** Message buffer overflow veya missing deduplication
- **Fix:** Message ID deduplication + buffer management

#### C. Süre Senkronizasyonu
**Sorun:** İki tarafta farklı kalan süre
- **Location:** fortune_session_countdown (local time)
- **Root Cause:** Geri sayım client-side yapılıyor, server time'dan farklı
- **Fix:** Server-provided startAt/endAt timestamp kullan

---

### AŞAMA 4: MALİ DOĞRULUK (Kritiklik: ORTA)

#### A. Hediye Raporu Hesaplaması
**Sorun:** Oturum sonu raporunda hediye tutarı yanlış
- **Location:** session_gift_summary.dart
- **Root Cause:** Aynı hediye iki kez sayılabiliyor veya rate yanlış
- **Fix:** Backend transaction log'u doğrula, duplicate filter

#### B. Jeton Bakiyesi Desynchronize
**Sorun:** Satın alma sonrası bakiye güncellenmiyor
- **Location:** wallet_provider.dart
- **Root Cause:** POST response'daki bakiye ignored, cache refresh yok
- **Fix:** POST sonrası refetch veya pessimistic update + confirm

---

### AŞAMA 5: PERFORMANS & MİMARİ (Kritiklik: ORTA)

#### A. İlk Açılış Hızı
**Sorun:** Uygulama ilk açılırken 3-5 saniye dondurulmuş
- **Root Cause:** 46 provider'ın tamamı initialize ediliyor
- **Fix:** Lazy loading + on-demand initialization

#### B. Provider Duplikasyonu
**Sorun:** 46 provider var, bazıları aynı şeyi yapıyor
- **Örnek:** voiceRoomLiveProvider, chatRoomDetailProvider (her ikisi presence)
- **Fix:** Provider consolidation + merge

---

## İŞ PLANI

### Faz 1: Sesli Oda Kritik Fixler (4-6 saat)
- [ ] RoomSessionManager canonical state → single source of truth
- [ ] SSE stream lifecycle management
- [ ] Lock mechanism improvement
- [ ] Host offline detection
- [ ] Session init cleanup

### Faz 2: PK & Falcı Entegrasyon (2-3 saat)
- [ ] PK delivery manager full integration
- [ ] Takım PK validation
- [ ] Fortune session manager full integration
- [ ] Message deduplication

### Faz 3: Finansal & Performans (3-4 saat)
- [ ] Hediye raporu doğrulama
- [ ] Jeton senkronizasyonu
- [ ] Provider cleanup
- [ ] Lazy loading

### Faz 4: Test & APK (2-3 saat)
- [ ] Unit test
- [ ] Integration test
- [ ] Device test
- [ ] APK build & validation

---

## SONRAKI ADIM
Faz 1'e başlayacağım. Sesli oda bağlantı sorunları ve PK teslim sistemi çalışmaya başlarsa, diğer sorunlar çözülmesi daha kolay hale gelecek.

