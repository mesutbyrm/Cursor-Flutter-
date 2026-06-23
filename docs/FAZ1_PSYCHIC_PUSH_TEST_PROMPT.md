# FAZ 1 — Canlı Falcı Push / Davet Teşhis ve Düzeltme

Bu belge, FAZ 1 test senaryosunun **eksiksiz** operasyonel prompt’udur. Kod değişikliği yapılmadan önce kök neden kesinleştirilir; APK üretilmez.

---

## Amaç

İlhamperisi (onaylı falcı) cihazında admin tarafından oluşturulan 10 dakikalık randevu davetinin **neden görünmediğini** veya **neden reddedildiğini** uçtan uca doğrulamak; ardından minimal düzeltme uygulamak.

---

## Ön koşullar

| Öğe | Değer (üretim) |
|-----|----------------|
| `tellerId` (profil) | `cmokzl5u900w2od09rpqq2fs9` |
| `tellerUserId` / `user.id` | `cmoks76yf00c4ph08ppcoqg98` |
| OneSignal `external_id` | `user.id` ile aynı (`OneSignalBootstrap.login`) |
| API | `https://canlifal.com` |
| İlhamperisi e-posta | `suna61722@gmail.com` (şifre test ortamında) |

**Gerekli hesaplar:** Admin + İlhamperisi (üretim veya staging JWT).

**APK:** Bu fazda **üretilmez**. Doğrulama debug build veya mevcut yüklü sürüm + Falcı Paneli teşhis kartı ile yapılır.

---

## Senaryo (sıra zorunlu)

### 1. Admin hesabı giriş

- Uygulama veya `POST /api/auth/login` ile admin JWT al.
- Jeton yeterli mi kontrol et (`Authorization: Bearer`).

### 2. İlhamperisi hesabı giriş (ayrı cihaz veya ikinci oturum)

- Aynı üretim API’ye giriş.
- Push izni verilmiş olmalı.
- Uygulama ön planda veya arka planda açık.

### 3. İlhamperisi cihazında ekrana yaz (Falcı Paneli → FAZ 1 teşhis kartı)

Aşağıdaki alanlar **ekranda** görünür olmalı:

| Alan | Kaynak |
|------|--------|
| `user.id` | `authControllerProvider` |
| `tellerId` | `approvedPsychicProvider.profile.id` |
| `tellerUserId` | `approvedPsychicProvider.profile.userId` |
| `OneSignal external_id` | `OneSignalBootstrap.externalUserId` |
| `approvedPsychicProvider` | profil + `lastDiagnostic` |
| `isFortuneTeller` | `profile.isUsable` |
| `shouldPresentPsychicIncomingInvite` | tam / minimal / nested-user-trap senaryoları + son gerçek push filtresi |

### 4. Admin 10 dakikalık randevu oluştur

```http
POST /api/fortune-tellers/session
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "tellerId": "cmokzl5u900w2od09rpqq2fs9",
  "tellerUserId": "cmoks76yf00c4ph08ppcoqg98",
  "clientName": "FAZ1 Admin Test",
  "durationMinutes": 10
}
```

Beklenen sunucu yan etkileri:

1. `createFortuneSession` → `sessionId`
2. `createNotification` → DB `appNotification` + `sendOneSignalToUser(tellerUserId)`
3. Falcı SSE / poll → pending istek listesi

---

## Rapor şablonu (zorunlu çıktı)

Her madde **evet/hayır + kanıt** ile doldurulur:

| Soru | Nasıl doğrulanır |
|------|------------------|
| **createNotification çalıştı mı?** | Üretim DB/log; yerel ayna: `[createNotification]` log satırı |
| **OneSignal API çağrıldı mı?** | `api/src/lib/notifications.ts` → `sendOneSignalToUser` |
| **OneSignal 200 döndü mü?** | Sunucu log: `OneSignal ok status=200` veya OneSignal dashboard |
| **Push telefona ulaştı mı?** | Cihaz bildirim tepsisi / OneSignal foreground listener / teşhis kartı `son filtre` |
| **shouldPresent true mu false mu?** | Teşhis kartı + `evaluatePsychicIncomingInvite` |
| **Davet neden reddedildi?** | `decision.reason` string (ör. `clientId boş + isFortuneTeller=false`) |

---

## Bilinen kök nedenler (doğrulanacak)

### A — `mergePsychicInviteNestedFields` (düzeltildi)

Nested `user.userId` yanlışlıkla `clientId` oluyordu → `isPsychicInviteForClientUser` true → davet gizleniyordu.

**Test:** `nested user trap` satırı teşhis kartında `clientId` boş ve `shouldPresent=true` olmalı.

### B — `approvedPsychicProvider` gecikmesi

Push geldiğinde `isFortuneTeller=false` ve `tellerProfileId=null`; minimal push’ta `tellerUserId` yoksa filtre red.

**Test:** Randevu öncesi teşhis kartında `isFortuneTeller=true` olmalı; değilse profil resolver sorunu.

### C — OneSignal ön plan `preventDefault`

Falcı davetleri sistem tepsisinde gösterilmez; yalnızca in-app kuyruk. Filtre red ederse kullanıcı **hiçbir şey görmez**.

---

## Otomasyon

```bash
export ADMIN_EMAIL="..."
export ADMIN_PASSWORD="..."
export TELLER_PASSWORD="..."
bash scripts/faz1-psychic-invite-probe.sh
```

Çıktı: `docs/FAZ1_LAST_PROBE.json`

---

## Kod dokunuşları (bu faz)

| Dosya | Değişiklik |
|-------|------------|
| `psychic_push_payload.dart` | `evaluatePsychicIncomingInvite`, nested `user` ayrımı |
| `psychic_invite_diagnostic_card.dart` | Ekran teşhisi |
| `push_lifecycle_listener.dart` | Son filtre kaydı |
| `onesignal_bootstrap.dart` | `externalUserId` |
| `notifications.ts` / `onesignal.ts` | OneSignal HTTP status log |

---

## Başarı kriterleri

1. İlhamperisi panelinde 7 alan + 3 senaryo sonucu görünür.
2. Admin randevu sonrası pending API’de istek görünür **veya** push `shouldPresent=true` ile kuyruğa girer.
3. Nested `user` trap unit test geçer.
4. Red durumunda `reason` açık metin olarak raporlanır.

---

## FAZ 2 (bu belgenin dışı)

- APK CI / sürüm bump
- Üretim deploy sonrası tekrar probe
- Çift bildirim (SSE + push dedup) iyileştirmesi
