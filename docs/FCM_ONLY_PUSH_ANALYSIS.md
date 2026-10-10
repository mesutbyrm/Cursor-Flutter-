# FCM-only push — mevcut sistem analizi (2026-10-10)

## Özet

| Katman | Mevcut durum | FCM-only hedef |
|--------|----------------|----------------|
| **Flutter** | OneSignal SDK birincil; FCM yalnızca OneSignal kapalıyken veya Android teslimat tüneli | **FCM birincil** (`USE_FCM_ONLY=true` varsayılan) |
| **canlifal.com backend** | `lib/push.ts` → `PUSH_PROVIDER='onesignal'`; gönderim **yalnızca** OneSignal REST (`external_id` = userId) | **Deploy gerekli:** FCM HTTP v1 / Admin SDK + `UserDevice` tokenları |
| **Token kaydı** | `POST /api/user/device-token` + `POST /api/auth/mobile/device-token` (aynı handler) | `provider: 'fcm'`, ham FCM token |
| **SSE / polling** | Bildirim listesi, mesaj, canlı olaylar | **Değişmez** — push yerine geçmez |

**Kritik:** Flutter FCM-only tek başına yeterli değildir; üretim hâlâ OneSignal ile push gönderiyorsa cihazda bildirim gelmez. Backend geçişi ayrı deploy adımıdır (`docs/FCM_BACKEND_DEPLOY_FCM_ONLY.md`).

---

## 1. Firebase / Android (Flutter repo)

| Öğe | Değer / durum |
|-----|----------------|
| Firebase proje | `canlifal-android` (`firebase_options_generated.dart`) |
| Messaging sender | `24667749197` |
| Android paket | `com.mesutbyrm.canlifal` |
| `google-services.json` | `mobile/android/app/google-services.json` (CI/release; repoda `.gitignore` olabilir) |
| Dart define alternatif | `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` |
| Bağımlılıklar | `firebase_core`, `firebase_messaging ^15.2.5`, `flutter_local_notifications` |
| Android izin | `POST_NOTIFICATIONS` (`AndroidManifest.xml`) |
| OneSignal App ID | `578518ed-7b16-46a9-a1e6-7692d3ba55d8` (`onesignal_config.dart`, override: `ONESIGNAL_APP_ID`) |

**Init sırası (eski):** `OneSignalBootstrap.init()` → `FirebaseBootstrap.init()`. OneSignal hazır olunca FCM foreground/tıklama dinleyicileri **bilerek** bağlanmıyordu (çift bildirim).

---

## 2. Flutter — token ve oturum

| Dosya | Rol |
|-------|-----|
| `push_registrar.dart` | Token çözümü: OneSignal aktifken OS token; değilse `FirebaseMessaging.getToken()`. Sunucu: `registerUserDeviceToken`, `authMobileDeviceToken`. |
| `auth_service.dart` | Logout: `DELETE /api/user/device-token` + FCM token body |
| `push_lifecycle_listener.dart` | Giriş: `OneSignal.login(userId)` + kayıt; çıkış: `OneSignal.logout()` |
| `push_notification_service.dart` | Foreground FCM → yerel bildirim; kanallar (`AppNotificationChannel`); deep link `PushNavigationHandler` |
| `firebase_bootstrap.dart` | `onBackgroundMessage` — eski hali yalnızca log |
| `notification_diagnostics_page.dart` | Test: `POST /api/notifications/test-push` (sunucu OneSignal yanıtı) |

**Logout boşluk (FCM-only öncesi):** OneSignal aktifken `_deregisterStaleFcmToken` FCM kaydını siliyordu; OneSignal token kayıtlı kalıyordu. FCM-only modda yalnızca FCM token kaydı kullanılır.

---

## 3. Backend canlifal.com (kaynak: `mesutbyrm/canlifal` full-source)

### Gönderim

- **`lib/push.ts`** — tek giriş: `sendPush` / `sendPushBulk` → **`lib/onesignal.ts`**
- **`lib/notify.ts`** — DB bildirimi + `sendPushToUser` (OneSignal)
- OneSignal hedefleme: `include_aliases.external_id = [userId]` (Flutter `OneSignal.login(userId)`)

### Token depolama

- Mobil: `POST /api/user/device-token` → `app/api/devices/fcm/route.ts` (UserDevice / DevicePushToken)
- **`provider: 'onesignal'`** ile platform alanına yazılıyor; tokenlar **gönderimde kullanılmıyordu** (`push.ts` yorumu)

### Olay kapsamı (notify + sendPush çağrıları — örnek tipler)

Mesaj, takip, beğeni, yorum, hediye, canlı yayın (`live_started`, `stream_start`), PK, ödeme (`payment_*`, `jeton_*`, `cfc_*`), fal (`session_request`, `session_update`), moderasyon, duyuru — **sunucu `type` + `targetPath` + `targetId` + `urgent`** taşır; Flutter `PushNavigationHandler` ile aynı sözleşme.

### Firebase Admin

- Üretim anahtar: `https://canlifal.com/canlifal-firebase-adminsdk.json` (repoda `.gitignore`; `scripts/sync-canlifal-config.sh`)
- **FCM HTTP v1 gönderim kodu** full-source’ta push yolunda **henüz bağlı değil** (2026-10-10 analiz).

---

## 4. OneSignal pasifleştirme (Flutter — bu PR)

- `PushConfig.useFcmOnly` varsayılan **true** → OneSignal SDK init yok
- FCM: token yenileme, foreground/background/opened-app, arka plan handler’da yerel gösterim (data-only)
- Kayıt payload: `provider: 'fcm'`
- `--dart-define=USE_FCM_ONLY=false` ile eski OneSignal davranışı (geçiş / A-B)

---

## 5. Backend geçiş (deploy onayı gerekir — yapılmadı)

1. `lib/fcm-push.ts` — Admin SDK, kullanıcının tüm `UserDevice.token` kayıtlarına multicast
2. `lib/push.ts` — `PUSH_PROVIDER=fcm` iken OneSignal çağrılmaz; `ONESIGNAL_SEND_DISABLED=1` ile gönderim no-op
3. `notify.ts` — değişmeden `sendPush` üzerinden gider
4. Test push ucu FCM yanıtını döndürmeli
5. Kademeli: önce FCM açık + OneSignal kapalı env; çift gönderim izleme

Parity şablon: `backend-parity/nextjs_space/lib/fcm-push.ts`, `push.ts` (FCM dalı).

---

## 6. Test durumu

| Test | Ortam |
|------|--------|
| Unit | `push_navigation_handler_test`, `message_notification_test`, `push_config_test` |
| **Redmi Note 13 Pro 5G** (kullanıcı listesi) | **BLOCKED** — Cloud Agent’ta fiziksel cihaz yok |
| Zorla durdur (Ayarlar) | Android FCM teslimi **garanti edilmez** — dokümante |

---

## 7. Kabul kriterleri eşlemesi

| Kriter | Flutter (bu değişiklik) | Backend (deploy sonrası) |
|--------|-------------------------|---------------------------|
| OneSignal push yok | SDK init kapalı | REST gönderim kapalı |
| FCM push | Token + UI hazır | Admin SDK gönderim |
| Çift bildirim yok | Tek kanal (FCM local) | Tek provider |
| Doğru deep link | Mevcut handler | `data` alanları aynı |
| SSE bozulmaz | Dokunulmadı | Dokunulmadı |
