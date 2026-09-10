# CanlıFal — Flutter Entegrasyon Rehberi

Amaç: Flutter uygulamasının mevcut backend ile **birebir** çalışması. Yeni backend yazılmayacak, mevcut 852 endpoint kullanılacak.

## 1. Katman tasarımı

```
lib/
  core/
    api_client.dart        // Dio + interceptor (Bearer, 401 refresh, 409 confirm, 429 backoff)
    token_store.dart       // flutter_secure_storage
    api_exception.dart
    sse_client.dart        // text/event-stream okuyucu
  models/                  // data_models.json'dan üretilir
  services/
    auth_service.dart
    wallet_service.dart
    fortune_service.dart   // SSE akışlı fal üretimi
    teller_service.dart
    chat_service.dart
    stream_service.dart    // TRTC + yayın
    gift_service.dart
    payment_service.dart
    notification_service.dart
  features/                // ekranlar
```

## 2. Zorunlu paketler

| Paket | Amaç |
|---|---|
| `dio` | HTTP + interceptor |
| `flutter_secure_storage` | Token saklama |
| `tencent_trtc_cloud` | Canlı ses/görüntü, sesli oda, PK |
| `onesignal_flutter` | Push bildirimi |
| `app_links` (veya `uni_links`) | Derin bağlantı |
| `cached_network_image` | Avatar/hediye görselleri |
| `lottie` / `video_player` | Hediye animasyonları (Lottie + MP4/WebM) |

## 3. API istemcisi (çekirdek davranış)

```dart
class ApiClient {
  final Dio dio;
  ApiClient(this.dio) {
    dio.options.baseUrl = 'https://canlifal.com/api/v1';
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final t = await TokenStore.access();
        if (t != null) o.headers['Authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) async {
        final code = e.response?.statusCode;
        if (code == 401 && await TokenStore.hasRefresh()) {
          if (await AuthService.refresh()) {
            return h.resolve(await dio.fetch(e.requestOptions));
          }
          await AuthService.logout();
        }
        if (code == 409 && e.response?.data?['requiresConfirmation'] == true) {
          // Çağıran katmana taşı — kullanıcı onaylarsa gövdeye confirm:true eklenip tekrar gönderilir
          return h.next(e);
        }
        h.next(e);
      },
    ));
  }
}
```

## 4. SSE okuma

```dart
final req = http.Request('GET', Uri.parse('$base/notifications/stream'))
  ..headers['Authorization'] = 'Bearer $token'
  ..headers['Accept'] = 'text/event-stream';
final res = await http.Client().send(req);
res.stream
  .transform(utf8.decoder)
  .transform(const LineSplitter())
  .where((l) => l.startsWith('data:'))
  .map((l) => jsonDecode(l.substring(5).trim()))
  .listen(handleEvent);
```

Akış kopmalarında **üstel geri çekilme ile yeniden bağlanın**; sunucu son olay kimliğini payload içinde taşır, `?since=<id>` ile boşluk doldurulabilir.

## 5. Ekran → endpoint eşlemesi (ana akışlar)

| Ekran | Başlıca endpoint’ler |
|---|---|
| Giriş / kayıt | `/api/auth/mobile-login`, `/mobile-register`, `/mobile-refresh`, `/mobile-google`, `/mobile-apple`, `/mobile-tiktok` |
| Ana sayfa | `/api/homepage-*`, `/api/activities`, `/api/presence/online-events`, `/api/trends` |
| Fal üretimi | `POST /api/fortunes/{tur}` (SSE akış), `/api/fortune-access`, `/api/fortune-request-types` |
| Canlı falcılar | `/api/fortune-tellers`, `/api/fortune-tellers/{id}`, `/api/favorite-tellers`, `/api/fortune-tellers/sessions/stream` |
| Canlı yayın | `/api/video-streams*`, `/api/live/*`, `/api/trtc/usersig`, `/api/pk/*` |
| Sesli oda | `/api/chat/rooms/*`, `/api/room/*`, `/api/music`, `/api/games/*` |
| Hediye | `/api/gifts*`, `/api/gift-engine`, `/api/animations`, `/api/effects` |
| Cüzdan | `/api/wallet`, `/api/jeton`, `/api/withdrawals`, `/api/credit-packages`, `/api/daily-login`, `/api/daily-missions` |
| Ödeme | `POST /api/payments/notify`, `GET /api/payments/notify`, `POST /api/payments/notifications/{id}/dispute` |
| Üyelik | `/api/memberships`, `/api/membership`, `/api/membership-badges` |
| Sosyal | `/api/social`, `/api/short-videos`, `/api/stories`, `/api/hashtags`, `/api/messages` |
| Rüya | `/api/dreams*`, `/api/dream-diary`, `/api/dream-symbols`, `/api/dream-contest`, `/api/weekly-dream-report` |
| Profil | `/api/user`, `/api/me`, `/api/profile-frames`, `/api/avatar-accessories`, `/api/entrance-effects`, `/api/name-effects`, `/api/mic-frames`, `/api/chat-bubbles` |
| Bildirim | `/api/notifications`, `/api/notifications/stream`, `/api/devices` |
| Destek | `/api/support`, `/api/contact` |
| Turnuva/Lider | `/api/tournaments`, `/api/leaderboards`, `/api/teams`, `/api/supporter-levels` |
| Ajans | `/api/agency/*` |
| Referans | `/api/referral` |

Tam liste için `ENDPOINTS.md` ve `endpoints_index.json`.

## 6. Model üretimi

`data_models.json` her modelin alan adı, Prisma tipi ve Dart karşılığını içerir. Bu dosyadan `json_serializable` uyumlu sınıflar üretilebilir. Kurallar:

- `DateTime` alanlar ISO-8601 string olarak gelir → `DateTime.parse`.
- `Decimal`/`Float` → `double`; JSON’da sayı olarak gelir, `num.toDouble()` ile güvenceye alın.
- `Json` alanlar → `dynamic` / `Map<String, dynamic>`.
- İlişki alanları (`type` skaler değilse) API yanıtında **her zaman gelmez**; ilgili endpoint’in `select`’ine bağlıdır → nullable tanımlayın.

## 7. Sayfalama

`lib/pagination.ts` iki mod destekler:
- **Offset:** `?page=1&limit=20` → `{ items, total, page, totalPages }`
- **Cursor:** `?cursor=<id>&limit=20` → `{ items, nextCursor, hasMore }`

Hangi modun geçerli olduğunu `endpoints_index.json` içindeki `queryParams` gösterir.

## 8. Yanıt biçimleri (dikkat)

Projede iki biçim bir arada bulunur:
- **Sarmalanmış:** `lib/api-response.ts` → `{ success, data, meta }` / `{ success:false, error:{ code, message } }`
- **Düz:** çoğu eski route doğrudan nesne döner; hata için `{ error: "..." }`

Flutter istemcisinde tek bir çözücü yazın: gövdede `success` alanı varsa `data`’yı açın, yoksa gövdenin kendisini kullanın. Hata mesajı için önce `error.message`, sonra `error` string’ine bakın.

## 9. Idempotency

Hediye gönderme, üyelik satın alma, para çekme gibi uçlarda sunucu `beginIdempotent`/`completeIdempotent` kullanır. İstemci ağ hatasında aynı isteği tekrar gönderdiğinde **çift kayıt oluşmaz**; `endpoints_index.json` içindeki `idempotent: true` bayrağı bu uçları işaretler.

## 10. Teslim kontrol listesi

- [ ] Bearer interceptor + 401 refresh döngüsü
- [ ] 409 `requiresConfirmation` onay diyaloğu
- [ ] 429 geri çekilme
- [ ] SSE yeniden bağlanma
- [ ] TRTC UserSig akışı + izinler (kamera/mikrofon)
- [ ] OneSignal kayıt + `/api/devices` ile cihaz eşleştirme
- [ ] Derin bağlantı yönlendirme
- [ ] Jeton / CFC ayrımının arayüzde doğru gösterimi
- [ ] Yayın sırasında media-heartbeat
- [ ] Hata biçimi çift mod çözücü
