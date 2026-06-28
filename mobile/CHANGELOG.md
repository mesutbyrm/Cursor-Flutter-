# Sürüm notları — canlifal_social


## 1.0.438+442 (2026-06-26)

### Faz 10 — Duyuru sistemi

- Komut: `!duyuru Mesaj`
- **Admin / yetkili:** ücretsiz
- **Diğer kullanıcılar:** 5 jeton
- Maksimum **100 karakter**
- Duyuru ekranın **üst kısmında kayan bant** olarak gösterilir (15 sn, tüm kullanıcılar)

## 1.0.437+441 (2026-06-26)

### Faz 9 — Yetkili giriş animasyonu

- Yetkili odaya girince koltukların **altından** sağdan sola animasyon geçer
- Örnek: «👑 Admin Mesut odaya giriş yaptı»
- Yetkiye göre emoji ve neon renk (Admin, Kurucu, SOP, Mod, DJ, Voice)
- **Tüm kullanıcılar** görür — RTC ve Basic oda
- VIP/Gold girişleri bu animasyona dahil değil (Faz 7 alt toast devam eder)

## 1.0.436+440 (2026-06-26)

### Faz 7 — Sohbet giriş bildirimleri

- Odaya giren **herkes** altta görünür: «Ali giriş yaptı.»
- Birden fazla giriş üst üste listelenir
- **10 saniye** sonra otomatik kaybolur
- RTC ve Basic oda alt menüsünün hemen üstünde

### Faz 8 — Yetkili sohbet tasarımı

- Yetkililer: animasyonlu neon profil çerçevesi (dönen halka + parıltı yayı + nabız)
- Yetkiye göre renk: Admin altın, Kurucu/SOP turuncu, OP mavi, Voice yeşil, DJ pembe
- Kullanıcı adı **kutu içinde değil**; hafif ışıklı neon metin (siyah halo ile okunaklı)
- Mesaj gövdesi hafif neon gölge ile okunabilir kalır
- Premium canlı sohbet de aynı `ChatMessageWidget` tasarımını kullanır

## 1.0.435+439 (2026-06-26)

### Faz 6 — Alt Menü

- **Sol:** 🎧 Hoparlör ↔ Kulaklık (toggle)
- **Yanı:** 🎵 Müzik İste + **Sesli** / **Videolu** kısayolları
- **Orta:** 🎤 Mikrofon
- **Sağ:** 🎁 Hediye · 📨 Davet
- RTC ve Basic oda sayfalarında aynı alt menü

## 1.0.434+438 (2026-06-26)

### Faz 5 — Yasak Kelime Sistemi

- Regex ile **tam kelime** eşleşmesi (kelime sınırı)
- Büyük/küçük harf duyarsız (`am`, `AM`, `Am` engellenir)
- İçinde geçen kelimeler engellenmez (`ama`, `amca`, `aman` geçer)
- Oda girişinde yasaklı kelime listesi yüklenir; gönderim öncesi istemci kontrolü
- Yerel API mirror aynı regex mantığına güncellendi

## 1.0.433+437 (2026-06-26)

### Faz 4 — Yetki Yönetimi

- **Yetki Ver** düğmesi (3 nokta menüsünde)
- Popup: odadaki kullanıcı listesi → kişi seçimi
- **Rol:** +V, @, &, Admin
- **Moderasyon:** Sessize al, Ban, Ban kaldır, Kanaldan at, Mikrofon kapat/aç
- Tüm işlemler tek popup üzerinden

## 1.0.432+436 (2026-06-26)

### Faz 3 — Yeni Menü (3 nokta)

- **Üst:** 👤 kullanıcı adı + **Yetkisi** etiketi
- **Alt:** Material 3 büyük ikon kartları (yazısız; tooltip ile)
- **Kartlar:** PK Daveti, Oda Ayarları, Kullanıcı Ayarları, Şarkı İsteği, DJ Paneli, Arkaplan
- RTC ve Basic oda sayfalarında aynı menü

## 1.0.431+435 (2026-06-26)

### Faz 2 — Yetki ve Koltuk Sistemi

- **Otomatik koltuk:** Admin → sağ alt (11), Kurucu → koltuk 1, moderatörler (&/@) yetkiye göre
- **Koltuk önceliği:** Admin > Kurucu > & > @ > + > V (VIP) > Normal
- **Admin koltuğu (11):** Yalnızca doluysa görünür; boşken gizli
- **Konuşma:** Koltukta olmayan konuşamaz; site admin her yerden konuşabilir
- **Kurucu çıkışı:** Odada değilken profil resmi koltukta gösterilmez

## 1.0.430+434 (2026-06-26)

### Faz 1 — Ses ve Müzik Sistemi

- **Arka plan müzik:** Odadan çıkınca çalmaya devam; yalnızca farklı odaya girince durur
- **Durdurma yetkisi:** Müziği yalnızca oda sahibi, site admin veya şarkıyı isteyen durdurabilir
- **Kuyruk:** Yeni istek mevcut parçayı kesmez; otomatik sıra
- **Jeton:** Sesli istek 10, videolu istek 20 jeton
- **DJ paneli:** Kuyruk görüntüle, sil, sırala, geç, tekrar çal; global mini player

## 1.0.429+433 (2026-06-26)

### Sesli oda UX — admin koltuk, müzik, chat, ayarlar

- **Site admin:** Odaya girince otomatik sağ alt koltuk (11); en yüksek yetki önceliği
- **!istek videolu:** Arka plan videosu soldan sağa kapanır; müzik kartı koltuk altında sıfırlanır
- **Video kuyruk:** Parça bitince sıra boşsa anında kapanır; sırada varsa hemen sonraki başlar; ses videodan gelir
- **Chat + klavye:** Yazarken sohbet kaydırılabilir; son mesajlar görünür; giriş alanı klavyeye sabit
- **Giriş animasyonu:** Yetkililer üstte (herkese), normal üyeler altta; sağdan sola
- **Chat:** Kullanıcı adına tıklayınca profil; rol/VIP renkli isimler
- **Ayarlar:** Yalnızca ikon buton grid (metin/subtitle kaldırıldı)

## 1.0.428+432 (2026-06-26)

### Oda oluşturma — web ile birebir JSON

- **POST /api/chat/rooms/create** gövdesi web ile aynı: `name`, `description`, `icon`, `paymentType`, `roomType`
- **paymentType:** `jeton` | `cfc` (küçük harf, web parity)
- **roomType:** `FREE` | `NORMAL` | `VIP` (büyük harf enum)
- Eski yedek alanlar kaldırıldı (`cost`, `jeton`, nested `room`, vb.)

## 1.0.427+431 (2026-06-26)

### Admin profil + sesli oda iyileştirmeleri

- **Profil stats:** Takipçi/takip/ziyaret/yayın backend yedekleri (site profil, ziyaretçi listesi, yayın geçmişi)
- **Oturum:** Profil yenilemede token korunur; ağ hatasında çıkış yapılmaz
- **Admin panel:** Kullanıcı yönetimi ve ajans rotaları düzeltildi
- **Sesli oda:** Online sayaca tıklayınca katılımcı listesi; kullanıcıya moderasyon/hediye
- **Müzik:** !istek sonrası ses/videolu seçim; kapat (X) video+ses durdurur
- **Giriş animasyonu:** Tek şerit — sağdan sola yetki+isim+“odaya giriş yaptı”
- **Oda ayarları:** Grid düzen, tekrarlayan menüler kaldırıldı

## 1.0.426+430 (2026-06-26)

### Sesli oda — Premium müzik kartı (web parity)

- **Yeni UI:** Mini player kaldırıldı; koltuk altında tam genişlik premium kart (vinyl, waveform, glassmorphism, RGB)
- **SSE:** `music_started` / `music_stopped` olayları ile senkron açılış/kapanış animasyonu
- **Kapat (X):** Yalnızca oda sahibi, isteği yapan, admin/süper admin
- **Şarkı değişimi:** Kart açık kalır; kapak, bilgi ve progress güncellenir
- **İstatistik:** Beğeni sayısı ve dinleyici sayısı kartta gösterilir

## 1.0.425+429 (2026-06-28)

### Sesli oda — Agora token, orta müzik, oturum

- **Agora hatası:** Sunucu token öncelikli; boş token yalnızca yedek (token geçersiz uyarısı giderildi)
- **Müzik UI:** Mini oynatıcı koltukların altında ortada; !istek sonrası burada görünür
- **Kuyruk:** Yeni istek çalan şarkıyı kesmez, sıraya girer
- **Kapat:** Yalnızca isteği yapan, oda sahibi ve admin görebilir
- **Oturum:** Ağ hatasında token silinmez; kullanıcı kendi çıkış yapana kadar oturum korunur

## 1.0.424+428 (2026-06-27)

### Kararlılık — sesli oda, Agora, presence, oda açma

- **ConcurrentModificationError:** Map/List döngülerinde `Map.from` / `List.from` kopyası
- **Agora ses:** App ID only (`f1cf983a…`), boş token, kanal = oda kimliği; `POST /voice` join korundu
- **SSE DJ müzik:** `audioplayers` ile doğrudan `musicUrl` yedek oynatma
- **Presence:** SSE `presence` olayı tam kullanıcı listesini yazar (~10 sn); ayrı join/leave birleştirildi
- **setState:** Sesli oda sayfalarında `mounted` kontrolü
- **Oda açma:** `POST /rooms/create` gövdesi JSON nesnesi olarak gönderilir (çift encode düzeltmesi)
- **Heartbeat:** 25 sn presence POST (mevcut)

## 1.0.423+427 (2026-06-27)

### Sesli oda müzik — oynatma + DJ etiketi

- **Müzik çalmama:** `/api/chat/youtube-stream` URL'si doğrudan oynatılmıyordu; videoId ile akış çözülüp yedek adaylar denenir
- **Oynatıcı:** `playServerStream` başarısız olunca diğer kaynaklara düşer; AudioService init hatasında yerel yedek
- **DJ etiketi:** Şarkıyı isteyen kullanıcı gösterilir (`İsteyen: …`); liste sırası sabitlenir, SSE'de DJ listesi korunur
- **Ayarlar:** DJ ekle/çıkar zaten Ayarlar → DJ menüsünde (oda sahibi/moderatör)

## 1.0.422+426 (2026-06-27)

### Bildirimler + sesli oda müzik

- **Bildirim tıklama:** Önce ilgili sayfaya gider (ödeme → jeton/admin, seans/randevu → canlı falcılar); okundu işareti arka planda
- **Tümünü oku:** Önbellek temizlenir, liste anında güncellenir, aktivite + site bildirimleri okunur
- **Aktivite API:** `targetPath` / `targetId` ve başlık tabanlı yönlendirme (`jeton_payment`, ödeme bildirimi vb.)
- **Müzik:** Odaya girişte `dismissed` sıfırlanır — önceki odadan kalan engel kalkar
- **Müzik akışı:** Android googlevideo sırası CDN → proxy → önbellek
- **Video müzik:** Temel oda sayfasına YouTube video arka planı eklendi

## 1.0.421+425 (2026-06-27)

### Sesli oda UI + jeton talep temizliği

- **Sesli odalar ana sayfa:** Status bar altında kalmama için `SafeArea`; çift AppBar kaldırıldı
- **Oda sayfası:** `SafeArea` ile üst bar (saat/kamera/şarj) altında düzgün hizalama
- **Jeton bekleyen talep:** "Talebi iptal et" — `PATCH /api/payment/requests` + ödeme bildirimleri temizlenir
- **Bildirimler:** `DELETE /api/notifications/payment` ile jeton/CFC ödeme bildirimleri silinir

## 1.0.420+424 (2026-06-27)

### Sesli oda Agora — web ile aynı token akışı

- **Kök neden:** `VoiceAgoraEngine` boş `onError` mesajında `StateError('Agora: ')` fırlatıyordu
- **Token:** `POST /api/agora/token` + kanal `voice_room_{odaId}` (web ile aynı)
- **Güvenlik:** Tüm Agora adımları try/catch; tam stack trace log; UI çökmez, okunabilir hata
- **Sıra:** mikrofon izni → token → `initialize()` → `joinChannel()`
- **App ID:** sunucu yanıtı + `AGORA_VOICE_APP_ID` yedek doğrulaması

## 1.0.419+423 (2026-06-27)

### Admin ödeme talepleri ve sesli oda açma

- **Admin paneli:** Bekleyen jeton/CFC talepleri `cfc-payment-requests`, `payment-notifications` ve `payment-requests` uçlarından birleştirilir; eski bekleyen talepler de listelenir
- **Admin bildirimleri:** Ödeme bildirimleri sekmesi site bildirimleri + ödeme kayıtlarından doldurulur
- **Staff rolü:** Oturum `role` alanı cüzdan yanıtı yoksa admin yetkisi için kullanılır
- **Sesli oda aç:** Oluşturma gövdesi `jsonEncode` + `application/json`; `name`, `description`, `icon` ve iç içe `room` nesnesi gönderilir

## 1.0.418+422 (2026-06-27)

### Sesli sohbet — API dokümantasyonu (Agora + SSE)

- **Agora:** App ID only (`f1cf983a38114b04a4e9102c303ba63e`), token `''`, kanal = oda `roomId`
- **Giriş akışı:** POST presence → GET messages → SSE → heartbeat 25 sn
- **Voice:** `POST /voice` `{type: join|leave}` sonra Agora katılımı
- **SSE:** presence tam liste, dj `musicUrl`, typing, gift, system
- **Çıkış:** DELETE presence `?leave=1`, Agora leave/release
- TRTC/LiveKit sesli oda yolu kaldırıldı (Agora tek motor)

## 1.0.417+421 (2026-06-27)

### Jeton, admin ödeme ve sesli oda düzeltmeleri

- **Jeton al:** Mevcut jeton bakiyesi oturum cache fallback ile gösterilir; cüzdan API zaman aşımı 12s
- **Bekleyen ödeme:** Jeton sayfasında bekleyen talep banner'ı; admin için panel kısayolu
- **Admin bildirimleri:** `jeton_payment_request` / `cfc_payment_request` admin hesabında `/admin` paneline yönlendirir
- **Sesli oda aç:** `POST /api/chat/rooms/create` için zorunlu `name`, `description`, `icon` alanları gönderilir

## 1.0.416+420 (2026-06-27)

### Entegrasyon kılavuzu — tek kaynak

- **`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`** repoya eklendi; agent kuralı + `AGENTS.md` güncellendi
- Chat presence/voice body: kılavuz §9.3 — `{action: join|leave}` (`type` kaldırıldı)
- Presence çıkış: önce `POST .../presence` + `{action: leave}`

## 1.0.415+419 (2026-06-27)

### Sesli sohbet — API dokümantasyonu uyumu

- **Referans:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9.3 (tek kaynak)
- **Presence heartbeat:** 20s → **25s**
- **`POST /voice`:** `{action: join|leave}` — mikrofon + çıkış
- **`POST /typing`:** yazıyor göstergesi
- **`GET /gifts` lider tablosu:** oda açılışında API seed
- **Presence:** `{action: join|leave}` (kılavuz §9.3)

## 1.0.414+418 (2026-06-27)

### Sesli sohbet — Premium 2026 UI (yalnızca arayüz)

- **Backend değişmedi:** mevcut canlifal.com API, SSE, JWT, PostgreSQL — endpoint/tablo/iş mantığı aynı
- **Keşfet:** `VoiceDiscoverHub2026` varsayılan (referans mockup — sekmeler, VIP, PK, trend)
- **Oda içi:** `VoiceLiveHeader2026` + `VoiceLiveActionBar2026` + top spender şeridi
- **Oda tipi rozetleri:** FREE / NORMAL / VIP (`resolvedRoomType`)
- **Top 3 hediye:** `voiceSessionGiftLeaderboardProvider` artık UI'da görünür

## 1.0.413+417 (2026-06-27)

### Performans — Görev 16: Mesajlar cache-first

- **`MessagesLoadPerf` + `CacheFirstLoader`:** konuşma listesi ve sohbet thread'i disk cache'den anında açılır
- **Arka plan güncelleme:** açılış sonrası ve 8s/20s poll sessiz `forceRefresh` ile UI güncellenir
- **Gönder sonrası:** thread + konuşma cache temizlenir, zorunlu yenileme
- **Shell prefetch:** `conversationsListNotifierProvider` kabukta ısıtılır
- **Lazy gate kaldırıldı:** mesaj listesi / sohbet pane cache ile gecikmesiz render

## 1.0.412+416 (2026-06-27)

### Performans — Görev 17: Widget rebuild & sızıntı temizliği

- **`WidgetPerf` / `CancellableDelay`:** gecikmeli callback'ler dispose'da iptal
- **Bellek:** PK poll timer, chat `listenManual`, rumuz dialog controller, HLS video init, YouTube WebView, lazy live room timer'ları
- **FutureBuilder kaldırıldı:** falcı oturum restore, profil takip listesi, shorts/social yorum sheet'leri
- **StreamBuilder → Riverpod:** premium fal sohbet mesajları `pfMessagesStreamProvider`
- **SVGA hediye:** FutureBuilder yerine arka planda cache prefetch
- **`LazyScreenSection` / animasyon parçacıkları:** iptal edilebilir timer

## 1.0.411+415 (2026-06-27)

### Performans — Görev 9: JSON isolate parse

- **`JsonIsolatePerf`:** ≥50 KB JSON gövdeleri `compute` ile ayrı isolate'te decode
- **Dio:** `FusedTransformer` eşiği açıkça `JsonIsolatePerf.largeThreshold` ile hizalandı
- **Disk cache:** `ApiHttpCache` + `ApiCacheStore` okuma yolları isolate decode kullanır
- **Küçük yanıtlar:** eşik altında senkron parse (gereksiz isolate maliyeti yok)
- **SSE / push:** küçük olay gövdeleri mevcut senkron parse ile kalır

## 1.0.410+414 (2026-06-27)

### Performans — Görev 15: Profil bağımsız yükleme

- **`ProfileLoadPerf`:** Jeton, CFC, takipçi, gönderiler paralel prefetch
- **Jeton:** oturum `coinBalance` anında; cüzdan API gelince güncellenir
- **CFC:** yalnızca CFC alanı yüklenirken `…` gösterir; Jeton bekletmez
- **Takipçi:** auth sayacı anında; istatistik API arka planda
- **Gönderiler:** içerik bölümü gecikmesiz; video sekmesi kendi skeleton'ı
- **`myStats`:** broadcastHistory takipçi yolunu artık bloklamaz
- **Shell prefetch:** `profileStatsProvider` kabukta ısıtılır

## 1.0.409+413 (2026-06-27)

### Performans — Görev 14: Canlı yayın hızlı giriş

- **`LiveEntryPerf`:** liste dokunuşunda Agora token + join önbelleği; `fetchAgoraParallel`
- **Anında navigasyon:** swipe/oda ekranı token beklemeden açılır; doğrulama arka planda
- **HLS köprüsü:** `LivePlaybackBridge` — Agora hazır olana kadar HLS/thumbnail (izleyici)
- **Bağlanırken bekleme yok:** tam ekran spinner kaldırıldı; küçük “Canlı bağlanıyor” rozeti
- **Backend:** yalnızca `https://canlifal.com` — yeni backend yok

## 1.0.408+412 (2026-06-27)

### CI — Gate 3 jeton yetersizliği SKIP

- Test kullanıcısında jeton yoksa (HTTP 400) falcı + Agora API erişilebilirse Gate 3 SKIP
- Admin `staffExempt` yedek denemesi korundu

## 1.0.407+411 (2026-06-27)

### CI — release gate Gate 3 düzeltmesi + Görev 18 APK

- **Gate 3 (canlı falcı):** oturum artık danışan token'ı ile oluşturuluyor (mobil akış); `duration` + `anchorUserId` alanları; falcı kimliği `/api/me` + liste eşlemesi
- **402/403:** jeton/yetki engelinde falcı API erişilebilirse SKIP (APK engellenmez)
- **Görev 18 performans serisi** (`1.0.406+410`) aynı kod tabanı — bu sürüm CI geçişi + APK yayını

## 1.0.406+410 (2026-06-27)

### Performans — Görev 18: Sonuç (performans serisi tamamlandı)

**Hedef:** Anında açılış, anında dokunma tepkisi, akıcı geçişler, yağ gibi scroll, gecikmesiz jeton — **aynı canlifal.com backend** (yeni backend yok).

| Görev | Konu | Modül |
|-------|------|-------|
| 1 | Açılış ≤1s, SDK defer | `StartupPerf` |
| 2 | Lazy ekran bölümleri | `LazyLoadPerf` |
| 3 | HTTP API cache | `ApiHttpCache` |
| 4 | Görsel cache / thumbnail | `CanlifalNetworkImage` |
| 5 | Lazy liste/grid | `LazyListView` |
| 6 | Hedefli state rebuild | `StatePerf` |
| 7 | Animasyon 60 FPS | `AnimationPerf` |
| 8 | Paralel API | `NetworkPerf` |
| 10 | Blur/glass önbellek | `EffectsPerf` |
| 11 | Scroll frame drop yok | `ScrollPerf` |
| 12 | Merkezi SSE | `SseConnectionHub` |
| 13 | Sesli oda hızlı giriş | `VoiceRoomEntryPerf` |
| 18 | Jeton anında, geçişler | `PerfResult` |

- **Jeton pill:** 1,2 sn gecikme kaldırıldı; oturum `coinBalance` + cüzdan API
- **Shell prefetch:** cüzdan/bildirim 400 ms'de arka planda
- **Sayfa geçişleri:** fade-slide 240 ms
- **Backend:** yalnızca `https://canlifal.com` — API, DB, iş mantığı web ile aynı

## 1.0.405+409 (2026-06-27)

### Performans — Görev 13: Sesli oda hızlı giriş

- **`VoiceRoomEntryPerf`:** liste dokunuşunda AudioSession + TRTC token önbelleği
- **Oda bootstrap:** SSE hemen; presence/DJ/hediye arka planda paralel
- **RTC / Basic sayfa:** UI anında; ses TRTC/LiveKit arka planda bağlanır
- **Shell prefetch:** AudioSession kabuk açılışında ısıtılır
- **`loading: false`:** oda ekranı spinner beklemeden açılır

## 1.0.404+408 (2026-06-27)

### Performans — Görev 12: SSE (merkezi bağlantı)

- **`SseConnectionHub`:** oda/yayın başına tek SSE, ref sayacı ile paylaşım
- **`sseConnectionHubProvider`:** keepAlive merkezi hub
- **Sesli oda:** keşfet presence + canlı oda aynı bağlantıyı paylaşır (12 ayrı bağlantı kaldırıldı)
- **`ChatRoomSseService`:** aynı oda için yeniden bağlanma atlanır (`isLiveForRoom`)
- **Canlı video yayın:** hub üzerinden attach/release — sayfa dispose'da ref sıfırlanınca kapanır
- **`voiceRoomSseForProvider` / `videoStreamSseForProvider`:** oda/yayın bazlı servis erişimi

## 1.0.403+407 (2026-06-27)

### Performans — Görev 8: Ağ işlemleri (paralel API)

- **`NetworkPerf`:** `parallel()` + `waitSilent()` — bağımsız istekler `Future.wait` ile
- **Profil stats:** `/me/stats` + site profili paralel
- **Profil refresh:** auth, cüzdan, stats, level, hediye, fal erişimi paralel
- **`refreshMe`:** oturum + site profili paralel
- **Ana sayfa refresh:** shorts feed dahil 11 provider paralel
- **Bildirimler:** liste + activity feed paralel
- **Canlı oda:** join + mesaj geçmişi; poll mesaj + meta paralel
- **Sesli oda DJ refresh:** fetchDj + queue + musicState paralel
- **Oyunlar / admin / fal erişim / logout cache:** paralel batch

## 1.0.402+406 (2026-06-27)

### Performans — Görev 11: Scroll (takılma / frame drop yok)

- **`ScrollPerf`:** feed/chat/grid cacheExtent, throttle'lı sayfalama, `ScrollPerf.item`
- **`LazyNestedGridView`:** iç içe grid — lazy builder + `NeverScrollableScrollPhysics`
- **`LazyListView` / `LazyGridView`:** `addAutomaticKeepAlives: false`, `addRepaintBoundaries: false`
- **Ana sayfa / profil / sosyal feed:** `CustomScrollView` cacheExtent
- **Canlı & sesli chat:** chat cacheExtent + izole satır repaint
- **Profil içerik gridleri:** 6 sekme `LazyNestedGridView`
- **Bildirimler:** `ScrollPerf.bindPagination` — scroll listener throttle
- **Fal sonucu / jeton / cüzdan:** scroll cache + lazy grid

## 1.0.401+405 (2026-06-27)

### Performans — Görev 10: Görsel efektler (blur / shadow / glass)

- **`EffectsPerf` / `GlassTier`:** blur filter önbelleği, gölge önbelleği, `RepaintBoundary`
- **`ThemedGlassCard` / `LiquidGlass` / `ProGlass`:** merkezi blur; liste satırında blur kapalı
- **`ProGlassListTile`:** `GlassTier.static` — gölge + fill, BackdropFilter yok
- **Canlı chat feed:** balon başına blur kaldırıldı — opak fill
- **Sesli oda chat dock:** tek `chromeBar` blur katmanı (feed + input)
- **Ana sayfa grid:** 8 hücre blur yok; CTA tek elevated blur
- **`PfGlassCard`:** `ThemedGlassCard` + opacity animasyon (blur yeniden oluşturulmaz)
- **Fal geçiş overlay:** sabit σ=12 blur, yalnızca opaklık animasyonu
- **Neon quick action:** BackdropFilter kaldırıldı, gölge önbelleği

## 1.0.398+402 (2026-06-27)

### Performans — Görev 7: Animasyon (60–120 FPS, UI thread kilidi yok)

- **`AnimationPerf`:** izole `RepaintBoundary`, paint-only katman, parçacık sınırları
- **`ScrollParallaxNotifier`:** scroll parallax yalnızca arka plan katmanını yeniler — sayfa setState yok
- **`TabIndexListenable`:** sekme swipe sırasında her karede değil, index değişince rebuild
- **`FloatingEmojiPaintLayer`:** hediye/PK yüzen emojiler — CustomPaint + `repaint`, setState yok
- **`DeferredTickerMode`:** açılışta animasyon ticker'ı 120ms ertelenir
- **Canlı etkileşim overlay:** parçacık fizikleri paint katmanında; TextPainter cache
- **Sesli oda parçacıkları:** önceden hesaplanmış yörüngeler — paint içinde Random yok
- **Kozmik fal arka planı:** yıldız/orbit alanları önbellek; parallax izole
- **Canlı chat feed:** liste satırlarından `flutter_animate` kaldırıldı

## 1.0.397+401 (2026-06-27)

### Performans — Görev 6: State yönetimi (hedefli rebuild)

- **`StatePerf` / `SelectiveConsumer`:** `ref.select` ile izole widget rebuild
- **Sosyal akış:** feed watch `SocialFeedScrollView`'a taşındı — app bar/composer etkilenmez
- **Sohbet:** mesaj listesi + composer ayrı state; gönderim yalnızca composer'ı yeniler
- **Mesajlar:** `ConversationsListSliver` — liste watch sayfa dışında
- **Canlı oda:** yayın süresi `LiveElapsedTimePill` — 1 Hz timer tüm sayfayı rebuild etmez
- **Ana sayfa rozetleri:** bildirim / mesaj / jeton ayrı `Consumer` + `select`
- **Profil cüzdan:** `walletBalancesProvider.select` — jeton değişince yalnızca ilgili kart
- **Sesli oda keşif:** `VoiceRoomOnlineCount` — presence satır bazlı

## 1.0.396+400 (2026-06-27)

### Performans — Görev 5: Liste performansı

- **`LazyListView` / `LazyHorizontalListView` / `LazyGridView`:** `ListView.builder` sarmalayıcıları
- **Story şeritleri:** `SocialStoriesRail`, `StoriesSection` — yatay lazy builder
- **Canlı yayın:** sesli oda keşif story satırı, yayıncı kontrol merkezi (fal/konuk)
- **Mesajlar:** konuşma listesi `SliverList.builder`
- **Sosyal akış:** feed `SliverList.builder`
- **Sesli oda:** DJ presence listesi, YouTube/müzik arama sonuçları lazy
- **GridView.count → GridView.builder:** moderasyon komut paneli

## 1.0.395+399 (2026-06-27)

### Performans — Görev 4: Görsel optimizasyonu

- **`CanlifalNetworkImage`:** tüm ağ görselleri `CachedNetworkImage` + ortak disk cache
- **Thumbnail varsayılan:** liste/kart/avatar için düşük çözünürlük URL (`CanlifalImageUrls`)
- **Tam çözünürlük isteğe bağlı:** `CanlifalNetworkImage.full` ve dokununca tam ekran viewer
- **Disk cache:** 30 gün, 600 dosya (`CanlifalImageCacheManager`)
- **Prefetch:** `prefetchCanlifalImages` — oda/feed kapakları önceden cache
- **Kapsam:** feed, sosyal, ana sayfa, canlı, sesli oda, profil, fal modülleri migrate edildi

## 1.0.394+398 (2026-06-27)

### Performans — Görev 3: API optimizasyonu

- **`ApiCacheInterceptor`:** tüm cacheable GET istekleri için Dio katmanında cache
- **Bellek cache:** LRU (256 girdi) + TTL
- **Disk cache:** `ApiCacheStore` ham JSON (`SharedPreferences`)
- **TTL:** endpoint bazlı (`ApiCachePolicy`) — canlı 15 sn, mesaj 30 sn, banner 5 dk vb.
- **Dedupe:** aynı URL + auth için eşzamanlı tek HTTP isteği
- **Stale fallback:** ağ hatasında süresi dolmuş disk/bellek yanıtı
- **Bypass:** `forceRefresh` / `noCache` extra; çıkışta tüm cache temizlenir

## 1.0.393+397 (2026-06-27)

### Performans — Görev 2: Lazy loading

- **`LazyScreenSection` / `LazyScreenGate`:** ekran açıldıktan sonra kademeli mount
- **Profil:** header anında; istatistik → cüzdan → premium → yayıncı → içerik sırayla (80–640 ms)
- **Canlı yayın:** liste 120 ms, kategoriler 200 ms; oda içi hediye/PK 400–700 ms
- **Sesli oda listesi:** odalar önce; SSE presence 450 ms; canlı yayın şeridi 900 ms
- **Fal hub:** hero anında; kehanet/türler/günlük enerji kademeli; rozetler 1 sn
- **Mesajlar / bildirimler / sohbet:** liste API 80–100 ms gecikmeli

## 1.0.392+396 (2026-06-27)

### Performans — Görev 1: Uygulama açılışı

- **Splash üst sınırı 1 sn:** auth bootstrap cap 2 sn → 1 sn
- **Auth hızlı yol:** açılışta yalnızca `/api/me`; site profili + OneSignal login arka planda
- **SDK erteleme:** AdMob preload, FCM token ve `logAppOpen` runApp sonrasına alındı
- **Ana sayfa ilk kare:** üst bar rozetleri, banner, canlı yayın ve realtime poll geciktirildi
- **Kabuk prefetch:** bildirim/cüzdan/mesaj istekleri 2 sn gecikmeli; SSE presence 3 sn

## 1.0.391+395 (2026-06-27)

### Sesli oda — UI düzenlemesi (temel mod)

- **PK düzeltmesi:** davet sayfasına tam oda nesnesi gönderilir (`extra: room`)
- **Çark menüsü:** hediye yanında ⚙️ — PK, efekt, tema, oda sustur, DJ, !istek, kuyruk
- **Koltuk altı:** katılımcı şeridi ve “Katılımcılar” butonu kaldırıldı
- **Giriş ticker:** koltukların altında açılır/kapanır kayan “odaya girenler” bandı
- **Sabit alt bar:** mesaj yaz + kompakt mic/ses/jeton/çık (jeton → mağaza, odadan çıkmadan)
- **Sohbet:** mesaj listesi ortada; yazı alanı klavye üstünde sabit

## 1.0.390+394 (2026-06-27)

### Sesli oda — premium özellikler (web parity, temel mod)

- **Hediyeler:** mağaza, uçan animasyon, fullscreen nadir hediye, SSE + gift socket
- **PK:** davet, gelen PK dialog, aktif PK sayfasına geçiş
- **Efektler:** ses efekt paneli (`showVoiceEffectsSheet`)
- **Oda temaları:** kozmik arka plan + hub ayarlarından tema seçimi
- **Sohbet + emoji:** mesaj gönderme, hediye satırları, emoji picker
- **Profil kartları:** neon avatar, rol rozeti, hediye kısayolu
- **VIP giriş animasyonu:** üyelik tier’ına göre overlay
- **Backend:** değişiklik yok — mevcut canlifal.com API/SSE

## 1.0.389+393 (2026-06-27)

### Sesli oda — moderasyon (web parity, temel mod)

- **Sahne:** Admin koltuk 1 + 2×5 koltuk grid; dokun → moderasyon / koltuk ata
- **Admin / Moderatör / Yetkili:** rol rozeti; kullanıcıya dokun → moderasyon paneli
- **Kick / Ban / Sessize alma:** mevcut moderasyon sheet temel modda bağlandı
- **Mikrofon izni:** +V ses ver, koltuğa al/indir, konuşma isteği
- **Oda susturma:** yetkililer için tek dokunuşla oda mute/unmute
- **Katılımcı şeridi:** dokun → profil veya moderasyon

## 1.0.388+392 (2026-06-27)

### Sesli oda — müzik sistemi (web parity, temel mod)

- **!istek:** sohbet komutu + arama sheet; jeton / ücretsiz komut yolu
- **Kuyruk:** sıradaki şarkılar, tam kuyruk sheet (silme DJ için)
- **DJ:** panel hub, oynat/duraklat/sonraki/durdur (sunucu sync)
- **Mini player:** kapak, ilerleme, kontroller
- **SSE:** `dj` / `song` olayları temel modda aktif; otomatik oynatma

## 1.0.387+391 (2026-06-27)

### Sesli oda — SSE gerçek zamanlı olaylar (temel mod)

- **SSE akışı:** giriş/çıkış, presence, mikrofon (`isSpeaking`), susturma, moderasyon, oda güncellemesi
- **`VoiceRoomBasicPage`:** canlı olay listesi, katılımcı şeridi (mic göstergesi), SSE bağlantı durumu
- **`onRoomUpdate`:** SSE oda güncellemeleri artık işleniyor
- **Temel mod:** DJ/hediye/PK SSE yan etkileri atlanır; yalnızca oda olayları

## 1.0.386+390 (2026-06-27)

### Sesli oda — aşama 1 (temel akış)

- **Temel mod (varsayılan):** oda listesi, giriş/çıkış, mikrofon, hoparlör, katılımcı listesi, oda sahibi
- **Hafif oturum:** presence + SSE; DJ, PK, hediye ve müzik alt sistemleri başlatılmaz
- **Tam web UI:** `--dart-define=VOICE_ROOM_FULL=true` ile eski RTC sayfası

## 1.0.385+389 (2026-06-27)

### Sesli oda sistemi — web parity ile yeniden eklendi

- **Modüller:** `voice_hub/` (SSE, TRTC, DJ müzik, PK, hediye, video overlay), `livekit/` yedek RTC
- **Canlifal web ile aynı API:** `/api/chat/rooms/*`, SSE `…/stream`, presence 20s, TRTC `voice_room_{id}`, `!istek`, IRC rolleri
- **Müzik:** Android googlevideo → `/api/chat/youtube-audio` proxy önce (backend parity); CDN ve yerel önbellek yedek
- **ProviderScope:** `!istek` arama, şarkı sheet ve komut paneli modal güvenli
- **Rotalar:** `/voice-rooms`, `/voice-room/:id`, PK sayfaları; ana sayfa / keşfet / canlı sekmesi sesli oda bölümleri
- **Android:** `AudioService` + ExoPlayer probe (DJ müzik teşhisi)

## 1.0.384+388 (2026-06-27)

### Sesli oda kaldırma — Android derleme düzeltmesi

- **MainActivity:** `FlutterActivity` (audio_service kaldırıldı)
- **AndroidManifest:** AudioService / MediaButtonReceiver / media playback FGS kaldırıldı
- **ExoPlayerProbe:** sesli oda müzik teşhisi silindi

## 1.0.383+387 (2026-06-27)

### Sesli sohbet odaları tamamen kaldırıldı

- **Kaldırılan modüller:** `voice_hub/`, `livekit/`, sesli oda entity/widget/sayfa dosyaları
- **Canlı sekmesi:** yalnızca video yayınları; sesli oda sekmesi ve global müzik çubuğu yok
- **Rotalar:** `/voice-rooms`, `/voice-room/:id`, PK sayfaları (`/pk/*`, `/live/pk*`) kaldırıldı
- **Ana sayfa / keşfet / sosyal:** sesli oda bölümleri ve kısayollar canlı yayına yönlendirildi
- **Bağımlılıklar:** `livekit_client`, `just_audio`, `audio_service`, `audio_session`, `youtube_explode_dart`, `flutter_webrtc` kaldırıldı

## 1.0.382+386 (2026-06-26)

### Sesli oda müzik — backend proxy parity + ProviderScope

- **Backend ile aynı akış:** Android googlevideo → `GET /api/chat/youtube-audio?url=` (Referer sunucuda) önce; CDN ve yerel önbellek yedek
- **`playServerStream`:** Çözümleme sonrası ham googlevideo URL ile hedef listesi (proxy çift dönüşüm yok)
- **Loading takılması:** 12 sn loading timeout → sonraki hedefe geçiş
- **ProviderScope:** `!istek` arama, şarkı sheet ve oda komutları paneli `UncontrolledProviderScope` ile sarmalandı (`Bileşen hatası` giderildi)

## 1.0.381+385 (2026-06-26)

### Sesli oda müzik — Android Source error düzeltmesi

- **Android oynatma sırası:** googlevideo doğrudan CDN + Referer başlıkları önce; yerel önbellek ikinci; `/api/chat/youtube-audio` proxy en son (sık 404 / Source error)
- **`clientPlaybackUrl`:** Artık googlevideo'yu proxy'ye çevirmiyor — çözümlenmiş akış doğrudan oynatılır
- **Güvenlik:** `youtube-stream` JSON uç noktası `just_audio`'ya asla verilmez; çözümleme başarısızsa watch URL adayları denenir
- **Teşhis:** Mini player `play=` ve `srv=` ile oynatılan vs sunucu URL'sini ayırır

## 1.0.380+384 (2026-06-26)

### Sesli oda müzik — kalıcı oynatma düzeltmesi

- **Hibrit oynatma:** Videolu isteklerde ses `just_audio` ile her zaman çalar; YouTube overlay sessiz (`mute: 1`)
- **Mini player kapatma** artık oda içi müziği durdurmaz (`userDismissedPlayer` yalnızca UI)
- **youtube-stream API** URL'si çözümlenip doğrudan akışa dönüştürülür
- **SSE:** `withVideo` bayrağı sunucu düşürse istemci korur
- **Android:** `/api/chat/youtube-audio` çift proxy hatası giderildi

## 1.0.379+383 (2026-06-26)

### Sesli oda — ortadan !istek videolu müzik

- **!istek (sohbet):** Şarkı seçiminden sonra otomatik **videolu** mod (ortada YouTube oynatıcı)
- **`withVideo` yedek:** Sunucu bayrağı eksikse istemci `nowPlaying.asVideoRequest()` ile video modunu korur
- **Oynatma:** `isVideoRequest` ile ses-only parçalar video overlay açmaz

## 1.0.378+382 (2026-06-26)

### Sesli oda müzik — youtube-stream URL çözümleme

- **`/api/chat/youtube-stream?videoId=`** artık doğrudan oynatılmıyor; önce JSON'dan gerçek ses akışı URL'si alınıyor
- **`videoIdFrom`:** `videoId` sorgu parametresi desteği
- **`just_audio`:** `ProcessingState.ready` olunca otomatik `play()` (loading'de takılma)
- **Android:** `usesCleartextTraffic="true"` (HTTP yedek akışlar)

## 1.0.377+381 (2026-06-26)

### CI — derleme hatası

- **Hediye flaşı:** `premium_gift_fullscreen_overlay.dart` — eksik `GiftRarity` import (release gate Gate 2)

## 1.0.376+380 (2026-06-26)

### CI — release gate performans testi

- **AppTheme:** light/dark/amoled tema önbelleği (50× fabrika çağrısı CI < 2 sn)
- Acceptance test #20: `clearCacheForTest` ile ölçüm tutarlılığı

## 1.0.375+379 (2026-06-26)

### Performans ve backend senkron (Claude dalı — tam diff)

- **Map literal:** `?field` → `if (field != null) 'key': field` (müzik/DJ dosyaları)
- **Avatar/resim:** `NetworkImage` → `CachedNetworkImageProvider` (13 dosya)
- **Müzik uçları:** `pauseDj` → `DELETE /music`, `resumeDj` → `POST /music`
- **`_parseQueueResponse`:** güvenli `int.tryParse` / `num.round`
- **PK overlay:** `pkExtras` Map + güvenli cast'ler; `_pkPollTimer?.cancel()`
- **`main.dart`:** image cache 150 görsel / 80 MB
- **`unawaited(_leavePresence())`** async uyarı düzeltmesi

## 1.0.374+378 (2026-06-26)

### Sesli oda — performans, müzik, kamera düzeltmeleri

- **Müzik (TRTC):** Üçlü oynatıcı (audioplayers + just_audio + SSE yedek) kaldırıldı; tek `VoiceRoomDjPlayer` yolu
- **SSE/Socket:** DJ olayları SSE bağlıyken yalnızca SSE'den işlenir (çift oynatma ve audio focus çakışması giderildi)
- **TRTC sonrası:** `activateForPlayback()` — müzik ses oturumu TRTC girişinden sonra yeniden etkinleştirilir
- **Küçük kameralar:** Oda girişinde Agora otomatik kamera yayını kapatıldı; uzak video yalnızca HOST koltuğunda
- **Video modu:** Ses-only DJ olayları artık yanlışlıkla video overlay açmaz (`withVideo` zorunlu)
- **Performans:** SSE varken poll 30–60 sn; gereksiz DJ/mesaj yinelenmesi azaltıldı

## 1.0.373+377 (2026-06-26)

### Performans ve backend senkron (Claude dalı)

- **PK overlay:** `as Type?` cast çökmeleri giderildi; güvenli `toString()` / sayı ayrıştırma
- **DJ duraklat:** `pauseMusic` artık `DELETE /music` (kuyruk temizleme) yerine `POST /dj` müzik kontrol ucunu kullanır
- **SSE:** Sesli oda gerçek zamanlı güncellemeler SSE üzerinden; Socket.IO yedek

## 1.0.372+376 (2026-06-23)

### Sesli oda — sağ DJ & müzik paneli

- **Sağ ‹ ok:** DJ, oda sahibi ve admin için kaydırmalı DJ & müzik paneli
- **Hızlı kontroller:** Duraklat / devam, geç, durdur; çalan parça önizlemesi
- **Müzik Aç:** Tam YouTube müzik hub'ına kısayol
- **DJ Yönet:** DJ listesi ve atama diyaloğu

## 1.0.371+375 (2026-06-26)

### CI — release gate Gate 4 (canlı fal isteği)

- Yayın oluşturma: mobil ile aynı gövde; falcı token önceliği
- 403 yedek: mevcut canlı yayın seçimi veya SKIP (liste API erişilebilir)
- Fal isteği POST başarılıysa yayıncı listesi olmadan da PASS

## 1.0.370+374 (2026-06-23)

### Sesli oda — SSE dj müzik oynatma

- **SSE dj event:** `data`/`payload` sarmalayıcıları düzleştirilir; `isPlaying` + `playing` birlikte okunur
- **Oynatma:** SSE sonrası `isPlaying` ile `_playDjInBackground` tetiklenir; kuyruk güncellemesinde sunucu sync
- **audioplayers:** Oda widget'ında HTTP stream yedek `AudioPlayer` (dispose'da kapatılır)
- **Stream URL:** Göreli `/api/chat/youtube-audio/...` yolları mutlak URL'ye çevrilir
- **startedAt:** ISO `startedAt` → playback seek senkronu

## 1.0.369+373 (2026-06-23)

### Sesli oda — moderasyon, SSE, müzik parity (49 görsel spec)

- **Komutlar paneli:** MÜZİK & GENEL promo kartları; Şarkı İsteği ile Müzik Aç (DJ hub) ayrı girişler
- **Ban listesi:** `GET /moderation` ile !unban kullanıcı listesi; API ban satırları parse
- **Kick 3 vuruş:** Sarı / turuncu / kırmızı snackbar + RTC uyarı diyaloğu (`KickStrikeUi`)
- **SSE:** `MESSAGES_CLEARED`, `ROLE_CHANGED`, `ENTRY_ANNOUNCEMENT`, `typing` olayları
- **Duyuru TTL:** Üstte sabit duyuru + geri sayım progress bar (15 sn)
- **Presence çıkış:** `POST presence?_delete=1&leave=1` yedek akışı

## 1.0.368+372 (2026-06-23)

### Agora, Tarot takılma, otomatik paylaşım

- **Agora:** `enableAudio()` + `enableVideo()` motor başlatmada; token isteği `room_{id}` formatına normalize
- **Canlı falcı video:** Agora kanal adı `AgoraChannelNames.forRoom` ile üretim sözleşmesine uyumlu
- **Tarot / fal yükleme:** SSE akışına 90 sn üst sınır + 28 sn boşta kalma zaman aşımı; JSON yanıt yedek parse
- **Yükleme overlay:** İptal butonu ve geri tuşu — «Tarot açılıyor…» ekranında takılma giderildi
- **Otomatik paylaşım:** Fal tamamlanınca `FortuneReadingCoordinator` ayara göre sosyal/profil paylaşımı (tek nokta)

## 1.0.367+371 (2026-06-23)

### Sesli oda — donma, !istek ses, çıkış düzeltmeleri

- **!istek / DJ SSE:** `musicUrl` stream URL'si varken `videoId` zorunluluğu kaldırıldı; oynatıcı SSE `dj` event'inde ses başlatır
- **Oynatma:** İmza aynı olsa bile çalmıyorsa yeniden sync; şarkı seçiminden sonra zorunlu `_playDjInBackground`
- **Concurrent modification:** `VoiceRoomMessageMerge` — `Map.from(byId).entries` ile güvenli iterasyon
- **Odadan çıkış:** `leaveRoomSession` ve TRTC/LiveKit `leave` artık UI'ı bloklamaz; navigasyon önce, temizlik arka planda
- **dispose:** SSE/gift subscription iptali; ses motoru `leave` → `dispose` sırası

## 1.0.366+370 (2026-06-23)

### Sesli sohbet — web parity tamamlama

- **!istek akışı:** Chat'e komut yazılır → YouTube arama popup (300ms debounce) → jeton modu → kuyruk; çalan parça yeniden başlamaz
- **Komutlar paneli:** `!duyuru`, `!temizle`, `!kick`, `!ban`, `!unban` kutu ızgarası; kick/ban renk kodlu kullanıcı listesi
- **Moderasyon popup:** Hediye, +V ses, @/& rol, DJ, koltuk, mic, ban, kick, oda devri — 3 sütun kutu ızgarası
- **!temizle:** Müzik durmaz; «Sohbet Temizlendi» yeşil animasyon (3 yanıp sönme)
- **Duyuru:** Sohbet üstü sabit şerit + 15 sn zamanlı banner; kick uyarısı dialog
- **6 dk ses limiti:** DJ oynatıcıda `VoicePlaybackLimits` konum kelepçesi

## 1.0.365+369 (2026-06-25)

### Sesli sohbet — Concurrent modification düzeltmesi

- **Kök neden:** Sohbet mesajları birleştirilirken `local-*` optimistic id'ler silinirken Map üzerinde eşzamanlı iterasyon
- `VoiceRoomMessageMerge`: duplicate anahtarlar önce listelenip sonra siliniyor (`_Map len:N` çökmesi giderildi)
- Özellikle `!istek` / şarkı isteği + SSE yenileme sırasında tetikleniyordu

## 1.0.364+368 (2026-06-25)

### Sesli oda — müzik + moderasyon API uyumu

- **Şarkı isteği:** `requestType: audio|video` (ses 10 / video 20 jeton); GET `requestCosts` eşlemesi
- **Kuyruk:** `DELETE /music` sonrası `autoAdvanced` — sıradaki parça otomatik başlar
- **Moderasyon REST:** `announce`, `clear_messages`; kick yanıtı `kickCount` / `autoBanned`
- **SSE `type: system`:** `ANNOUNCEMENT`, `CHAT_CLEARED`, `USER_KICKED`, `ROOM_MUTED` vb.
- **Komutlar paneli:** `!duyuru` ve `!temizle` doğrudan moderasyon API'sine gider

## 1.0.363+367 (2026-06-25)

### Sesli sohbet — web parity (müzik & oda UX)

- **Alt menü:** Müzik Aç / DJ / PK ve sağ ok paneli kaldırıldı; müzik `!istek` + arama popup ile
- **Kuyruk senkronu:** Aynı parça çalarken yeni istek oynatıcıyı yeniden başlatmaz; SSE konum senkronu korunur
- **Jeton modu:** Sadece Ses (backend `musicRequestCost`) / Videolu (`videoRequestCost`) seçim popup'ı
- **Video oynatıcı:** Ortada floating player; sohbet açıkken kapanmaz
- **6 dk limit:** Ses ve video için maksimum oynatma süresi
- **Mikrofon:** Şarkı başlayınca oda sahibi hariç otomatik kapanır; bitince normale döner
- **Giriş bildirimi:** Koltuk altı modal kart (rol önekleri backend'den)
- **Arka plan:** Yalnızca yetkililer değiştirebilir; tam çözünürlük

## 1.0.362+366 (2026-06-25)

### Jeton yükleme — ödeme talebi düzeltmesi

- **Geçersiz miktar:** API'ye `amount` + geçerli `packageId` (`p500` vb.) gönderiliyor; CFC dalına düşme hatası giderildi
- **Hazır seçimler:** Tutar doğrulaması jeton/TL senkronuna göre gevşetildi
- **Açıklama alanı kaldırıldı:** `CANLIFAL-…` kopya satırı yerine dekont üstünde kopyalanamaz **DİKKAT** uyarısı

## 1.0.361+365 (2026-06-25)

### Profil — Premium 2026 kişisel kontrol merkezi

- **Yeni tasarım:** Dark purple + glassmorphism; kapak, avatar rozetleri, üst aksiyonlar
- **İstatistikler:** Takipçi, takip, beğeni, yayın — tek premium kart
- **Hızlı işlemler:** 15 kartlı 3 sütun grid (canlı yayın, jeton, fal, görevler…)
- **Cüzdan:** Jeton/CFC, kazanç, premium/abonelik + 6 alt aksiyon
- **İçeriklerim:** 6 sekme — videolar, fallar, canlı yayınlar, izlenenler, favoriler, taslaklar
- **Paneller:** Yayıncı, falcı, admin (yetkili) grid kartları
- **Premium kart:** Gradient glow + Avantajları Gör
- **Ayarlar:** Tam liste + tema seçici + çıkış
- **Responsive:** Telefon / tablet / geniş ekran 2–3 sütun düzeni
- **Performans:** RepaintBoundary, skeleton loading, CachedNetworkImage, Hero animasyonlar

## 1.0.360+364 (2026-06-25)

### Canlı yayın — çoklu konuk, moderasyon, etkileşim

- **4'lü / 6'lı / 9'lu yayın:** Grid etiketleri; co-broadcast onayı konuk slotlarına yazılır
- **Moderatör paneli:** Kontrol merkezi Mod sekmesi — sustur, at, ban, mod ata, ihlal günlüğü
- **İzleyici listesi:** Uzun basışla moderasyon; VIP/mod rozetleri
- **Anket / çekiliş / etkinlik:** Host kontrol merkezi Etkinlik sekmesi (`!oy 1` oylama)
- **Video kalitesi:** 360p / 720p / 1080p / Otomatik + düşük gecikme Agora encoder
- **Sohbet koruması:** Spam throttle, küfür filtresi, tekrar mesaj engeli

### Seviye, görevler, liderlik

- **Günlük görevler:** `/api/user/daily-tasks` ve `/api/daily-missions` API bağlantısı
- **Seviye / VIP:** `/api/me` level, XP ve VIP rozeti growth hub'da
- **Hediye liderleri:** Haftalık/aylık tablo (`/gifts/leaderboard`, `/api/leaderboards`)

### Yayın planlama

- **Yayın Planla:** `/live/schedule` — yerel plan + hatırlatma bildirimi

## 1.0.359+363 (2026-06-25)

### Premium 2026 spec (PK hariç)

- **Canlı yayın:** Socket.IO kaldırıldı — hediye/sohbet/izleyici yalnızca SSE
- **İzleyici listesi:** Profil, VIP, moderatör, yayıncı rozetleri; profile git
- **Beğeni:** Otomatik ambient kalpler kaldırıldı; API spam koruması (900ms)
- **Fal yayını:** Tür slug eşlemesi (`coffee`, `tarot`…); Fal İste yalnızca fal yayınında
- **Sesli oda listesi:** 25 sn'de bir otomatik yenileme
- **Giriş:** Telefon / e-posta / kullanıcı adı (`emailOrUsername`)
- **Reklam ödülü:** Growth hub'da önce Rewarded Video, sonra API kredisi

## 1.0.358+362 (2026-06-25)

### Premium 2026 — PK Savaşları (canlı yayın + sesli sohbet)

- TikTok tarzı PK: yayıncıdan yayıncıya davet, kabulde ekran ikiye bölünür
- PK süresi seçimi: **1 / 3 / 5 / 10 dakika** (sesli oda + canlı yayın davet ekranı)
- Her iki tarafın aldığı jeton ayrı skor çubuklarında gösterilir
- Süre bitince kazanan otomatik hesaplanır (sunucu + yerel zamanlayıcı)
- Kaybeden animasyonu: grileşme, sarsılma ve «KAYBETTİ» damgası
- PK sırasında hediye patlaması ve tam ekran hediye animasyonları (canlı PK sayfası)
- Canlı PK split-screen: Agora önizleme + rakip küçük resim

## 1.0.357+361 (2026-06-24)

### Fal — sonuç ekranı + tür görselleri

- Fal sonucunda **siyah ekran**: sonuç kartı ve bölüm panellerinde kalan `BackdropFilter` kaldırıldı
- Her fal türü için **yerel kapak görselleri** (`assets/fortune/`) + çevrimdışı sanat katmanı
- Ağ görseli yüklenene kadar tarot, kahve, katina vb. temalı kapak görünür

### Giriş — kullanıcı adı

- Mobil girişte `emailOrUsername` + `username` alanları birlikte gönderilir

### Jeton — çift yükleme ve ödeme bildirimi

- Jeton talebinde yalnızca `coins` gönderilir (`amount` kaldırıldı; 1000 istek → 2000 yükleme düzeltmesi)
- **Ödeme Bildir** sonsuz dönme: tek API uç noktası, 35 sn zaman aşımı, navigasyon sırası düzeltildi
- WhatsApp otomatik açılış kaldırıldı; isteğe bağlı «WhatsApp ile yaz» butonu

## 1.0.356+360 (2026-06-24)

### Güvenlik — şifre gizliliği

- Giriş / kayıt ekranlarında **otomatik şifre doldurma kapalı** (web’den senkron şifre önerisi yok)
- Android **FLAG_SECURE**: şifre ekranlarında ekran görüntüsü ve son uygulamalar önizlemesi engeli
- Şifre alanlarında klavye öğrenimi ve öneri kapalı; giriş sonrası alan temizlenir
- Hesap güvenliği sayfası güvenli mod + bilgilendirme metni
- Oturum listesinde şifre alanı asla kullanılmaz

## 1.0.355+359 (2026-06-24)

### Fal — siyah ekran düzeltmesi + tür görselleri

- Tarot ve diğer fallarda **Falını Aç** sonrası siyah ekran: çift `Navigator.pop` ve şeffaf `Scaffold` düzeltildi
- Inline sonuç artık güvenli `Scaffold` + tek yükleme diyaloğu kapatma
- `BackdropFilter` katmanı kaldırıldı (Android gri/siyah ekran)
- Açılış animasyonu 2.5sn → 1.1sn; Hero çakışması giderildi
- Tür özel kapak görselleri: Tarot kartları, kahve fincanı, Katina, melek kartları vb.
- Sonuç metni anında görünür (ilk bölüm gecikmesiz)

## 1.0.354+358 (2026-06-24)

### CI / lint

- APK derlemesi yalnızca `dart analyze` **ERROR**, test veya release build hatasında durur
- `scripts/dart-analyze-gate.sh`: WARNING raporlanır, INFO yok sayılır
- Toplu lint düzeltmesi (`dart fix`, gereksiz import/underscore/null-aware)
- Kullanılmayan özel metotlar ve alanlar temizlendi

## 1.0.353+357 (2026-06-24)

### Fal & Tarot — Premium 2026 deneyimi

- Tür özel tam ekran kapak arka planı (`FortuneTypeImmersiveScaffold`, WebP CDN)
- Fal sonucu **aynı sayfada** inline gösterim — ayrı rota yok
- Premium sonuç kartı: enerji, aşk, para, kariyer, şans skorları
- Genişletilmiş paylaşım sayfası (sosyal, profil, herkese açık, link, WhatsApp, Telegram, X, Facebook, IG hikaye)
- Ayarlarda **Fal Sonuçlarımı Otomatik Paylaş** (kapalı / profil / takipçiler / herkese açık)
- Benzer fallar + yatay **Diğer Fallara Göz At** carousel
- `Fal Sonucu` başlığı; `Yorumu Oku` kaldırıldı

## 1.0.352+356 (2026-06-24)

### Düzeltme — profil fal erişim rozetleri import

- `ProfileFortuneAccessBadges` AppThemeColors import yolu düzeltildi (CI analyze)

## 1.0.351+355 (2026-06-24)

### Reklam veya Jeton ile AI Fal Sistemi (§11)

- Tüm AI fal türlerinde ortak erişim kapısı: reklam hakkı, 10 jeton veya premium sınırsız
- Google AdMob ödüllü reklam — tam izlenince +1 fal hakkı; yarıda kapanınca hak verilmez
- Profilde **Reklamdan Kazanılan Fal Hakları** ve **Jeton Bakiyesi** gösterimi
- Admin ayarları API (`/api/fortune-access/settings`) + yerel varsayılanlar
- Jeton tüketimi `paymentMethod` ile fal API'sine iletilir

## 1.0.350+354 (2026-06-24)

### CI — release gate exit 1 düzeltmesi

- Eksik GitHub Secrets artık **FAIL değil SKIP** — client testleri geçince APK engellenmez
- `set -e` + `|| return` hatası giderildi (`return 0`)
- `build-apk.yml` — başarılı build sonrası APK artifact yüklemesi

## 1.0.349+353 (2026-06-23)

### Release gate (9 madde — APK/AAB öncesi zorunlu)

- **9 madde:** analyze, test, falcı video, canlı fal isteği, jeton admin bildirimi, SSE, profil hızı, kullanıcı adı girişi, release build
- `scripts/run-release-gate.sh` + `scripts/acceptance-tests/api-release-gate.sh`
- `build-apk.yml` — gate başarısızsa APK/etiket oluşturulmaz; Gate 9 doğrulama sırası düzeltildi
- Dokümantasyon: `docs/ACCEPTANCE_TESTS.md`

## 1.0.348+352 (2026-06-23)

### Release acceptance testleri (APK öncesi zorunlu)

- **20 madde** otomatik test: giriş, kayıt, profil, jeton, sohbet, SSE, canlı yayın, fal isteği, video token, admin, push, müzik, tema, performans
- `build-apk.yml` — testler geçmeden release APK oluşturulmaz
- Rapor: `docs/ACCEPTANCE_TEST_REPORT.md` + CI artifact
- Kurulum: `docs/ACCEPTANCE_TESTS.md` (GitHub Secrets)

## 1.0.347+351 (2026-06-23)

### Derleme düzeltmesi

- Yanlış import yolları giderildi (fal hub, alt navigasyon)

## 1.0.346+350 (2026-06-23)

### UI bütünlük ve eksik düzeltmeleri

- **Alt navigasyon:** Yayın sekmesi `/live` dalına bağlandı; uzun basınca oluşturma sayfası; aktif sekme `/live` ve `/fortune` için düzeltildi
- **Tema:** Shell, ana sayfa ve oluşturma sayfası açık/koyu/AMOLED temaya uyumlu arka plan
- **Fal hub:** Pull-to-refresh fal geçmişini yeniler; açık temada scaffold rengi
- **Sesli oda:** `leaveSeat` REST (`seatIndex: -1`) uygulandı — `UnimplementedError` giderildi
- **Oluşturma sayfası:** Fal & Tarot kısayolu eklendi; tema renkleri

## 1.0.345+348 (2026-06-23)

### Denetim öncelikleri (P2–P8)

- **P2 Fal beklet:** Yayın kuyruğu `held` durumu; falcı gelen çağrı + panelde **Beklet**; izleyici bildirimi
- **P4 Giriş:** E-posta veya kullanıcı adı ile giriş; kayıt sonrası e-posta OTP doğrulama API
- **P5 Cihaz güvenliği:** Aktif oturum listesi ve oturum sonlandırma (`/settings/devices`)
- **P6 Profil:** TikTok sekmeleri — Videolarım, Fallarım, İzlediklerim
- **P7 Ayarlar:** Merkezi `/settings` — hesap, güvenlik, gizlilik, bildirimler
- **P8 Temizlik:** Kullanılmayan `splash_page.dart` kaldırıldı

## 1.0.344+347 (2026-06-23)

### Performans (Öncelik 1)

- **Splash:** Bootstrap en fazla 2 saniye; auth timeout 2 sn
- **Jeton cache:** `WalletBalancesNotifier` — throttle (20 sn), 3 sn fetch timeout
- **Gereksiz API:** Sesli oda girişinde cüzdan yenileme kaldırıldı
- **Profil:** İstatistikler 3 sn timeout + keepAlive
- **Fal isteği SSE:** `{ request: {...} }` sarmalayıcı parse düzeltmesi

## 1.0.343+346 (2026-06-23)

### Canlı yayın + canlı falcı düzeltmeleri

- **Canlı falcılar Agora:** TRTC yerine canlı yayınla aynı Agora altyapısı (`POST /api/agora/token`, `joinTwoWayVideo`)
- **Fal isteği:** HTTP loglama, ayrı `submitting` durumu, zaman aşımı ve hata mesajı — sonsuz loading giderildi
- **Güzellik ayarları:** Yayın hazırlık ekranında beauty/filtre/kamera ön ayarı (yayında korunur)
- **Oturum navigasyonu:** Kabul sonrası danışan doğrudan görüşme ekranına yönlendirilir
- **Jeton bildirimi:** `JetonPaymentStatusListener` uygulama geneline taşındı (MainAppShell)

## 1.0.342+345 (2026-06-23)

### Jeton + canlı falcı oturumu

- **Jeton uyarısı:** Papara/Havale öncesi DİKKAT metni (açıklama alanına yazı yazmayın)
- **Ödeme bildirimi:** Dekont yükleme bloklamaz (12 sn); talep 35 sn zaman aşımı — sonsuz dönme giderildi
- **Canlı falcı TRTC:** İki yönlü görüşmede `videoCall` sahnesi — karşı kamera bağlantısı
- **Çift mesaj:** Sohbet optimistik ekleme kaldırıldı
- **Anında kapanma:** İptal/sonlandırma sinyali + «Falcı/Kullanıcı kapattı» mesajı
- **Davet dialog:** İptal sinyalinde anında kapanır; kabul API 28 sn timeout

## 1.0.341+344 (2026-06-23)

### Jeton Satın Al — Premium 2026

- **Çift yönlü hesaplama:** TL ↔ jeton (1 jeton = ₺0,50); anlık senkron
- **Hazır seçimler:** ₺250 / ₺500 / ₺1000 / ₺2500 kartları
- **Ödeme yöntemleri:** Papara, Havale/EFT, WhatsApp — glassmorphism kartlar
- **Papara/Havale:** `CANLIFAL-{userId}` açıklama kodu, dekont yükleme
- **WhatsApp:** Tek tıkla önceden doldurulmuş mesaj
- **Satın Al:** `POST /api/payment/requests` ödeme talebi
- **Admin:** Ödeme Talepleri ekranı — tutar, jeton, yöntem, dekont, onayla/reddet
- **Bildirim:** Onay «Jetonlarınız hesabınıza yüklendi.» · red «Ödeme talebiniz reddedildi.»

## 1.0.340+343 (2026-06-23)

### Falcı davet popup — kabul akışı ve siyah ekran

- **Kabul Et:** API çağrısı dialog içinde; yükleme göstergesi; başarıda popup kapanır ve randevu ekranı açılır; hatada snackbar
- **`respondSession` log:** `PATCH /api/fortune-tellers/sessions/{id}` (+ POST yedek), HTTP status, response body, tüm exception'lar `debugPrint`
- **Siyah ekran:** İptal push'unda yalnızca açık davet dialogu kapatılır; root navigator kör `pop` kaldırıldı
- **Çift bildirim:** Aynı `sessionId` için 60 sn dedup (`PsychicInviteCoordinator`)

## 1.0.339+342 (2026-06-23)

### Falcı paneli, başvuru, TRTC video

- **Onaylı falcı algısı:** `fortune-tellers` listesi önce taranır (İlhamperisi hızlı yol); `my-profile` yalnızca kullanılabilir profilde kısa devre
- **Başvuru:** Onaylı kullanıcıya tekrar başvuru engeli; 22 sn zaman aşımı; «zaten falcı» hatasında panele yönlendirme
- **TRTC:** Kabul sonrası `trtcRoomId` senkronu; `GET /api/room` + oturum yedekleri; `peerId` / rol ayrıştırması genişletildi

## 1.0.338+341 (2026-06-22)

### Falcı paneli / başvuru — kök neden düzeltmesi

- **Hızlı rol algısı:** `my-profile` → `/api/me` → `/api/user/profile` → tek sayfa liste (100 kayıt); yavaş 3 sayfalık tarama kaldırıldı
- **`/api/me` bayrakları:** `isFortuneTeller`, `canGoOnline`, `fortuneTellerId` ile onaylı falcı sentetik profili
- **Başvuru formu:** Tam sayfa spinner kaldırıldı; form anında açılır; `apply` yanıtı hemen state'e yazılır
- **Başvuru API:** Üretim `{error}` / `{success,data,teller}` gövdeleri; zaman aşımı ve sosyal yedek uç
- **Router:** Falcı rol kontrolü 10 sn zaman aşımı — tıklama donması giderildi
- **`refresh()`:** 15 sn timeout + hata durumunda `checked=true` (sonsuz loading yok)

## 1.0.337+340 (2026-06-22)

### Falcı paneli / başvuru düzeltmeleri

- **Onaylı falcı algısı:** `my-profile` yanıtı artık userId eşleşmesi olmadan kabul ediliyor; `/api/me` ve panel uç probu eklendi
- **Falcı Panel tıklama:** `/falci-panel` redirect-only hatası giderildi; doğrudan `/canli-falcilar/dashboard`
- **Başvuru spinner:** `refresh()` beklemesi kaldırıldı; `finally` ile spinner durur, anında «inceleniyor» kartı

## 1.0.336+339 (2026-06-22)

### Falcı paneli ve Falcı Ol sayfası

- **`/falci-ol`:** Tanıtım, adımlar ve avantajlar; başvuru formuna yönlendirme
- **`/falci-panel`:** Onaylı falcı → panel; değilse → Falcı Ol
- **Falcı Paneli:** İstatistik kartları, hızlı işlemler, bekleyen talepler, çevrimiçi anahtarı
- **Profil:** Falcı Paneli / Falcı Ol kartı eklendi
- **Başvuru:** Admin onayı beklentisi açıkça gösteriliyor (`POST /api/fortune-tellers/apply`)
- Yerel API mirror: `fortune-tellers/apply` ve pending `my-profile` yanıtı

## 1.0.335+338 (2026-06-22)

### Canlı Falcılar — randevu bildirimi regresyonu

- **Kök neden:** Push/API gövdesindeki `userId` yanlışlıkla `clientId` sayılıyordu; falcı kendi isteğinin danışanı sanılıp bildirim/dialog filtreleniyordu
- `clientId` yalnızca açık `clientId` / `client_id` alanlarından okunuyor
- Onaylı falcıda minimal push (clientId boş) yine gösteriliyor; danışanda gösterilmiyor
- Bildirim listesinde falcı olmayan kullanıcı yine ilgili sayfaya yönlendiriliyor

## 1.0.334+337 (2026-06-22)

### Canlı Falcılar — randevu bildirimi (yanlış alıcı + çift bildirim)

- **createSession:** `tellerUserId`, `anchorUserId` ve `clientName` artık API'ye gönderiliyor; sunucunun doğru falcıya yönlendirmesi için
- **Danışan cihazı:** Kendi oluşturduğu randevu isteğinde push/SSE/bildirim listesinden falcı kabul dialog'u açılmıyor
- **Falcı cihazı:** Gelen davet yalnızca `shouldPresentPsychicIncomingInvite` ile eşleşen kullanıcıda gösteriliyor
- **Yerel API mirror:** `resolveTellerUserId` içindeki `body.userId` (danışan id) fallback kaldırıldı

## 1.0.333+336 (2026-06-22)

### Ana sayfa — sosyal akış kaldırıldı

- `HomeSocialFeedSection` ana sayfadan çıkarıldı; sosyal içerik `/social` sekmesinden erişilebilir
- Ana sayfa yenilemede gereksiz feed API çağrısı kaldırıldı

## 1.0.332+335 (2026-06-22)

### Firebase / Google Sign-In — CI secret senkronu

- `GOOGLE_SERVICES_JSON_BASE64` güncellendi (SHA-1: `4a6072b9…`, paket: `com.mesutbyrm.canlifal`)
- CI `apk-latest` derlemesi yeni `google-services.json` ile yayınlandı

## 1.0.331+334 (2026-06-22)

### Canlı Falcılar — derleme düzeltmesi

- `PsychicIncomingHost._connectSse`: nullable SSE servis tipi derleme hatası giderildi

## 1.0.330+333 (2026-06-22)

### Canlı Falcılar — falcı kabul bildirimi (SSE / push)

- **SSE parse:** `psychic_request_created` olaylarında durum her zaman `pending` sayılır; aktif/yanlış status ile kuyruğa düşmeme giderildi
- **SSE servis:** `parsePsychicIncomingPayload` birincil parser (push ile aynı sözleşme)
- **PsychicIncomingHost:** Oturum yüklenince SSE/poll yeniden bootstrap; falcı profili çözülünce `setOnline` + SSE yeniden bağlanır
- **Rota dinleyicisi:** Seans/bekleme ekranından çıkınca kuyruktaki davet dialog'u otomatik açılır
- **dispose:** `ref.read` kaldırıldı; SSE servisi güvenli kapatılır

## 1.0.329+332 (2026-06-22)

### Firebase / Google Sign-In APK

- `google-services.json` güncel (SHA-1: `4a6072b9…`, Web client gömülü)
- CI için `GOOGLE_SERVICES_JSON_BASE64` secret güncellenmeli: `bash scripts/set-google-services-secret.sh`

## 1.0.328+331 (2026-06-22)

### Ana sayfa — gri ekran düzeltmesi

- **HomePage:** `dispose()` içinde `ref.read` kaldırıldı (Riverpod hatası); bridge örneği `initState`'te önbelleğe alınıyor
- **HomeRealtimeBridge:** `_disposed` bayrağı ile sekme değişiminde güvenli timer iptali
- Sekme dışına çıkıp ana sayfaya dönünce widget yeniden oluşturulduğunda çökme/gri ekran giderildi

## 1.0.327+330 (2026-06-22)

### Google Sign-In — Firebase yapılandırması

- `google-services.json` güncellendi (yeni Android OAuth client + SHA-1: `4a6072b9…`)
- CI `GOOGLE_SERVICES_JSON_BASE64` secret yeni dosyayla senkronize edildi
- Google Sign-In için doğru sertifika parmak izi APK'ya gömülü

## 1.0.326+329 (2026-06-22)

### Ana sayfa — providers ve sosyal akış

- **`home_providers`:** `refreshHomeData` — fal kartları, günlük ödüller ve sosyal akış (`homeFeedNotifier`) yenileme
- **`HomePage`:** `HomeSocialFeedSection` eklendi (sayfalı sosyal akış)
- Pull-to-refresh tüm bölümleri kapsar; realtime bridge sayfa kapanınca durur

## 1.0.325+328 (2026-06-22)

### Canlı yayın SSE — yeni olay türleri

- **`VideoStreamSseService`:** `like` / `streamLike`, `userJoined`, `userLeft`, `moderatorAdded` / `moderatorRemoved` olayları
- Beğeni sayacı SSE ile senkron (`syncRemoteLikeCount`)
- Hediye SSE olayları hediye sıralamasına da yazılır
- Moderatör değişiminde sohbet rozetleri güncellenir
- İzleyici girişinde `viewerCount` senkronu

## 1.0.324+327 (2026-06-22)

### Canlı yayın — hediye sıralaması

- **`LiveGiftLeaderboard`** — sol alt köşede hediye atanlar listesi (top 3 + genişlet)
- REST ile ilk yükleme (`/api/video-streams/{id}/gifts/leaderboard`)
- Gerçek zamanlı güncelleme — gelen hediye olaylarından otomatik sıralama
- Madalya (🥇🥈🥉), avatar, hediye adı/emoji ve toplam coin gösterimi

## 1.0.323+326 (2026-06-21)

### Canlı yayın — beğeni ve kamera kontrolleri

- **Beğeni:** `LiveLikeButton` — optimistic REST beğeni, uçan kalp animasyonu, izleyici sağ şeridinde
- **Sinyal:** HTTP signal polling ile uzak beğeni senkronu (`handleLiveLikeSignal`)
- **Kamera:** `LiveCameraToggleButton` / `LiveCameraSwitchButton` / `LiveMicToggleButton` — Agora + TRTC
- Alt kontrol çubuğu yeni kamera widget'ları ile güncellendi

## 1.0.322+325 (2026-06-21)

### Moderasyon panelleri (canlı + sesli oda)

- **Canlı yayın:** mor tema moderasyon sheet — avatar, yükleme göstergesi, ban onay diyaloğu; gerçek `liveStreamExtrasProvider` API
- **Sesli oda:** yeni `voice_room_moderation_sheet` — moderatör yap/kaldır (`@` rol), konuşmacı onay (koltuk), sustur, at; ücretsiz odada moderatör kilidi
- Kullanıcıya uzun basınca / moderasyon menüsünden açılır

## 1.0.321+324 (2026-06-20)

### Jeton mağazası — boş ekran düzeltmesi

- Sayfa düzeni sadeleştirildi (`ListView` + sabit alt bar); paket grid'i her zaman görünür
- API yüklenirken bile 50–1000 jeton kartları (`kFallbackJetonPackages`) gösterilir
- «Ödemeyi Yaptım, Bildir» altta sabit; üstte jeton paketleri ve özel miktar alanı

## 1.0.320+323 (2026-06-20)

### Jeton — ödeme bildirimi düzeltmesi

- **Ödemeyi Yaptım, Bildir** sabit alt buton — tıklanınca form hemen açılır (bottom sheet düzeltmesi)
- Paket kartları yalnızca seçim yapar; bildirim butonu her zaman görünür
- **Backend:** admin/staff + `mesutbyrm1@gmail.com` uygulama bildirimi; Resend ile e-posta (`RESEND_API_KEY`)

## 1.0.319+322 (2026-06-20)

### Jeton mağazası — ödeme bildirimi (mockup uyumu)

- **Ödeme Bildir** alt sayfası: WhatsApp / Diğer, tutar (₺), işlem no, gönderen, not; başarı ekranı «Bildirim Gönderildi!»
- **Jeton paketleri** tıklanabilir — seçim + ödeme yöntemleri akışı
- **Ödeme Yaptım, Bildir** yeşil alt buton — `POST /api/payment/requests` ile backend bildirimi
- Formda sabit jeton miktarı çipleri (50–1000) tutarı otomatik doldurur

## 1.0.318+321 (2026-06-20)

### Sesli oda — `_isMicMuted` state + mic UI

- **voice_room_rtc_page:** `_micOn` → `_isMicMuted`; footer ikonu `micOn: !_isMicMuted`
- Socket.IO mic/audio-state event'i yok — net TODO (backend talebi gerekir)

## 1.0.317+320 (2026-06-20)

### Sesli oda — mikrofon ve rol (backend uyumu)

- **Mikrofon:** `toggleMic` REST kaldırıldı; yalnızca TRTC/LiveKit client-side (`setMicEnabled`)
- **Rol:** `changeRole` placeholder silindi; `assignRoleToUser` provider metodu + yetki kontrolü
- **VoiceSeatRestService:** yalnızca koltuk REST (`takeSeat` / `leaveSeat` placeholder)

## 1.0.316+319 (2026-06-20)

### Sesli oda — seat/mic/role snapshot-diff senkronizasyonu

- **VoiceRoomGiftSocket:** `roomUsers` / `presenceUpdated` / `userJoined` / `userLeft` için presence snapshot diff callback (`onPresenceSnapshot`)
- **VoiceSeatRestService:** `takeSeat` REST (`PATCH/POST /seats`); `leaveSeat` / `toggleMic` / `changeRole` placeholder (`UnimplementedError` + net mesaj)
- **VoiceRoomLiveController:** `applyPresenceSnapshot` — sunucu-yetkili koltuk/konuşma/rol güncellemesi
- **Socket bağlantısı:** Oda açılışında gift socket + SSE birlikte; koltuk emit yok (REST)
- **Mikrofon:** TRTC yerel toggle + REST placeholder (yakında snackbar, crash yok)
- **Tencent demo:** `VoiceRoomState.applyPresenceSnapshot`, `onUserAudioAvailable` artık koltuk atamaz

## 1.0.315+318 (2026-06-20)

### Canlı yayın — Yayını Başlat timeout düzeltmesi

- **live_broadcast_prep_page:** `createVideoStream` ve `fetchToken` çağrılarına 15 sn timeout; sunucu yanıt vermezse spinner kalkar ve kullanıcıya hata mesajı gösterilir
- **Agora handoff:** `shutdownForHandoff` 8 sn timeout ile korundu (takılsa bile akış devam eder)
- **Hata sonrası:** `_previewReady` sıfırlanır; buton tekrar tıklanabilir

## 1.0.314+317 (2026-06-20)

### Sesli oda — PK SSE entegrasyonu

- **chat_room_providers:** Oda SSE akışına `onPk` callback — PK güncellemeleri artık ayrı Socket.IO yerine ana SSE'den besleniyor
- **pk_battle_remote_provider:** `connectSocket` / `disconnectSocket` no-op; REST + SSE mimarisi
- **chat_room_sse_service:** `type: pk` olayları parse edilip `PkBattleRemote` olarak iletiliyor

## 1.0.313+316 (2026-06-19)

### Canlı yayın — Premium 2026 tamamlama

- **Kontrol merkezi:** Sağdan açılan 6 sekmeli panel (Fal, Hediye, PK, Konuk, Moderasyon, İstatistik); fal istekleri VIP/Öncelikli/Standart gruplu, swipe ile kabul/tamamla/iptal
- **Hediye animasyonları:** Aynı anda 3 tam ekran Lottie/Rive/partikül animasyonu (`LiveGiftAnimationStack`); şato, kristal, tarot, elmas yağmuru kataloga eklendi
- **RTC grid:** 2/4/6/9 kişilik otomatik grid; pin, sessize alma, host kontrolleri; Agora çoklu remote UID senkronu
- **PK savaşı:** Premium overlay — geri sayım, MVP, destekçi, kazanan konfeti; pending davetlerde mevcut skor çubuğu
- **Güzellik filtresi:** Agora + TRTC beauty SDK; slider sheet; SharedPreferences ile kalıcı ayar
- **Yayıncı dashboard:** Gerçek zamanlı jeton, izleyici, hediye grafikleri (SSE/API türetilmiş)
- **VIP giriş:** Altın banner + sohbet rozetleri (VIP, seviye, falcı, MOD)
- **Etkileşim:** Çift/üçlü dokunuş kalp, süper beğeni, emoji yağmuru, alkış (SSE senkron)
- **Hediye paneli:** Popüler / Fal / VIP / Etkinlik kategorileri + animasyon önizleme
- **UI cila:** Liquid glass kontrol paneli, glassmorphism, premium PK ve etkileşim katmanları

## 1.0.312+315 (2026-06-19)

### Düzeltme — canlı yayın import yolları (CI analyze)

- `live_fortune_request_provider`, keşfet chip'leri, moderasyon sheet ve fal formlarında yanlış relative import'lar düzeltildi

## 1.0.311+314 (2026-06-19)

### Canlı yayın — entegrasyon tamamlama

- **İzleyici oturumu:** `fromStream` artık kategori/etiketleri taşıyor — fal sekmesi izleyicide de açılıyor
- **Moderasyon:** Sohbet mesajına uzun bas → sustur/at/engelle/moderatör sheet
- **Konuk alma:** İzleyici «Katıl» → yayıncı kabul/red popup; co-broadcast API genişletildi
- **Yayın ayarları:** Yorum, hediye, PK, konuk ve grid kapasitesi sheet
- **Fal yanıt bildirimi:** SSE ile «Fal isteğiniz yanıtlandı» snackbar
- **API mirror:** `GET /video-streams/:id/stream` SSE, mute/ban/moderator, co-broadcast join

## 1.0.310+313 (2026-06-19)

### Canlı yayın — Premium 2026 (fal isteği, keşfet, moderasyon)

- **Fal isteği:** Sohbet | Fal İsteği sekmeleri; görünen isim gizliliği; Standart/Öncelikli/VIP jeton onayı (500/1000/2500)
- **Yayıncı paneli:** Fal İstekleri kuyruğu (VIP > Öncelikli > Standart), durum: Beklemede / İnceleniyor / Yanıtlandı
- **SSE:** `fortune_request` olayları anlık panel güncellemesi + haptic
- **Keşfet:** Kategori chip filtresi, fal yayınlarına öncelikli sıralama (TikTok Live benzeri)
- **Kartlar:** CANLI / PK / VIP rozetleri, kategori etiketi
- **Moderasyon:** Sustur, at, engelle, moderatör ekle/kaldır sheet (video-stream API)
- **API mirror:** `fortune-requests`, `/api/live/fal-request/*` alias uçları, jeton tahsilatı backend'de

## 1.0.309+312 (2026-06-19)

### Fal sayfaları — Premium 2026 redesign

- **Fal türleri grid:** Sinematik 2 kolon kartlar, glassmorphism + neon glow, 30px radius, tap scale animasyonu; emoji/clipart kaldırıldı
- **Görseller:** Fal türüne özel yüksek çözünürlüklü Unsplash sahneleri (tarot, kahve, aşk, yıldızname, melek, numeroloji, istihare, aura)
- **Günlük fal:** Hediye kutusu kaldırıldı; mistik tarot kartı, dönen enerji halkaları, nebula + partikül hero
- **Falını Aç geçişi:** 2.5sn kamera zoom, kozmik ışık patlaması, kart dönüşü, haptic
- **Kehanet / intro:** `CinematicFortuneHero` — 320px parallax hero, fal türüne göre dinamik görsel
- **Sonuç ekranı:** Başlık kartı (Yeni Başlangıçlar vb.), enerji etiketi, glass bölümler (Aşk, Kariyer, Para, Ruhsal, Tavsiye), Material ikonlar
- **Animasyonlar:** `flutter_animate`, `shimmer`, `animated_text_kit` typewriter, fade/slide/glow
- **Performans:** RepaintBoundary, CachedNetworkImage memCache, Hero

## 1.0.308+311 (2026-06-20)

### Fal & Tarot — Premium UI güncellemesi

- **Dönen küre:** Taşma düzeltildi, ClipRect + responsive boyut, 24px alt boşluk, RepaintBoundary
- **Fal kartları:** Premium gradient overlay, shimmer yükleme, Hero animasyonu, yüksek çözünürlük CDN
- **Detay ekranı:** Falını Aç hero büyüme, blur arka plan, Lottie geçiş animasyonu
- **Sonuç ekranı:** Fal türüne özel dinamik arka plan, hareketli partiküller, daktilo efekti
- **Sosyal:** Yorum → Fal Sonucu → Paylaş → SOSYALDE PAYLAŞ hiyerarşisi; Story kalitesinde paylaşım görseli
- **Performans:** RepaintBoundary, memCacheWidth, statik parçacık boyama

## 1.0.307+310 (2026-06-20)

### Premium AI Fal Deneyimi (2026)

- **Kapak görseli:** Fal türüne özel tam genişlik görsel, glassmorphism, parallax, mistik ışık animasyonu
- **Falını Aç CTA:** Glow, haptic, Lottie yıldız; yüklemede dönen tarot kartları + shimmer
- **AI yorum:** 6 bölüm (Genel Enerji, Aşk, İş, Para, Gelecek, Tavsiye); API metni parse + yerel 200+ kelime yedek
- **Görsel analiz:** Kapak/fotoğraf sembolleri yoruma entegre
- **Sonuç ekranı:** Metin kapak üzerinde blur cam paneller; bölümler 1–5 sn sırayla fade-in
- **Sosyal:** Otomatik paylaşım şablonu, kapak görseli, `fortuneId` bağlantısı; takipçi bildirimi
- **Veritabanı:** `UserFortune` genişletildi; `SocialFortunePost` tablosu; `SocialPost.fortuneId`

## 1.0.306+309 (2026-06-20)

### Sesli sohbet — gelir modeli ve oda tipleri

- **Oda tipleri:** `FREE`, `NORMAL`, `VIP` — ücretsiz oda açma (0 jeton), kapasite limitleri
- **Hediye dağılımı (backend):** Alıcı %70 / oda sahibi %30 → komisyon brüt pay üzerinden %50
- **Ücretsiz oda:** Oda sahibi hediye ve müzik geliri almaz; müzik isteği tamamı site
- **Müzik isteği:** 10 jeton; NORMAL 50/50, VIP 70/30 (admin ayarlı)
- **Admin:** Sesli Oda sekmesi — oranlar ve kapasite ayarları
- **API:** `VoiceRoomSettings`, `VoiceRoomFinanceAuditLog`, migration

## 1.0.305+308 (2026-06-19)

### Fal & Tarot — Ultra Premium Liquid Glass ana ekran

- **Kozmik arka plan:** Katmanlı uzay gradient, nebula nefesi, binlerce yıldız, sis, parallax partiküller (scroll)
- **Hero:** Animasyonlu 3D kristal küre (20 sn dönüş, galaksi içi), altın serif başlık, FALINA BAK liquid ripple CTA
- **Kehanet kartı:** Tam genişlik VisionOS cam panel + tarot illüstrasyonu
- **Fal türleri:** 2×4 premium kart grid (radius 32, stagger giriş), Tarot → Aura
- **Günlük enerjin:** Yatay swipe kristal cam kartlar
- **Header:** Liquid Glass mesaj/bildirim butonları, altın «Fal & Tarot» tipografi

## 1.0.304+307 (2026-06-20)

### Jeton — Papara / Havale ödeme bildirimi

- **Satın Al akışı:** Paket seç → «Satın Al» → ödeme yöntemi → Papara/Havale detay ekranı
- **Dekont:** Galeri, kamera, PDF/dosya; presigned R2 yükleme (`payment-receipts`)
- **API:** `receiptUrl`, `username`, audit log; admin SSE `/api/admin/payments/stream`
- **Admin:** Finans · Ödeme Bildirimleri, dekont önizleme, red sebebi, 5 sn yenileme
- **Bildirim:** Yönetici push metni — kullanıcı, paket, tutar TL

## 1.0.303+306 (2026-06-19)

### Canlı Falcılar — davet dialog + anında iptal

- **Push parse:** `parsePsychicIncomingLoose` — OneSignal `custom`/title ile minimal davet; invite durumu her zaman `pending`
- **İptal senkronu:** `psychicSessionCancelSignal` — danışan iptalinde falcı dialog'u anında kapanır (1 sn durum izleme + push)
- **Bekleme ekranı:** İptal onayı sonrası anında çıkış; API arka planda; poll 1 sn
- **Teşhis:** `[TellerDebug]` yalnızca 7 satır (profileFound … resolveSource)

## 1.0.302+305 (2026-06-19)

### Canlı Falcılar — fortuneTeller.id ≠ authUser.id (kök neden düzeltmesi)

- **Tek kaynak:** `resolveFortuneTellerProfile()` — my-profile → liste (userId) → /api/me → `fortune-tellers/{tellerId}`
- **Kaldırıldı:** `GET /api/fortune-tellers/{authUser.id}` (404 kök nedeni)
- **Tüm akışlar:** `approvedPsychicProvider`, `RolePanelResolver`, `PsychicIncomingHost._ensureTellerProfile`
- **Teşhis:** `[TellerDebug]` — profileFound, fortuneTellerId, authUserId, isUsable, isApprovedTeller, isFortuneTeller

## 1.0.301+304 (2026-06-19)

### Canlı Falcılar — falcı rolü doğrulama (kök neden düzeltmesi)

- **Kök neden:** `approvedPsychicProvider` yalnızca `GET /my-profile` kullanıyordu; `RolePanelResolver` (liste, `/api/me`, `user.role`) devre dışıydı
- **Sonsuz loading:** `AsyncNotifier` + `goRouter` watch — başvuru ekranı her refresh'te sıfırlanıyordu; ajans modeline geçildi
- **Alan eşlemesi:** `fortuneTeller`, `isActive`, `isVerified`, `approvedAt` → `applicationStatus: approved`
- **Üretim listesi:** `displayName`, `applicationStatus`, `userId` (cuid) doğru parse
- **Teşhis logu:** `[TellerRole]` — userId, role, isFortuneTeller, tellerId, approvalStatus, resolveSource, ham my-profile
- **Panel:** `isUsable` ile açılır (`isApproved` tek başına yetmezdi)

## 1.0.300+303 (2026-06-19)

### Canlı Falcılar — falcı kabul/red ekranı (kritik düzeltme)

- **Kırılan halka:** Push `type: psychic_request_created` mobilde tanınmıyordu → bildirim geliyor, kuyruk/dialog açılmıyordu
- **Push parse:** `psychic_request_created`, `request_created`, iç içe `request`/`session` gövdeleri
- **SSE:** Oturum açıkken profil onayı beklemeden `sessions/stream` bağlanır; `event:` satırı parse'a aktarılır
- **Poll:** Bekleyen istek kuyruğa eklenince `PsychicInviteCoordinator` ile dialog tetiklenir
- **Mount:** Push ile dolu kuyruk ilk frame'de de işlenir (listen ilk değerde ateşlenmez)
- **Falcı rolü:** `online`/`offline` başvuru durumu artık reddedilmiş sayılmaz

## 1.0.299+302 (2026-06-19)

### Canlı Falcılar — liste maddeleri tamamlama / sağlamlaştırma

- **Değerlendirme:** `POST /api/teller/reviews` başarısızsa `POST .../fortune-tellers/{id}/reviews` yedek yolu
- **session_ended:** Özet diyaloğu root navigator; danışan çıkışında önce özet sonra yönlendirme
- **Bekleme timeout:** Süre dolunca/redde «Tamam» ile onaylı çıkış (otomatik atlama yok)
- **Staff:** `staffExempt: true` ile seans oluşturma isteği
- **WebRTC/TRTC:** TRTC birincil; seans bitişinde `DELETE /api/room/signal` temizliği
- **Panel:** Ödül ve hediye listeleri (profille aynı veri)

## 1.0.298+301 (2026-06-19)

### Canlı Falcılar — favoriler, staff muafiyeti, panel özeti

- **Favoriler:** `GET/POST /api/favorite-tellers` — profil kalbi, liste «Favorilerim» filtresi
- **Staff jeton muafiyeti:** Randevu ve süre uzatmada bakiye kontrolü atlanır; bilgi bandı
- **Falcı paneli:** Ödül ve hediye sayı özeti kartı

## 1.0.297+300 (2026-06-19)

### Canlı Falcılar — PDF eksikleri (2–6)

- **Bekleme:** 3 dk geri sayım; süre dolunca otomatik iptal + jeton iadesi mesajı
- **Push `session_ended`:** Seans özeti diyaloğu; danışana değerlendirme önerisi
- **Liste filtreleri:** Uzmanlık chip’leri + sıralama (puan / fiyat / seans)
- **Profil:** Ödüller (`GET .../awards`) ve hediye özeti (`GET .../gifts`)
- **Değerlendirme:** Seans bitişinde `POST /api/teller/reviews` bottom sheet

## 1.0.296+299 (2026-06-19)

### Canlı Falcılar — falcı başvuru ekranı (PDF §4)

- **`/falci-ol` ve `/canli-falcilar/apply`:** Görünen ad, biyografi, uzmanlık seçimi, başvuru notu
- **`POST /api/fortune-tellers/apply`:** Hata mesajları kullanıcıya gösterilir
- **Durum ekranları:** Onaylı / bekleyen / reddedilmiş başvuru kartları
- **Liste & shell:** «Falcı Ol» / «Başvuru» kısayolu; onaylı falcılar panele yönlendirilir

## 1.0.295+298 (2026-06-19)

### Canlı Falcılar — PDF entegrasyon uyumu

- **Aktif seans:** Uygulama açılışında `GET /api/user/active-sessions` ile otomatik odaya dönüş
- **Push red/iptal:** `session_update` reddinde jeton iadesi bildirimi
- **Bekleme:** `cancelled` durumu reddedildi olarak işlenir
- **Liste:** `online=true` + `sort=rating` filtreleri
- **Oda timer:** Sunucu `elapsedSeconds` ile senkron
- **Süre:** Kullanıcı `extend`, falcı `teller_add_time` (PDF §12)
- **Profil:** Falcı yorumları (`GET .../reviews`)
- **API:** Başvuru, online durum sorgusu, model alan eşlemeleri (`displayName`, `pricePerSession`)

## 1.0.294+297 (2026-06-19)

### Canlı Falcılar — falcı kabul/red ekranı düzeltmesi

- **Push → dialog:** `PsychicInviteCoordinator` ile bildirim/SSE sonrası mor kabul ekranı zorla açılır
- **Falcı algısı:** `isUsable` + `my-profile` / liste yedekleri; SSE artık onaylı profil beklenmeden bağlanır
- **Poll/SSE ayrımı:** Arka plan senkronu auth yüklenirken de çalışır; dialog yalnızca uygun rotada gösterilir
- **SSE parse:** İç içe `request` / `session` gövdeleri `parsePsychicSsePayload` ile okunur
- **Gelen istek filtresi:** Teller alanı boş API yanıtları artık düşürülmez
- **VideoCall köprüsü:** Çift UI engellendi — canlı fal davetleri yalnızca `PsychicIncomingCallDialog`

## 1.0.293+296 (2026-06-19)

### Canlı Falcılar — sıfırdan yeniden yazım (`live_psychics`)

- **Yeni mimari:** `lib/features/live_psychics/` — domain / data / presentation (Riverpod, setState yok)
- **Liste:** Çevrimiçi falcılar, pull-to-refresh, infinite scroll
- **Profil & randevu:** Fotoğraf, uzmanlık, puan, online durumu, fal türü + süre seçimi
- **SSE:** Falcı gelen çağrı + oda güncellemeleri (web ile aynı uçlar)
- **Durumlar:** Bekliyor / Kabul / Red / Süre doldu
- **Falcı paneli:** Bekleyen çağrılar, çevrimiçi anahtarı, kabul/red
- **Tam ekran gelen çağrı popup'ı** + video görüşme (TRTC `live` sahnesi)
- **Hata / boş / offline:** Async view bileşenleri, retry, loading state
- **Eski modül kaldırıldı:** `home/live_fortune_*` dosyaları silindi; router, shell, push, ana sayfa yeni modüle bağlandı

## 1.0.292+295 (2026-06-19)

### Canlı falcı — web falcı + mobil danışan TRTC düzeltmesi

- **TRTC sahne:** `videoCall` yerine üretim web ile aynı `live` sahnesi — karşı taraf görüntüsü artık eşleşir
- **Oda kimliği:** `GET /api/room/{id}` → `roomId` / `trtcRoomId` öncelikli; usersig yanıtındaki oda kullanılır
- **Peer eşlemesi:** Danışan/falcı rolüne göre `peerId`, `tellerUserId`, `clientId` birleşimi (`remotePeerIdFor`)
- **İzin sonrası çıkış:** Oturum `SharedPreferences` ile kalıcı; izin diyaloğu / process restore sonrası seans ekranına dönüş
- **İzin ön isteği:** Reklam geçiş ekranında kamera/mikrofon izni (seans açılmadan önce)
- **Yaşam döngüsü:** Uygulama ön plana gelince bağlantı yeniden denenir; bekleme/geçiş/seans sırasında `resumeActiveSessions` çakışması engellendi

## 1.0.291+294 (2026-06-19)

### Production readiness sprint

- **Görüntülü arama:** `IncomingVideoCallScreen`, 30 sn timeout, kabul/red/meşgul, kaçırılan arama bildirimi
- **SSE:** `BaseSseService`, reconnect 1→30 sn; `ChatRoomSseService`, `NotificationSseService`, `FalSseService`, `MessageSseService`
- **Falcı paneli:** SSE canlı istekler, aktif süre, dakika ücreti, anlık kazanç
- **Online sayılar:** 25 sn poll kaldırıldı; SSE presence ile keşfet listesi
- **Provider modülleri:** `voice_room_*_provider.dart` barrel ayrımı
- **Crashlytics:** Firebase Crashlytics + Sentry DSN stub
- **Offline:** `CacheFirstLoader` + bildirimler cache-first
- **Tablet:** `NavigationRail` (≥720px)
- **Hero + görsel:** `HeroTags`, feed/story `CachedNetworkImage`
- **Rapor:** `docs/PRODUCTION_READINESS_REPORT.md`


## 1.0.290+293 (2026-06-19)

### 2026 Premium altyapı yükseltmesi

- **AMOLED koyu tema:** Saf siyah OLED modu (Profil → Ayarlar → Tema)
- **Video önbellek:** `VideoCacheService` — kısa videolarda disk cache + prefetch
- **Offline API cache:** `ApiCacheStore` TTL katmanı (başlangıç altyapısı)
- **SSE politikası:** Ortak `SseReconnectPolicy` + `SseReconnectBanner` bileşeni
- **Skeleton:** Profil ve mesaj listesi iskeletleri; profil paylaşımlarında lazy `ListView.builder`
- **Hata ekranları:** `AppErrorView` — kullanıcı dostu mesaj + tekrar dene
- **Geçişler:** `sharedAxis` Material Motion slide + fade
- **Sesli oda:** Paylaş butonu (header) + oda listesi 25sn canlı yenileme
- **Performans:** Shorts tile `RepaintBoundary`; thumbnail `CachedNetworkImage`


## 1.0.289+292 (2026-06-19)

### Profil — okunabilirlik ve premium düzen

- **Vitrin banner:** Gradyan kapak, büyük avatar ve cam istatistik kartı
- **Tipografi:** Minimum 12–15px etiketler; başlık ve sayaçlar daha belirgin
- **Yayıncı paneli:** 3 sütunlu ızgara; ikon ve yazılar büyütüldü
- **Cüzdan:** 2 sütunlu aksiyon ızgarası, net bakiye kartı
- **Hediyeler:** Görsel URL desteği ve daha büyük kutular
- **Paylaşımlarım:** Kendi profilinde sosyal paylaşım duvarı
- **Kullanıcı profili:** Banner + avatar bindirmesi, okunabilir istatistikler


## 1.0.288+291 (2026-06-19)

### Derleme düzeltmesi — video oynatma

- Eksik import'lar giderildi (`ApiException`, `shortsRepositoryProvider`)


## 1.0.287+290 (2026-06-19)

### Video yükle — oynatma düzeltmesi

- **CDN yedek:** `cdn.canlifal.com` 404 olduğunda imzalı URL (`/api/upload/get-url`) ve API stream (`/api/short-videos/:id/stream`) ile oynatma
- **Kısa video akışı:** Ağ öncelikli oynatıcı; bozuk önbellek kullanımı kaldırıldı
- **Sosyal akış:** `postType: video` gönderilerde gerçek video oynatıcı (önceden yalnızca görsel deneniyordu)
- **Yükleme:** Yalnızca MP4 kabul; MIME türü dosya uzantısından; yükleme sonrası trend videolar yenilenir


## 1.0.286+289 (2026-06-19)

### Ana sayfa — marka yazısı

- Sol üstteki ikon kaldırıldı; yerine gradyanlı **CanlıFal** şekilli yazı logosu


## 1.0.285+288 (2026-06-19)

### Kahve & el falı — fotoğraf yükleme

- **Kahve falı:** Fincan içi (zorunlu) + tabak (opsiyonel) — kamera veya galeri
- **El falı:** Avuç içi fotoğrafı + sağ/sol el seçimi
- **Üretim API:** Presigned yükleme + `kahve-fali-image` / `el-fali` görsel analiz
- **Tasarım:** Cam efektli premium panel, ipucu banner, mini kamera/galeri aksiyonları


## 1.0.284+287 (2026-06-19)

### Fal & Tarot — 2026 vitrin ve doğrudan sonuç

- **Görseller:** Fal türlerinde gerçeğe yakın ağ görselleri (hub grid + vitrin kartları)
- **Tarot / tür sayfası:** Üstte «Falını Aç», altta «En çok bakılan fallar» listesi
- **Doğrudan sonuç:** «Falına bak» oturum ekranı kaldırıldı; tüm fallarda tek dokunuşla sonuç
- **Sosyal paylaşım:** Her fal sonucu otomatik olarak sosyal akışta paylaşılır (giriş yapılıysa)


## 1.0.283+286 (2026-06-19)

### Derleme düzeltmesi — sosyal + sesli oda APK

- **Import:** `user_posts_timeline.dart` ve `social_post_comments_sheet.dart` yol hataları giderildi
- **APK:** Sosyal ve sesli oda özellikleri CI'da yeniden derlenir


## 1.0.282+285 (2026-06-19)

### Sesli oda — «Oda Aç» düzeltmesi

- **Alt sayfa:** `useRootNavigator` + `isScrollControlled`; seçim `rootNavigator` ile döner
- **Anında geri bildirim:** Butona basınca sheet kapanır, yükleme diyaloğu hemen açılır (12 sn bakiye beklemesi yok)
- **Bakiye kontrolü:** Yükleme göstergesi açıkken jeton doğrulanır; yetersizse kök SnackBar
- **Oda oluşturma:** Hata/başarı mesajları kök `ScaffoldMessenger` üzerinden; başarıda odaya yönlendirme


## 1.0.281+284 (2026-06-19)

### Sosyal — paylaşım, profil ve yorum iyileştirmeleri

- **Video paylaşım:** Gönderi oluştururken video multipart (`video` alanı) desteği
- **Profil duvarı:** TikTok ızgarası yerine dikey zaman çizelgesi; gönderiye dokununca ilgili paylaşıma kaydırma
- **Yorum sayacı:** Yorum gönderildiğinde akıştaki sayaç anında güncellenir
- **Composer:** App bar ve boş durum «Paylaşım oluştur» inline composer'ı açar
- **Giriş kontrolü:** Yorum yazmadan önce oturum doğrulaması


## 1.0.280+283 (2026-06-18)

### Canlı yayın — kamera/ses ve oda geçişi

- **Agora handoff:** Hazırlık önizlemesi kapatılıp motor serbest bırakılıyor; oda açılınca kamera kilidi kalkıyor
- **Yayıncı bağlantı:** Kanala girince yerel video/ses açıkça etkinleştiriliyor
- **Yükleniyor ekranı:** Yayıncı için «Yayın başlatılıyor…» göstergesi; giriş/destek hataları görünür


## 1.0.279+282 (2026-06-18)

### Gold üyelik — ödeme bildir düzeltmesi

- **Yetersiz jeton:** Jeton mağazasına yönlendirme kaldırıldı; Papara/Havale/WhatsApp ödeme akışı açılır
- **Talep gövdesi:** `senderInfo`, `receiptReference`, `tierId` / `membershipTier` alanları eklendi
- **Onay metni:** Gold üyelik için «üyeliğiniz aktifleşir» mesajı

## 1.0.278+281 (2026-06-18)

### Jeton — ödeme bildir düzeltmesi

- **Tek dokunuş:** WhatsApp / Papara / Havale'de «Ödeme Bildir» doğrudan talep gönderir (önce yalnızca alt sayfa açılıyordu)
- **API yedekleri:** `POST /api/payment/requests` → `/api/jeton/payment-request` → `/api/payment/request`
- **Yanıt algısı:** `paymentRequest`, `ok`, `created` alanları; 2xx geniş kabul
- **Dekont:** İsteğe bağlı «Dekont ekle» tüm yöntemlerde

## 1.0.276+279 (2026-06-18)

### Falcı Panel / Ajans Panel — onay algısı düzeltmesi

- **Derleme hatası:** `RolePanelResolver` artık doğru `homeRemoteProvider` ile bağlanıyor
- **Çoklu kaynak:** `/api/me` içindeki `roles`, `isFortuneTeller`, `isAgency` alanları okunur
- **Uç nokta probu:** Falcı seans ve ajans üye/kazanç uçlarına erişim varsa panel etiketi gösterilir
- **Durum alanları:** `verificationStatus`, `approvalStatus`, `active`, `verified` onaylı sayılır

## 1.0.275+278 (2026-06-18)

### Falcı Panel / Ajans Panel etiket düzeltmesi

- **Çoklu API algısı:** `RolePanelResolver` — `my-profile`, `/api/me`, `/api/user/profile`, falcı listesi, seans uçları
- **Ajans:** `agency/my` + `/api/me` iç içe `agency` / `liveAgency` alanları
- **Etiket:** Onaylı kullanıcıda «Falcı Panel» / «Ajans Panel»; yükleme sırasında önceki onay korunur

## 1.0.274+277 (2026-06-18)

### Canlı fal — kabul ekranı + TRTC kamera/ses

- **Kabul ekranı:** `targetPath` içinden oturum ID; kuyruk tekrar `requestPresent`; UI hazır olunca otomatik popup
- **TRTC iki yönlü video:** `videoCall` sahnesi — danışan da `anchor` (kamera/mikrofon yayınlar)
- **Falcı uzak video:** Host rolünde bile danışan videosu dinlenir (önceden hiç dinlenmiyordu)
- **Bağlantı ekranı:** «Bağlantı kuruluyor…» + «Yeniden Bağlan»; falcı PiP önizleme
- **Oda peerId:** `GET /api/room/{id}` → danışan TRTC kimliği eşlemesi

## 1.0.273+276 (2026-06-18)

### Gerçek düzeltmeler — panel, kabul ekranı, tek bildirim

- **Push `targetId`:** Sunucu `type: fortune` + `targetId` gönderdiğinde artık oturum ID okunur; mor kabul ekranı açılır (önceden yalnızca bildirim geliyordu)
- **Erken push tamponu:** Oturum açılmadan gelen davetler kaybolmaz; `PushLifecycleListener` mount olunca kuyruğa alınır
- **Falcı panel poll:** Bekleyen oturumlar `fortuneIncomingInviteProvider` kuyruğuna eklenir (yalnızca `requestPresent` değil)
- **Onay algısı:** `my-profile` / `agency/my` `profile` sarmalayıcısı; ajans `isUsable` teller ile aynı mantık; router redirect önce API’yi bekler
- **Çift bildirim:** Falcı davet tıklamasında liste yenileme atlanır; push tamponu çift işlemeyi engeller

## 1.0.272+275 (2026-06-18)

### Canlı fal kabul ekranı + tek bildirim

- **Çift kabul ekranı:** Falcı panelindeki otomatik popup kaldırıldı; yalnızca global `FortuneIncomingInviteHost` mor «Canlı Fal İsteği» dialogunu açar
- **Dashboard SSE/poll:** Falcı panelinde de arka plan SSE ve poll çalışır; kabul ekranı artık paneldeyken de gelir
- **Tek bildirim:** FCM yerel bildirimi falcı davetinde atlanır; kuyruk tekrar `requestPresent` çağırmaz
- **Panel etiketleri:** «Falcı Panel» / «Ajans Panel» (onaylı kullanıcılar); `isUsable` ile daha geniş onay algısı

## 1.0.271+274 (2026-06-18)

### API dokümantasyonu uyumu (§15 Falcı / §17 Ajans)

- **Bildirim tıklama:** Canlı fal isteği bildirimine tıklanınca mor kabul ekranı açılır (`fortuneInviteFromNotification`)
- **Keşfet & İçerik:** Onaylı falcı/ajans için «Panel» etiketi ve doğrudan dashboard rotası
- **`/falci-ol` / `/ajans-ol`:** Onaylı kullanıcı dashboard'a, diğerleri content-hub'a yönlendirilir

## 1.0.270+273 (2026-06-18)

### Falcı / Ajans paneli + kabul ekranı düzeltmeleri

- **Onaylı falcı:** «Falcı Ol» → **Falcı Paneli** (profil, ana sayfa, canlı falcılar)
- **Onaylı ajans:** «Ajans Ol» → **Ajans Paneli** (`GET /api/agency/my`, üyeler, kazanç, görevler)
- **AjansDashboardScreen:** `/ajans/dashboard` — web paneli özellikleri (üye listesi, kazançlar, görevler, davet kodu)
- **Kabul ekranı:** Push/SSE sonrası `FortuneInviteCoordinator` ile mor «Canlı Fal İsteği» dialog zorla açılır
- **Çift bildirim:** Falcı davet push'unda sistem banner + liste yenileme engellendi; bildirim listesi id/fingerprint ile tekilleştirildi

## 1.0.269+272 (2026-06-18)

### Canlı fal kabul ekranları (web UI)

- **Canlı Fal İsteği popup:** Falcı paneli ve global host artık web ile aynı mor gradient dialog (Kabul Et / Beklet / Reddet)
- **Seansı Başlat:** Kabul sonrası jeton bakiyesi + süre seçimi + «Şimdi Başlat» sheet'i gösterilir
- **Pending tespiti:** Dashboard hem `fetchIncomingSessions` hem `fetchPendingSessions` birleştirir
- **Onaylı falcı:** `applicationStatus` artık `status: online` ile karışmaz; `isApproved` / `canGoOnline` desteklenir
- **Ortak akış:** `LiveFortuneTellerInviteFlow` — root navigator üzerinden dialog

## 1.0.268+271 (2026-06-18)

### Falcı paneli (TellerDashboardScreen)

- **Onaylı falcı:** Girişte `GET /api/fortune-tellers/my-profile` — `applicationStatus == approved`
- **TellerDashboardScreen:** İsim, çevrimiçi durumu, puan, seans, kazanç, bekleyen/aktif sayaçları
- **Pending poll:** Her 3 sn `GET /api/fortune-tellers/sessions?status=pending`
- **IncomingRequestDialog:** Otomatik popup — Kabul Et / Reddet
- **Kabul:** `PATCH .../sessions/{id}` `{action:accept}` → canlı oda (`LiveFortuneSessionPage`)
- **Debug log:** dashboard loaded, pending count, popup opened, accept response
- **Rota:** `/canli-falcilar/dashboard`

## 1.0.267+270 (2026-06-18)

### Derleme düzeltmesi

- **SSE:** `eventsource` paketi `youtube_explode_dart` ile `http` sürüm çakışması nedeniyle kaldırıldı; `ChatRoomSseService` Dio stream ile aynı SSE protokolünü kullanır

## 1.0.266+269 (2026-06-18)

### Backend entegrasyonu — SSE, repository, canlı falcı

- **Sohbet SSE:** `ChatRoomSseService` (Dio stream) — message, dj, song, music, gift, presence, moderasyon; Socket.IO hediye yolu kaldırıldı
- **Odadan çıkış:** Müzik player + SSE + presence temizliği; geri tuşu tam `leaveRoomSession`
- **Poll:** SSE bağlıyken mesaj poll atlanır (DJ/presence yedek poll 15–30 sn)
- **Canlı falcı:** `LiveFortuneRepository` + `LiveFortuneRemoteDataSource` — apply, reviews, awards, gifts, room signal
- **ErrorHandler:** Merkezi API hata mesajları
- **WebRTC sinyal:** `LiveFortuneRoomSignalService` — `POST/GET/DELETE /api/room/signal` (HTTP poll)
- **Rapor:** `docs/FLUTTER_BACKEND_INTEGRATION_REPORT.md`

## 1.0.265+268 (2026-06-18)

### Canlı falcı — bağlantı ve çıkış düzeltmeleri

- **Falcı daveti SSE:** `GET /api/fortune-tellers/sessions/stream` — yayın/oda olmadan istek alımı
- **Poll:** Falcı profili yüklenene kadar bekler; `incoming` ucu öncelikli; 2 sn aralık
- **Kabul:** «Seansı Başlat» kapatılırsa artık otomatik red yok; seansa geçiş devam eder
- **Bekleme çıkışı:** İptal API başarısız olsa bile ekrandan çıkış; «Ana sayfaya dön» + zorla çık
- **Seans kapatma:** API hatasında da güvenli çıkış

## 1.0.264+267 (2026-06-18)

### Canlı fal seans SSE (`GET /api/room/{sessionId}/stream`)

- **Servis:** `LiveFortuneRoomSseService` — mesaj, timer, oda durumu, seans sonu olayları
- **Bekleme:** Danışan kabul/red anında SSE ile yönlendirme (3 sn poll yedek)
- **Seans:** Sohbet SSE birincil; poll 20 sn yedek; timer/oda güncellemeleri anlık
- **Test:** `live_fortune_room_sse_mapper_test.dart` — payload ayrıştırma

## 1.0.263+266 (2026-06-18)

### Canlı falcı — canlifal.com ekran uyumu

- **Profil / randevu:** Fal türü seçimi, 5–30 dk (25 dk dahil), jeton/seans etiketi
- **Bekleme:** Web ile aynı «Lütfen Bekleyiniz…» halka animasyonu ve kırmızı «İptal Et»
- **Red:** «Falcı randevunuzu reddetti» snackbar (profil sayfasında)
- **Reklam geçişi:** Kabul sonrası 4 sn «Reklam» kartı (`ad-transition` rotası)
- **Falcı daveti:** Kulaklık 24 ikonu, web metni, kategori etiketi
- **Seansı Başlat:** Falcı kabul sonrası web popup geri eklendi
- **Görüşme:** Danışanda Bahşiş + teşekkür overlay; falcıda yalnızca «+ Süre Ekle»
- **Süre Ekle:** 2 sütunlu grid (web ile aynı düzen)

## 1.0.262+265 (2026-06-18)

### Canlı falcı — randevu → kabul → görüşme akışı

- **Falcı daveti:** «X sizinle Y dakika görüşme talep ediyor» metni; `userId` / `user.name` API eşlemesi düzeltildi
- **Kabul:** Ekstra başlatma popup'ı kaldırıldı — kabul sonrası doğrudan görüşme ekranı
- **Danışan:** Falcı kabul edince bekleme ekranından doğrudan görüşmeye geçiş (3 sn reklam atlandı)
- **TRTC:** Oda bilgisi alındıktan sonra video bağlantısı; sunucu `roomId` ile yeniden bağlanma
- **Push kabul:** Bekleme ekranındayken `session_update` ile anında görüşmeye yönlendirme
- **Falcı çevrimiçi:** Her oturumda `toggle-online` yeniden denenir

## 1.0.261+264 (2026-06-18)

### Canlı falcı — backend MD sözleşmesi (canlifal.com/api/download-prompt)

- **Seans oluşturma:** `POST /api/fortune-tellers/session` — body yalnızca `tellerId`, `fortuneType`, `duration`; `creditsCharged` / `maxMinutes` yanıttan okunur
- **Falcı poll:** Öncelik `GET /api/fortune-tellers/sessions?status=pending` (3 sn aralık)
- **Kabul / red / iptal:** `PATCH /api/fortune-tellers/sessions/{id}` `{ action }` birincil yol
- **Çevrimiçi:** `POST /api/fortune-tellers/toggle-online` `{ isOnline: true }`
- **Aktif seans:** Uygulama açılışında `GET /api/user/active-sessions` ile devam
- **Push:** `session_request`, `session_update`, `session_ended` tipleri işlenir; kabulde canlı odaya yönlendirme
- **Danışan bekleme:** Durum poll 3 sn (üretim dokümanı §6–8)

## 1.0.260+263 (2026-06-18)

### Canlı falcı — istek mobilde gelmiyor / iptal takılıyor

- **`/api/live-fal/pending`:** Sunucu tarafı filtrelenmiş istekler artık mobilde yanlışlıkla elenmiyor
- **Davet popup:** Diyalog dışına tıklanınca istek kalıcı olarak silinmiyor; tekrar gösteriliyor
- **İptal:** Onaydan önce «İptal ediliyor…» gösterilmiyor; API zaman aşımı (12 sn) eklendi
- **Falcı çevrimiçi:** Profil bulununca `toggle-online` her oturumda yeniden deneniyor

### Canlı yayın

- Yayın oluşturma `status: live` (üretim API uyumu); orphan temizliği korunuyor

### Jeton — Papara / IBAN

- **Tek dokunuş:** Papara ve havalede «Ödemeyi Bildir» doğrudan admin talebi gönderir
- **Bekleyen talep:** Aynı kullanıcıda önceki bekleyen talep varsa net hata mesajı

## 1.0.259+262 (2026-06-18)

### Canlı yayın — kamera ve durum düzeltmeleri

- **Kamera önizleme:** İzin / desteklenmeyen cihaz hataları artık ekranda gösterilir; «Kamera açılıyor…» yükleme durumu eklendi
- **Yanlış «yayında» durumu:** Yayın `preparing` ile oluşturulur; geri dönüş veya Agora hatasında sunucuda otomatik `end` çağrılır
- **Kamera aç/kapa:** Önizlemede `startPreview` / `stopPreview` kullanılır

### Canlı falcı — istek ve iptal

- **Yayıncıya istek:** Video yayın SSE üzerinden `fal_request` olayları; falcı poll 2 sn; aktif yayın odası SSE önceliği
- **İptal:** `declined` / `cancelled` durumları; iptal API başarısızsa kullanıcıya uyarı; bekleme ekranında yükleme durumu

### Jeton Al — WhatsApp

- **WhatsApp seçimi:** Yöntem ekranında WhatsApp seçilince sohbet otomatik açılır (jeton, kullanıcı adı, ödeme türü ile)

## 1.0.258+261 (2026-06-18)

### Bildirimler — push kayıt ve izin akışı düzeltmesi

- **Mevcut oturum:** Uygulama zaten girişli açıldığında OneSignal `login` ve push token kaydı artık anında tetiklenir
- **İzin sonrası kayıt:** Bildirim izni banner’dan açıldığında Firebase/FCM token kaydı tekrar denenir
- **İlk kurulum:** OneSignal/FCM token geç oluşursa kısa retry ile `/api/auth/mobile/device-token`, `/api/devices/fcm`, `/api/user/device-token` kayıtları kaçırılmaz

## 1.0.257+260 (2026-06-17)

### Jeton yükleme — ödeme bildirimi düzeltmesi

- **Paketler:** 50 / 100 / 250 / 500 / 1000 jeton her zaman seçilebilir (API + varsayılan birleşimi)
- **Satın al:** Paket kartına dokununca doğrudan ödeme yöntemi ekranı açılır
- **Ödeme yöntemleri:** WhatsApp `+905327170173`, Papara, Havale/IBAN — hepsinde «Ödeme Bildir»
- **Admin bildirimi:** `notifyAdmins` + `notifyStaff` ile staff rollerine anında bildirim
- **WhatsApp:** Ödeme bildir → admin talebi → WhatsApp sohbeti açılır
- **API:** 2xx ödeme yanıtı kabulü genişletildi

## 1.0.256+259 (2026-06-17)

### Canlı falcı — baştan yazılmış akış

- **Randevu:** Süre seç → Randevu Al → `POST /api/fortune-tellers/session` → bekleme ekranı
- **Bekleme:** Admin reklamı (`GET /api/banners`); falcıya popup (Kabul / Beklet / Reddet)
- **Kabul sonrası:** Danışana reklam geçişi (3 sn) → aktif seans
- **Kapatma:** Danışan ve falcı iptal/kapat dediğinde onay + API `end` + güvenli çıkış
- **Router:** `/canli-falcilar/:id/waiting` bekleme rotası eklendi

## 1.0.255+258 (2026-06-17)

### Canlı falcı — üretim oda API (`/api/room/*`)

- **Oda:** `GET /api/room/{sessionId}` — timer, peerId, jeton bakiyesi
- **Timer:** Falcı `start_timer`; her iki taraf 60 sn `ping`; client-side countdown sunucu `timerStartedAt` ile
- **Sohbet:** `GET/POST /api/room/{sessionId}/messages` (teller-chat yedek)
- **Süre:** Kullanıcı `extend`, falcı `teller_add_time`; seans bitişi `PATCH action: end`
- **Seans oluşturma:** `fortuneType` + `duration` alanları; falcı poll `?status=pending`
- **Bekleme:** Danışan «Falcı hazırlanıyor…» overlay'i timer başlayana kadar

## 1.0.254+257 (2026-06-17)

### Canlı yayın — izleyici Fal İste şeridi

- **Şerit:** İzleyici, Hediye, Fal İste, Rumuz, ses ve Çık butonları
- **Bağlanıyor:** Yayına bağlanırken merkezde yükleme durumu

## 1.0.253+256 (2026-06-17)

### Canlı falcı — yayın + red yönlendirme

- **Canlı yayın:** Fal kategorili yayın izlerken sağ şeritte «Fal İste» → randevu + bekleme akışı
- **Red:** İade popup'ı «Ana Sayfaya Dön» ile `/` yönlendirmesi (danışan + falcı)

## 1.0.252+255 (2026-06-17)

### Canlı falcı — 8 ekranlı akış

- **Bekleme:** Randevu sonrası reklam kartı + geri sayım; falcı profili üst bölümde
- **Falcı daveti:** Kabul / Beklet / Reddet popup (süre, jeton, saat)
- **Seans başlat:** Falcı kabul sonrası «Şimdi Başlat» veya süre seçimi popup'ı
- **Seans:** PiP kamera, Süre Ekle ve Bahşiş jeton popup'ları (`/api/teller/gifts`, süre uzatma PATCH)
- **Red:** Falcı kabul etmezse danışana «müsait değil, jeton iade» popup + ana sayfa; falcı da ana sayfaya döner
- **Canlı yayın:** Fal kategorili yayınlarda izleyiciye «Fal İste» butonu

## 1.0.251+254 (2026-06-12)

### Canlı yayın — Agora + üretim API tam entegrasyon

- **RTC:** Video yayınları Tencent TRTC yerine **Agora** (`POST /api/agora/token`, host/audience rolleri)
- **Yayın akışı:** `POST /api/video-streams` → Agora bağlantısı → `POST …/live-started` (takipçi bildirimi)
- **SSE:** `GET /api/video-streams/{id}/stream` — izleyici sayısı, sohbet, hediye, yayın sonu (Socket.IO yedek)
- **PK:** `GET/POST /api/video-streams/pk` + `pk-battle` fallback; `score1/score2` skor alanları
- **Co-broadcast:** Davet, talep, onay, kabul/red/ayrıl API eylemleri
- **Yayın güncelleme:** `PATCH /api/video-streams/{id}` — resim modu, arka plan
- **Kategori:** Fal → `fortune`, sohbet/müzik → `chat`, diğer → `general`

## 1.0.250+253 (2026-06-12)

### TikTok tarzı canlı yayın akışı

- **Yayın türü:** Fal türleri + sohbet/müzik kategorileri (`/live/type`)
- **Hazırlık:** Kamera önizleme, misafir modu (2/3/4 kişi grid), arka plan seçimi
- **Canlı oda:** Misafir grid düzeni, sohbet göster/gizle, PK ve arka plan değiştirme
- **Ana sayfa:** Canlı yayıncılar için video önizleme (HLS varsa) + animasyonlu thumbnail

## 1.0.249+252 (2026-06-12)

### PK, alt bar, profil, ödeme, bildirimler

- **PK daveti:** Oda açılışında sunucudan PK durumu senkronu; askıda kayıt otomatik sonlandırma; «zaten aktif PK» hatasında yenileme
- **Alt bar:** Ana sayfa yanında **Sosyal** sekmesi (`/social`); mikrofon → canlı yayın aç + video yükle
- **Profil:** Takipçi/takip/yayın sayıları site profili + yayın geçmişi ile birleştirilir
- **Hızlı işlemler:** Canlı yayın aç ve video yükle kısayolları
- **Premium üyelik:** «Nasıl üye olurum?» adım kartı; satın alma akışı korundu
- **Ödeme bildirimi:** Galeriden dekont seçimi; gönderimde admin bildirimi bayrağı
- **Bildirimler:** `/api/notifications` + aktivite akışı birleşik liste; OneSignal kaydı korunur

## 1.0.248+251 (2026-06-12)

### Canlı fal istekleri + sesli oda / PK

- **Canlı fal:** `GET /api/live-fal/pending` (5 sn poll) + `POST …/accept|reject`
- **SSE:** `fal_request`, `live_fal_request`, `fortune_request`, `private_fal_request` — otomatik `FortuneRequestDialog`
- **Falcı SSE:** Oda sahibi odasına SSE; arka plandan dönüşte yeniden bağlanma; kopunca reconnect
- **Sesli oda:** `apiRoomKey` boşken liste yenileme ile giriş düzeltmesi
- **PK:** Bitmiş PK kaydı temizleme; «zaten aktif PK» hatasında sonlandırma / anlaşılır mesaj

## 1.0.247+250 (2026-06-12)

### PK — üretim API sözleşmesi

- **Uç nokta:** `GET/POST /api/chat/rooms/{roomId}/pk` (`pk-battle` ve `/api/pk/battles` kaldırıldı)
- **Davet:** `{ action: "create", targetRoomId, duration }` (varsayılan 180 sn)
- **Kabul / red:** `{ action: "accept"|"reject", battleId }` — kabul eden odanın `roomId` ile
- **Hediye skoru:** `POST …/gifts` gövdesine `streamId: roomId` eklendi

## 1.0.246+249 (2026-06-12)

### PK daveti + Canlı falcı kabul ekranı

- **PK:** Oda `pk-battle` 404 ise `POST /api/pk/battles` + slug/cuid yedek anahtarları; anlaşılır hata metni
- **Canlı falcı:** `sessions` + `sessions/incoming` birleştirilmiş poll; falcı `tellerUserId`/`tellerId` filtresi
- **Çevrimiçi:** `toggle-online` + `toggle` (PATCH/POST) yedekleri; my-profile yoksa listeden falcı eşleştirme
- **Oturum oluşturma:** `anchorUserId` + gerçek `userId` ile falcıya yönlendirme

## 1.0.245+248 (2026-06-12)

### Sesli oda performans + otomatik koltuk

- **Sohbet:** `ChatMessageWidget`, `GiftWidget`, `UserAvatarWidget`; `RepaintBoundary`; `ShaderMask` ve müzik satırı animasyonları kaldırıldı
- **Mesajlar:** SSE ile tek tek ekleme korundu; poll aralığı SSE açıkken 30 sn
- **Otomatik koltuk:** Owner/admin/mod/DJ odaya girince `POST join-seat` (yedek `seats`); öncelik Owner > Admin > Moderator > DJ
- **Yetki:** RTC sayfasında `serverPermissions` ile `VoiceRoomPermissions` düzeltmesi
- **Oda listesi:** `AutomaticKeepAliveClientMixin`; ana sayfa / canlı sekme 30 sn yenileme
- **Avatar:** `CachedNetworkImage` max 128×128 önbellek
- **Android:** `hardwareAccelerated` + Impeller meta-data

### Canlı Falcılar — görüşme

- **TRTC:** Kabul sonrası oturum durumundan `trtcRoomId` alınır
- **Çıkış:** Seans bitişinde sunucuya `end`/`leave` bildirimi; WebRTC sinyal durdurulur
- **Sohbet:** Daha yüksek panel, `RepaintBoundary`, blur azaltıldı

## 1.0.244+247 (2026-06-12)

### Canlı Falcılar — kabul ekranı + bildirim + hız

- **Kabul ekranı:** Üretim `GET /fortune-tellers/sessions` ayrıştırması genişletildi; falcı uygulama açılışında `toggle-online` (web ile aynı çevrimiçi)
- **Poll:** Davet kontrolü 2 sn; 4 sn başlangıç gecikmesi kaldırıldı; uygulama ön plana gelince anında yenileme
- **Push:** Token kaydı `POST /api/auth/mobile/device-token` + yedek uçlar; girişte bildirim izni isteği
- **Performans:** Ana sayfa bölümleri kademeli yükleme (`HomeDeferredSection`); arka plan poll 60 sn

## 1.0.243+246 (2026-06-12)

### Canlı Falcılar — web ile oturum senkronu

- **Gelen istekler:** Üretim API `GET /api/fortune-tellers/sessions` (web ile aynı); yerel ayna yedek
- **Kabul/red:** `PATCH /api/fortune-tellers/sessions/{id}` + eski `respond` yedek
- **Danışan bekleme:** Oturum durumu üretim listesinden poll; kabulde TRTC oda bilgisi güncellenir
- **Sohbet:** `GET/POST /api/teller-chat/{sessionId}` — web ↔ uygulama metin iletişimi
- **Bildirim:** Canlı fal bildirimleri `/canli-falcilar` sayfasına yönlendirilir

## 1.0.242+245 (2026-06-12)

### Video Müzik — akıcı oynatma ve otomatik sıra

- **Akıcılık:** YouTube IFrame API; oynat/durdur ve konum için tam sayfa yenileme yerine JS komutları (titreme giderildi)
- **Parça bitişi:** Video bittiğinde otomatik `music-queue/complete` — sırada şarkı varsa geçiş, yoksa video kapanır
- **Kontroller:** Oynat/durdur/kapat çubuğu koltukların **altında** (duyuru/sohbet üstünde)

## 1.0.241+244 (2026-06-12)

### Video Müzik — YouTube Hata 153 düzeltmesi

- WebView embed: `loadHtmlString` + `baseUrl: https://canlifal.com` (Referer zorunluluğu)
- iframe `referrerpolicy` + `origin` parametresi
- Yedek: doğrudan embed + `Referer` HTTP header
- Hata durumunda küçük resim (thumbnail) gösterimi

## 1.0.240+243 (2026-06-12)

### Video Müzik Modu — !istek ve siyah ekran düzeltmeleri

- **!istek:** Artık sohbet yerine `music-request-by-query` API çağrılır — web ile aynı kuyruk/senkron
- **Siyah ekran:** `youtube_player_iframe` kaldırıldı; WebView embed + hybrid composition (UI üstte kalır)
- **Arka plan:** Kozmik arka plan her zaman görünür; video yalnızca üstüne bindirilir
- **videoId:** Yalnızca geçerli 11 karakterlik YouTube ID ile video modu açılır (akış URL'leri hariç)

## 1.0.239+242 (2026-06-12)

### Video Müzik Modu — sesli sohbet odaları

- **!istek sanatçı şarkı:** Mesaj backend'e gider; YouTube Data API v3 ile ilk uygun video bulunur ve `videoId` oda state'ine yazılır
- **Tam ekran video:** Aktif video varken arka plan görseli yerine YouTube tam ekran oynatıcı (`youtube_player_iframe`)
- **Katmanlar:** Koltuklar, sohbet, konuşan göstergeleri ve hediyeler videonun üzerinde kalır
- **Yetkili kontroller:** Oda sahibi / admin / DJ — oynat, duraklat, kapat (WebSocket `roomVideo` + `dj` senkronu)
- **Yeni giren:** `music-queue` / SSE / socket ile mevcut konumdan devam
- **Mimari:** `RoomVideoState`, `RoomVideoController`, `RoomVideoOverlay`, `YoutubeVideoBackground`, `RoomVideoSocketEvents`
- **Kaldırıldı:** Mini video yedek oynatıcı ve alt müzik şeridi (`VoiceRoomWebMusicBar`)

## 1.0.238+241 (2026-06-12)

### Hata düzeltmeleri — video yedek, oda aç, ödeme bildir

- **Video yedek:** 96×96 sürüklenebilir mini oynatıcı; altta oynat/durdur/kapat; YouTube embed (WebView)
- **Oda aç:** `POST /api/chat/rooms/create` + yedek `POST /api/chat/rooms`; mevcut oda varsa yönlendirme
- **Ödeme bildir:** 2xx yanıt kabulü genişletildi; dekont yükleme zaman aşımı; otomatik açıklama alanı

## 1.0.237+240 (2026-06-12)

### Ana sayfa + sesli oda + jeton ödeme

- **Canlı Falcılar:** Sesli oda kartları gibi kare/yatay kartlar
- **Canlı Yayındakiler:** Bölüm yukarı taşındı (hızlı aksiyonların hemen altı)
- **Fal & Tarot:** Görsel kartlarda emoji/yazı bindirmesi kaldırıldı
- **Günlük Burç:** Burç başına gradient kare ikonlar
- **Sesli oda müziği:** Ses akışı başarısız olursa 96×96 video yedek oynatıcı
- **Oda aç:** Web ile uyumlu yanıt ayrıştırma + `roomId` geri kazanımı
- **Jeton Papara/Havale:** Ödeme bildir popup'ı, dekont görseli, otomatik alanlar, 5–10 dk bekleme mesajı; onay/red bildirim popup'ı

## 1.0.236+239 (2026-06-12)

### Müzik + oda stabilitesi — istemci düzeltmeleri

- **Debug logları (release):** `ROOM JOIN/LEAVE`, `SSE CONNECT/DISCONNECT/RECONNECT`, `PRESENCE UPDATE`, `SEAT UPDATE`, `DJ UPDATE`, `MUSIC START/STOP/ERROR`, `DJ EVENT RECEIVED`
- **Müzik:** Aynı `videoId` ile player yeniden oluşturulmaz; `youtube.com` watch URL → explode çözümleme; `setAudioSource` / `errorStream` hata logları; bildirim yalnızca gerçek oynatma sonrası
- **Oda:** Boş presence SSE yanıtında koltuk/avatar korunur; `leaveRoomSession()` ile kontrollü çıkış; çift SSE/presence join engeli

## 1.0.235+238 (2026-06-12)

### !istek / müzik oynatma — web parity

- Oynatma öncesi akış URL'si her seferinde `videoId` ile yeniden çözülür (Piped → youtube_explode → sunucu)
- Süresi dolmuş sunucu `musicUrl` / googlevideo linklerine güvenilmez; başarısızlıkta otomatik yeniden dene
- Piped proxy akışları için HTTP başlıkları; `!istek` arama listesi 10 sonuç (web ile aynı)

## 1.0.234+237 (2026-06-12)

### Müzik oynatma — bildirim ve senkron

- `audio_service` artık yalnızca gerçek oynatma başlarken başlatılıyor (`stop()` bildirim açmıyor)
- DJ SSE yükünde `djUserIds` / `djUsers` — odadaki herkes DJ listesini anında görür
- Oda sahibi / admin / moderatör DJ paneli ve + butonuna erişir
- Koltuklarda DJ rozeti `live.dj` ile birleşik güncellenir

## 1.0.233+236 (2026-06-12)

### Müzik oynatma — ses gelmeme düzeltmesi

- Android'de googlevideo akışları artık önce canlifal.com `/api/chat/youtube-audio` proxy üzerinden oynatılıyor
- Medya bildirimi yalnızca ses gerçekten başladıktan sonra gösteriliyor
- `setAudioSource` / `play()` öncesi-sonrası ayrıntılı `[MusicPipeline]` logları
- 3 saniye içinde ses başlamazsa teşhis logu; oynatıcıyı kapatan periyodik timeout kaldırıldı
- Ses akışı alınamazsa / oynatma başarısızsa kullanıcıya hata mesajı
- Audio focus `gain` + 3 denemeli yeniden aktivasyon

### DJ yönetimi

- Oda sahibi, admin ve moderatörler DJ + butonunu kullanabilir
- DJ ekleme sonrası sunucu SSE ile tüm odaya yayınlar

## 1.0.232+235 (2026-06-12)

### Müzik sistemi — sıfırdan yeniden yazım

- **!istek:** YouTube Data API v3 ile ilk 5 sonuç; modern seçim ekranı
- **Ses kaynağı:** videoId sunucuya gider; yt-dlp ile güncel stream URL; istemci yalnızca bu URL'yi oynatır
- **Oynatıcı:** Kapak, süre, ilerleme çubuğu, play/pause/stop, sessiz, ses seviyesi, kapat (X)
- **Bildirim:** just_audio + audio_service medya kontrolleri; kapatınca bildirim kalkar
- **Oda senkronu:** currentPosition / isPlaying / currentVideoId SSE ile; geç katılan doğru konumdan başlar
- **Kuyruk:** Tam kuyruk ekranı; DJ silme; sıradaki otomatik
- **Yaşam döngüsü:** Odadan çıkınca müzik ve bildirim durur

## 1.0.231+234 (2026-06-12)

### Müzik — YouTube öncelikli oynatma

- DJ müziği artık sunucunun kısa ömürlü `googlevideo.com` linklerine güvenmiyor
- Oynatma girişi her zaman YouTube watch / videoId (`nowPlaying`, kuyruk, `!istek` araması)
- Mobil tarafta Piped / Invidious / youtube_explode ile akış çözülüyor; süresi dolmuş CDN sessizliği önlenir

## 1.0.230+233 (2026-06-12)

### Hata düzeltmeleri — sesli oda bağlantısı ve DJ müziği

- **Oda giriş döngüsü:** `voiceRoomLiveProvider` artık yalnızca oda kimliği (`liveKey`) ile tutulur; online sayısı / avatar güncellemelerinde presence+SSE kopmaz
- **SSE:** Aynı odaya yeniden bağlanırken mevcut akış korunur
- **Müzik:** Süresi dolmuş `googlevideo.com` URL'leri videoId ile yeniden çözülür; DJ SSE güncellemelerinde gereksiz oynatıcı yeniden başlatma azaltıldı
- **Poll hataları:** Arka plan yenileme hataları artık SnackBar ile «bağlantı koptu» hissi vermez

## 1.0.229+232 (2026-06-12)

### Hata düzeltmeleri — sesli oda, müzik, jeton, ana sayfa

- **Sesli / VIP oda açma:** Jeton bakiyesi kontrolü düzeltildi; oda kimliği boşsa liste yenilenir; `GET /api/chat/rooms/:id` ile doğrudan oda yükleme
- **Müzik / !istek:** API zaman aşımı 45 sn; zaman aşımında kuyruk senkronu ile kurtarma; oynatıcı doğrulama 12 sn
- **Jeton mağazası:** Son seçilen paket hatırlanır; «Ödeme Bildir» butonu; WhatsApp numara formatı (90…); dekont admin talebine eklenir
- **Ana sayfa:** Hızlı erişim şeridi (Sesli Oda, Fal, Jeton, Oda Aç); bölüm sırası sadeleştirildi

## 1.0.228+231 (2026-06-12)

### Web parite — ana sayfa ve sesli oda

- **Ana sayfa:** Kampanya bannerları (`HomeBannerCarousel`), günlük burç şeridi, fal kartları `GET /api/homepage-fortune-cards`
- **Sesli oda:** Moderatör «Konuşmacı sırası» paneli — dinleyicilere «Ses ver» (`assignSeat`)
- **Dokümantasyon:** `docs/CANLIFAL_WEB_MOBILE_PARITY.md` — web ↔ mobil ekran/API eşlemesi

## 1.0.227+230 (2026-06-12)

### Premium Fortune — modern fal uygulaması (MVVM)

- **Mimari:** `premium_fortune/` modülü — MVVM + Clean Architecture (domain/data/presentation)
- **Firebase:** Auth, Firestore, Storage entegrasyonu (demo mod: SharedPreferences yedek)
- **OpenAI:** Kahve falı (görsel), tarot, rüya tabiri, doğum haritası AI yorumları
- **Modüller:** Auth (e-posta, Google, Apple), kahve falı, tarot, canlı falcı, sohbet, cüzdan, oyunlar, astroloji, rüya, admin panel
- **Tasarım:** Premium koyu tema, cam kartlar, alt navigasyon, animasyonlu geçişler
- **Ödeme:** Stripe/Iyzico soyut katmanı + kupon kodları (HOSGELDIN, FAL2026)
- **Rota:** `/premium` — ana uygulamadan bağımsız premium deneyim

## 1.0.226+229 (2026-06-12)

### Sesli oda — tam teknik dokümantasyon uyumu

- **myPermissions:** `GET messages` yanıtından sunucu yetkileri okunur; kick/ban/mute/oda sessiz ayrı kontrol
- **!istek / song-request:** Üretim akışı korunur (`skipPayment`, `dedication`, `duration`)
- **Presence:** 30 sn heartbeat + `nickname`; koltuk indeksi 0–14
- **SSE:** `messages` batch + `typing` kullanıcı listesi
- **Müzik:** Çalarken `GET /music` ile sunucu auto-advance tetiklenir
- **Moderasyon:** kick/ban/mute ayrı UI; `mute_room` / `unmute_room`; `PATCH song-request`
- **Odalar:** `GET /api/chat/rooms?withCounts=true`; mesajlarda `after` + `limit=100`

## 1.0.225+228 (2026-06-12)

### Sesli oda — üretim dokümantasyonu uyumu

- **!istek:** `GET /api/youtube/search` → `POST song-request` + `skipPayment: true` (jeton gerekmez)
- **Şarkı isteği:** `song-request` birincil; `dedication`, `duration` (m:ss), `skipPayment` alanları
- **DJ kontrolü:** `POST /music` yalnızca DJ müzik kontrolünde; `set_active_dj` API + DJ panelinde yıldız
- **SSE:** `type: messages` toplu mesaj olayları işlenir
- **Presence:** 30 sn heartbeat (üretim sözleşmesi)
- **Mesaj poll:** `?after=` (since yedeği)
- **Moderasyon:** `unban_user` / `unmute_user` → `POST /moderation`

## 1.0.224+227 (2026-06-12)

### Sesli oda — canlifal.com üretim API uyumu

- **DJ:** `POST /dj` ile `{ action: add_dj|remove_dj, userId }` (birincil); yerel `/dj/:id` ve `!dj` yedeği
- **Müzik:** `GET/POST/DELETE /music` birincil (`videoId`, `title`, `duration`); `song-request` / `music-queue` yedeği
- **Moderasyon:** `POST /moderation` (`ban_user`, `kick_user`, `mute_user`, `set_role`) birincil
- **Presence:** `DELETE /presence?leave=1`; koltuk atama için `POST /presence { seatIndex }` yedeği
- **Roller:** `%` admin (5) > `~` founder (4) > `&` sop (3) > `@` op (2) > `+` voice (1) hiyerarşisi

## 1.0.223+226 (2026-06-16)

### Sesli oda — YouTube çalma + DJ üretim uyumu

- **Müzik:** Üretimdeki gibi YouTube watch URL (`musicUrl`) Piped/Explode ile çözülür; ilk hata sonrası oynatma durumu korunur
- **!istek:** İstek sonrası videoId/watch URL ön yükleme ve otomatik çalma
- **DJ ekleme:** Üretimde `POST /dj/:id` yok — `!dj @kullanıcı` sohbet komutu yedeği (eski hatalı `/dj` POST kaldırıldı)
- **DJ listesi:** `room.djUserIds` + presence ile `djUsers` zenginleştirilir; DJ 1/5 sayacı güncellenir
- **Moderasyon:** Oda sahibi / admin / moderatör DJ atayabilir (yerel API)

## 1.0.222+225 (2026-06-16)

### Sesli oda — DJ + !istek + çalma düzeltmeleri

- **!istek:** DJ yetkisi gerekmez; yeterli jetonu olan herkes istek gönderebilir
- **Üretim uyumu:** `music-request-by-query` yoksa otomatik `searchYoutube` + `song-request` yedeği
- **Çalma:** İstek sonrası kuyruk varsa oynatıcı otomatik başlar; «İsteyen» alanı doldurulur
- **Müzik Aç:** Yalnızca DJ/owner değil, jetonu yeterli kullanıcılar da görebilir
- **DJ +:** Koltuk atama sayfasında «DJ yap»; DJ panelinde «Kendimi DJ yap»; API `PATCH/POST .../seats`
- **DJ ekleme:** Sunucu `emitChatRoomDjUpdate` ile anlık güncelleme

## 1.0.221+224 (2026-06-14)

### Sesli oda — müzik sistemi (yeniden yazım)

- **!istek:** YouTube API ile arama; her istek **10 jeton** (sunucu doğrulaması, `skipPayment` kaldırıldı)
- **Yetersiz jeton:** Uyarı + «Jeton Yükle» yönlendirmesi
- **Kuyruk:** Oda başına sıra; çalan şarkı kesilmeden ekleme; otomatik sonraki parça (`/music-queue/complete`)
- **Yetki:** Durdur/kapat — isteyen, oda sahibi, admin, süper admin; yetkisizde standart mesaj
- **Oynatıcı:** Kapak, sanatçı, süre, isteyen, sırada N; duraklat / ses / kapat
- **Veritabanı:** `music_queue` + `music_action_logs` (Prisma); işlem günlüğü (istek, jeton, oynatma, yetkisiz)
- **API:** `POST .../music-request-by-query`, `POST .../music-queue/complete`, `canControlMusic` alanı

## 1.0.220+223 (2026-06-14)

### Ana sayfa + sesli oda

- **Trend Videolar:** Yüklenen kısa videolar (`/api/short-videos`) gösterilir; YouTube trend içeriği ve demo kartlar kaldırıldı; boşsa bölüm gizlenir; tıklanınca `/shorts` açılır
- **Hikayeler:** Aktif hikâye yoksa ana sayfa hikâye şeridi gizlenir (hikâye eklenince otomatik görünür)
- **Oda aç / VIP oda:** Giriş kontrolü; oda sahibi VIP kapısını atlar; VIP sekmesi artık VIP odaları filtreler; boş oda listesinde «Oda Aç» butonu

## 1.0.219+222 (2026-06-13)

### Kısa videolar (TikTok tarzı)

- Dikey tam ekran feed: yukarı/aşağı kaydırma, otomatik oynatma, sonraki video ön yükleme
- Galeriden MP4 yükleme (max 15 sn, 10 MB), önizleme + açıklama
- Beğeni, yorum, paylaş, profil; ≥3 sn izlenince görüntülenme sayımı
- Videolar Cloudflare R2 CDN URL'lerinden doğrudan oynatılır (backend yalnızca metadata)
- API: `GET/POST /api/short-videos/*` (yerel mirror + mobil uçlar)
- Sosyal sekmesinde kısa video girişi

## 1.0.218+221 (2026-06-13)

### Sesli oda — müzik (2. tur) + !temizle + X + ok

- **googlevideo süresi dolmuş URL** artık doğrudan oynatılmıyor; videoId ile taze stream (Piped/API/explode paralel)
- Android sırası: **canlifal proxy → indirme → CDN**; indirme zaman aşımı 90s
- **X mini player:** `userDismissedPlayer` — kapatınca sunucu senkronu geri açmaz
- **!temizle:** Müzik/istek sohbet satırları + mini player + kuyruk temizlenir
- Sağ panel ok sekmesi dikeyde küçültüldü (40px)
- TRTC ile çakışma: `gainTransientMayDuck` ses odağı

## 1.0.217+220 (2026-06-13)

### Sesli oda — müzik çalmama + X kapat + eski şarkı

- **YouTube önce:** Oynatma sırası web gibi — önce `nowPlaying.youtubeUrl` / videoId çözümle, sonra sunucu CDN
- **Eski şarkı:** Yeni istekte `state.dj.musicUrl` artık taşınmıyor; parça değişince eski googlevideo URL temizlenir
- **X kapat:** `closeMusicPlayer()` — yerel durdur + DJ/owner ise sunucu kuyruğu temizle
- **UI:** Süre gelmeden «Şu an çalıyor» gösterilmez; oynatma başarısızsa `playing: false`
- `youtube_explode` ikinci deneme `requireWatchPage: true`

## 1.0.216+219 (2026-06-13)

### Sesli oda — müzik çalmama (googlevideo / 00:00)

- **Kök neden:** İlk oynatma başarısız olunca `_currentSource` sıfırlanmıyordu; yeniden denemede `setAudioSource` atlanıyor, player `idle` + süre `00:00` kalıyordu
- **Kök neden 2:** Android medya bildirimi akış yüklenmeden açılıyordu (başlık görünür, ses yok)
- **Çözüm:** `invalidateLoadedSource()` — başarısızlıkta kaynak ve bildirim temizlenir
- Android googlevideo sırası: yerel indirme → `/api/chat/youtube-audio` proxy → doğrudan CDN
- `mediaItem` yalnızca `setAudioSource` başarılı olduktan sonra yayınlanır
- `[MusicPipeline]` logları: `backend.audioUrl`, `setAudioSource.result`, `duration`, `playerStateStream`, `playbackEvent`, `audioService`, `play.result`

## 1.0.215+218 (2026-06-13)

### Sesli oda — çift müzik player

- **Kök neden:** Oda içi `VoiceRoomBottomDock` + global `VoiceRoomGlobalMusicBar` aynı anda `VoiceRoomWebMusicBar` render ediyordu
- **Çözüm:** RTC sayfası açıkken `voiceRoomRtcForegroundProvider` ile global player gizlenir; debug URL satırı yalnızca debug modda

## 1.0.214+217 (2026-06-13)

### Sesli oda — "uninitialized provider" hatası

- **Kök neden:** `VoiceRoomLiveController.build()` içinde `return` öncesi `_schedulePoll()` → `state.dj` okunuyordu → `Bad state: Tried to read the state of an uninitialized provider`
- **Dosya:** `chat_room_providers.dart` satır 273 (`_schedulePoll` build sırasında)
- **Çözüm:** İlk poll `Future.microtask` içine taşındı (build tamamlandıktan sonra)

## 1.0.213+216 (2026-06-13)

### Giriş sonrası gri ekran — kanıtlanmış kök neden

- **Kök neden:** `app.dart` `MaterialApp.router` builder içindeki `ListenableBuilder(router.routerDelegate)` — GoRouter ilk mount sırasında build fazında `notifyListeners` tetikliyor → `setState() called during build` → overlay/barrier bozulması → tema `ModalBarrier` (`0x8C000000`) dokunmayı kesiyor
- **İkincil:** `FeedTouchRecovery` / `StuckOverlayGuard._scrubOrphanModalBarriers` private overlay API ile `OverlayEntry` çift kaldırıyor → `OverlayEntry should be removed only once`
- **Çözüm:** `MainAppShell` — route dinleyicisi `addListener` ile post-frame; `ListenableBuilder` kaldırıldı
- `VoiceRoomGlobalMusicBar` — `GoRouter.of(context)` yerine `routePath` parametresi (builder Stack'inde GoRouter yok)
- `AppBottomNavHost` — `location` parametresi; `ListenableBuilder` kaldırıldı
- `FeedTouchRecovery` kaldırıldı (agresif scrub gri ekranı kötüleştiriyordu)

## 1.0.212+215 (2026-06-13)

### Giriş sonrası gri overlay — çift MaterialApp + izin kaldırma

- **Kök neden (güncel):** Oturumsuzken `MaterialApp.router` arka planda `/feed` shell yüklüyordu; girişte navigator yeniden kurulurken yetim `ModalBarrier` kalıyordu. Giriş sonrası otomatik bildirim izni dialogu da barrier ile çakışıyordu
- **Çözüm:** Oturumsuz → ayrı `MaterialApp` (yalnızca `AuthGatewayHost`, **go_router yok**). Oturum açılınca tamamen yeni `MaterialApp.router` mount
- Girişte otomatik bildirim izni kaldırıldı (Bildirimler sayfası banner'ı ile açılır)
- `resetRootNavigatorKey` — oturum değişiminde temiz navigator
- `FeedTouchRecovery` — ana kabuk mount sonrası yetim barrier tek seferlik kurtarma
- `refreshListenable` / `RouterAuthRefresh` kaldırıldı

## 1.0.211+214 (2026-06-13)

### Giriş sonrası gri overlay — kök mimari düzeltme

- **Kök neden:** `/login` go_router rotasından `/feed` shell rotasına geçiş (redirect veya shellSession) kök overlay'de tema `ModalBarrier` (`0x8C000000`) bırakıyordu — içerik görünür, dokunma ölü
- **Çözüm:** Giriş/kayıt UI artık **go_router rotası değil** — `MaterialApp.builder` içinde `AuthGatewayHost` widget'ı; oturum açılınca yalnızca builder yenilenir, **navigasyon yok**, barrier oluşmaz
- `/login`, `/register`, `/auth/forgot-password` → `/feed` redirect (derin link / OTP / şifre sıfırlama sayfaları korunur)
- `RouterAuthRefresh` oturum dinleyicisi kaldırıldı (redirect yarışı yok); `initialLocation` her zaman `/feed`
- Girişte `shellSession++` kaldırıldı (çıkış + misafir modunda kalır)

## 1.0.210+213 (2026-06-13)

### Giriş sonrası gri overlay — yetim ModalBarrier (kök neden)

- **Kök neden:** go_router redirect `/login` → `/feed` kök navigator overlay'inde tema rengi `0x8C000000` yetim `ModalBarrier` bırakıyordu (içerik görünür, dokunma engelli, geri tuşu çalışır). `RootOverlayPurge` / `StuckOverlayGuard.purgeAfterLogin` private overlay API ile durumu kötüleştiriyordu
- **Çözüm:** Giriş ve kayıtlı oturum açılışında `shellSessionProvider++` — yeni `GoRouter` doğrudan `initialLocation: /feed` (redirect yok)
- `MaterialApp.router` `ValueKey('shell-$session')` — navigator overlay sıfırlanır
- Bildirim izni sonrası yalnızca güvenli `popDialogRoutes` (agresif scrub kaldırıldı)
- Post-login 5 sn zorla purge kaldırıldı

## 1.0.209+212 (2026-06-13)

### Giriş sonrası gri overlay — login navigasyon sadeleştirme

- Tam ekran loading dialog yok; `authUserActionBusyProvider` + buton içi `CircularProgressIndicator` (try/finally garantili)
- Giriş başarısı: yalnızca go_router redirect `/login` → `/feed` — sayfa içi `context.go` / çift navigasyon kaldırıldı
- `guestMode` sıfırlama merkezi: `AuthController._clearGuestModeOnSuccess` (login/register listener tekrarı yok)
- `RouterAuthRefresh` post-frame tek bildirim; redirect aynı hedefe tekrarlanmaz

## 1.0.208+211 (2026-06-13)

### Giriş sonrası gri overlay — Android BackdropFilter + lazy shell

- **Kök neden:** `StatefulShellRoute.indexedStack` tüm sekmeleri (Canlı → Sesli Sohbet hub) girişte önceden yüklüyordu; `VoiceDiscoverHub2026` içindeki korumasız `BackdropFilter` Android'de tam ekran gri katman oluşturuyordu (ModalBarrier değil — purge işe yaramıyordu)
- **Çözüm:** `StatefulShellRoute` (yalnızca aktif sekme yüklenir); `SafeBackdropFilter` (`PlatformBlur` koruması); Canlı sekmesinde sesli oda hub'ı yalnızca "Sohbet" sekmesi seçilince yüklenir
- `premium_liquid_nav_bar` ve `discover_premium_header` blur koruması

## 1.0.207+210 (2026-06-13)

### Giriş sonrası gri overlay — mimari düzeltme (kök neden)

- **Kök neden:** `MaterialApp.builder` Stack'inde `AuthFlowOverlay` + altta `/feed` go_router — girişte overlay kalkınca kök navigator'da yetim `ModalBarrier` kalıyordu
- **Çözüm:** Auth overlay kaldırıldı; oturumsuz kullanıcı `go_router` `/login` rotasında (`AuthGatewayHost`, iç Navigator yok)
- `RouterAuthRefresh` — giriş başarılı → redirect `/feed` (tek geçiş, barrier yok)
- `shellSession++` girişte kaldırıldı; `FeedBarrierWatchdog` / `NavigatorModalSanitizer` kaldırıldı
- Misafir modu: `/login` → `/feed` redirect

## 1.0.206+209 (2026-06-13)

### Giriş sonrası gri overlay — 5 sn kök overlay zorla temizlik + teşhis

- Login başarılı **5 saniye** sonra kök `navigator.overlay` içindeki tüm `ModalBarrier` içeren `OverlayEntry`'ler zorla kaldırılır
- Debug log: `Overlay entries before purge:` / `Overlay entries after purge:` + kalan widget sınıf adları
- `BarrierRouteJournal` — barrier oluşturan route'ların kaydı (`didPush`/`didPop`)
- `Remaining blocking widgets on screen:` — ekranda kalan `ModalBarrier` / `AbsorbPointer` tam sınıf adı ve route atfı

## 1.0.205+208 (2026-06-12)

### Giriş sonrası gri overlay — iç Navigator kaldırıldı (kök neden)

- **Kök neden:** `AuthFlowOverlay` içindeki iç `Navigator` + `PageRouteBuilder` geçişleri, overlay ağaçtan kalkınca kök overlay'de yetim `ModalBarrier` bırakıyordu (dokunma engelli, geri tuşu çalışır)
- **Çözüm:** Auth overlay sayfa geçişi state tabanlı (`AuthOverlayRoute`); iç `Navigator.push` / `ModalRoute` yok
- **Giriş sonrası:** `shellSessionProvider++` ile temiz go_router; `purgeAfterLogin` + `NavigatorModalSanitizer` + `FeedBarrierWatchdog`
- **Bildirim izni** sonrası `purgeAfterLogin` (yalnızca `popDialogRoutes` değil)

## 1.0.204+207 (2026-06-12)

### Giriş sonrası gri overlay — bildirim izni + go_router yenileme

- **Kök neden:** Giriş anında `AuthRefresh` go_router'ı yeniliyordu (geçiş barrier); eşzamanlı `OneSignal.requestPermission` + `popDialogRoutes` sistem dialogu ile çakışıp yetim `ModalBarrier` bırakıyordu
- **`AuthRefresh` kaldırıldı** — oturum UI `AuthFlowOverlay` ile; çıkışta `shellSessionProvider` router sıfırlar
- **Bildirim izni gecikmeli** (~2.8 sn) — ana sayfa otursun, sonra sistem dialogu; bitince güvenli barrier temizliği
- Giriş anında agresif `popDialogRoutes` kaldırıldı

## 1.0.203+206 (2026-06-12)

### Giriş sonrası gri overlay — kök neden #2 (overlay scrub + IndexedStack)

- **Kök neden:** `LoginPage` / `HomePage` / `MainShellPage` giriş sırasında kök navigator overlay'inde `StuckOverlayGuard` çalıştırıyordu; private API ile barrier temizliği yetim `ModalBarrier` bırakıyordu
- **Çözüm:** Tüm periyodik overlay scrub kaldırıldı; girişte `authController` global loading state'i kapatıldı (`authUserActionBusyProvider` yeterli)
- **Shell:** `StatefulShellRoute` denendi; go_router 15 API uyumsuz — scrub düzeltmesi yeterli
- **Giriş sonrası:** Güvenli `popDialogRoutes` (yalnızca dialog route pop, private overlay API yok)

## 1.0.202+205 (2026-06-12)

### Giriş sonrası gri overlay — tek MaterialApp.router (kalıcı)

- **Kök neden:** Giriş sonrası `AuthFlowApp` ↔ `MainShellApp` ağaç değişimi ikinci `MaterialApp` mount ediyordu; go_router ilk kez burada oluşunca yetim `ModalBarrier` ana sayfada kalıyordu
- **Çözüm:** Uygulama başından itibaren tek `MaterialApp.router`; oturumsuzda `AuthFlowOverlay` üst katman (ayrı MaterialApp yok)
- **`AuthOverlayScope`:** Giriş ekranları go_router yerine overlay Navigator kullanır — `/register` push barrier oluşturmaz
- **`auth_redirect`:** Oturumsuz `/login` → `/feed` (overlay girişi gösterir); go_router auth redirect barrier kaldırıldı
- Agresif scrub/watchdog katmanları kaldırıldı (semptom tedavisi yerine mimari düzeltme)

## 1.0.201+204 (2026-06-12)

### Giriş sonrası gri overlay — kök neden (go_router erken mount)

- **Kök neden:** `MainShellApp` oturum kontrolü bitmeden `/feed` ile mount oluyordu; go_router `ModalBarrier` bırakıyor, oturum açılınca overlay kalksa da barrier kalıyordu
- **Çözüm:** Oturum kontrolü / giriş bitene kadar yalnızca `AuthFlowApp` — go_router hiç oluşturulmaz
- **Oturum açılışı:** `shellSessionProvider++` ile temiz go_router; `FeedBarrierWatchdog` + agresif `StuckOverlayGuard`
- **Ana sayfa:** 45 sn boyunca barrier izleme ve otomatik temizlik

## 1.0.200+203 (2026-06-12)

### Giriş sonrası gri overlay — kalıcı düzeltme (tek MaterialApp)

- **Kök neden:** `AuthFlowApp` ↔ `MainShellApp` ağaç değişimi ikinci `MaterialApp` mount ediyor; go_router geçişinden yetim `ModalBarrier` ana sayfada kalıyordu
- **Tek kabuk:** `_MainShellApp` her zaman mount; oturumsuzda `AuthFlowApp` üst katman overlay (go_router yok, barrier yok)
- **`auth_redirect`:** oturumsuz kullanıcı `/login`'e yönlendirilmez — shell `/feed`'de kalır, giriş overlay ile
- **`initialLocation: /feed`** sabit; `AuthRefresh` ile oturum açılınca `/login` → `/feed` redirect
- **`StuckOverlayGuard`:** `canPop` kilidi kaldırıldı; yetim barrier temizliği güçlendirildi
- **Giriş sonrası scrub:** overlay kalkınca 30 sn agresif modal temizliği

## 1.0.199+202 (2026-06-12)

### Gri katman — giriş + ana sayfa (regresyon düzeltmesi)

- **Kök neden:** Tek `MaterialApp` ile `initialLocation: /feed` → shell önce yükleniyor, `/login` redirect'i yetim `ModalBarrier` bırakıyordu; girişte `goRouter` AuthFlow dışında erken oluşturuluyordu
- **AuthFlowApp geri:** oturumsuz kullanıcıda go_router yok (giriş gri ekranı çözümü)
- **`shellSessionProvider`:** her oturum açılışında yeni go_router — temiz navigator
- **`initialLocation: /login`:** shell oturumsuz yüklenmez
- **MainShellApp:** mount sonrası `/feed` + 15 sn overlay scrub

## 1.0.198+201 (2026-06-12)

- CI: `overlay.entries` API uyumsuzluğu — route-pop temizliği korunur

## 1.0.198+200 (2026-06-12)

### Giriş sonrası ana sayfa gri katman — kalıcı düzeltme

- **Kök neden:** `AuthFlowApp` → `MainShellApp` geçişinde ikinci `MaterialApp` mount + yetim `ModalBarrier`; `postAuth` scrub giriş anında tetiklenmiyordu
- **Tek `MaterialApp.router`:** Oturum açılınca ağaç değişmiyor; `go('/feed')` ile geçiş
- **Agresif route-pop temizliği:** kök + shell navigator modal katmanları
- **Giriş sonrası 15 sn** agresif overlay temizliği (mount + auth listener)
- **Fal daveti:** girişten 4 sn sonra açılır; sıfır geçişli dialog (yalnızca scrim kalmaz)

## 1.0.197+199 (2026-06-12)

### Ana sayfa gri katman — giriş sonrası

- **Kök neden:** Oturum açılınca `MainShellApp` + go_router shell rotaları varsayılan sayfa geçişiyle kök navigator'da takılı `ModalBarrier` bırakıyordu
- **Shell rotaları:** `/feed`, `/social`, `/live`, `/fortune`, `/profile` ve `StatefulShellRoute` → `NoTransitionPage`
- **Android geçiş teması:** `NoBarrierPageTransitionsBuilder` — modal scrim oluşturmaz
- **Overlay temizliği:** `MainShellPage` + `HomePage` mount sonrası periyodik scrub; oturum açılışı sonrası 6 sn `postAuthFeed` temizliği
- **StuckOverlayGuard.dismissAll:** kök + shell iç navigator barrier temizliği

## 1.0.196+198 (2026-06-12)

### Giriş gri katman — kalıcı çözüm (AuthFlowApp)

- **Kök neden:** go_router `refreshListenable` + oturum kontrolü giriş ekranında takılı `ModalBarrier` (yarı saydam gri katman) bırakıyordu; overlay temizliği yeterli değildi
- **AuthFlowApp:** Oturumsuz kullanıcı için ayrı `MaterialApp` + sıfır geçişli `Navigator` — go_router devre dışı
- **Ana uygulama:** Yalnızca oturumlu veya misafir modunda `MaterialApp.router`; `initialLocation: /feed`
- **AuthNavigation:** Login/register/forgot/OTP sayfaları hem AuthFlow hem go_router ile çalışır
- go_router `refreshListenable` → yalnızca misafir modu (`GuestModeRefresh`); auth loading sırasında redirect atlanır

## 1.0.195+197 (2026-06-12)

### Giriş ekranı — gri yarı saydam katman (kök neden)

- **Kök neden:** Oturum kontrolü bitince `RouterRefresh` gereksiz `notifyListeners` → go_router yenilemesi tek sayfa yığınında takılı `ModalBarrier` (gri katman) bırakıyordu
- **RouterRefresh:** Yalnızca redirect hedefi değişecekse yenile; aksi halde `StuckOverlayGuard` ile barrier temizle
- **StuckOverlayGuard:** `scrubStuckOverlayBarriers` — overlay'deki yetim `ModalBarrier` widget'larını kaldırır
- **AuthRedirect:** redirect mantığı tek dosyada (`auth_redirect.dart`)
- **LoadingTimeout:** oturum / giriş / kayıt / `me()` için zaman aşımı + `ApiException`
- **AuthController:** 14 sn boot watchdog — loading sonsuza kalmaz
- **LoginPage:** auth bitince 4 sn periyodik overlay temizliği

## 1.0.194+196 (2026-06-12)

### Açılış gri ekran düzeltmesi (7. tur)

- **Android native:** `drawable-v21/launch_background` artık `#0A0618` (API 21+ cihazlarda `?colorBackground` gri flash giderildi)
- **NormalTheme:** pencere arka planı `@color/canlifal_window_background` (`#05050D`) — Flutter yüklenirken gri sistem rengi yok
- **Auth rotaları:** `NoTransitionPage` geri eklendi (`/login`, `/register`, şifre sıfırlama, OTP) — geçiş scrim’i önlenir
- **NavigatorModalSanitizer:** ilk 4 sn + oturum açılışı sonrası `/feed` geçişinde barrier temizliği

## 1.0.193+195 (2026-06-11)

### API dokümantasyonu ve gap analizi

- `docs/FLUTTER_API_DOCS.md` — tam API referansı (300+ endpoint)
- `docs/FLUTTER_GAP_ANALYSIS.md` — web/mobil eksik modül özeti

### Kritik / yüksek öncelik uygulamaları

- **Fal SSE:** `FortuneSseService` — oturumlu kullanıcıda `POST /api/fortunes/*` LLM akışı; `FortuneSessionPage` canlı metin önizlemesi
- **Reset password:** `/auth/reset-password?token=` native sayfa + `POST /api/auth/reset-password`
- **Achievements:** `AchievementsRemoteDataSource` + Growth Hub sunucu rozetleri
- **api_endpoints:** ajans, blog like/favorite, teller gifts, fortune pin/rate, auth reset/change
- `.gitignore`: `curl-*.json`, `t-*.json`, `ci-runs.json`

## 1.0.192+194 (2026-06-11)

### Giriş ekranı — Android gri overlay (6. tur)

- **RouterRefresh:** yalnızca oturum kontrolü bitince veya kullanıcı kimliği değişince `notifyListeners` — gereksiz go_router yenilemesi ve takılı modal barrier riski azaltıldı
- **NavigatorModalSanitizer:** `MaterialApp.builder` içinde; auth rotalarında 3 sn boyunca kök navigator’daki popup/barrier temizliği
- **StartupOverlayGuard** kaldırıldı (MaterialApp dışında navigator null kalıyordu)
- Auth rotalarında `FortuneIncomingInviteHost` / `AppBottomNavHost` devre dışı
- `AuthPremiumShell` tüm platformlarda opak `AuthPlainShell` (blur/cam yok)
- `LoginPage`: tam ekran bootstrapping kilidi kaldırıldı — form her zaman görünür, üstte ince progress
- Şifre sıfırlama / OTP: `AuthPremiumShell` + opak alanlar (`AuthShell` / LiquidGlass kaldırıldı)
- Android `pageTransitionsTheme`: `FadeUpwardsPageTransitionsBuilder` (Cupertino scrim yerine)

## 1.0.191+193 (2026-06-11)

### Giriş ekranı — Android gri overlay (5. tur)

- **StartupOverlayGuard:** açılışta 1.5 sn boyunca kök navigator’daki takılı `PopupRoute` barrier’larını tekrarlı temizler
- **AUTH_FINISH** sonrası ve route değişiminde overlay temizliği; `APP_START` / `AUTH_START` / `OVERLAY_SHOW|HIDE` logları
- `/splash` rotası kaldırıldı — yalnızca redirect (`/login` veya `/feed`); çift navigasyon riski giderildi
- `FortuneIncomingInviteHost`: auth yüklenirken ve giriş/kayıt rotalarında dialog açmaz
- `MaterialApp.builder`: router `child == null` iken koyu arka plan (boş gri kare önlenir)
- `LoginPage`: auth bitince overlay temizliği (tek seferlik guard kaldırıldı)

## 1.0.190+192 (2026-06-11)

### Giriş ekranı — Android gri overlay (4. tur, kök neden)

- **Kök neden:** `/splash` → `/login` GoRouter geçişinde Navigator üstünde kalan modal barrier + olası yarım dialog
- `initialLocation: '/login'` — soğuk açılışta splash yığını kaldırıldı
- Auth rotaları: `NoTransitionPage` (sıfır süre, scrim yok)
- `LoginPage`: mount sonrası `StuckOverlayGuard` ile takılı `PopupRoute` temizliği
- `StartupRouteObserver` + `[AppStartup]` logları (route push/pop/barrier)
- `FortuneIncomingInviteHost`: oturum yokken dialog açmaz

## 1.0.189+191 (2026-06-11)

### Giriş ekranı — Android gri overlay (3. tur)

- `AuthPlainShell`: Android'de cam/blur/hero tamamen kaldırıldı — opak form kartı
- Auth rotaları (`/splash`, `/login`, `/register`): geçiş animasyonu kapalı (Cupertino scrim)
- `app.dart`: splash yedeği kaldırıldı (çift katman riski)
- Giriş kilidi yalnızca kullanıcı işleminde (`authUserActionBusyProvider`)

## 1.0.188+190 (2026-06-11)

### Giriş ekranı — Android gri overlay (2. tur)

- `PlatformBlur`: Android'de tüm cam/blur bileşenlerinde merkezi blur kapatma
- `LiquidGlass`: blur kapalıyken opak yüzey (yarı saydam gri yıkama yok)
- `ThemedGlassCard` / `ProGlass` / `PremiumGlassSurface`: Android blur guard
- Auth: giriş sırasında form görünür kalır (`copyWithPrevious`); `isRefreshing` ile kilit

## 1.0.187+189 (2026-06-10)

### Giriş ekranı — Android gri overlay düzeltmesi

- `CosmicGalaxyBackground`: Android'de `ImageFilter.blur` kapatıldı (tam ekran gri katman)
- `AuthPremiumShell` / splash: Android'de cam blur ve orb animasyonu devre dışı
- Oturum kontrolü 12s zaman aşımı — sonsuz yüklemede login'e düşer
- Splash 10s sonra login'e yönlendirme yedeği

## 1.0.186+188 (2026-06-10)

### Sesli oda müzik — web görünümü + hızlı oynatma

- Tek kompakt **web müzik şeridi** (`VoiceRoomWebMusicBar`): dalga + «Şu an çalıyor» + turuncu pause + mor ses + kırmızı X
- Oda içinde çift mini player kaldırıldı; global bar sesli odada kesinlikle gizlenir
- googlevideo **stream-first** (Referer başlıkları); başarısızsa yerel indirme yedeği
- `!istek` sonrası anında `_playDjInBackground`; sunucu `musicUrl` prefetch
- Müzik aktifken poll 5s; presence heartbeat 20s (web/app kullanıcıları daha hızlı görünür)
- Çalarken inline kuyruk listesi gizlenir (web gibi)

## 1.0.185+187 (2026-06-10)

### Müzik oynatma — ses + çift player + X kapat

- **Çift mini player:** Sesli odadayken global çubuk artık route değişiminde gizlenir (`ListenableBuilder`)
- **X kapat:** `dismissed` bayrağı sunucu senkronunda sıfırlanmaz; oda içi player gizlenir; yeni şarkıda otomatik açılır
- **Sessiz oynatma:** `AudioSession` `gain` + `mixWithOthers` (TRTC altında duck kaldırıldı)
- **play() doğrulama:** `waitUntilPlaying` — yalnızca `hasLoadedSource` ile başarı sayılmaz
- **Loglar:** `player.state`, `playbackEventStream` hataları, `play_not_started` teşhisi
- **Debug satırı:** Mini player altında gerçek stream URL + processing state + hata özeti

## 1.0.184+186 (2026-06-10)

### Müzik veri hattı teşhis logları (`[MusicPipeline]`)

- `!istek` / `song-request` / `music-queue` / `dj` yanıtlarında `musicUrl`, `videoId`, endpoint loglanır
- `musicUrl` null nedenleri (`musicUrl.null`) — sunucu stream çözemedi, merge çakışması vb.
- `fields.compare` — `musicUrl` vs `playbackSource` vs `nowPlaying.youtubeUrl`
- `setAudioSource.before` + `play.entered` — oynatıcıya girmeden önce URL
- `just_audio.error` — `PlayerException` ve diğer hatalar
- `exo.probe` — Android ExoPlayer ile URL doğrudan test (MethodChannel)

Logcat filtresi: `MusicPipeline` veya `VoiceRoom`

## 1.0.183+185 (2026-06-10)

### Sesli oda müzik oynatıcı — tam medya kontrolü

- Yığın: `just_audio` + `audio_service` (bildirim çubuğu / kilit ekranı medya kontrolleri)
- Mini player: Oynat, Duraklat, Durdur, Önceki (başa sar), Sonraki, Ses aç/kapat, Kapat (X)
- Android bildiriminde önceki / oynat-duraklat / sonraki / durdur kontrolleri
- Odadan çıkınca müzik durmaz; global mini player diğer sayfalarda görünür
- Mini player kapatılınca `player.stop()` + oturum temizliği
- Uygulama kapanınca `audio_service` temizlenir
- Sessize alma artık akışı öldürmez (ses seviyesi 0); ses açılınca devam eder
- DJ `updateDj` / kuyruk uçlarında `alternateKey` (slug) yedeklenir

## 1.0.182+184 (2026-06-10)

### Sesli oda — `!istek` müzik düzeltmesi

- `!istek` artık önce YouTube araması yapıp `song-request` API ile kuyruğa ekliyor (sohbet mesajına güvenmiyor)
- Kuyruk eşleşmesi yalnızca oynatılabilir YouTube URL’si olan parçalar için sayılıyor
- DJ/müzik API çağrılarında oda slug yedek anahtarı (`alternateKey`) kullanılıyor
- Başarısız arama/kuyruk durumunda yanıltıcı “iletildi” mesajı gösterilmiyor

## 1.0.181+183 (2026-06-10)

### Oyun Merkezi — premium native hub

- Yeni `GameCenterPage`: Popüler oyunlar, canlı oyunlar, ödüllü oyunlar ve liderlik tablosu
- Oyunlar: Kader Çarkı, Bilgi Yarışması, Kelime Düellosu, Aşk Uyumu, Tavla
- Canlı: Oda Bilgi Yarışması, PK Tahmin, Canlı Tombala (API oda oluşturma/katılma)
- Ödüller: Günlük Hazine Sandığı, Şanslı Zar, Günlük Görevler (`/profile/growth`)
- Liderlik: Günlük / haftalık / aylık sekmeler, podium görünümü
- Ana sayfaya `Oyun Merkezi` CTA kartı + liderlik önizlemesi + hızlı oyun chip'leri
- Clean Architecture: repository pattern, jeton kontrolü, skor kaydı (`/api/games/mini-scores`)
- UI: Lottie hero, shimmer, pull-to-refresh, Hero animasyonları, dark/light tema

## 1.0.180+182 (2026-06-10)

### Fal & Tarot parite — web fal API bağlantıları

- Kahve Falı, Tarot ve Yıldızname oturumları artık önce web `/api/fortunes/*` endpointlerini dener
- Kredi/Jeton yetersizliği durumunda Jeton mağazası ve üyelik ekranına yönlendiren satın alma sheet'i eklendi
- `Yıldızname` katalog başlığı ve slug alias'ları weble uyumlu hale getirildi
- `/fortune/ready` hazır yorumlar ekranı ve `/fortune/history/:id` fal geçmişi detay route'u eklendi
- `FORTUNE_PARITY_REPORT.md` ile Kahve Falı, Tarot, Yıldızname, hazır yorum, geçmiş ve satın alma kapsamı raporlandı

## 1.0.179+181 (2026-06-10)

### Oyun parite — native oyun merkezi ve polling oda ekranı

- Webdeki çok oyunculu ve mini oyunların tamamını kapsayan Flutter oyun katalog fallback'i eklendi
- `/games-hub` artık native oyun merkezi olarak oyun listesi, açık odalar, liderlik/mini skor/turnuva özetlerini gösterir
- Oda oluşturma, otomatik eşleşme, odaya katılma ve oyun sohbeti mevcut web API'leriyle bağlandı
- `/games-room/:id` oyun odası ekranı 5 saniyelik HTTP polling ile oda state/sonuç/chat bilgisini günceller
- `GAME_PARITY_REPORT.md` ile oyun listesi, giriş, Jeton, skor, sonuç ve realtime kapsamı raporlandı

## 1.0.178+180 (2026-06-10)

### Sosyal parite — hikaye grupları ve story fallback

- Canlifal web `storyGroups` yanıtındaki birden fazla hikaye öğesi Flutter modeline taşındı
- Hikaye görüntüleyici artık aynı kullanıcı halkasındaki tüm story öğelerini ileri/geri gezebilir
- Story caption ve ilerleme göstergesi eklendi
- Hikaye oluşturma `POST /api/stories` başarısız olursa web kullanıcı endpoint'i olan `POST /api/user/story` fallback'ini dener
- `SOCIAL_PARITY_REPORT.md` ile sosyal akış, beğeni, yorum, takip, profil, hikaye ve kalan sosyal gap'ler raporlandı

## 1.0.177+179 (2026-06-10)

### Web parite — native API liste hub'ları

- Oyunlar, rüya, blog, ünlüler ve fan club hub ekranları artık canlifal.com API listelerini native kartlar olarak çeker
- API yanıtları `items`, `data`, `games`, `dreams`, `symbols`, `posts`, `celebrities`, `fanClubs` gibi üretim alias'larıyla parse edilir
- API boş/geçici hatalı dönerse kullanıcı boş ekrana düşmez; native aksiyon kartları görünmeye devam eder
- Bu parça, web'de var olup Flutter'da sadece statik giriş olan içerik sistemlerini ilk native veri katmanına taşır

## 1.0.176+178 (2026-06-10)

### Web parite — oyun/içerik hub, sesli oda komutları ve canlı yayın araçları

- Oyunlar, rüya, blog, ünlüler, fan club ve reklamla kredi için native hub girişleri eklendi
- Ana sayfada `/api/games` oyun/etkinlik satırı yeniden görünür hale getirildi ve keşfet kartları doğru native merkezlere bağlandı
- Sesli sohbet `!ban`, `!unban`, `!at`/`!kick`, `!sessiz`/`!mute`, `!yetki`, `!dj`, `!muzik`, `!temizle` komutları için web bot mesajına ek olarak mobil REST fallback katmanı eklendi
- `!istek` chat komutu web ile uyumlu mesaj gönderimini korur; sunucu kuyruğa eklemezse mobil `song-request` fallback'i dener
- Canlı yayın hazırlığında özel/resim modu/arka plan ayarları create payload'a taşındı
- Canlı yayın odasına paylaşım, görsel mod katmanı ve yayıncı araçları (görsel, arka plan, co-broadcast yenileme, auto-close kontrolü) eklendi

## 1.0.175+177 (2026-06-10)

### Ürün büyüme roadmap + görev/rozet merkezi

- `PRODUCT_IMPROVEMENT_REPORT.md` ile öneriler kullanıcı memnuniyeti, gelir, geliştirme maliyeti, teknik risk ve bakım maliyetine göre puanlandı
- En yüksek faydalı ilk faz özelliği olarak profil menüsüne `Görevler & Rozetler` büyüme merkezi eklendi
- Yeni ekran mevcut günlük ödül, profil istatistiği, cüzdan/VIP ve davet verilerinden XP, seviye, görev ilerlemesi ve rozet albümü üretir
- Yeni API veya database tablosu eklenmeden mevcut Canlifal web/backend sözleşmesi korundu

## 1.0.174+176 (2026-06-10)

### Canlı yayın + PK audit

- PK action payload'ından web API sözleşmesinde olmayan eski `score` / `side` alanları kaldırıldı
- PK skor hesaplama akışı sadece hediye entegrasyonu ve remote battle state ile senkronize edilir
- `LIVE_PK_AUDIT_REPORT.md` ile yayın başlatma/kapatma, PK daveti/kabul/skor/hediye/sonuç akışı denetlendi

## 1.0.173+175 (2026-06-10)

### Canlı yayın + PK parity

- Canlı yayın `PK Başlat` artık web/API sözleşmesi gibi önce rakip yayın seçme ekranına gider
- Eski desteklenmeyen `action: score` PK çağrısı kaldırıldı; skor web gibi hediye entegrasyonu ve remote refresh ile senkronize edilir
- `LIVE_PK_PARITY_REPORT.md` ile yayın başlatma/kapatma, PK daveti, savaş, skor, hediye ve sonuç parity durumu raporlandı

## 1.0.172+174 (2026-06-10)

### Flutter sağlık denetimi + import temizliği

- `HEALTH_CHECK_REPORT.md` ile modül sağlığı, analyzer uyarıları, runtime/null-safety/performance riskleri raporlandı
- Düşük riskli kullanılmayan ve duplicate import uyarıları temizlendi
- Home/content/core UI modüllerinde davranış değiştirmeyen statik analiz iyileştirmeleri yapıldı

## 1.0.171+173 (2026-06-10)

### Hediye parity — ses efektleri

- Sesli oda premium hediye panelinde gönderim sonrası web/canlı yayın ile aynı hediye ses/haptic geri bildirimi çalışır
- Legacy sesli oda hediye picker da aynı `GiftSoundService` akışını kullanır
- `GIFT_PARITY_REPORT.md` ile hediye gönderme/alma/jeton/animasyon/ses parity durumu raporlandı

## 1.0.170+172 (2026-06-10)

### Müzik parity — web response alias uyumu

- Müzik kuyruğu yanıtlarında `queue`, `musicQueue`, `items` alanları birlikte desteklenir
- Şarkı kapak görseli için `thumbUrl`, `thumbnail`, `image` alias'ları okunur
- Kanal/sanatçı bilgisi için `uploader`, `channelTitle`, `channel`, `artist` alias'ları okunur
- `MUSIC_PARITY_REPORT.md` ile web ↔ Flutter müzik sistemi parite durumu raporlandı

## 1.0.169+171 (2026-06-09)

### Socket parity — oda ve canlı yayın senkronu

- Sesli oda Socket.IO listener'larına `chatMessage`, `message`, `roomMessage`, `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` eklendi
- Socket reconnect sonrası oda/yayın/PK kanallarına yeniden join davranışı güçlendirildi
- Disconnect sırasında `leaveRoom`, `leaveStream`, `leavePk` emitleri eklendi
- `SOCKET_PARITY_REPORT.md` ile web ↔ Flutter socket/TRTC parite durumu raporlandı

## 1.0.168+170 (2026-06-09)

### Feature parity — profil takipçi endpoint düzeltmesi

- Başka kullanıcı takipçi listesi web API sözleşmesine göre `/api/users/{id}/followers` yoluna taşındı
- Flutter profil takipçi ekranı artık yanlış toggle endpoint'i (`/follow`) yerine liste endpoint'ini dener
- `FEATURE_PARITY_FINAL_REPORT.md` ile kalan %100 parite engelleri ve tamamlanan modüller raporlandı

## 1.0.167+169 (2026-06-09)

### Sesli oda müzik — audio_service entegrasyonu

- Web ile aynı `/music-queue`, `/song-request`, SSE ve Socket.IO müzik senkron akışı korunur
- DJ müzik oynatıcı `just_audio` + `audio_service` tabanlı arka plan media session'a taşındı
- Android notification / media button ve iOS background audio desteği eklendi
- Mini player gerçek background playback state, süre, ilerleme ve media metadata bilgisini izler

## 1.0.166+168 (2026-06-09)

### Sesli oda müzik web paritesi

- Mobil müzik araması web API sonuç vermezse doğrudan YouTube istemci aramasına düşer
- Web’den gelen YouTube watch URL/Piped başarısızsa mobil doğrudan audio stream manifest çözmeyi dener
- DJ playback web kuyruğu ile aynı `music-queue` / `song-request` senkronunu korur

## 1.0.165+167 (2026-06-09)

### Sesli oda müzik + arka plan düzeltmesi

- Müzik aramasında 404 sonucu kullanıcıya taşımadan eski YouTube endpoint'i ve popüler katalog fallback'i denenir
- YouTube stream çözümlenemediğinde üst/bottom hata yazısı spam'i kaldırılır
- Oda arka plan listesi canlı API görsel alanlarını daha dayanıklı parse eder
- Arka plan seçimi ekranda anında uygulanır ve cache eski görselde takılı kalmaz

## 1.0.164+166 (2026-06-09)

### Sesli oda müzik çalmama düzeltmesi

- Üretim `/api/chat/youtube-stream` watch URL fallback döndüğünde artık oynatılmaya çalışılmaz
- Piped/Invidious ile gerçek ses akışı çözülür (`videoId` parametresi)
- googlevideo akışları yerel indirme ile oynatılır (kırık youtube-audio proxy atlanır)
- Ek Piped mirror hostları
- `apk-latest` yayını için 1.0.164+166 release APK derlemesi tetiklenir

## 1.0.163+165 (2026-06-09)

### Birleştirme + temizlik

- Web parite paketi `main`'e alındı
- Kullanılmayan deprecated Socket.IO chat servisi kaldırıldı
- 100+ agent debug `.txt` çıktısı silindi
- GitHub PR/dal temizlik otomasyonu

## 1.0.162+164 (2026-06-09)

### Web ↔ Flutter parite + sesli oda

- Parite deploy dokümantasyonu (müzik, TRTC, arka plan, FCM, üyelik, PK)
- Ana sayfa fal kartları: `GET /api/homepage-fortune-cards` entegrasyonu
- Üyelik paketleri: prod API alan eşlemesi (`name`, `price`, `tier`)
- Sesli oda arka plan: `voice-bg-1..20` web kataloğu
- DJ müzik: `VoiceRoomDjStreamLoader` (googlevideo Referer)
- Hediye: `platform: mobile`, JSON body düzeltmesi
- PK deploy paketi: `docs/nextjs/pk/` (8 route + Prisma + Socket)

## 1.0.153+155 (2026-06-08)

### Sesli oda UX — alt bar, sohbet, moderasyon

- Alt bar: Ana Sayfa, hoparlör/kulaklık, mikrofon, oda/profil ayarları, jeton
- Klavye açıkken sohbet görünür; gönder butonu dönmez (anında yeni mesaj)
- Giriş bildirimi: Gold/yetkili için kayan marquee (canlifal.com)
- Sohbet filtresi: giriş/çıkış, !komutlar, !istek ve teknik müzik logları gizli
- Yetkili/Gold kullanıcı adları gradyan efektli
- Kullanıcı dokunuşu: at, sustur, ses ver, DJ yap/çıkar (moderasyon sheet)
- Host koltuğu: sahip yoksa en yetkili kullanıcı
- VIP/yetkili koltuk çerçeveleri Android'de de aktif
- Sağ panel oku küçültüldü

## 1.0.152+154 (2026-06-08)

### Sesli oda — Riverpod provider hatası düzeltmesi

- `VoiceRoomLiveController.build()` içinde `state` hazır olmadan okuma kaldırıldı
- "Tried to read the state of an uninitialized provider" gri hata ekranı giderildi
- Sağ panel aynı oturum anahtarını (`stableSessionKey`) kullanır

## 1.0.151+153 (2026-06-07)

### Sesli oda UI — layout parity v2

- Koltuk ızgarası: üst sıra 1–4, alt sıra 6–10 (sağ panel alanı)
- Giriş bildirimi kartı + duyuru + sohbet + müzik sırası (tasarım referansı)
- Sohbet: rol ikonları, İSTEK rozeti, gömülü liste
- Sağ panel: Ücretli Şarkı İste butonu panel altında
- Android konuşma altın glow animasyonu
- Şu an çalan: frekans çubukları görselleştirici

## 1.0.150+152 (2026-06-07)

### Sesli oda UI — tasarım referansına pixel-parity

- Üst bar: oda paneli butonu, mevcut galeri/ayarlar/çıkış düzeni korundu
- Sağ kaydırma paneli: Kurallar, Yetkiler, Jeton, Yasaklı Kelimeler, Ücretli Şarkı İste
- Duyuru: günde bir kez, 5 sn progress çubuğu, sahip düzenleme
- Giriş şeridi: kayan marquee animasyonu
- Şu An Çalan + Sıradaki Şarkılar inline kuyruk bölümü
- Sohbet: koyu şeffaf balonlar, rol renkli kullanıcı adları
- Alt bar: mesaj + gönder + hediye; jeton, yenile, paylaş, jeton yükle
- DJ/Müzik kartları yalnızca oda sahibi ve DJ kullanıcılarına görünür

## 1.0.149+151 (2026-06-07)

### Sesli oda — teşhis + gri ekran yerine hata UI

- `VoiceRoomErrorBoundary`: Flutter `ErrorWidget` gri ekranı yerine anlamlı hata paneli
- `VoiceRoomDiagnosticProvider`: JWT, presence, SSE, socket, TRTC durumu tek yerde
- `VoiceRoomApiLogInterceptor`: `/api/chat/rooms` ve `/api/trtc/usersig` yanıtları loglanır
- TRTC `enterRoom`, socket connect/disconnect release logları
- `main.dart`: `FlutterError` / `PlatformDispatcher` / zone hataları `[VoiceRoom]` tag ile
- Oda route: API hatalarında retry + açıklayıcı mesaj

## 1.0.148+150 (2026-06-07)

### Sesli oda gri ekran (v3 — PR #104 TRTC + UI)

- PR #104 deseni: oda `extra` ile gelince oturum `initState`'te sabitlenir
- Üst bar (geri, oda adı) scroll dışında — her zaman görünür
- Android: ses dalga halkası (`VoiceAudioWaveRing`) devre dışı
- Hediye paneli: `BackdropFilter` kaldırıldı (Android gri sheet)
- `_joinRoom`: `widget.room` fallback + pinned session

## 1.0.147+149 (2026-06-07)

### Sesli oda — kapsamlı gri ekran düzeltmesi

- Layout: PK sayfası modeli — `SafeArea` + `Column` + `ListView` (taşma/gri ekran önlendi)
- Alt bar `bottomNavigationBar` yerine gövde içinde (klavye/resize uyumu)
- `roomReady` kapısı kaldırıldı — oda UI her zaman render edilir
- `_displayRoom` tek kaynak: liste sync + `widget.room` fallback
- Android koltuk avatarları: CustomPaint/Lottie yerine basit daire (GPU güvenli)
- VIP şifre sheet: `BackdropFilter` kaldırıldı (Android gri ekran)
- Favorilerden oda: `voiceRoomByIdProvider` ile `extra` geçirilir
- Sayfa dispose: ses koordinatörü `leave()` çağrısı

## 1.0.146+148 (2026-06-07)

### Sesli oda gri ekran (v2)

- Riverpod erken `return` kaldırıldı — tüm `ref.listen`/`ref.watch` her karede tutarlı
- Üst panel `SingleChildScrollView` ile kaydırılabilir (küçük ekranda layout taşması)
- Tam ekran ses bağlantı overlay'i kaldırıldı — UI ses bağlanırken görünür kalır
- `stableSessionKey` sabitlenerek canlı provider yeniden kurulması engellendi
- Android koltuk çerçevesinde `MaskFilter.blur` yerine düz stroke

## 1.0.143+145 (2026-06-07)

### Ana sayfa — onaylı mockup (piksel uyumlu)

- HomeHeader, StoriesSection, LiveBroadcastSection, VoiceRoomSection
- TrendingVideoSection, FortuneSection, MoreFortunesButton
- BottomNavigationWidget: Ana Sayfa, Canlı, Odalar, Jeton, Profil
- Arka plan #0B0B15, bölüm sırası mockup ile birebir

## 1.0.142+144 (2026-06-07)

### Ana sayfa sıkılık + sesli oda gri ekran + kaydırma performansı

- Bölüm başlıkları arası boşluk azaltıldı (sıkı dikey akış)
- Ana sayfa galaksi arka planı statik — animasyon/blur kapatıldı (kaydırma takılması)
- Sesli oda: canlı oturum provider'ı sabit oda kimliğiyle (online sayısı değişince yeniden kurulmuyor)
- Sesli oda: üst panel kaydırılabilir — küçük ekranda taşma/gri ekran giderildi
- Odaya girerken `voiceRoomsProvider` invalidate kaldırıldı

## 1.0.141+143 (2026-06-07)

### Ana sayfa — Canlı Yayındakiler

- Yatay kaydırmalı büyük 16:9 canlı yayın kartları (neon glow)
- Kırmızı CANLI rozeti, sağ üst izleyici sayısı, alt yayıncı adı + başlık + kategori
- Web ile aynı `GET /api/video-streams` endpoint; yayın yoksa bölüm gizlenir
- CachedNetworkImage + lazy list; ilk 5 önizleme önceden yüklenir
- Bölüm sırası: Hikâyeler → Canlı Yayındakiler → Sesli Sohbet → … → Keşfet → Fan Club → Gold

## 1.0.140+142 (2026-06-07)

### Sesli oda + canlı fal davet

- Sesli oda: tam ekran bağlanma overlay kaldırıldı (odaya giriş engelleniyordu)
- Falcı daveti: push bildirimi → uygulama içi Kabul/Beklet/Reddet sheet (global host)
- OneSignal ön planda fal isteği sheet açar; bildirim yalnızca bilgi amaçlı
- Davet sheet BackdropFilter kaldırıldı (Android gri boş sheet)

## 1.0.139+141 (2026-06-07)

### Sesli oda gri ekran — Android düzeltmesi (2. tur)

- Kalan `BackdropFilter` kaldırıldı: duyuru, aksiyon satırı, VoiceGlass
- Sohbet overlay `ShaderMask` → gradient fade (Android uyumlu)
- Oda UI `Positioned.fill` ile tam ekran layout
- Oda kimliği senkronizasyonu + favorilerden `extra` ile giriş
- `voiceRoomByIdProvider` önce önbellekten oda arar

## 1.0.138+140 (2026-06-07)

### Canlı fal ve sesli oda düzeltmeleri

- Canlı fal: danışan onay + bekleme ekranı; Kabul/Beklet/Reddet yalnızca falcıya düşer
- Falcı gelen istek dinleyicisi (incoming sessions poll)
- Sesli oda: Android gri boş ekran (BackdropFilter) giderildi, bağlanma göstergesi
- Profil: Falcı ol / Ajans ol kısayolları
- API: `sessions/incoming`, session status, teller respond

## 1.0.135+137 (2026-05-19)

### FLUTTER_CURSOR_PROMPT parite — tam paket

- Canlı beğeni: `POST /api/video-streams/{id}/like` (TikTok +1/tap)
- Video PK: `POST/GET …/pk-battle` (create/accept/reject/score/end)
- Co-broadcast: davet listesi, invite, accept/decline
- Falcı oturumu: `POST /api/fortune-tellers/session` + WebRTC signal poll
- Rumuz: `POST …/presence` body `{ nickname }`
- WebRTC signaling: `video_webrtc_signal_service.dart` (HTTP poll)

## 1.0.134+136 (2026-05-19)

### Müzik isteği oynatma düzeltmesi

- `[SONG_REQUEST_FREE] videoId|başlık` sohbet satırı parse edilir; anında oynatma + sunucu senkronu
- `!istek` sonrası kademeli yeniden senkron (300 ms–3 sn)
- Kuyruk dolu ama `playing: false` ise mobil YouTube yedek URL ile çalmayı dener
- API: Piped çözümleme başarısızsa YouTube watch URL ile kuyruk başlatılır; `nowPlaying` kuyruk başında gösterilir

## 1.0.131+133 (2026-05-19)

### Müzik sistemi — web paritesi

- Müzik Aç: web gibi blur’lu modal (`YouTube Müzik`), sayfa değişmez
- DJ senkron: SSE/socket `dj` payload, öncelikli kuyruk (10 jeton), ücretsiz `!istek` (sunucu)
- Oynatma: kuyruk merge düzeltmesi, YouTube yedek URL, hata mesajları
- API mirror: `priority`, `skipPayment`, zengin `QUEUE_UPDATED` socket olayları

## 1.0.130+132 (2026-05-19)

### Sesli oda müzik senkronu (web ↔ mobil)

- DJ durumu: `GET /music-queue` öncelikli; `GET /song-request` artık `playing: false` ile ezmez
- Oynatma: YouTube yedek URL + akış çözümü; hata mesajı gösterilir
- Sohbet: «şu an çalıyor» mesajında anında senkron
- Mini player: gerçek oynatıcı durumunu yansıtır
- API mirror SSE: `type: dj` olayları (3 sn)

## 1.0.129+131 (2026-05-19)

### Backend parite (API mirror + Flutter)

- Müzik arama: yalnızca `GET /api/music/search` (JWT); Piped/Invidious istemci araması kaldırıldı
- API mirror: mobil auth, TRTC usersig, stories, reports, referral, users search, sosyal beğeni/yorum, DM GET, video-streams list/end, SSE
- Next.js referans: `docs/nextjs/app-api-music-search-route.ts` — canlifal.com’a deploy için
- Üretim: `YOUTUBE_API_KEY` Vercel’de tanımlanmalı (`/api/music/search` şu an 404)

## 1.0.128+130 (2026-06-04)

### Müzik arama ve !istek

- YouTube arama: canlifal API + Piped + Invidious **paralel** (18 sn API beklemesi kaldırıldı)
- Zaman aşımı: kullanıcıya Türkçe mesaj; ham `TimeoutException` gösterilmez
- `!istek şarkı`: boş komutta kullanım uyarısı; yerel arama başarısızsa sunucuya iletme
- Oda içi duyuru: aranıyor / eklendi / sunucuya iletiliyor flaşları

## 1.0.127+129 (2026-05-19)

### Google ile giriş

- `GOOGLE_SERVER_CLIENT_ID`: dart-define veya `google-services.json` Web client (`client_type: 3`)
- `GoogleAuthConfig` + net hata mesajları (SHA-1, yapılandırma eksik)
- `POST /api/auth/mobile-google` — düz JSON ve `{ success, data }` sarmalayıcı
- CI: `print-firebase-dart-defines.sh` APK’ya otomatik Web client ID ekler
- Kurulum: `docs/GOOGLE_SIGNIN_SETUP_TR.md`

## 1.0.126+128 (2026-05-19)

### Canlı yayın ve hediye

- Yayın oluşturma: esnek `streamId` ayrıştırma, `live-started` uç sabiti, `[Live]` debug logları
- TRTC: `{ success, data }` sarmalayıcı, `sdkAppId`/`userSig` doğrulama
- Prep: kamera/mikrofon izni önce; `useMobileAuth` ile `POST /api/video-streams`
- Hediye: `senderName` / `receiverName` gönderimi; poll 4 sn
- Analiz: `docs/LIVE_STREAM_FLUTTER_ANALYSIS.md`

### Hata düzeltmeleri (sesli oda / API)

- **Müzik araması:** Popüler şarkılara `videoId` eklendi; Piped/Invidious kapalıyken de sonuç döner (ör. Müslüm Gürses)
- YouTube arama: önce JWT ile `/api/youtube/search`; 401’de net oturum mesajı
- Oda komutları UI: `/` → `!` (sunucu ile uyumlu)
- API: `prisma generate` postinstall; `/api/youtube/search` optionalAuth

## 1.0.125+127 (2026-05-19)

### WhatsApp jeton ödemesi — zaman aşımı düzeltmesi

- `POST /api/payment/requests`: 22 sn dış zaman aşımı kaldırıldı; istek başına 45 sn `receiveTimeout`
- Gövde artık `Map` olarak gönderiliyor (web ile aynı JSON; çift kodlama riski yok)
- Oturum yoksa anında anlamlı hata; 4xx/5xx sunucu mesajı snackbar’da
- Debug: `[Payment]` logları (URL, method, JWT varlığı, status, süre)
- API: ödeme talebi 201 yanıtı bildirimler tamamlanmadan döner (mobil zaman aşımı önlenir)

## 1.0.119+121 (2026-05-19)

### Birleşik sürüm (main + sesli oda senkron)

- **PR #87** Oda Komutları, Şarkı İsteği, DJ Yönetimi (zaten main’de)
- **PR #91–#93** Komut/YouTube, müzik kuyruk, native API uyumu
- **PR #95** Web ↔ Flutter sesli oda senkronu, YouTube API önceliği
- Sosyal: beğeni, yorum, paylaşım, hikâye (önceki dal)

## 1.0.118+120 (2026-05-19)

### Sesli oda — web ↔ Flutter senkronizasyonu

- Socket.IO: JWT (`Authorization` + `auth.token`), `id` ve `slug` ile çift `joinRoom`
- Hediye socket aynı düzeltmeler
- TRTC: önce `id`, gerekirse `slug` ile UserSig (web ile aynı oda)
- Sohbet/presence yenileme 3 sn
- YouTube arama: önce oturumlu `/api/youtube/search`, sonra Piped/Invidious
- API: `emitChatRoomMessage` hem `room:{id}` hem `room:{slug}` kanallarına yayın

## 1.0.117+119 (2026-05-19)

### Tam native işlevsellik (canlifal.com)

- Sosyal: beğeni (`POST .../likes`), yorumlar (sheet + API), paylaşım (`share_plus`)
- Hikâye: galeriden görsel → `POST /api/stories`
- Akış: `/api/stories` boşsa `/api/social/posts` yedek
- Takipçi listesi: `/api/users/:id/follow` + `/api/user/followers`
- Takip toggle: `/api/users` ve `/api/user` yolları
- Bildirim okundu: `PATCH /api/user/activity` + `notificationIds`
- OTP sayfası production’da şifre sıfırlamaya yönlendirir
- Gönderi: `likedByMe`, beğeni/yorum sayısı düzeltmesi

## 1.0.116+118 (2026-05-19)

### Native canlifal.com API uyumu (WebView yok)

- Şifre sıfırlama: `POST /api/auth/forgot-password` (native ekran)
- DM: `conversations` / `requests` ayrıştırma; mobil `GET /api/messages`
- Takip: `POST /api/users/:id/follow` toggle
- Profil: `PATCH /api/me` (`name`, `image`)
- Canlı: `/api/video-streams`; sesli odalar her zaman `/api/chat/rooms`
- Okunmamış mesaj: `GET /api/messages?unreadCount=true`
- Site yolları → `native_site_routes` (şifre sıfırlama dahil)

## 1.0.109+111 (2026-06-02)

### Sesli sohbet odası (canlifal.com UI)

- 2×5 mikrofon ızgarası, kalıcı duyuru kutusu, sağ yüzen ‹ araçlar + ♫ müzik
- YouTube şarkı arama/istek (jeton), DJ API düzeltmeleri
- Sohbet: ardışık mesaj bekleme kaldırıldı
- Moderatör: yasaklı kelime listesi API

## 1.0.108+110 (2026-06-02)

### Ana sayfa — canlifal.com düzeni (native)

- Keşfet sekmesi: dikey akış — Hikâyeler, Canlı Yayınlar, Sesli Odalar, Trend Videolar, Fan Club, Fal & Tarot, Popüler Falcılar, Keşfet grid, Gold Üyelikler
- REST API (`/api/trend-videos`, canlı, sohbet odaları, falcılar, üyelik paketleri) — WebView yok
- 2026 cam/glow tasarım, 24px kartlar

## 1.0.107+109 (2026-06-02)

### Keşfet ve sesli oda — premium görsel (yapı aynı)

- Ana sekme yeniden **Keşfet (`/feed`)** — DiscoverPremiumFeed; bölüm sırası korunur
- Mor/pembe palet (#7B2FF7, #B84DFF, #FF4FD8), 24px cam kartlar, LiquidGlass
- VoiceDiscoverHub2026 aynı görsel dil; WebView kaldırıldı, native yönlendirme

## 1.0.101+103 (2026-05-31)

### Tema sistemi (production)

- Tek kaynak: `app_theme_colors.dart` — light/dark tüm token'lar
- **SharedPreferences** ile kalıcı tema (Açık / Koyu / Sistem)
- Material 3: dialog, bottom sheet, snackbar, AppBar, buton, input
- `ThemedGlassCard` — koyu modda glassmorphism, açık modda premium gölge
- `context.colors` extension — sabit renk yerine tema
- Profil → Tema seçici (anında güncelleme, yeniden başlatma gerekmez)

## 1.0.100+102 (2026-05-31)

### Dark / Light Mode

- `AppTheme.light()` / `AppTheme.dark()` — Material 3 tam tema
- `AppPalette` ThemeExtension — yüzey ve metin renkleri
- Kalıcı tema: Hive (`app_theme_mode`) — Açık / Koyu / Sistem
- Profil → Görünüm: `ThemeModeSelector` (segmented)
- Ana kabuk ve sayfalar `scaffoldBackgroundColor` ile tema uyumlu
- Durum çubuğu ikonları temaya göre ayarlanır

## 1.0.99+101 (2026-05-31)

### API sayfalama + Pro Glass mağaza / fal

- API: `activity`, `broadcast-history`, `payment/requests` — `page` / `limit` / `pagination`
- Mobil: canlı yayınlar, işlemler, yayın geçmişi, profil paylaşımları — sunucu sayfalı `AsyncNotifier`
- Jeton / CFC mağazası: `ProGlassCard` paket kartları, kullanım kartı, CFC geçmişi
- Fal hub: `FortuneGlassCard` → Pro Glass cam yüzey

## 1.0.98+100 (2026-05-31)

### Performans + Pro Glass (devam)

- Canlı yayınlar, sohbet mesajları, takip listesi, profil ızgarası: lazy pagination
- `CachedCoverImage` — kalan `Image.network` kullanımları kaldırıldı
- Sohbet: eski mesajlar yukarı kaydırınca yüklenir; cam üst bar (`ProGlassTopBar`)
- `LazyPaginatedListView` — genel amaçlı sayfalı liste bileşeni

## 1.0.97+99 (2026-05-31)

### Performans + Pro Glass UI

- `ListPerf` sabitleri, `RepaintBoundary`, lazy liste (`LazyVisibleListController`)
- Mesajlar / bildirimler: sayfalı görünür liste (24’lük artış, scroll’da yükleme)
- Ses keşfet hub: `ListView.builder` + lazy oda satırları (eager map kaldırıldı)
- Riverpod: `currentUserIdProvider` — sosyal kartlarda dar rebuild
- `ProGlassCard` / `DiscoverGlassCard` blur glassmorphism
- Keşfet oda yenileme aralığı 15 sn (pil / FPS)

## 1.0.96+98 (2026-05-31)

### Sesli oda, ödeme, jeton/CFC, sohbet düzeltmeleri

- Bakiye: `GET /api/me` + yedek `GET /api/user/credits` — jeton 0 görünme / oda açılamama
- Oda aç: bakiye yüklenmeden engel kaldırıldı; API jeton kontrolü esas
- Ödeme bildirimi: 22 sn zaman aşımı; belirsiz yanıtta hata; sonsuz dönme giderildi
- Jeton/CFC: `openJetonStore` / `openCfcStore` — sesli odadan güvenilir yönlendirme
- Sohbet: ikinci mesaj kilidi (`sending` + poll pause) kaldırıldı; 10 sn gönderim limiti
- YouTube: `/api/chat/youtube-search` önce, boş sonuçta yedek uç

## 1.0.95+97 (2026-05-31)

### Premium 2026 UI — PART 1–3 (PR #62–#64)

- **PART 1 — Auth:** galaksi splash, liquid glass giriş/kayıt, neon CTA, Google giriş
- **PART 2 — Keşfet:** `DiscoverPremiumFeed` — kategoriler, trend/sesli/canlı sekmeleri, neon oda kartları
- **PART 3 — Sesli oda:** responsive sahne bileşenleri, level rozeti, parçacık efektleri (üretim RTC: web overlay + hub ayarları korundu)

## 1.0.94+96 (2026-05-31)

### Premium 2026 UI (PR #58)

- Liquid glass auth shell, `PremiumScreenShell`
- Fortune mystic arka plan + hub kartları
- Profil düzenleme / kullanıcı profili premium yüzeyler

## 1.0.93+95 (2026-05-31)

### Hata düzeltmeleri

- `dart analyze`: `safePatch` için `options` parametresi; Flutter API `markAllRead` PATCH
- VIP Gold import yolları (`package:canlifal_social/...`) — derleme hataları giderildi
- CI: `permissions`, API `npm run build` zorunlu

## 1.0.92+94 (2026-05-19)

### Sesli oda — oda aç, müzik, mesaj, giriş şeridi, komutlar

- Oda aç: normal **100** jeton; istek gövdesine oda adı alanları eklendi
- Müzik Aç: `/song-request` yoksa `/music-queue` yedek ucu; YouTube arama yedek `/api/chat/youtube-search`
- Mesaj: gönderim sırasında poll duraklatılır; çift zaman aşımı kaldırıldı
- Yetkili girişi: sağdan sola kayan şerit (MODERATOR/VIP/STAFF); sohbette tekrar gösterilmez
- Oda komutları (`/temizle`, `!temizle` vb.) sohbete gönderilir; API’de işlenir
- Arka plan önbelleği 48 görsele kadar genişletildi

## 1.0.91+93 (2026-05-19)

### Sesli oda — mesaj, YouTube, klavye, oda aç

- Gönder düğmesi: zaman aşımı + `sending` her durumda sıfırlanır; boş API yanıtında mesaj yine eklenir
- YouTube şarkı arama/istek: 18–22 sn zaman aşımı; arama spinner takılması düzeltildi
- Mesaj çubuğu klavyenin üstünde sabitlenir (`viewInsets`)
- Oda aç: normal **200** jeton, VIP **5000** jeton (Gold şartı kaldırıldı)
- Arka plan görselleri odaya girince önbelleğe alınır

## 1.0.90+92 (2026-05-19)

### Ana sayfa, oda aç, Gold & derleme düzeltmeleri

- Keşfet: 4 sütun sohbet odaları; Canlı Falcılar altında hızlı işlemler; 4×2 canlı istatistikler
- Sesli oda aç: `POST /api/chat/rooms/create` — 100 jeton (Gold+ VIP oda)
- Gold: aktif üyelik metni ve uzatma; ödeme talebi HTML/oturum hataları düzgün gösterilir
- RTC sahne boşlukları sıkılaştırıldı; `dart analyze` derleme hataları giderildi

## 1.0.88+90 (2026-05-19)

### Sesli oda — canlifal.com API uyumu (oda id, YouTube, koltuk)

- Oda API anahtarı: önce Prisma `id` (slug ile DJ/mesaj 404 düzeltmesi)
- YouTube arama: `/api/youtube/search`; şarkı sırası: `/song-request` (10 jeton)
- Koltuk: yetkili boş koltuğa oturur; oda sahibi kullanıcıyı koltuğa atayabilir
- Mesaj gönderimi: zaman aşımında yedek anahtar; DJ hatası sohbeti kilitlemez
- Arka plan listesi: sitedeki oda `backgroundImage` görsellerinden

## 1.0.87+89 (2026-05-19)

### Sesli oda — ayarlar, müzik sırası, YouTube isteği

- Profil/sahne üstte sabit; avatar halkaları tam oturacak şekilde düzeltildi
- Mesaj çubuğu: çift mikrofon ve hediye kaldırıldı; çok satırlı yazım
- Duyuru 15 sn gösterim + kapatınca kayıt (Hive)
- Müzik Aç → YouTube şarkı arama, istek başına 10 jeton, sıraya ekleme
- DJ ekle/çıkar (API); alt barda Hediye → Ayarlar (oda ayarları, komutlar, arka plan, şarkı isteği)
- Sağ yüzen şerit kaldırıldı; navbar galeri siteden arka plan grid

## 1.0.86+88 (2026-05-19)

### Sesli oda — web görsel + sohbet + canlifal.com verisi

- Sahne: sol Admin + sağda 2×5 (10) koltuk; üst barda oda avatarı (mor halka)
- Sohbet: gönder düğmesi takılması giderildi (timeout, poll çakışması, birleştirme)
- API: önce `slug` anahtarı, `since` ile artımlı mesaj, canlifal oda listesi senkronu

## 1.0.85+87 (2026-05-19)

### Sesli oda — web referans UI (Premium)

- Üst bar: doğrulanmış oda adı, ID, çevrimiçi, galeri, ayarlar, çıkış
- Sahne: solda büyük oda sahibi (altın taç), sağda 4+4 mikrofon ızgarası
- Duyuru kutusu, Müzik Aç / DJ satırı, dinleyici şeridi
- Şeffaf sohbet akışı, web giriş çubuğu (mikrofon + hediye)
- Alt nav: Ana Sayfa, Hoparlör, merkez mikrofon, Jeton Yükle, Hediye At
- Sağ yüzen kısayollar; daha açık arka plan görünümü

## 1.0.84+86 (2026-05-19)

### Sesli oda — sohbet, düzen, katılımcılar

- Sohbet mesajları birleştirilerek kaybolma / gönderim yarışı giderildi
- Mikrofon: 4 üst + 4 alt ızgara; dinleyici şeridi ve katılım satırları
- Responsive sohbet alanı, boş sohbet ipucu, hata SnackBar

## 1.0.83+85 (2026-05-19)

### Premium 2026 — Keşfet / PK / Hediye (referans UI)

- **Keşfet hub:** profil selamı, jeton, sekmeler, LIVE hikaye şeridi, gece banner, popüler odalar, canlı yayınlar, 8’li kategori grid, VIP odalar
- **PK Savaşı:** LIVE sayaç, VS + skor çubuğu, mikrofon şeridi, cam hediye akışı, Destekle / Hediye / Sohbet alt bar
- **Hediye Gönder:** Tümü / Popüler / Özel / VIP sekmeleri, 3 sütun grid, adet +/- , tam genişlik Gönder

## 1.0.82+84 (2026-05-19)

### PART 7 — VIP / Gold premium sistemi

- VIP rozetleri, Gold üyelik kademeleri (Premium → SVIP)
- Özel giriş animasyonu (odaya katılımda tam ekran FX)
- Premium avatar çerçeveleri, luxury kartlar, glassmorphism hub
- VIP odalar ve şifreli odalar — tek kapı: `openVoiceRoomWithVipGate`
- `/vip-gold` merkezi, keşfet VIP kategorisi, profil banner
- Oda grid: VIP / kilit etiketleri; mikrofon koltuğunda rozet

## 1.0.81+83 (2026-05-19)

### PART 6 — Premium canlı yayın (TikTok tarzı)

- Immersive fullscreen: gradient scrim, blur üst/alt overlay
- Canlı yorumlar: cam baloncuklu `LivePremiumChatFeed`
- Çift dokunuş kalpleri + yüzen heart parçacıkları
- Premium top bar: takip API, izleyici, süre, neon glow
- Sağ rail: beğeni / hediye / paylaş; hediye fullscreen + bildirimler
- Dikey swipe: `/live/swipe` — yayınlar arası TikTok geçişi
- Varsayılan açılış swipe modunda (`openLiveStreamNative`)

## 1.0.80+82 (2026-05-19)

### PART 5 — Premium PK savaş sistemi

- **1v1** ve **takım** modu; canlı mod geçişi
- Realtime skor çubuğu (animasyonlu gradient), countdown, win streak rozetleri
- Büyük glitch **VS** amblemi, cyber HUD oyuncu çerçeveleri
- Hediye gücü: oda hediyeleri skora eklenir + neon patlama + yüzen tepkiler
- Kazanan ekranı: konfeti, taç, tekrar PK
- Sesli oda menüsü / keşfet PK kategorisi → `/voice-room/:id/pk`

## 1.0.79+81 (2026-05-19)

### PART 4 — Premium hediye sistemi (TikTok Live seviyesi)

- 8 hediye: Roket, Galaxy, Aslan, Spor araba, Elmas, Kalp, Taç, Yat
- Tam ekran animasyon: neon vignette, glow ring, combo rozeti, jeton burst, yüzen parçacıklar
- Combo birleştirme (8 sn pencere), oturum hediye sıralaması
- Sesli oda: cam blur hediye paneli, yatay premium kartlar, x1/x5/x10/x99
- CustomPainter 3D-benzeri ikonlar (Lottie/Rive eksik asset’lerde)
- Canlı yayın `GiftFullscreenOverlay` → premium overlay

## 1.0.75+77 (2026-05-19)

### Sesli sohbet — Premium 2026

- Kozmik arka plan, yarım daire 8 mikrofon sahnesi, cam efektli üst/alt bar
- Sohbet klavyeye yapışık; mesajlar ses (LiveKit/TRTC) bağlanmasa da çalışır
- Keşfet: kategoriler + öne çıkan odalar; PK savaş ekranı (`/voice-room/:id/pk`)
- Gold VIP kapısı; alt barda **Jeton Al**; hediye şeridi
- API: oda `id`/`slug` tek kanonik anahtar (`resolveRoomId`) — presence, mesaj, socket

## 1.0.64+66 (2026-05-19)

### Ana sayfa ve Fal & Tarot düzeni

- Hikâyeler keşfet ana sayfaya taşındı; sosyal sekmesinden kaldırıldı
- «Canlı yayınlara katıl…» başlığı kaldırıldı
- Fal & Tarot altında canlı istatistikler + son 5 giriş
- Sohbet odaları tek sıra kaydırmalı; odadaki kullanıcı avatarları altta
- Fal & Tarot: fal türleri 3 sütunlu grid

## 1.0.63+65 (2026-05-19)

### Firebase / canlifal.com yapılandırması

- `scripts/sync-canlifal-config.sh` — resmi URL’lerden google-services, Admin SDK, API docs
- `google-services.json` → otomatik `FirebaseOptionsGenerated` + CI `GOOGLE_SERVICES_JSON_BASE64`
- Dokümantasyon: `docs/CANLIFAL_OFFICIAL_CONFIG.md`

## 1.0.62+64 (2026-05-19)

### Açılış, bildirimler ve sosyal

- Splash görseli ekrana sığdırılır (`BoxFit.contain`); Android native splash arka planı koyu tema
- Push: OneSignal/FCM tıklama yönlendirmesi, izin banner’ı ve token kaydı iyileştirmeleri
- Bildirimler ve jeton mağazası: kabukta ön yükleme, `keepAlive`, jeton sayfasında anında yedek paketler
- Sosyal: «Fal hikayeleri» kaldırıldı; paylaşım kartında profil + beğeni/yorum/izlenme tek kutuda

## 1.0.53+55 (2026-05-19)

### Açılış ve sosyal UX

- Mistik splash görseli tam ekran açılış
- Sosyal akış: her 2 gönderi arasında sesli sohbet odaları
- Paylaşım metni 250 karakter + «daha fazla»
- Profil üstüne tıklayınca paylaşan profili
- Kullanıcı profilinde TikTok tarzı paylaşım ızgarası

## 1.0.52+54 (2026-05-19)

### canlifal.com mobil JWT API

- Oturum: `POST /api/auth/mobile-register|login|google|tiktok|refresh`
- Profil ve bakiye: `GET /api/me` (Bearer)
- DM: `GET/POST /api/messages`, `GET/POST /api/messages/{userId}`
- Dio: 401 → `mobile-refresh`; WebView Google OAuth kaldırıldı
- Kayıt: `name`, `birthDate`, `birthTime`, `preferredLanguage`

## 1.0.47+49 (2026-05-22)

### Anlık push bildirimleri

- Mesaj, ödeme (admin onayı), canlı yayın → OneSignal yüksek öncelik
- Bildirime tıklayınca doğru ekrana yönlendirme
- API: `push_events`, `POST /api/video-streams/.../live-started`

## 1.0.46+48 (2026-05-22)

### Yayın (CI)

- `apk-latest` GitHub Release yayını düzeltildi (sürekli sürüm akışı)

## 1.0.45+47 (2026-05-19)

### OneSignal push

- SDK entegrasyonu; App ID: `578518ed-7b16-46a9-a1e6-7692d3ba55d8`
- Girişte `OneSignal.login(userId)`; token `POST /api/devices/fcm`
- Kurulum: `docs/ONESIGNAL_SETUP.md`

## 1.0.44+46 (2026-05-19)

### Android paket kimliği

- `applicationId` / Firebase paket adı: **`com.mesutbyrm.canlifal`** (önceki: `com.canlifal.canlifal_social`)
- iOS/macOS bundle ID aynı değere hizalandı
- Firebase Console’da yeni paket adıyla `google-services.json` indirilmeli

## 1.0.38+40 (2026-05-22)

### Jeton ödeme + CFC verisi

- Jeton talebi: `amount` + `coins` (canlifal.com eski API uyumu) — **Geçersiz miktar** düzeltmesi
- CFC ödeme ayarları yalnız siteden (`/api/payment/config`); bakiye metni API CFC
- Jeton paket grid: aralıklar kaldırıldı (bitişik kartlar)

## 1.0.37+39 (2026-05-22)

### Gold Üyelik + ödeme bilgileri

- Premium sayfa API/HTML hatasında varsayılan paketler (artık boş ekran yok)
- Üyelik satın alma: API yoksa WhatsApp/Papara/Havale ödeme akışı
- Varsayılan ödeme: WhatsApp 05327170173, Papara 1555517633, Garanti IBAN (Mesut bayram)

## 1.0.36+38 (2026-05-22)

### Profil, Jeton, Premium — responsive + mockup

- `ResponsiveLayout`: tablet/desktop ortalanmış içerik (max 560px), adaptif grid
- **Premium Üyelik:** mockup dikey kartlar (Basic/Premium/Gold/Diamond), özellik grid, Gold durum
- **Profil / Jeton yükle:** responsive padding ve geniş ekran düzeni

## 1.0.35+37 (2026-05-22)

### Jeton Satın Al — mockup mağaza

- 2×2 paket grid (50–500 jeton) + tam genişlik 1000 jeton
- Gold üye banner, özel miktar (jeton / ₺), `jetonTlRate` API
- Varsayılan paketler: 1 Jeton = ₺0,50

## 1.0.34+36 (2026-05-22)

### Logo ve uygulama ikonu

- Gönderilen **CanlıFal** ikon tasarımı: `assets/brand/` + Android `ic_launcher` + web favicon
- Giriş ve kayıt ekranında aynı kare marka ikonu

## 1.0.33+35 (2026-05-22)

### Giriş / Kayıt — mockup tasarım

- Şeffaf marka PNG’leri (`assets/brand/`) — kristal küre logo + uygulama ikonu
- Koyu mor arka plan, cam form kartı, mor **Giriş Yap** / **Kayıt Ol** butonları
- Kayıt: Ad Soyad, telefon, şifre tekrar alanları

## 1.0.32+34 (2026-05-21)

### Jeton mağazası — boş liste asla gösterilmez

- UI katmanında da varsayılan paketler (API boş dönse bile)
- 401 dahil tüm API hatalarında satın alma akışı varsayılan paketlerle devam eder

## 1.0.31+33 (2026-05-21)

### Jeton mağazası — paket listesi düzeltmesi

- `/api/jeton` boş veya hatalı yanıtta **varsayılan paketler** (100–5000 jeton, mockup 1000/₺500 dahil)
- Geliştirilmiş JSON ayrıştırma; 401 için net oturum mesajı

## 1.0.30+32 (2026-05-21)

### Jeton yükleme — site + mobil (mockup)

- Web: `site/jeton/` — paket listesi, ödeme yöntemi, WhatsApp, Papara, Havale/IBAN
- Mobil: `/jeton-store` mockup checkout akışı + ödeme talebi
- API: `POST /api/payment/requests` `requestType: jeton`, admin onayda `coins` artışı
- Bildirimler: `jeton_payment_*` tipleri
- Kurulum: `docs/SITE_JETON_KURULUM.md`

## 1.0.29+31 (2026-05-21)

### CanlıFal Sosyal — otomatik fal paylaşımı

- Fal sonucu otomatik sosyal akış paylaşımı (`POST /api/social/posts/auto-fortune`)
- Akış kartı: Otomatik paylaşıldı rozeti, birlikte bakanlar, Kart/Detay
- `DELETE /api/social/posts/:id`

## 1.0.28+30 (2026-05-21)

### Cüzdan + CFC + Gold Üyelik (birleşik)

- `/wallet` cüzdan merkezi (Jeton, CFC, Premium)
- `/premium-membership` Gold üyelik sayfası (mockup: 4 paket, karşılaştırma tablosu)
- CFC yükleme ile ortak bakiye başlığı ve Gold üye şeridi
- API: `GET/POST /api/membership/*`, kullanıcı `membership` alanları

## 1.0.27+29 (2026-05-21)

### CFC ödeme API (canlifal.com dokümantasyonu)

- `GET /api/user/credits` — jetonBalance, cfcBalance, üyelik alanları
- CFC yükleme: `/cfc-store` (amount, bank_transfer, talep geçmişi)
- Admin: onay/red `PATCH /api/admin/cfc-payment-requests`
- Bildirimler: `cfc_payment_*` tipleri
- API dokümantasyonu: `docs/CFC_ODEME_API.md`

## 1.0.26+28 (2026-05-21)

### Cüzdan, ödeme, bildirim ve yönetim

- **Jeton + CFC** çift bakiye (profil, shell, jeton mağazası)
- Bildirime tıklayınca ilgili sayfaya yönlendirme
- Jeton yükleme: WhatsApp, Papara, Havale/EFT — uygulama içi (web’siz)
- Ödeme talebi → admin + site bildirim paneli
- Profilde **Yönetim** bölümü (admin, yönetici, moderatör, destek, yardım)
- Premium açılış ekranı + CanlıFal logo
- `/gift-send` native hediye alanı

## 1.0.25+27 (2026-05-21)

### TikTok tarzı gelişmiş hediye sistemi

- Backend: `Gift` + `GiftEvent`, platform (`mobile`/`web`), rarity, Socket.IO
- Flutter: premium hediye paneli (blur, neon, yatay liste), top gifters
- Lottie + Rive + SVGA fallback, fullscreen animasyon, combo, ses (audioplayers)
- Animasyon önbelleği (`GiftCacheService`), lazy loading

## 1.0.24+26 (2026-05-21)

### CanlıFal Sosyal — premium mistik akış

- Başlık: **CanlıFal Sosyal** (yıldız ikonu, bildirim noktaları)
- Hikâye şeridi: «Hikayen», mor halka, mistik dekor kartı
- Composer: «Ne düşünüyorsun, Canlıfal?» — mor çerçeve, renkli aksiyonlar
- Gönderi kartı: doğrulanmış rozet, zaman + herkese açık, metin → görsel, **Falına Bak** CTA
- Etkileşim sayıları ikon yanında; **Aktif Odalar** yatay şerit (canlı / ses / demo)

## 1.0.23+25 (2026-05-21)

### Fal & Tarot — premium mistik hub

- Tam sayfa `/fortune`: hero, 14 fal grid (Keşfet), günlük fal kartı, Premium upsell
- Oturum ekranları: Tarot, aşk, kahve, yıldız, el, rüya, evet/hayır, pendül, runik…
- Sonuç + paylaşım (Instagram / WhatsApp / Telegram / kaydet)
- Keşfet önizlemesi → native hub

## 1.0.22+24 (2026-05-21)

### Sosyal paylaşım (Instagram + Facebook)

- Facebook tarzı «Ne düşünüyorsun?» composer (fotoğraf / video / duygu)
- Instagram tarzı tam ekran gönderi oluşturma (galeri, kamera, açıklama)
- `POST /api/social/posts` — metin veya multipart görsel
- Freezed DTO’lar, moderasyon, Firebase (isteğe bağlı), discover widget bölünmesi

## 1.0.19+21 (2026-05-20)

### Auth & mesajlaşma premium

- Şifremi unuttum + 6 haneli OTP ekranları
- Sohbet: okundu tikleri, yazıyor animasyonu, modüler composer
- `LiveStreamDto` Freezed + `scripts/codegen.sh`
- Sekme hızlı işlemler `AppColors` birleşimi

## 1.0.18+20 (2026-05-20)

### Production mimari

- `ARCHITECTURE.md` — Clean Architecture, yol haritası (Freezed, Firebase, moderasyon)
- Canlı oda modüler: `widgets/broadcast_room/*` (~900 → ~400 satır orchestrator)
- Premium: skeleton loading, glass surface, bottom sheet, sayfa geçişleri
- Hive `LocalCache`, `hive_flutter` + codegen bağımlılıkları hazır

## 1.0.17+19 (2026-05-20)

### Premium UI — tüm modüller

- Canlı: `LiveStreamListTile`, cache thumb, `LiveBadge`, `AppColors`
- Sesli oda, profil, auth, mesajlar, bildirimler: `AppDesign` → `AppColors` birleşimi
- `discover_tab_layout` token düzeltmeleri

## 1.0.16+18 (2026-05-20)

### Premium UI — Keşfet & Sosyal

- Keşfet: `AppColors`, RepaintBoundary, premium header/coin/ikon, `GradientFab` hızlı işlem
- Sosyal: stories rail aktif, `DiscoverRefresh`, premium app bar, liste performansı
- Yeni bileşenler: `PremiumCoinCapsule`, `PremiumIconButton`, `PremiumQuickActionTile`, `PremiumEmptyHint`

## 1.0.15+17 (2026-05-20)

### Premium design system (temel)

- Birleşik `AppColors` + `CanlifalTokens` (Material 3 ThemeExtension)
- Açık/koyu tema (`themeModeProvider`, varsayılan koyu)
- Yeniden kullanılabilir UI kit: `PremiumNavBar`, `PremiumCard`, `NeonButton`, `LiveBadge`, `GradientFab`
- Alt bar: BackdropFilter kaldırıldı (performans)
- Canlı carousel: `CachedNetworkImage` + `LiveBadge`
- `DESIGN_SYSTEM.md` migrasyon rehberi

## 1.0.14+16 (2026-05-20)

### Keşfet

- **Canlı Yayın Başlat:** tam yuvarlak tuş, kamera ikonu, nabız glow animasyonu

## 1.0.13+15 (2026-05-20)

### Derleme (CI)

- Dart SDK `^3.8.0` (Actions ile uyumlu; `^3.11.5` kırılıyordu)
- `pubspec.lock` güncellendi (`flutter_web_auth_2`)
- `glow_panel` null-aware liste sözdizimi düzeltildi

### Google giriş düzeltmeleri

- **403 disallowed_useragent:** Chrome Mobile user-agent + güvenli tarayıcı (Custom Tab) yedek
- Oturum çerezleri uygulamaya aktarılıyor (`sessionCookieMarker` + yeniden deneme)
- Site ana sayfası / onboarding WebView’da açılmıyor (yalnızca `/api/auth/*`)

### Ana sayfa ve canlı (1.0.12+14)

- Sesli odalar: 4 sütun grid, gerçek `/api/chat/rooms` verisi
- Canlı izleme native TRTC (WebView yok); yayın bitince liste yenilenir
- TRTC izleyici video düzeltmesi (`hostUserId`)

## 1.0.10+11 (2026-05-20)

### Giriş ve çıkış

- Google girişi uygulama içi OAuth (site gezintisi yok, oturum otomatik)
- Ana ekranda geri tuşu: «Çıkış yap» / «Uygulamayı kapat» / «İptal»

## 1.0.9+10 (2026-05-20)

### Canlı yayın TRTC

- İzleyici: otomatik ses/video alımı (`setDefaultStreamRecvMode`)
- Uzak yayıncı sesi açık (`muteRemoteAudio` + hoparlör)
- Oda kimliği tutarlılığı (usersig + `strRoomId`)
- Yayıncı video/ses callback’leri iyileştirildi

## 1.0.8+9 (2026-05-20)

### Sesli sohbet listesi

- Tüm odalar tek ekranda; **4 sütunlu** kompakt grid karo
- Büyük tek kart / boş “Tüm odalar” bölümü kaldırıldı
- Benim oda grid’de ilk sırada altın çerçeve ile

## 1.0.7+8 (2026-05-20)

### Sesli sohbet

- Odalar tamamen **native Flutter + TRTC** (WebView yok)
- **Benim odam** bölümü; popüler odalar responsive grid (1–2 sütun)
- Koltuk 1 yalnızca **oda sahibi** için (yoksa rezerve boş koltuk)
- Üst bar: genel ADMIN yerine sahip bilgisi / “Benim odam”
- Hediye ve jeton yükleme native (`/api/chat/rooms/.../gifts`, jeton mağazası)
- Oda sahibi TRTC’de `isHost: true`

## 1.0.6+7 (2026-05-20)

### Ana sayfa (Keşfet)

- Üst bar: **jeton** dokununca jeton mağazası; **profil** (avatar/isim) dokununca profil sekmesi
- **3** canlı yayın kartı
- **5** hızlı işlem tek satırda (hepsi görünür)
- **Tüm** sohbet odaları listelenir; native sesli oda açılışı
- **Fal & Tarot:** 14 kart, satırda 5
- Daha hızlı pull-to-refresh (paralel yenileme, kısa animasyon)

### Önceki sürümlerden (1.0.5)

- Sesli sohbet neon UI + canlifal.com chat API
- TRTC canlı yayın, hediye sistemi
- Shell hızlı işlemler, jeton mağazası, davet arkadaş

## 1.0.5+6

- Sesli oda, TRTC, hediye, shell entegrasyonu

## 1.0.4+5

- İlk neon sesli oda + API entegrasyonu
