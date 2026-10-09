# VOICE ROOM → HOME LEAVE FIX — 1.0.747+800 (2026-10-09)

Kapsam: yalnız Sesli Oda → Ana Sayfa çıkışındaki presence/leave. Hediye, PK, müzik, Riverpod/TRTC/SSE mimarisi ve backend değişmedi.

## 1. Kanıt (cihaz logcat, 1.0.746+799)

- `04:56:04` Oda A → Oda B: `LEAVE_START source=room_switch` → `LEAVE_PRESENCE` → `presence leave response accepted=true` → `live leave-room ok=true` → `TRTC_EXIT` → `STATE_CLEAR` → `SSE disposed` → `POLLING_CANCEL` → `LEAVE_COMPLETE`. **Room A → B zinciri eksiksiz.**
- `04:56:05`–`04:56:48` Oda B: join, SSE ve presence tikleri. Kullanıcı sağ üstteki kapatma tuşuna bastı → logda **hiç `LEAVE_START` / `ROOM LEAVE` / `LEAVE_PRESENCE` yok**.
- Aynı oturumda tekrar eden `ui.zone error=NoSuchMethodError …` ve `Bad state: Tried to read the state of an uninitialized provider` hataları var: UI tarafında istisnalar zone'a düşüyor.
- Backend (`canlifal` `app/api/chat/rooms/[roomId]/presence/route.ts` DELETE): `lastSeen = epoch` (+ intentional ise `seatIndex=-1`) ve SSE leave yayını. Oda listesi (`app/api/chat/rooms/route.ts`) yalnız `lastSeen ≥ now-60s` olanları sayıyor. **Sunucuya leave ulaşırsa kullanıcı listeden anında düşer.** Sorun, leave isteğinin hiç gönderilmemesi.

## 2. Kök neden

1. **Kapatma tuşu yolu** (`VoiceRoomLeaveFlow.leaveWithSummary`):
   - Akış sırası: `prepareLeave` (korumalı) → hediye/ziyaretçi özeti → `leaveRoomSession`.
   - Özet adımı korumasızdı. Burada atılan bir istisna dış `catch`'e düşüyor, `navigateAwayFromRoom` çağrılıyor ve **`leaveRoomSession` hiç çalışmıyordu**. Logda `LEAVE_START` olmamasının açıklaması bu.
   - Ardından oda sayfası `dispose`'u, `_leaveSessionStarted=true` olduğu için kendi leave'ini de atlıyordu.
2. **Güvenlik ağı (`VoiceRoomRoutePresenceGuard`) hiç çalışmıyordu:**
   - Rota yalnız `build`'de okunuyordu. Widget `MaterialApp`'in üstünde olduğu için gezinmede yeniden build edilmiyor, Ana Sayfa'ya geçiş hiç algılanmıyordu.
   - `clearStaleVoicePresenceOnAuth(ref as Ref)`: `WidgetRef` → `Ref` dönüşümü çalışma anında `TypeError` verip `_leaveInFlight=true` kilidini açık bırakıyordu.
   - `shouldLeaveVoiceRoomRoute` doğru: `/feed` muaf değil.

Not: Özetteki istisnanın kesin sınıfı obfuscated build'de çözülemedi. Yeni log fazları (`LEAVE_UI`, `LEAVE_SUMMARY_SKIPPED error=<tip>`) cihazda bunu gösterecek.

## 3. Uygulanan düzeltmeler

| Dosya | Değişiklik |
|-------|-----------|
| `mobile/lib/features/voice_hub/presentation/utils/voice_room_leave_flow.dart` | Özet bloğu `try/catch` içinde. Hata `LEAVE_SUMMARY_SKIPPED` olarak loglanır ve `leaveRoomSession(force:true, awaitBackend:true)` **her durumda** çalışır. Leave hatası `LEAVE_FAILED`, tıklama `LEAVE_UI` olarak loglanır. `voiceRoomInStack()` yardımcısı eklendi. |
| `mobile/lib/features/voice_hub/presentation/widgets/voice_room/voice_room_route_presence_guard.dart` | Bkz. aşağıdaki liste. |
| `mobile/lib/features/voice_hub/data/services/voice_room_debug_log.dart` | Release'de de görünen fazlar: `LEAVE_UI`, `LEAVE_SUMMARY_SKIPPED`, `LEAVE_FAILED`, `ROUTE_LEFT_VOICE_ROOM`. |
| `mobile/test/features/voice_hub/voice_room_home_leave_test.dart` | 6 yeni test. |
| `mobile/pubspec.yaml`, `mobile/CHANGELOG.md` | 1.0.747+800. |

`voice_room_route_presence_guard.dart` değişiklikleri:
- `routerDelegate` dinleyicisiyle gezinmeyi gerçekten izliyor.
- Yığında (push edilen sayfalar dahil) oda sayfası kaldığı sürece çıkış yapmıyor; örneğin odanın üstüne profil açıldığında.
- Odadan çıkış algılanırsa ve aktif oda varsa tek `leaveRoomSession(force:false)` çağırıyor. Bu çağrı devam eden ya da bitmiş leave ile birleşir, çift leave olmaz.
- `ref as Ref` kaldırıldı; kilit `finally` içinde açılıyor.

Çıkış sırası (mevcut `leaveRoomSession`, değişmedi):
1. Polling/timer iptali, SSE kapatma ve heartbeat durdurma, mic gate temizliği, TRTC reconnect askıya alma
2. Presence leave (`DELETE ?leave=1`)
3. Live `leave-room`
4. TRTC exit
5. `STATE_CLEAR`
6. SSE/polling dispose
7. `LEAVE_COMPLETE`

Leave başında `_sessionActive=false` ve `_liveSessionGeneration++` yapılıyor. Yeni join ve SSE reconnect girişlerinde `BLOCKED_IMPLICIT_JOIN` kontrolleri (1.0.745) olduğu gibi duruyor.

## 4. Test sonuçları

| Kontrol | Sonuç |
|---------|-------|
| `dart analyze lib` | 0 error. 435 info/warning; değişiklik öncesiyle aynı, yeni uyarı yok |
| `flutter test test/features/voice_hub/voice_room_home_leave_test.dart` | PASS 6/6 |
| `flutter test` (tam) | PASS: 2225 geçti, 2 atlandı |
| Release derleme (`flutter build apk --release --obfuscate`) | **BLOCKED (yerel):** Dart derlendi, Gradle `assembleRelease` ağdan artifact indiremedi ("Gradle threw an error while downloading artifacts from the network"). Release APK merge sonrası CI `build-apk.yml` ile derlenecek. PR CI: Flutter test gate ✅, API + Flutter analyze ✅ |

Yeni testler:
- `/feed` ve `/voice-rooms` route kontrolü
- Yığında oda varken leave yok
- **Room → Home:** tek `route_left_voice_room` leave
- **Room A → Room B:** guard leave göndermez
- Oda üstüne profil push: leave yok
- UI leave sonrası (aktif oda temizlenmiş) çift leave yok

Unit testle doğrulanamayanlar:
- Çıkıştan sonra SSE reconnect veya heartbeat ile yeniden join olmaması: controller tam DI gerektiriyor; mevcut generation/`_sessionActive` korumaları değiştirilmedi. → Cihazda **BLOCKED**.
- Özet istisnası senaryosu (`leaveWithSummary` BuildContext + gerçek provider'lar ister). → Cihazda **BLOCKED**.

## 5. Cihazda doğrulanması gerekenler (hepsi BLOCKED)

| # | Senaryo | Beklenen log |
|---|---------|--------------|
| 1 | Odaya gir → sağ üst kapatma → Evet → Ana sayfa | `LEAVE_UI` → (varsa `LEAVE_SUMMARY_SKIPPED error=…`) → `LEAVE_START source=rtc_leave` → `presence leave response accepted=true` → `live leave-room ok=true` → `LEAVE_COMPLETE` |
| 2 | Çıkıştan 30 sn sonra | `PRESENCE_JOIN`, `SSE_START`, `JOIN_START` veya `api.presence.join` **yok** |
| 3 | İkinci cihazda oda listesi | Kullanıcı ≤ 60 sn içinde (normalde anında) listeden düşer; oda online sayısı azalır |
| 4 | Oda A → Oda B | Öncekiyle aynı `room_switch` zinciri; tek leave |
| 5 | Oda içinden profil aç → geri dön | `ROUTE_LEFT_VOICE_ROOM` **yok**, odada kalır |
| 6 | Odadayken bildirime tıkla → ana sayfa | `ROUTE_LEFT_VOICE_ROOM` + tek `LEAVE_START` |

Logcat filtresi:

```
tag:flutter message~:"LEAVE_|ROOM LEAVE|ROUTE_LEFT|PRESENCE_JOIN|SSE_START|JOIN_"
```

## 6. Kapsam dışı / açık

- `NoSuchMethodError: 'xHc<List<Mya>>' … getter 'SCh'` ve "uninitialized provider" (`JOIN_START` anında, yeni provider örneğinde) hâlâ logda. Ayrı iş: `canlifal-1.0.747+800-symbols` CI artifact'ı ile `flutter symbolize` gerekli.
- `401` DioException'lar (oda girişinde) bu görevin kapsamı dışında.
