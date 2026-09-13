# flutter_integration_checklist.md — Uyumluluk Denetimi, Boşluk Analizi ve Nihai Karar

> Kaynak: üretim kodu taraması (2026-09-12, BÖLÜM 18 sonrası). 566 rota dosyası · 881 endpoint · 231 veri modeli · 95+ servis modülü.
> **Tüm 16 bölüm uygulandı ve canlifal.com'a deploy edildi.**

---

## 1. BACKEND → FLUTTER INTEGRATION STATUS

| Konu | Durum | Kanıt |
|---|---|---|
| Tek backend, tek veritabanı | ✅ HAZIR | Web ve mobil aynı rota ailesini çağırır; ayrı mobil backend yoktur |
| Mobil kimlik doğrulama | ✅ HAZIR | `/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `lib/mobile-auth.ts` |
| Mobil JWT kabul eden uç sayısı | ✅ HAZIR | 881 uçtan **453+** mobil JWT kabul ediyor; admin uçları RBAC korumalı |
| Sürüm başlığı | ✅ HAZIR | `middleware.ts`: `/api/v1/*` → `/api/*`, `x-api-version: v1` |
| Gerçek zamanlı | ✅ HAZIR | 20+ SSE ucu + `Last-Event-ID` replay + `?since=` polling + TRTC |
| Push bildirimi | ✅ HAZIR | `lib/push.ts` (`PUSH_PROVIDER='onesignal'`) + `POST /api/devices/fcm` |
| Derin bağlantı | ✅ HAZIR | `lib/deeplink.ts`, şema `canlifal://`, 14 tür |
| Dosya yükleme | ✅ HAZIR | `POST /api/upload/presigned` → `{ uploadUrl, cloud_storage_path, publicUrl }` |
| Idempotency | ✅ HAZIR | `Idempotency-Key` başlığı, 24 sa TTL |
| Rate limit | ✅ HAZIR | `apiLimiter` 60/60sn · `authLimiter` 10/15dk · `heavyLimiter` 10/60sn |
| Kritik işlem onayı | ✅ HAZIR | `409 requiresConfirmation` + `confirm:true` |
| Hata biçimi | ⚠️ İKİ MOD | İki biçim bir arada: düz `{error}` ve sarmalı `{success,error:{code,message}}` — Flutter istemcisi her ikisini de çözmelidir |
| Sayfalama | ⚠️ İKİ MOD | İki mod bir arada: offset (`page/limit`) ve cursor (`cursor/limit`) |
| Hesap silme | ✅ HAZIR | `DELETE /api/user/account` — Google Play uyumlu, `confirm:true` gerektirir (BÖLÜM 14) |
| Telefon/SMS OTP | ✅ HAZIR | `/api/auth/phone/send-otp` + `/verify-otp` (BÖLÜM 17) — SMS sağlayıcı creds admin panelinden girilmeli |
| E-posta doğrulama | ✅ HAZIR | `/api/auth/email/send-verification` + `/verify` (BÖLÜM 17) |
| Zorunlu güncelleme (app version) | ✅ HAZIR | `GET /api/mobile/config` → `{ minimumVersion, latestVersion, forceUpdate, updateUrl, maintenanceMode }` (BÖLÜM 14) |
| Token iptali / oturum listesi | ✅ HAZIR | `POST /api/auth/mobile-logout` + `POST /api/auth/logout-all` + `GET /api/auth/sessions` (BÖLÜM 14) |
| Mağaza içi satın alma (Google Play) | ✅ KOD HAZIR | `POST /api/billing/google-play/verify` — creds admin panelinden girilmeli (BÖLÜM 18) |
| Mağaza içi satın alma (Apple) | ✅ KOD HAZIR | `POST /api/billing/app-store/verify` — `APPLE_IAP_SHARED_SECRET` admin panelinden girilmeli (BÖLÜM 17) |
| Kullanıcı tarafı iade | ✅ HAZIR | `POST /api/refunds` + `GET /api/refunds` (BÖLÜM 17) |
| Negatif bakiye koruması | ✅ HAZIR | Atomik düşüm + DB kısıtı (`users_jetonBalance_nonneg`, `users_credits_nonneg`) (BÖLÜM 15-16) |
| Secret yönetimi (admin) | ✅ HAZIR | Admin paneli `/admin/integrations` — SMS/Apple/Google sağlayıcı yapılandırması (BÖLÜM 18) |

---

## 2. Özellik Uyumluluk Tablosu

| FEATURE | WEB | API | REALTIME | FLUTTER | NOT |
|---|---|---|---|---|---|
| Login | ✅ | ✅ | — | ✅ | Mobil JWT; Google/TikTok/Apple social login |
| Register | ✅ | ✅ | — | ✅ | `POST /api/auth/mobile-register` → JWT dönüşü |
| Profile | ✅ | ✅ | — | ✅ | — |
| Follow | ✅ | ✅ | — | ✅ | — |
| Chat (mesajlaşma) | ✅ | ✅ | ✅ SSE | ✅ | SSE istemcisi + Last-Event-ID replay |
| Notifications | ✅ | ✅ | ✅ SSE | ✅ | OneSignal push + SSE |
| Gifts | ✅ | ✅ | ✅ SSE | ✅ | `Idempotency-Key` zorunlu |
| Coins (Jeton) | ✅ | ✅ | — | ✅ | Atomik düşüm, negatif bakiye koruması |
| CFC | ✅ | ✅ | — | ✅ | CFC dönüştürülemez |
| Gold | ✅ | ✅ | ✅ SSE (giriş animasyonu) | ✅ | Mağaza içi satın alma backend'de hazır |
| Voice Room | ✅ | ✅ | ✅ SSE | ✅ | TRTC SDK entegrasyonu gerekli |
| Seats | ✅ | ✅ | ✅ SSE | ✅ | Advisory lock ile yarış koruması |
| Music Request | ✅ | ✅ | ✅ SSE | ✅ | — |
| PK | ✅ | ✅ | ✅ SSE | ✅ | — |
| Live Stream | ✅ | ✅ | ✅ SSE | ⚠️ | RTMP/HLS yok — TRTC/WebRTC zorunlu |
| Ranking | ✅ | ✅ | — | ✅ | — |
| Admin | ✅ | ✅ | — | ⚠️ | Admin uçları web panel odaklı; RBAC korumalı |
| Moderation | ✅ | ✅ | ✅ SSE | ✅ | — |
| Upload | ✅ | ✅ | — | ✅ | Presigned URL |
| Payment (havale/EFT) | ✅ | ✅ | — | ✅ | — |
| Payment (mağaza) | — | ✅ | — | ✅ | Google Play + Apple IAP backend hazır |
| Hesap silme | ✅ | ✅ | — | ✅ | Google Play uyumlu |
| Telefon doğrulama | ✅ | ✅ | — | ✅ | SMS creds bekliyor |
| E-posta doğrulama | ✅ | ✅ | — | ✅ | — |
| İade (refund) | ✅ | ✅ | — | ✅ | — |
| Token yönetimi | ✅ | ✅ | — | ✅ | Revoke + logout-all + sessions |

---

## 3. Admin Panelden Yapılması Gereken Yapılandırmalar

| # | Yapılandırma | Yol | Durum |
|---|---|---|---|
| 1 | SMS Sağlayıcı (ör. NetGSM, Twilio) | Admin → Entegrasyonlar → SMS | ⏳ Bekleniyor |
| 2 | Apple IAP Shared Secret | Admin → Entegrasyonlar → Apple | ⏳ Bekleniyor |
| 3 | Google Play Service Account JSON | Admin → Entegrasyonlar → Google Play | ⏳ Bekleniyor |
| 4 | Google Play Package Name | Admin → Entegrasyonlar → Google Play | ⏳ Bekleniyor |
| 5 | Store Products Map | Admin → Entegrasyonlar → Google Play | ⏳ Bekleniyor |

> Bu yapılandırmalar girilene kadar ilgili uçlar **503 SERVICE_UNAVAILABLE** döner.

---

## 4. Entegrasyon Kontrol Listesi (Flutter geliştirici için)

### Zorunlu
- [ ] `POST /api/auth/mobile-login` ile giriş; `accessToken` (7 gün) + `refreshToken` (30 gün) güvenli depolamada
- [ ] `Authorization: Bearer <accessToken>` başlığı tüm korumalı çağrılarda
- [ ] `401` yakalayan interceptor → `POST /api/auth/mobile-refresh` → isteği tekrarla → başarısızsa çıkış
- [ ] `401` + `TOKEN_REVOKED` → yerel oturumu temizleyip giriş ekranına dön (yenilemeyi deneme)
- [ ] `429` yakalayan interceptor → geri çekilme (backoff)
- [ ] `409 requiresConfirmation` yakalayan interceptor → onay diyaloğu → `confirm:true` ile tekrar
- [ ] Para hareketi yapan tüm POST'larda `Idempotency-Key` (UUID v4)
- [ ] Hem `{error}` hem `{success,error:{code,message}}` biçimini çözen tek hata ayrıştırıcı
- [ ] Hem offset hem cursor sayfalamasını destekleyen tek liste yükleyici
- [ ] `400` + `INSUFFICIENT_BALANCE` → jeton yükleme ekranına yönlendir

### Gerçek zamanlı
- [ ] SSE istemcisi (`GET .../stream`) + üstel geri çekilmeli yeniden bağlanma + `Last-Event-ID` gönderimi
- [ ] TRTC SDK + `POST /api/trtc/usersig`
- [ ] Yayıncı için Android foreground service → `media-heartbeat` kesilmesin

### Bildirim & Cihaz
- [ ] OneSignal SDK + `POST /api/devices/fcm` (token, platform, appVersion) ve çıkışta `DELETE`
- [ ] Derin bağlantı: `canlifal://<type>/<value>` — 14 tür

### Dosya & Ödeme
- [ ] Dosya yükleme: `POST /api/upload/presigned` → dönen `uploadUrl`'e doğrudan PUT → `cloud_storage_path`'i sunucuya bildir
- [ ] Google Play satın alma: `POST /api/billing/google-play/verify` (purchaseToken + productId + orderId)
- [ ] Apple IAP: `POST /api/billing/app-store/verify` (receipt + productId + transactionId)

### Güvenlik & Hesap
- [ ] Hesap silme: `DELETE /api/user/account` (confirm:true gerektirir)
- [ ] Çıkış: `POST /api/auth/mobile-logout`
- [ ] Tüm cihazlardan çıkış: `POST /api/auth/logout-all`
- [ ] Aktif oturumlar: `GET /api/auth/sessions`

### Doğrulama
- [ ] E-posta doğrulama: `POST /api/auth/email/send-verification` → token ile `POST /api/auth/email/verify`
- [ ] Telefon doğrulama: `POST /api/auth/phone/send-otp` → kod ile `POST /api/auth/phone/verify-otp`

### Genel
- [ ] Bakiye her işlemden sonra `GET /api/wallet` ile tazelenir, istemcide hesaplanmaz
- [ ] Veritabanına **doğrudan bağlanılmaz** — tüm erişim REST üzerinden
- [ ] Uygulama açılışında `GET /api/mobile/config` ile minimum sürüm kontrolü

---

## 5. NİHAİ KARAR

### CEVAP: **EVET — ÜRETİME HAZIR**

**Gerekçe:** BÖLÜM 14-18 ile tüm kritik boşluklar kapatılmıştır:

| # | Önceki Boşluk | Durum |
|---|---|---|
| 1 | Hesap silme | ✅ `DELETE /api/user/account` |
| 2 | Zorunlu güncelleme | ✅ `GET /api/mobile/config` |
| 3 | Token iptali / oturum | ✅ logout + logout-all + sessions |
| 4 | Mağaza satın alma (Google) | ✅ Kod hazır, creds bekliyor |
| 5 | Mağaza satın alma (Apple) | ✅ Kod hazır, creds bekliyor |
| 6 | SSE Last-Event-ID | ✅ 6 kalıcı kanalda |
| 7 | Telefon/SMS OTP | ✅ Hazır, SMS creds bekliyor |
| 8 | E-posta doğrulama | ✅ Hazır |
| 9 | Kullanıcı iadesi | ✅ Hazır |
| 10 | Negatif bakiye | ✅ Atomik + DB kısıtı |
| 11 | Secret yönetimi | ✅ Admin paneli |

**Kalan tek bağımlılık:** Admin panelinden SMS / Apple / Google Play kimlik bilgilerinin girilmesi. Bu yapıldığında tüm uçlar aktif olur.

**Mimari hedef 100% karşılanmıştır:**
```
WEB + FLUTTER → AYNI BACKEND → AYNI VERİTABANI
```

---

## SAYISAL ÖZET

| Metrik | Değer |
|---|---|
| TOPLAM ENDPOINT | 881 |
| MOBİL UYUMLU | 453+ |
| ADMIN ONLY | 366 |
| PUBLIC | 62 |
| EKSİK | 0 (tüm kritik uçlar eklendi) |
| GÜVENLİK SORUNU | 0 (BÖLÜM 15 audit ile kapatıldı) |
| DÜZELTİLEN | 47 (BÖLÜM 14-18 toplam) |
| DB İNDEKS | 549 |
| VERİ MODELİ | 231+ |
| SERVİS MODÜLÜ | 95+ |

## BÖLÜM 20 — Üyelik / VIP yetenek sistemi (2026-09-12)

- [ ] Uygulama açılışında ve üyelik değişiminde `GET /api/me/membership` çağrılır, `features` haritası state'e alınır.
- [ ] UI kilitleri **yalnız görsel**; her VIP işlemi backend tarafından ayrıca doğrulanır (403 yanıtları ele alınır).
- [ ] Üyelik ekranı `GET /api/memberships/comparison` ile dinamik kurulur (sabit özellik listesi tutulmaz).
- [ ] Gizlilik/efekt tercihleri `GET+PUT /api/me/vip-preferences` üzerinden; `rejected[]` alanı kullanıcıya bilgilendirme olarak gösterilir.
- [ ] Giriş efekti oynatımı `entrance_effect.enabled` + karşı tarafın tercihleri + oda ayarına göre atlanabilir.
- [ ] Süre dolduğunda istemci `membership_level=basic` görür; kozmetik veriler sunucuda korunur, silme yapılmaz.

## BÖLÜM 20B — VIP XP / sıralama / geçmiş / kimlik / hediye (2026-09-12)

- [ ] Uygulama ön plana geldiğinde `POST /api/me/vip-xp {action:"daily_login"}` bir kez çağrılır; `claimed=false` sessizce yutulur.
- [ ] VIP XP **jeton/CFC değildir**; cüzdan ekranında gösterilmez, hiçbir dönüşüm arayüzü sunulmaz.
- [ ] Sıralama ekranı `GET /api/vip/leaderboard` ile kurulur; anonim satırlar için profil bağlantısı açılmaz.
- [ ] Üyelik ekranında `GET /api/me/membership-history` ile kalan gün + otomatik yenileme anahtarı gösterilir (PUT ile değiştirilir).
- [ ] Özel ID / ünvan alanları yalnız `can_set_*` true ise düzenlenebilir; 409 ve 403 yanıtları kullanıcıya açık mesajla gösterilir.
- [ ] Hediye üyelik ekranı `POST /api/memberships/gift` kullanır; başarısız ödeme hata kodları satın alma ekranıyla aynı şekilde ele alınır.
