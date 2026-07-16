# Flutter ↔ Backend Uyumluluk Raporu

**Güncelleme:** 16 Temmuz 2026  
**Tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](./FLUTTER_ENTegrasyon_KILAVUZU.md)

---

## Özet

Bu rapor, mobil servis katmanı (`mobile/lib/services/`) ile **canlifal.com** üretim API’sinin son hizalamasını özetler. Yeni uçlar bu oturumda eklendi; mevcut feature modülleri kademeli olarak bu servislere yönlendirilebilir.

| Alan | Durum | Flutter |
|------|--------|---------|
| Apple Sign-In | ✅ | `AuthService.loginWithApple` / `signInWithApple` |
| Mobil config | ✅ | `ConfigService.getConfig` + `MobileConfigGate` |
| Şifre değiştirme | ✅ | `AuthService.changePassword` + profil güvenlik sayfası |
| Kullanıcı engelleme | ✅ | `UserService.blockUser` (toggle) + `getBlockedUsers` |
| Kullanıcı şikayet | ✅ | `UserService.reportUser` |

---

## Yeni endpoint tablosu

| Metot | Servis | Path | Body / Query | Yanıt |
|--------|--------|------|--------------|-------|
| POST | `AuthService` | `/api/auth/mobile-apple` | `{identityToken, fullName?, referralCode?}` | Login ile aynı (`accessToken`, `refreshToken`, `user`, `isNewUser`) |
| GET | `ConfigService` | `/api/mobile/config` | `?platform=ios\|android&version=x.y.z` | `{success, data: {maintenance, version, features, ads, links}}` |
| POST | `AuthService` | `/api/auth/change-password` | `{currentPassword, newPassword}` | Bearer gerekli |
| POST | `ConfigService` | — | — | Public (auth yok) |
| POST | `UserService` | `/api/user/block` | `{userId}` | `{success, blocked, message}` — toggle |
| GET | `UserService` | `/api/user/block` | — | `{success, data: [{userId, name, username, image, blockedAt}]}` |
| POST | `UserService` | `/api/user/report` | `{userId, reason, details?}` | `{success, message, reportId}` |

### Apple Sign-In notları

- Paket: `sign_in_with_apple`
- iOS Service ID: `APPLE_SERVICE_ID` (`Env.appleServiceId`)
- `fullName` yalnızca ilk girişte Apple’dan gelir → `AppleFullName.toJson()`
- UI: `AuthSocialSection` — `Env.hasAppleLogin` true ise buton görünür

### Mobil config — uygulama açılışı

`MobileConfigGate` (`app.dart`):

| `data` alanı | Davranış |
|--------------|----------|
| `maintenance.enabled` | Tam ekran bakım (`MaintenanceScreen`) |
| `version.forceUpdate` | Zorunlu güncelleme (`ForceUpdateScreen`) |
| `version.optionalUpdate` | İsteğe bağlı dialog (oturumda bir kez) |
| `features.*` | `mobileFeatureFlagsProvider` — modül görünürlüğü |

### Şikayet nedenleri (`reason`)

`harassment`, `spam`, `inappropriate_content`, `fake_account`, `scam`, `other`

Aynı kullanıcı + aynı neden → 24 saat içinde tekrar şikayet edilemez (sunucu kuralı).

### Engelleme — geriye dönük uyum

`UserService.blockUser` önce `POST /api/user/block` dener; 404/405’te kılavuzdaki `POST /api/user/blocked` + `{blockedUserId}` yedeğine düşer.

---

## Dosya haritası

| Dosya | Açıklama |
|-------|----------|
| `mobile/lib/services/auth_service.dart` | `loginWithApple`, `signInWithApple`, `changePassword` |
| `mobile/lib/services/config_service.dart` | `getConfig` |
| `mobile/lib/services/user_service.dart` | `blockUser`, `getBlockedUsers`, `reportUser` |
| `mobile/lib/services/models/apple_full_name.dart` | Apple `fullName` DTO |
| `mobile/lib/services/models/mobile_config.dart` | Config yanıt modelleri |
| `mobile/lib/services/models/user_action_models.dart` | Block / report modelleri |
| `mobile/lib/core/network/api_endpoints.dart` | `authMobileApple`, `mobileConfig`, `userBlock`, `userReport` |
| `mobile/lib/core/config/env.dart` | `APPLE_SERVICE_ID`, `hasAppleLogin` |
| `mobile/lib/core/bootstrap/mobile_config_gate.dart` | Bakım / güncelleme kapısı |
| `mobile/lib/core/bootstrap/mobile_config_providers.dart` | Riverpod provider’lar |

---

## Doğrulama

```bash
cd mobile && flutter test test/new_endpoints_test.dart
cd mobile && dart analyze
```

---

## Bilinçli sınırlar

| Konu | Not |
|------|-----|
| `features.*` → alt navigasyon | Provider hazır; sekme gizleme kademeli bağlanabilir |
| DM engelleme | `messages_remote_datasource` hâlâ eski `/api/user/blocked` — `UserService` tercih edilmeli |
| Backend değişikliği | **Yapılmaz** — yalnızca istemci |
