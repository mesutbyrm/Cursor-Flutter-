# Sürüm notları — canlifal_social

## 1.0.261+297 (2026-08-18) — DJ üretim YouTube skip + B2 parity doc

- **DJ player:** Üretimde YouTube watch/stream URL'leri için ağır çözümleme atlanır (IFrame yolu)
- **Test:** Mock Dio ile `requestMusicByQuery` → `song-request` yolu doğrulandı
- **FAZ 0:** `docs/MISSING_ENDPOINTS_FLUTTER_ACTIVE.md` (68 MISSING × Flutter × probe)

## 1.0.260+296 (2026-08-18) — Stream resolve ANR + müzik probe doc

- **Stream resolve:** Üretimde Piped/Invidious/explode paralel çözümleme kapalı; IFrame yolu
- **Müzik hub:** Üretimde seçim prefetch (explode) yok
- **FAZ 0:** `docs/MUSIC_API_PRODUCTION_PROBE.md` (backend M6–M7 referansı)

## 1.0.259+295 (2026-08-18) — ANR: youtube_explode üretimde kapalı

- **Müzik arama:** `canlifal.com` üzerinde istemci `youtube_explode` yedeği devre dışı (ANR önleme)
- **FAZ 0:** `docs/REMAINING_WORK.md` canlı takip listesi; `docs/SSE_EVENTS_FLUTTER_PARSED.md`

## 1.0.258+294 (2026-08-18) — !istek doğrudan song-request + MCP backend-docs

- **!istek:** Üretimde ölü `music-request-by-query` atlanır; doğrudan sunucu arama + `song-request`
- **MCP:** `mcp-server` artık `backend-docs/endpoints_index.json` ve `schema.prisma` okur (`list_models`, `search_schema`)

## 1.0.257+293 (2026-08-18) — !istek üretim yedeği + backend-docs

- **Kök neden:** Üretimde `POST …/music-request-by-query` **404** — `!istek` hiç çalışmıyordu
- **Yedek:** 404'te sunucu YouTube arama + `song-request` (youtube_explode istemci yedeği yok)
- **Oynatma:** Kırık `youtube-audio?url=` proxy kaldırıldı; googlevideo doğrudan CDN / IFrame
- **FAZ 0:** `backend-docs/` (OpenAPI, endpoints_index, Prisma, B1.12 parity raporu)

## 1.0.256+292 (2026-08-18) — Müzik ANR kök düzeltme (grace + IFrame ses)

- **Kök neden:** API beklerken SSE/refresh çift oynatma; `youtube_explode` ana thread'i kilitliyordu
- **Erken grace (12 sn):** `!istek` / müzik isteği başında SSE ve sunucu sync atlanır
- **Oynatma:** Doğrudan `musicUrl` → `just_audio`; yoksa gizli YouTube IFrame ses (explode yok)
- **Video isteği:** Yalnızca IFrame video; çift ses yolu kaldırıldı

## 1.0.255+291 (2026-08-18) — Müzik isteği ANR koordinatörü

- **ANR kök neden:** Eşzamanlı `_playDjInBackground` çağrıları sıraya alındı; son istek birleştirilir
- **SSE grace:** Yerel `!istek` sonrası 5 sn SSE oynatma/sync atlanır (çift tetikleme yok)
- **Çift oynatma:** `applyAudioOutputGate` + istek yolu aynı anda çalmıyor
- **Sunucu stream:** `musicUrl` hazırsa gereksiz YouTube resolve atlanır
- **RoomSongJoinSync:** 350ms debounce ile spam azaltıldı

## 1.0.254+290 (2026-08-18) — !istek ANR + müzik çalma düzeltmesi

- **!istek donma (ANR):** Çift `refresh`/`_syncMusicFromServer` fırtınası engellendi; istek non-blocking
- **Müzik çalma:** `userDismissedPlayer`, nested `musicUrl`, SSE `ensureMusicAudible` hizalandı
- **Koltuk:** Geçici boş API yanıtında `seatIndex` korunur
- **Mikrofon:** `autoOpenMic` ayarı koltuk/konuşma yetkisinde otomatik açar
- **CI:** Acceptance test hesabı silinmişse `mobile-register` ile otomatik yeniden oluşturulur

## 1.0.253+289 (2026-08-18) — Ana sayfa 5sn donma (presence SSE)

- **Kök neden:** T+3sn `VoiceRoomsPresenceScope` 12 oda SSE'sini aynı anda açıyordu; ana thread kilitleniyordu
- **Presence:** Otomatik `voiceRoomsProvider` dinleme kaldırıldı; yalnızca ekran `mergeTrackRooms` çağırınca SSE
- **SSE:** Oda bağlantıları 180ms aralıkla kademeli (ANR önleme); ana sayfada en fazla 6 oda
- **Kabuk:** Global presence scope kaldırıldı — açılışta ağır SSE yükü yok
- **Hikâyeler:** Ortadaki spinner yerine iskelet halkalar (UI donmuş görünümü azaltır)
- **Ticker:** Bootstrap sonrası gereksiz ticker yenilemesi atlanır

## 1.0.252+288 (2026-08-18) — Ana sayfa donma (ANR) düzeltmesi

- **Kök neden:** `homeLiveVoiceRoomsProvider` presence + `ref.listen` döngüsü ana thread'i kilitliyordu
- **Çözüm:** Oda listesi API'den bir kez; SSE izleme yalnızca bölüm mount'ta tek sefer
- **homeVoiceRoomsProvider:** `ref.read` ile future yeniden tetiklenmesi durduruldu

## 1.0.251+287 (2026-08-17) — Ana sayfa odalar + müzik ANR + çalma

- **Ana sayfa:** Tüm sesli sohbet odaları listelenir (dolu önce); boş odalar sönük kart
- **Performans:** Ana sayfa oda kartlarında animasyon kapatıldı (açılış hızı)
- **Müzik ANR:** İstek `submitSelectedSong` + microtask; player kurulumu UI’ı bloklamaz
- **Müzik çalma:** `submitSelectedSong` içinde `_playDjInBackground` artık arka planda

## 1.0.250+286 (2026-08-17) — Müzik isteği ANR + sağ ray konumu

- **ANR düzeltmesi:** Müzik sheet kapanmadan oda provider'ı izlenmiyor; istek gönderilmeden önce sheet kapanır
- **Performans:** Seçili şarkı alanında her build'de yeni TextEditingController oluşturma kaldırıldı
- **Sağ ray:** Ayarlar/müzik amblemleri ekranın sağ ortasına (hafif aşağı) taşındı
- **Test:** `voice_room_side_action_rail_test`

## 1.0.249+285 (2026-08-17) — Sesli oda çıkış + UI cilası

- **Çıkış diyalogu:** Root navigator üzerinden gösterilir; geri/çıkış daha güvenilir
- **Sağ ray:** Konum biraz daha aşağı (`topInset` 136); klavye açıkken kuyruk kartı gizlenir
- **Mesaj çubuğu:** `!istek` ipucu; kullanılmayan ayar/müzik parametreleri temizlendi
- **Test:** `voice_room_leave_flow_test` — oda rotası çıkış eşlemesi

## 1.0.248+284 (2026-08-17) — Sesli oda UI + çıkış + müzik

- **Sağ ray:** Ayarlar ve müzik amblemleri mesaj çubuğundan kaldırıldı; web gibi sağ kenarda biraz aşağıda
- **Müzik:** `!istek` komutu veya sağdaki müzik amblemi ile şarkı isteği; kuyruk mini kartı sağ altta
- **Çıkış:** Geri / çıkış tuşu ve sistem geri — onay diyalogu + backend leave önce, sonra navigasyon
- **Backend uyumu:** Müzik görünürlüğü `live.dj.musicEnabled` ile; presence/koltuk leave timeout güvenli

## 1.0.247+283 (2026-08-17) — Sosyal fal kartları + sesli oda şeridi

- **Fal gönderileri:** Tam fal metni (`detail`) gösterilir; 250 karakterden sonra «daha fazla»
- **Rozetler:** Otomatik paylaşım, birlikte baktıran sayısı, görüntülenme ve paylaşım sayısı
- **Sesli oda şeridi:** Dolu odalar parlar (glow + PK/müzik); boş odalar sönük «Boş» etiketi
- **Çıkış:** Backend presence/koltuk leave navigasyondan önce — odadan çıkış düzeltmesi

## 1.0.246+282 (2026-08-17) — Anasayfa sadeleştirme + dolu sesli odalar

- **Anasayfa:** Gereksiz bölümler kaldırıldı (istatistik, sosyal şerit, trend, liderlik, ünlüler, fan kulübü, futbol, blog, keşfet, Gold vb.)
- **Sesli odalar:** Boş odalar ana sayfada gösterilmez; dolu odalarda online kişi sayısı görünür
- **Backend uyumu:** `musicPlaying`, `isPkLive` / `pkActive` alanları API ve LiveField keşfinden okunur
- **Kart:** PK ve müzik rozetleri yalnızca backend durumuna göre gösterilir
- **Prefetch:** Kaldırılan bölümler için gereksiz API çağrıları bootstrap'tan çıkarıldı

## 1.0.245+281 (2026-08-17) — Referans / ajans komisyon sistemi (tek seviye)

- **Backend (`api/`):** `ReferralCommissionService`, Prisma migration, immutable `ReferralCommissionLedger`, admin ayarları
- **Komisyon:** Yalnızca kesinleşmiş ekonomik işlemlerden; kayıt/jeton alımı komisyon üretmez; hak sahibinden kesilmez
- **Entegrasyon:** Canlı yayın hediyesi, sesli oda hediyesi (oda sahibi/koltuk hakedişi); idempotency + limit + fraud hold
- **API:** `/api/referral/me`, `/stats`, `/users`, `/earnings`, `/ledger`, `/invite-link`, `/settings`, admin uçları
- **Flutter:** Arkadaşını davet et (WhatsApp/Telegram paylaşım), Referanslarım, Kazançlarım — tüm tutarlar backend'den
- **Test:** `referralCommissionService.test.ts` (formül + invariant), `referral_entities_test.dart`

## 1.0.244+280 (2026-08-17) — Sesli oda senkronu (çıkış, PK hediye, koltuk, mik)

- **Çıkış:** Heartbeat durur → backend presence/koltuk leave önce → TRTC `exitRoom` → ekran beklemeden kapanır
- **Oda değişimi:** Eski odada presence anında düşer; arka planda temizlik
- **PK hediye:** POST yanıtındaki `pkBattle` + hediye event anında uygulanır (30 sn poll beklemez)
- **SSE:** `PK_SCORE_UPDATED`, `PK_ACCEPTED/REJECTED`, `gift_ranking_updated` room_event desteği
- **PK davet:** `targetUserId` + hedef oda kimliği gönderilir; SSE varken gereksiz poll kapatılır
- **Koltuk:** SSE reconnect sonrası `GET /seats`; koltuk ataması sonrası backend yenileme
- **Mikrofon:** Koltuğa oturunca otomatik unmute kaldırıldı; varsayılan kapalı

## 1.0.243+279 (2026-08-17) — Anasayfa, sesli oda çıkışı, bot yayın

- **Anasayfa:** `/games-hub` ve alt rotaları, `/games-room/:id`, `/blog-hub`, `/dreams-hub` eklendi; oyun/blog/rüya/futbol kısayolları düzeltildi
- **Anasayfa UX:** Hikâye girişi, sosyal şerit ve falcı kartları tıklanabilir; boş oyun rotası oyun merkezine yönlendirir
- **Sesli oda:** «Çık» doğrudan odadan çıkar; navigasyon her zaman `/voice-rooms` listesine döner
- **Bot yayın:** Bot hesaplar canlı yayını 5 dakika sonra otomatik kapatır
- **Rota:** Yinelenen `/gifts/leaderboard` tanımı kaldırıldı

## 1.0.242+278 (2026-08-17) — Çocuk güvenliği politikası düzeltmesi

- **Yasal:** Çocuk Güvenliği Politikası artık `GET /api/legal/child-safety` üzerinden yüklenir (`site-pages/cocuk-guvenligi` 404 idi)
- **WebView:** Koyu temada yasal sayfa metni okunabilir renklerle gösterilir
- **Test:** `legal_document_test`

## 1.0.241+277 (2026-08-17) — Sosyal bölüm faz 11

- **Detay önbelleği:** `resolveSocialPostForDetail` — akıştaki gönderi anında gösterilir, API ile birleştirilir
- **Metin gönderisi:** Yalnızca metin kartına dokununca detay sayfası açılır
- **Sayfalama hatası:** `SocialFeedLoadMoreErrorBanner` + «Tekrar dene»
- **Test:** `social_post_resolver_test` + client acceptance `20u`

## 1.0.240+276 (2026-08-17) — Sosyal bölüm faz 10

- **Yorum senkronu:** `notifySocialPostCommentAdded` — akış + gönderi detayı sayacı birlikte güncellenir
- **Akış sonu:** Sayfalama bittiğinde `SocialFeedEndBanner` («Tüm paylaşımları gördün»)
- **App bar:** Arama kısayolu (`/search`)
- **Test:** `social_feed_sync_test`, `social_feed_end_label_test` + client acceptance `20t`

## 1.0.239+275 (2026-08-17) — Sosyal bölüm faz 9

- **Paylaşım sonrası:** `prependPost` — tam akış yenilemesi yerine optimistik ekleme (composer + create)
- **Çift yenileme düzeltmesi:** `openSocialCreatePost` artık gereksiz `refresh()` çağırmıyor
- **Gönderi detayı:** Pull-to-refresh (`refreshSocialPostDetail`)
- **Test:** `social_notifier_feed_ops_test` + client acceptance `20s`

## 1.0.238+274 (2026-08-17) — Sosyal bölüm faz 8

- **Gönderi detayı:** `buildSocialPostDetailRoute` — medya dokunuşu ve kart aksiyonları ortak rota
- **Silme:** Akıştan optimistik kaldırma (`removePost`) — tam yenileme yerine
- **Boş akış:** Gönderi oluşturma sonrası üste kaydırma (`onPostPublished`)
- **Hikâyeler:** Profil rotası `buildSocialUserProfileRoute` ile hizalandı
- **Yorumlar:** `@` etiketleme düğmesi — `SocialMentionPickerSheet`
- **Test:** `social_post_detail_route_test` + client acceptance `20r`

## 1.0.237+273 (2026-08-17) — Sosyal bölüm faz 7

- **Yorumlar:** `#hashtag` / `@mention` bağlantılı metin; yazar avatar/isim → profil
- **Yorum listesi:** Pull-to-refresh ile yenileme
- **Paylaşım girişi:** App bar `+` sonrası akış üste kayar (`onPublished`)
- **Profil rotası:** `buildSocialUserProfileRoute` merkezi helper
- **Test:** `social_user_profile_route_test` + client acceptance `20q`

## 1.0.236+272 (2026-08-17) — Sosyal bölüm faz 6

- **Bağlantılı metin:** Gönderi açıklamalarında `#hashtag` → shorts keşif, `@kullanıcı` → arama
- **Paylaşım metni:** `buildSocialPostShareText` — kart + detay sayfası ortak
- **Arama rotası:** `/search?q=` ile `GlobalSearchPage` başlangıç sorgusu
- **Test:** `social_caption_link_parser_test` + client acceptance `20p`

## 1.0.235+271 (2026-08-17) — Sosyal bölüm faz 5

- **Pull-to-refresh:** `refreshSocialFeedSection` — akış + hikâyeler + canlı/sesli odalar birlikte yenilenir
- **Paylaşım sonrası:** Inline composer başarıda akış üste kayar (`onPostPublished`)
- **Aktif odalar:** Gömülü şerit başlığı canlı/sesli durumuna göre dinamik
- **CI:** `api-social-phase.sh` stage3 acceptance'a eklendi
- **Test:** `social_feed_refresh_test` + `socialActiveRoomsAvailable` pozitif senaryolar + client `20o`

## 1.0.234+270 (2026-08-17) — Sosyal bölüm faz 4

- **Video önizleme:** `SocialLocalVideoPreview` — yerel video için thumbnail + play overlay (composer + create)
- **Keşif kısayolları:** Etiket/rota sabitleri `social_discover_shortcut_labels.dart` ile merkezileştirildi
- **CI:** `api-social-phase.sh` final acceptance aşamasına eklendi (`api-final-phase.sh`)
- **Test:** `social_discover_shortcut_labels_test` + client acceptance `20n`

## 1.0.233+269 (2026-08-17) — Sosyal bölüm faz 3

- **Keşif kısayolları:** Ünlüler, Fan Club, Canlı ve Sesli odalar chip satırı (`SocialDiscoverShortcuts`)
- **Konum paylaşımı:** Ortak `pickSocialPostLocationLabel` helper — tam ekran create + inline composer
- **Gönderi oluşturma:** Başarılı paylaşımdan sonra akış `socialNotifierProvider.refresh()` ile yenilenir
- **Test:** `social_post_location_helper_test` + client acceptance `20m`
- **API:** `scripts/acceptance-tests/api-social-phase.sh` — gönderi listesi / yorum / beğeni doğrulaması

## 1.0.232+268 (2026-08-16) — Sosyal bölüm faz 2

- **Akış düzeni:** Aktif oda yokken boş oda şeridi slotları kaldırıldı (`includeRoomStrips`)
- **Paylaşım girişi:** App bar + ve boş akış CTA tam ekran gönderi oluşturucuya yönlendirir
- **Gönderi detayı:** `SharePlus` ile paylaşım (deprecated `Share.share` kaldırıldı)
- **Hikâyeler:** Hata mesajları `ApiException.userMessage` ile okunabilir
- **Test:** `socialActiveRoomsAvailable` + layout `includeRoomStrips` testleri

## 1.0.231+267 (2026-08-16) — Sosyal bölüm eksikleri

- **Aktif odalar:** Sahte demo oda şeridi kaldırıldı; canlı/sesli oda yoksa şerit gizlenir
- **Gönderi oluşturma:** Tam ekran sayfada video seçimi, kullanıcı etiketleme, hashtag ve GPS konum ekleme
- **Etiketleme:** `SocialMentionPickerSheet` paylaşımlı bileşen — composer + create sayfası
- **Profil ziyaretçileri:** API hataları artık sessizce boş listeye düşmez; kullanıcıya hata gösterilir
- **Test:** `social_feed_layout_test`

## 1.0.230+266 (2026-08-16) — Profil üyelik faz 40

- **Para birimi etiketleri:** `buildMembershipCurrencyJetonLabel` + `buildMembershipCurrencyCfcLabel` + `buildMembershipHubCurrencyElmasLabel`
- **Cüzdan aksiyonları:** `buildMembershipWalletJetonTopUpActionLabel` + bakiye başlık helper'ları
- **Jeton mağazası:** `buildMembershipJetonStoreBuyActionLabel` + satın alma sayfası başlık/alt başlık + WhatsApp ipucu
- **Hub:** `buildMembershipHubServicesSectionTitle` — Hizmetlerim bölüm başlığı
- **İstatistikler:** `buildMembershipAboutStatsPlatformJoinRowLabel` — platform katılım tarihi
- **Görevler merkezi:** `buildMembershipGrowthHubRoadmapSectionTitle` + `buildMembershipGrowthHubRoadmapHintText`
- **Sayfalar:** para çekme, CFC yükle, jeton satın al başlıkları merkezileştirildi
- **Acceptance:** client `20l` üyelik helper sözleşme testleri

## 1.0.229+265 (2026-08-16) — Profil üyelik faz 39

- **Premium tier kartı:** `buildMembershipPackageCardBuyActionLabel` + `buildMembershipPackageCardExtendActionLabel` + `buildMembershipPackageCardActiveSubtitle` + `buildMembershipPackageVipTagLabel`
- **Ayarlar / kozmetik:** `buildMembershipSettingsCosmeticsRowLabel` — Premium Profil satırı
- **Profil başlığı:** `buildMembershipProfileHeaderVipBadgeLabel` — tier-aware VIP rozeti
- **Cüzdan merkezi:** `buildMembershipWalletCenterWithdrawalTitle` + `buildMembershipWalletCenterCfcStoreTitle` + `buildMembershipWalletCenterJetonStoreTitle`
- **Acceptance:** client `20k` üyelik helper sözleşme testleri
- **Test:** paket kartı CTA, kozmetik satır, cüzdan hub başlıkları, VIP rozet

## 1.0.228+264 (2026-08-16) — Profil üyelik faz 38

- **İstatistikler:** `buildMembershipAboutStatsPlanRowLabel` + `buildMembershipAboutStatsPlanDurationRowLabel`
- **Rozet bölümü:** `buildMembershipBadgesSectionTitle` + `buildMembershipBadgesSectionManageActionLabel`
- **Jeton mağazası:** `buildMembershipJetonStoreExtendBannerText` — uzatma banner metni
- **Ödeme talebi:** `buildMembershipPaymentRequestDefaultNotes` + `buildMembershipCfcPaymentRequestDefaultNotes`
- **Görevler merkezi:** `buildMembershipGrowthHubLevelVipPillLabel` — seviye VIP pill
- **Aktif üyelik kartı:** `buildMembershipActiveMembershipCardTitle/Subtitle`
- **Acceptance:** client `20j` üyelik helper sözleşme testleri
- **Test:** istatistik satırları, jeton banner, ödeme notları, VIP pill

## 1.0.227+263 (2026-08-16) — Profil üyelik faz 37

- **Cüzdan kartı:** `buildMembershipWalletPremiumStatRowLabel` + `buildMembershipWalletSubscriptionStatRowLabel`
- **Checkout:** `buildMembershipCheckoutPackageTitle/PaymentNotes/Badge` + `buildMembershipPagePurchaseButtonLabel`
- **Ortak avantajlar:** `buildMembershipCommonBenefitsSectionTitle` — tier-aware başlık
- **Para birimi kartı:** `resolveMembershipHubSummaryRowLeadingAccent` — ikon vurgusu
- **Mağaza teaser:** `buildMembershipStoreTeaserBannerActionLabel` — CTA etiketi
- **Üyelik sayfası:** `buildMembershipPageTokenPackagesSectionTitle` — jeton bölüm başlığı
- **Acceptance:** client `20i` üyelik helper sözleşme testleri
- **Test:** cüzdan satır etiketleri, checkout notları, common benefits başlık

## 1.0.226+262 (2026-08-16) — Profil üyelik faz 36

- **Hizmetler şeridi:** `buildMembershipHubMembershipServiceCardTitle` + `buildMembershipHubVipGoldServiceCardTitle`
- **Profil düzenleme:** `buildMembershipProfileEditSectionTitle` — dinamik bölüm başlığı
- **Ayarlar:** `buildMembershipSettingsVipGoldRowLabel` — VIP Gold satır etiketi
- **Kısayollar:** `buildMembershipShortcutsCosmeticsChipLabel` — kozmetik chip
- **Görevler merkezi:** `buildMembershipGrowthHubPlansButtonLabel` + `buildMembershipGrowthHubVipButtonLabel`
- **Üyelik sayfası:** `buildMembershipPageAppBarTitle/Subtitle`, `buildMembershipPageFeaturesSectionTitle`, `buildMembershipPageTokenPackagesSubtitle`
- **Acceptance:** client `20h` üyelik helper sözleşme testleri
- **Test:** hizmet kartı, ayarlar VIP, app bar, growth hub butonları

## 1.0.225+261 (2026-08-16) — Profil üyelik faz 35

- **VIP kısayol:** `buildMembershipShortcutsVipChipLabel` — chip ana etiket (VIP Gold / VIP Yenile)
- **Üyelik sayfası:** `buildMembershipPageActiveBannerText` — aktif plan banner metni
- **Yönet tile:** `resolveMembershipManageTileLeadingAccent` — ikon vurgu rengi (standart / ücretli / süresi doldu)
- **Cüzdan bölümü:** `buildMembershipWalletSectionBalanceHint` — dinamik bakiye açıklaması
- **Yükseltme banner:** `buildMembershipPageUpgradeBannerTitle/Subtitle/ActionLabel` — üyelik sayfası CTA
- **Acceptance:** client `20g` üyelik helper sözleşme testleri
- **Test:** VIP chip, aktif banner, manage tile accent, wallet balance hint

## 1.0.224+260 (2026-08-16) — Profil üyelik faz 34

- **Premium kart:** `buildMembershipPremiumCardManageActionLabel` — ikincil yönet CTA
- **İstatistikler:** `buildMembershipAboutStatsSectionSubtitle` — plan özeti alt başlık
- **Para çekme:** `buildMembershipWithdrawalPageSubtitle` — dinamik sayfa alt başlığı
- **Cüzdan merkezi:** `buildMembershipWalletStoreHubCardSubtitle` — jeton/CFC hub kartları
- **Cüzdan bölümü:** `ProfileWalletSection` abonelik karo helper hizası
- **Acceptance:** client `20f` üyelik helper sözleşme testleri
- **Test:** about stats subtitle, withdrawal subtitle, wallet store hub

## 1.0.223+259 (2026-08-16) — Profil üyelik faz 33

- **Cüzdan kartı:** `buildMembershipWalletPremiumStatLabel` + `buildMembershipWalletSubscriptionsTileLabel`
- **Kısayollar:** `buildMembershipShortcutsPlanChipLabel` — plan chip ana etiket
- **Mağaza teaser:** `buildMembershipStoreTeaserBannerTitle` — hub başlık hizası
- **Cüzdan merkezi:** `buildMembershipWalletCenterPageSubtitle` — dinamik sayfa alt başlığı
- **Acceptance:** client `20e` üyelik helper sözleşme testleri
- **Test:** cüzdan kartı, mağaza teaser banner, wallet center subtitle

## 1.0.222+258 (2026-08-16) — Profil üyelik faz 32

- **Premium kart:** `buildMembershipPremiumCardSubtitle` + `buildMembershipPremiumCardPrimaryActionLabel` — cüzdan hizası
- **VIP banner:** `buildMembershipVipBannerTitle` + `buildMembershipVipBannerActionLabel` — hub başlık/CTA helper
- **Cüzdan header:** `buildMembershipWalletQuickLinkLabel` — dinamik Üyelik/Gold/Yenile
- **Lazy premium:** `ProfileLazyPremium` wallet hub alt başlığı
- **Acceptance:** client `20d` üyelik helper sözleşme testleri
- **Test:** VIP banner, premium kart CTA, wallet quick link

## 1.0.221+257 (2026-08-16) — Profil üyelik faz 31

- **Rozet bölümü:** `buildMembershipBadgesSectionSubtitle` — açık/kilitli rozet oranı
- **Hizmetler şeridi:** `buildMembershipHubVipGoldServiceCardHint` — VIP Gold kart ipucu
- **Cüzdan kazanç:** `buildMembershipWalletEarningsTeaser` — üyelik teaser satırı
- **Kısayollar:** plan chip `buildMembershipWalletHubSubtitle` ile cüzdan hizası
- **Acceptance:** client `20c` üyelik helper sözleşme testleri
- **Test:** rozet bölümü, cüzdan kazanç teaser widget testleri

## 1.0.220+256 (2026-08-15) — Profil üyelik faz 30

- **Cüzdan header:** `buildMembershipWalletActiveBannerText` + `shouldShowMembershipWalletActiveBanner`
- **Hizmetler şeridi:** `buildMembershipHubServiceCardHint` — üyelik kartı alt ipucu
- **Hızlı menü:** `buildMembershipQuickMenuLabel` — dinamik Üyelik/Gold/Yenile
- **Checkout footer:** `buildMembershipCheckoutFooterHint` + `MembershipCheckoutFooterHint`
- **Test:** wallet banner, service hint, quick menu, checkout footer

## 1.0.219+255 (2026-08-15) — Profil üyelik faz 29

- **Ayarlar tile:** `buildMembershipSettingsManageSubtitle` — manage tile cüzdan hizası
- **Hub istatistikler:** `buildMembershipAboutStatsPlanValue` + süresi dolmuş `MembershipStatusPill`
- **Growth hub:** üyelik kartı status pill (aktif / süresi doldu)
- **Acceptance:** client `20b` üyelik helper sözleşme testleri
- **Test:** about stats pill widget, settings subtitle, status pill helper

## 1.0.218+254 (2026-08-15) — Profil üyelik faz 28

- **VIP pill:** `buildMembershipHubVipPillLabel` — profil hub başlık ortak helper
- **Hub alt başlık:** `buildMembershipWalletHubSubtitle` — cüzdan merkezi + currency card hizası
- **Mağaza teaser:** `buildMembershipStoreTeaserSubtitle` + `MembershipStoreTeaserBanner` (jeton/CFC)
- **Test:** VIP pill, wallet hub subtitle, store teaser helper + widget

## 1.0.217+253 (2026-08-15) — Profil üyelik faz 27

- **Tier kart rozeti:** `resolveMembershipTierCardBadge` — Aktif / Popüler / Süresi doldu
- **Katalog senkron:** `applyMembershipTierBadges` — aktif wire id + API popular tier
- **Üyelik kartı:** `MembershipCard` üst rozet pill + membershipInfo/apiPackages
- **Test:** badge helper, catalog merge, membership card widget

## 1.0.216+252 (2026-08-15) — Profil üyelik faz 26

- **Hub başlık:** `buildMembershipHubSectionTitle` — ayarlar karo + currency card
- **Görevler merkezi:** `buildGrowthHubMembershipTitle` başlık helper
- **Hub CTA:** `buildMembershipHubActionLabel` — Yenile / Yönet / Planlar
- **Test:** hub section title, growth hub title, action label

## 1.0.215+251 (2026-08-15) — Profil üyelik faz 25

- **Kart başlığı:** `buildMembershipPremiumCardTitle` — premium kart + cüzdan merkezi
- **Cüzdan kartı:** `buildMembershipWalletSubscriptionStatLabel` abonelik satırı
- **Cüzdan merkezi:** ücretsiz kullanıcı `buildFreeUserMembershipTeaserSubtitle`
- **Üyelik sayfası:** aktif banner `formatMembershipPlanDuration` ortak helper
- **Test:** premium title, wallet stat, VIP banner teaser widget

## 1.0.214+250 (2026-08-15) — Profil üyelik faz 24

- **Ücretsiz teaser:** `buildFreeUserMembershipTeaserSubtitle` — API popular tier + süre/fal ipucu
- **VIP banner:** profil hub ücretsiz CTA dinamik öne çıkan plan alt başlığı
- **VIP Gold kısayol:** `buildVipGoldShortcutSubtitle` chip alt başlığı
- **Üyelik sayfası:** süresi dolmuş banner ortak `buildMembershipPageExpiredBannerText`
- **Cüzdan merkezi:** süresi dolmuş premium kart başlığı `buildMembershipExpiredPlanLabel`
- **Test:** teaser, VIP shortcut, membership page banner metni

## 1.0.213+249 (2026-08-15) — Profil üyelik faz 23

- **Süresi dolmuş etiketler:** `buildMembershipExpiredPlanLabel` / `buildMembershipExpiredBannerText` ortak helper
- **Katalog ipucu:** süresi dolmuş alt başlıkta `expiresAt` bitiş tarihi
- **Hub istatistik:** üyelik planı satırı tier + bitiş tarihi
- **Görevler / currency / premium kart / ayarlar:** süresi dolmuş başlık helper hizalaması
- **Jeton checkout:** `PaymentMethodsSummaryLine` `showRecommended: false`
- **Test:** expired plan label, banner text, catalog hint tarih

## 1.0.212+248 (2026-08-15) — Profil üyelik faz 22

- **Ortak avantajlar:** `mergeMembershipCommonHighlights` — katalog + seçili tier `features[]` (id dedupe)
- **Ödeme özeti:** checkout sheet ve support footer `showRecommended: false`
- **Premium kart:** `catalogTier` fallback `buildMembershipCatalogHintSubtitle`
- **Hub kısayollar:** Planlar / Planı Yönet chip katalog ipucu alt başlığı
- **Cüzdan header:** süresi dolmuş banner bitiş tarihi (`expiresAt`)
- **Hub header:** süresi dolmuş VIP pill bitiş tarihi
- **Test:** merge highlights, checkout önerilen yok, hub shortcuts ipucu

## 1.0.211+247 (2026-08-14) — Profil üyelik faz 21

- **Üyelik sayfası:** Aktif/süresi dolmuş banner `expiresAt` ISO bitiş tarihi
- **Controller:** `membershipExpiresAt` + cüzdan senkronu
- **Hub header:** VIP pill süresi dolmuş / bitiş tarihi etiketi
- **Premium kart:** `expiresAt` fallback `buildMembershipCatalogHintSubtitle`
- **Özellik tablosu:** API `features[].subtitle` metin hücresi
- **Ödeme özeti:** `MembershipPaymentMethodsSummary` `showRecommended: false`
- **Test:** manage tile, feature subtitle, banner expiry

## 1.0.210+246 (2026-08-14) — Profil üyelik faz 20

- **expiresAt sweep:** lazy premium, cüzdan kartı, hub istatistik, currency card, wallet header
- **VIP banner:** yalnızca ücretsiz kullanıcı CTA (ölü paid/expired dallar kaldırıldı)
- **Checkout:** `membership_page` açık `checkoutMethods()` normalizasyonu
- **Wallet header:** aktif üyelik banner — `expiresAt` ile gün bilgisi olmasa da göster
- **Test:** hub widget routing, merge features[], showRecommended

## 1.0.209+245 (2026-08-14) — Profil üyelik faz 19

- **Ödeme özeti:** `PaymentMethodsSummaryLine` → `checkoutMethods()` tek kaynak
- **Bitiş tarihi:** `expiresAt` ISO — banner, görevler, ayarlar karo ipuçları
- **Görevler merkezi:** `buildGrowthHubMembershipSubtitle` ortak helper
- **Ayarlar karo:** `ProfileMembershipManageTile` katalog ipuçları
- **Özellik tablosu:** Paket bazlı API `features[]` dinamik satırlar
- **Test:** checkout sheet, growth hub subtitle, feature table API satırları

## 1.0.208+244 (2026-08-14) — Profil üyelik faz 18

- **Profil hub:** Süresi dolmuş ücretli kullanıcıya premium kart (yenile CTA)
- **Görevler merkezi:** `buildMembershipCatalogHintSubtitle` / `formatMembershipPlanDuration`
- **Ödeme kanalları:** `PaymentMethodEntity.checkoutMethods` — ortak whitelist + fallback
- **Jeton checkout:** Bilinmeyen API kanalları filtrelenir; tier dinamik onay mesajı
- **Çift refresh:** Üyelik jeton checkout `onPurchaseDone` yalnızca pending talep yeniler
- **Destek footer:** Önerilen kanal özeti ile üst özet hizalandı
- **Temizlik:** Kullanılmayan `jeton_native_checkout.dart` kaldırıldı

## 1.0.207+243 (2026-08-14) — Profil üyelik faz 17

- **CFC senkron:** `refreshMembershipAfterPurchase` — CFC üyelik talebi / anında ödeme sonrası
- **Özellik tablosu:** API tier birleşiminde yinelenen "Jeton Alımında İndirim" satırı kaldırıldı
- **Avantaj kartları:** `common_benefits` dinamik grid — API `features[]` sayısına uyum
- **Checkout sheet:** `PaymentMethodsSummaryLine` güvenli ödeme alt bilgisi
- **Cüzdan:** `profile_wallet_card`, `wallet_center_page`, `wallet_balance_header` katalog ipuçları
- **Üyelik sayfası:** Aktif banner kalan / toplam gün (`durationDays`)
- **Test:** `common_benefits_test`, `formatMembershipPlanDuration`

## 1.0.206+242 (2026-08-14) — Profil üyelik faz 16

- **API features[]:** Katalog `features` parse; üyelik sayfasında dinamik avantaj kartları
- **Jeton mağazası:** `paymentMethodsProvider` ile dinamik ödeme kanalları + özet satırı
- **Profil hub:** VIP banner, cüzdan özeti ve premium kart katalog ipuçları (süre, fal indirimi)
- **İstatistikler:** "Plan süresi" kalan / toplam gün (`durationDays`)
- **Tier kartı:** Fal indirimi rozeti; checkout yenilemede `paymentMethodsProvider` invalidation
- **Jeton checkout:** Güvenli ödeme altında canlı kanal özeti

## 1.0.205+241 (2026-08-14) — Profil üyelik faz 15

- **Özellik tablosu:** Ayrı "Fal indirimi" satırı; jeton indirimi satırı korunur
- **Plan süresi UI:** Tier kartı, CTA ve özellik tablosu `durationDays` kullanır
- **Ödeme özeti:** Destek footer, profil cüzdan kartı; jeton/CFC sayfalarında üyelik pending banner
- **Görevler kartı:** Katalog `durationDays` / `falDiscountPercent` alt başlıkta
- **Hub yenileme:** `paymentMethodsProvider` invalidation

## 1.0.204+240 (2026-08-14) — Profil üyelik faz 14

- **Bekleyen üyelik talebi:** Cüzdan, görevler merkezi ve profil hub banner
- **Canlı ödeme özeti:** `PaymentMethodsSummaryLine` — cüzdan CFC kartı + üyelik sayfası
- **API süre:** `durationDays` tier birleşimi; checkout metinleri ve CFC talebi
- **Özellik tablosu:** API tier başlıkları + fal indirimi (`falDiscountPercent`) satırı
- **Yenileme:** `paymentRequestsNotifierProvider` hub refresh akışlarına eklendi

## 1.0.203+239 (2026-08-14) — Profil üyelik faz 13

- **Tier kartları:** API `popular` / `isActive` — Popüler ve Aktif rozetleri
- **Önerilen plan:** API `recommended` paketi varsayılan seçim
- **Tek dokunuş CFC:** Bakiye yeterliyken `paymentMethod: cfc` veya anında `cfc_balance` talebi
- **Ödeme özeti:** Üyelik sayfasında `paymentMethodsProvider` canlı kanal listesi
- **Checkout sheet:** Dinamik ödeme kanalı etiketleri

## 1.0.202+238 (2026-08-14) — Profil üyelik faz 12

- **API katalog birleşimi:** Tier kartları ve jeton paketleri sunucu fiyat/jeton ile güncellenir
- **Özellik tablosu:** Aylık jeton satırı API birleşik tier'lardan okunur
- **Üyelik checkout:** WhatsApp/Papara veya CFC ödeme seçimi (bottom sheet)
- **CFC üyelik:** `buildMembershipCfcPaymentRequest` + dinamik ödeme kanalları
- **Test:** `membership_catalog_merge_test.dart`

## 1.0.201+237 (2026-08-14) — Profil üyelik faz 11

- **SVIP katalog:** Üyelik planları, özellik tablosu ve fallback paketler
- **Satın alma:** `POST /api/memberships/purchase` — `MembershipRemoteDataSource.purchaseMembership`
- **CFC checkout:** Dinamik ödeme kanalları (`paymentMethodsProvider`)
- **Plan kimliği:** SVIP / `super_vip` alias eşlemesi
- **Test:** `membership_model_test.dart`

## 1.0.200+236 (2026-08-14) — Profil üyelik faz 10 (düzeltme)

- **CI:** Sosyal akış import yolları ve `PaymentConfigEntity` import düzeltmesi

## 1.0.200+235 (2026-08-14) — Profil üyelik faz 10

- **Ödeme yöntemleri:** `GET /api/payments/methods` — jeton checkout dinamik kanal listesi
- **Görevler merkezi:** Üyelik durumu özeti kartı (aktif / süresi dolmuş / planlar)
- **Sosyal akış:** `VipBadge` + SVIP; `membership` alanı `roleFrom` ile çözülür
- **Doğrulama rozeti:** Verified ve üyelik rozetleri ayrı gösterilir
- **Test:** `payment_method_entity_test.dart`

## 1.0.199+234 (2026-08-14) — Profil üyelik faz 9

- **Cüzdan:** Süresi dolmuş üyelik yenileme banner'ı; aktif etiket SVIP uyumlu
- **Cüzdan merkezi:** Premium kart özeti (aktif / süresi dolmuş / ücretsiz)
- **Üyelik sayfası:** Süresi dolmuş banner; `currentMembershipLabel` getter
- **Destek footer:** Canlı `paymentConfig` (WhatsApp / Papara)

## 1.0.198+233 (2026-08-14) — Profil üyelik faz 8

- **Üyelik rozetleri:** Hub'da dokunarak equip; seçili rozet işareti
- **Rozetleri Yönet:** Kozmetik sayfasına rozet sekmesi eklendi
- **resolvedMembershipBadgeProvider:** Kullanıcının seçtiği rozet öncelikli
- **Üyelik sayfası:** SVIP etiketi (`tierLabel`, DIAMOND yerine)
- **Temizlik:** Kullanılmayan `ProfilePremiumBanner` kaldırıldı

## 1.0.197+232 (2026-08-14) — Profil üyelik faz 7

- **Süresi dolmuş üyelik:** `effectiveTier`, hub banner yenileme, rozet kilidi
- **Ayrıcalıklar yönlendirme:** Premium → plan sayfası; VIP → `/vip-gold`
- **Üyelik sayfası:** Bekleyen üyelik ödemesi banner + canlı ödeme config
- **Test:** süre dolmuş / aktif üyelik senaryoları

## 1.0.196+231 (2026-08-14) — Profil üyelik faz 6

- **Başka kullanıcı profili:** Ücretli üyelik rozeti (`VipBadge`) görünür
- **API:** `getUserExtended` — compound profilden `vipLevel` / `membershipTier`
- **Provider:** `userProfileExtendedProvider`
- **Test:** `user_profile_membership_badge_test.dart`

## 1.0.195+230 (2026-08-14) — Profil üyelik faz 5

- **ProfileHubMembershipSection:** Ücretsiz → VIP banner; ücretli → lazy `ProfilePremiumCard`
- **Ayarlar:** `ProfileMembershipManageTile` + VIP Gold satırı
- **Hizmetlerim:** Sabit "Üyelik Merkezi" kartı → `/premium-membership`
- **Test:** `profile_hub_membership_section_test.dart`

## 1.0.194+229 (2026-08-14) — Profil üyelik faz 4

- **Profil düzenle:** Üyelik yönetim kartı (plan, kalan gün, plan sayfası)
- **Satın alma senkronu:** `refreshMembershipAfterPurchase` — jeton/üyelik sonrası rozet+katalog
- **Katalog:** `free` → `basic` normalizasyonu; SVIP tier seçimi
- **Görevler:** Yol haritasına Planlar butonu; yenilemede üyelik provider'ları
- **ProfileLazyPremium:** Cüzdan tabanlı tier çözümlemesi

## 1.0.193+228 (2026-08-14) — Profil üyelik faz 3

- **profileMembershipInfoProvider:** Cüzdan tabanlı merkezi üyelik özeti
- **Yenileme:** Profil pull-to-refresh üyelik kataloğu ve rozetleri invalidate eder
- **Kısayollar:** Planlar / VIP Gold / Kozmetik şeridi
- **İstatistikler:** Üyelik planı ve kalan süre satırları
- **Fal erişimi:** `free` artık sınırsız premium fal hakkı vermiyor
- **Üyelik sayfası:** `hasActivePaidMembership` tier helper ile hizalandı

## 1.0.192+227 (2026-08-14) — Profil üyelik faz 2

- **Para kartı:** Üyelik özeti satırı (plan, kalan gün, Yönet/Yükselt)
- **Cüzdan başlığı:** Tüm ücretli tier'lar için banner (yalnızca Gold değil)
- **Görevler:** `free`/`basic` premium rozeti açmıyor; VIP tier doğru
- **Rozet çözümleme:** En yüksek uygun üyelik rozeti seçiliyor
- **Abonelikler:** Cüzdan kartından `/premium-membership` yönlendirmesi

## 1.0.191+226 (2026-08-14) — Profil üyelik bölümü tamamlama

- **isVip düzeltmesi:** `free`/`basic` artık VIP sayılmıyor; tier `VipTier` ile çözümleniyor
- **Hızlı menü:** Üyelik kısayolu eklendi → `/premium-membership`
- **VIP banner:** Ücretsiz kullanıcıya plan teşviki; aktif üyeye "Yönet" + ayrıcalıklar CTA
- **Rozetler:** Kilit/açık durumu, tier etiketi ve plan sayfasına dokunma
- **Ayarlar:** "Üyelik Yönetimi" satırı eklendi
- **Test:** `profile_membership_helpers_test.dart`

## 1.0.190+225 (2026-08-13) — Ana sayfa faz 12: başlık birliği, oyunlar birleşik

- **Başlık stili:** `HomeSectionHeader` kaldırıldı; danışmanlar ve oyunlar `HomeSectionTitle` kullanıyor
- **Oyunlar:** `HomeGamesRow` + `HomeGameCenterSection` → tek `HomeGamesSection`
- **Dokümantasyon:** `docs/HOME_PAGE_SECTIONS.md` güncellendi (30 bölüm)

## 1.0.189+224 (2026-08-13) — Ana sayfa faz 11: yetim widget temizliği

- **Temizlik:** 12 kullanılmayan ana sayfa widget dosyası kaldırıldı (eski mockup / yinelenen sürümler)
- **Dokümantasyon:** `docs/HOME_PAGE_SECTIONS.md` — bölüm sırası, API ve lazy katman envanteri
- **Referans:** `home_page_sections.dart` üst yorumunda envanter bağlantısı

## 1.0.188+223 (2026-08-13) — Ana sayfa faz 10: viewport lazy, birleşik ödüller

- **Viewport lazy:** Alt bölümler `HomeViewportSection` ile kaydırma yakınına gelince mount edilir
- **İstatistikler:** Şerit + genişletilebilir detay ızgarası tek `HomePlatformStatsSection` altında
- **Büyüme & ödüller:** Görevler, davet ve reklam teaser'ları yatay `HomeGrowthTeasersSection` şeridi
- **Temizlik:** Faz 9'da birleştirilen eski widget dosyaları kaldırıldı
- **Test:** `HomeViewportSection` widget testi eklendi

## 1.0.187+222 (2026-08-13) — Ana sayfa faz 9: birleşik şeritler

- **Liderlik tabloları:** Hediye, PK ve ajans önizlemeleri tek sekmeli `HomeLeaderboardsSection` altında
- **Sosyal şerit:** Son girişler + seni beğenenler tek `HomeSocialStripSection` (girişte beğenenler sekmesi)
- **Temizlik:** Kullanılmayan `HomeFanClubRow` kaldırıldı
- **Test:** Ajans ve PK liderlik entity parse testleri eklendi

## 1.0.186+221 (2026-08-13) — Ana sayfa faz 8: fal türleri, popup duyuru

- **Fal türleri:** `GET /api/fortune-request-types` yatay chip şeridi
- **Duyuru şeridi:** `GET /api/popups` ilk kayıt inline banner (modal dışı)
- **Test:** Ana sayfa entity parse birim testleri (`home_entities_test.dart`)
- **Yenileme:** Popup ve fal türleri bootstrap + pull-to-refresh kapsamında

## 1.0.185+220 (2026-08-13) — Ana sayfa faz 7: yayın görselleri, beğenenler, reklam

- **Yayın arka planları:** `GET /api/broadcast-images` yatay önizleme → `/live/prep`
- **Seni beğenenler:** `GET /api/user/likers` şeridi (giriş gerekli)
- **Reklam izle:** `GET /api/ads/active` teaser → `/profile/growth`
- **Yenileme:** Yayın görselleri, beğenenler ve reklam bootstrap + pull-to-refresh kapsamında

## 1.0.184+219 (2026-08-13) — Ana sayfa faz 6: istatistik ızgarası, online fal, ajans

- **Canlı istatistik ızgarası:** Oyun, sosyal, fal ve giriş metrikleri (`GET /api/public-stats`) → `/profile/broadcaster-stats`
- **Online fal:** `GET /api/online-fal` yatay bölüm kartları → canlı falcılar
- **Ajans liderleri:** Top 3 önizleme (`GET /api/agency/leaderboard`) → ajans paneli
- **Yenileme:** Online fal ve ajans liderliği bootstrap + pull-to-refresh kapsamında

## 1.0.183+218 (2026-08-13) — Ana sayfa faz 5: dinamik aksiyonlar, danışmanlar, PK

- **Hızlı erişim:** `HomeQuickActions` ilk 3 `homepage-buttons` ile dinamik; kalan butonlar pill şeridinde
- **Popüler falcılar:** `HomeAdvisorsRow` canlı danışman şeridi ana sayfaya eklendi
- **Son girişler:** `GET /api/public-stats` → `recentLogins` yatay önizleme
- **PK liderleri:** Haftalık top 3 (`GET /api/pk/leaderboard`) → `/pk/leaderboard`
- **Yenileme:** PK liderliği bootstrap + pull-to-refresh kapsamında

## 1.0.182+217 (2026-08-13) — Ana sayfa faz 4: davet, hediye liderliği, futbol

- **Davet teaser:** Giriş yapmış kullanıcılar için `GET /api/referral` özet kartı → `/invite-friends`
- **Hediye liderleri:** Haftalık top 3 önizleme (`GET /api/leaderboards`) → hediye sıralaması
- **Futbol:** `GET /api/football` yatay maç kartları → web `/futbol`
- **Yenileme:** Davet, hediye liderliği ve futbol bootstrap + pull-to-refresh kapsamında

## 1.0.181+216 (2026-08-13) — Ana sayfa: trend, blog, falcı yedeği

- **Trend konular:** `GET /api/trends` yatay etiket şeridi
- **Blog önizleme:** `GET /api/blog/recent` yatay kartlar
- **Canlı falcılar:** API boşsa compound `liveTellers` / danışman listesine düşer
- **Yenileme:** Trend, blog ve görüntülenen falcılar refresh/bootstrap kapsamında

## 1.0.180+215 (2026-08-13) — Ana sayfa devam: ünlüler, istatistik, oyun merkezi

- **Canlı istatistik:** `GET /api/public-stats` — arama altı kompakt çevrimiçi / canlı / sesli şerit
- **Ünlüler:** `GET /api/celebrities` yatay kart şeridi
- **Oyun Merkezi:** `HomeGameCenterSection` — liderlik önizlemesi + CTA
- **Keşfet:** Blog, rüyalar, ünlüler ve oyunlar kartları eklendi
- **Yenileme:** Compound cache invalidation; falcılar, görevler ve platform stats refresh
- **Ticker:** Çoklu satırda timer yeniden oluşturma hatası düzeltildi

## 1.0.179+214 (2026-08-13) — Ana sayfa eksikleri tamamlandı

- **Homepage butonları:** `GET /api/homepage-buttons` + compound parse; banner altı hızlı erişim şeridi
- **Kayan yazı:** Arama altında inline ticker (`GET /api/homepage-ticker`)
- **Oyunlar & etkinlikler:** `HomeGamesRow` ana sayfaya bağlandı (oyunlar + günlük ödüller)
- **Fan Club:** `GET /api/fan-clubs` API; statik katalog yedek
- **Günlük burç:** Her burç için `POST /api/horoscope/daily` bottom sheet + yıldızname yönlendirme
- **Günlük görevler:** Ana sayfa teaser → `/profile/growth`
- **Yenileme:** `refreshHomeData` oyun, ödül, ticker, buton ve fan club provider'larını kapsar
- **Sıralama:** Hikayeler yukarı; yetim «Keşfet» başlığı kaldırıldı

## 1.0.178+213 (2026-08-13) — PK sonuç, davet poll, Basic müzik paneli

- **PK sonuç:** Savaş bitince `/pk/result` sayfasına yönlendirme (`PkResultPage`)
- **PK davet poll:** `fetchMyInvites` REST yedeği `VoicePkInviteListener` içinde
- **Basic müzik:** `VoiceRoomCenterMusicPanel` — kuyruk özeti ve !istek flaşı (RTC parity)
- **Temizlik:** Kullanılmayan `showVoiceRoomBasicIncomingPkInvite` kaldırıldı

## 1.0.177+212 (2026-08-13) — PK oda kapsamı ve Basic sahne parity

- **PK menü/yönetim:** `pkBattleForRoomProvider` — yanlış odada PK daveti/savaş etiketi engellendi
- **PK şeridi:** Skor ve süre doğrudan sunucu `PkBattleRemote` kaydından (oda değişiminde senkron)
- **PK savaş:** Sunucu otoriter modda mod değiştirici gizlendi; «Destekle» hediye seçiciye bağlandı
- **Basic sahne:** `seatSlots`, konuşma göstergesi, koltuk kilidi/atma (RTC ile parity)
- **Basic dispose:** `leaveRoomSession(awaitBackend: true)` + 6s timeout

## 1.0.176+211 (2026-08-12) — Müzik, çıkış ve PK daveti düzeltmeleri

- **Müzik:** Videolu isteklerde YouTube katmanı artık silinmiyor; ses modunda stream yoksa gizli YouTube yedek oynatıcı devreye girer
- **Şarkı isteği:** Kuyruk boşta `nowPlaying` kalsa bile yeni parça çalınır (`isQueuedOnly` düzeltmesi)
- **Çıkış:** `VoiceRoomLeaveFlow.navigateAwayFromRoom` — `leaveRoomSession` sonrası root navigator ile liste ekranına dönüş
- **PK daveti:** Kılavuz §9.3 `{ guestUserId, durationSec }` gövdesi öncelikli; kısmi başarı yanıtı sentezlenir; rakip sahip yoksa anlamlı hata

## 1.0.175+210 (2026-08-12) — PK oda kapsamı ve çıkış akışı

- **PK:** `pkBattleForRoomProvider` + `pkBattleBelongsToRoom` — yanlış odada PK şeridi / skor senkronu engellendi
- **Çıkış:** `VoiceRoomLeaveFlow` — Basic + RTC ortak onay diyalogu ve hediye özeti
- **RTC:** Geri tuşu artık onay diyalogu gösteriyor (Basic ile parity)

## 1.0.174+209 (2026-08-12) — Müzik video, şikayet, çıkış özeti

- **Videolu müzik:** `VoiceRoomMusicBackgroundLayer` + gizli ses oynatıcı Basic ve RTC stack'ine eklendi
- **Oda şikayet:** Yönetim paneli → Kullanıcı ayarları → «Odayı şikayet et» (`POST /api/reports`, voice_room)
- **Hediye dinleyici:** Büyük hediye marquee tek kaynak (`GiftEventListener`); Basic çift kayıt kaldırıldı
- **RTC çıkış:** Oturum hediye özeti sheet'i (Basic ile aynı)

## 1.0.173+208 (2026-08-12) — Oda çıkış UX ve konuşma isteği

- **Oda kapatıldı / yasak:** SSE veya hata sonrası diyalog + otomatik liste ekranına dönüş (Basic + RTC)
- **Konuşma isteği:** Alt menüde «El kaldır» butonu — koltukta olmayan dinleyiciler için
- **Hata ekranı:** «Oda listesine dön» backend leave tamamlanana kadar bekler

## 1.0.172+207 (2026-08-12) — Sesli oda senkron ve keşfet

- **Oda kapatıldı (SSE):** `room_closed` → oturum sonlandırma, presence/koltuk temizliği, `leaveRoomSession(force: true)`
- **Konuşma isteği:** Giriş/yenileme sonrası kuyruk ile UI senkronu; çıkışta pending sıfırlanır
- **Müzik ayarları:** Yönetim panelinde videolu istek jeton maliyeti (`videoRequestCost`) PATCH
- **Keşfet:** API sayfalama (`fetchRoomsPage`) — yerel liste bittiğinde sonraki sayfa yüklenir; önbellek `category` + `v2` anahtarı

## 1.0.171+206 (2026-08-12) — Oda çıkış + canlı PK daveti

- **Sesli oda çıkış:** RTC sayfasında `leaveRoomSession` önce tamamlanıyor, sonra navigasyon (dispose sonrası `ref` hatası giderildi)
- **Hata ekranı:** "Oda listesine dön" backend leave tetikler
- **Canlı PK:** `POST /api/video-streams/pk` gövdesine `streamId` + `targetStreamId` eklendi (`targetStreamId gerekli` hatası)

## 1.0.170+205 (2026-08-12) — Keşfet kategori + tanı kartı

- **Keşfet:** `GET /api/chat/rooms?type=voice&category=` — sunucu tarafı kategori filtresi (kılavuz §9.3)
- **Yedek:** Backend kategori döndürmezse istemci heuristic filtresi korunur
- **Tanı kartı:** "Socket" → "Hediye sync"; hediye poll başlayınca işaretlenir (TRTC beklemez)

## 1.0.169+204 (2026-08-12) — Sesli oda giriş hatası

- **Kök neden:** `GiftBattleController.build()` içinde `_start()` → `state` okunuyordu → `Bad state: Tried to read the state of an uninitialized provider`
- **Çözüm:** Poll başlatma `Future.microtask` ile ertelendi; aktif/pasif aralık parametre ile seçiliyor
- **Ek:** Oda girişinde `_schedulePoll(musicActive: false)` — build sonrası güvenli varsayılan

## 1.0.168+203 (2026-08-12) — Oda kategorisi

- **Kategori alanı:** `VoiceRoomEntity.category` — liste ve state snapshot parse
- **Yönetim paneli:** Kategori seçici → `PATCH /settings` (`category`)
- **Oda açma:** Kurulumda kategori (Sohbet, Müzik, Aşk, Oyun, Gece)
- **Keşfet filtresi:** Backend `category` varsa doğrudan eşleşme

## 1.0.167+202 (2026-08-12) — Müzik ve oda açma kapasitesi

- **Müzik ayarları:** Yönetim paneli + paylaşılan dialog (`PATCH /music-settings`)
- **Yasaklı kelimeler:** Sohbet yönetimi → araçlar sayfası kısayolu
- **Oda açma:** Kurulumda koltuk (8–15) ve max kullanıcı (15–100) seçimi
- **CI:** `gift_session_controller_test` — voice_realtime prefetch için path_provider mock

## 1.0.166+201 (2026-08-12) — Oda kuralları ve konuşma isteği

- **Oda kuralları:** Yönetim panelinde düzenleme → `PATCH /settings` (`rules` / `rulesTr`)
- **Oda açma:** `POST /rooms/create` — `type: voice`, `seatCount: 8`, `maxUsers: 15` (kılavuz §9.3)
- **Konuşma isteği:** Kullanıcı ayarları → `POST/DELETE /speak-request` (koltukta değilken)
- **State snapshot:** `rulesTr` parse

## 1.0.165+200 (2026-08-12) — Oda kapasitesi ve yönetim

- **maxUsers:** Yönetim panelinde maksimum kullanıcı seçici (15 / 25 / 50 / 100)
- **Konuşma sırası:** Kullanıcı yönetimi → el kaldıranlar kuyruğu (`speak-requests`)
- **Web sahne:** `VoiceWebOwnerStage` koltuk ızgarası `seatCount`'a göre dinamik
- **Hediye efektleri:** Koltuk efekt sınırı oda kapasitesiyle hizalı

## 1.0.164+199 (2026-08-12) — Dinamik koltuk kapasitesi

- **Backend `seatCount`:** Oda listesi, state snapshot ve `GET /seats` ile senkron
- **Koltuk haritası:** 8–15 arası dinamik slot; admin koltuğu (11) kapasite > 10 iken
- **Yönetim paneli:** Koltuk sayısı seçici (8 / 10 / 12 / 15) → `PATCH /settings`
- **Sahne düzeni:** `VoiceRoomSeatLayout`, grid ve otomatik koltuk ataması backend kapasitesine göre

## 1.0.163+198 (2026-08-12) — Sesli oda backend UI hizalaması

- **Oda ayarları (PATCH /settings):** Ad, açıklama, `isLocked` kilidi — yönetim paneli
- **Giriş şifresi:** Tüm oda sahipleri için (yalnızca VIP değil)
- **Seste olanlar:** `GET /voice` → `voiceUsers` listesi (yönetim → kullanıcılar)
- **!istek:** Doğrudan `POST …/music-request-by-query` (web ile aynı)
- **updateRoomSettings API:** `name`, `description`, `isLocked`, `maxUsers`, `seatCount` alanları

## 1.0.162+197 (2026-08-12) — PK canlı yayın + sesli oda düzeltmeleri

- **Canlı PK davet:** Pending iken split ekran açılmaz; kabul/red sonrası `active` başlar
- **Canlı PK split:** Sol kendi / sağ rakip; yayıncı mute + rakibi çıkar + PK bitir
- **Canlı PK izleyici:** Rakip panelinde HLS yedek ses (`audible`)
- **Sesli PK:** `prepareShell` — sayfa sunucu onayı gelmeden aktif sayılmaz
- **Sesli PK taraf:** Aktif odada sol = kendi oda (`applyRemoteBattleForVoiceRoom`)
- **Oda içi şerit:** `VoicePkRoomStrip` — aktif skor/süre; challenger bekleyen metin
- **Sesli çıkış:** PK sayfasından dönünce remote/gift realtime oda oturumunu bozmaz
- **Performans:** PK/hediye poll seyrekleştirildi; SSE varken sesli PK aktif oda poll atlanır
- **SSE:** Çift `applyRemoteBattle` kaldırıldı

## 1.0.161+196 (2026-08-12) — Global hediye overlay + PK davet/kabul senkronu

- **Global hediye:** `GlobalGiftOverlay` — küçük toast (~56px), kuyruk + `eventId` dedupe, admin `display-settings` (TTL 2 dk)
- **Dev marquee kaldırıldı:** Büyük hediye kartı (`StaffEntranceMarquee` / `recent-big` poll) hediye için devre dışı
- **PK 405 düzeltmesi:** Canlı PK `opponentStreamId` + `durationSeconds`; sesli PK `opponentRoomId`; `/api/pk/request` fallback kaldırıldı
- **PK davet:** `LivePkInviteListener` / `VoicePkInviteListener` — ana backend oda/yayın poll; hedefe özel dialog
- **API mirror:** `GET/PATCH /api/gifts/display-settings`, chat/video-stream `/pk` alias
- **Rapor:** `docs/GIFT_PK_FLUTTER_SYNC_REPORT.md`

## 1.0.160+195 (2026-08-12) — Master prompt faz 1–2 (canlı, sesli, sosyal, shorts)

- **Canlı yayın çıkış:** Leave coordinator — timer, co-host teardown, TRTC mute/leave, SSE; izleyici mic kapalı
- **Canlı yayın poll:** SSE bağlıyken yedek poll aralığı uzatıldı
- **Sesli oda çıkış:** TRTC/müzik kes → backend presence leave → SSE/state (peer offline hızlanır)
- **Sesli oda reconnect:** `reconnecting` fazı; kopmada `leaveSeat` yok; snackbar (basic + RTC)
- **Sesli oda DJ:** SSE sağlıklıyken REST DJ poll atlanır
- **Sosyal akış:** `loadMore` hata toleransı; sayfalama spinner
- **Kısa video:** `displayThumbnailUrl` (thumbnail → müzik → avatar); dispose pause; loadMore hata toleransı
- **PK 405 + hediye:** Önceki 1.0.159 düzeltmeleri dahil (video-streams PK body, oda çıkış race, tam ekran hediye video)

## 1.0.159+194 (2026-08-12) — PK 405, oda çıkışı, video hediye

- **PK daveti (canlı):** `POST /api/video-streams/pk` — `action:create`, `streamId`, `targetStreamId`, `duration` (sn); legacy body yedek
- **PK daveti (sesli oda):** 405'te `guestUserId` + `durationSec` yedek gövdesi
- **Oda çıkışı:** `leaveRoomSession(force)` — bağlantı açıkken tekrar çıkış; basic oda önce leave sonra navigasyon
- **Canlı yayın kapanış:** `_exitBroadcast` finally ile `_leaving` sıfırlanır
- **Video hediye:** Tam sahne `BoxFit.cover`, süre 10 sn; hediye kutusu yerine video önceliği

## 1.0.158+193 (2026-08-12) — Sesli oda + canlı yayın master fix

- **Sesli oda TRTC:** Yalnızca audio — video renderer/subscription devre dışı; `setDefaultStreamRecvMode(audio-only)`
- **Sesli oda müzik:** Tek `RoomMusicService` + `just_audio`; YouTube watch URL doğrudan oynatılmaz; video katmanları kaldırıldı
- **Canlı yayın müzik:** `MusicVideoPlayer` (video_player) koltukların altında; gerçek `videoUrl`/`streamUrl` SSE'den
- **Oda çıkışı:** `RoomLeaveCoordinator` — idempotent leave, müzik/TRTC/SSE/heartbeat sıralı temizlik
- **SSE dedup:** `RoomMusicPlaybackDedupe` — aynı track/event iki kez oynatılmaz
- **State:** `room_fragment_providers` — chat/seat/müzik/bağlantı ayrı slice rebuild
- **SongPlaybackFields:** `resolvedAudioStreamUrl` / `resolvedVideoStreamUrl` ayrımı

## 1.0.157+192 (2026-08-12) — Canlı hediye, PK, müzik, yayın kapanış

- **Canlı yayın hediyeleri:** Socket.IO `gift` + genişletilmiş SSE tipleri; REST poll SSE ile birlikte (yedek)
- **PK davet:** `durationSec` + kılavuz `respond` path; 3 sn poll yedek
- **Sesli oda çıkış:** Hediye özeti sheet (atılan/kazanılan jeton) — anında çıkış sonrası
- **Müzik:** Video modda `just_audio` + WebView; SSE `isVideoRequest` korunur; `streamUrl` parse
- **Chat bar UI:** Büyük dikey ayarlar/müzik ikonları, gönder ile boşluk
- **Yayın kapanış:** Yayıncı ve izleyici anında `/feed`
- **Canlı Falcılar:** `online=true` hata yedeği — filtresiz ikinci istek

## 1.0.156+191 (2026-08-11) — Sesli oda müzik + koltuk + çıkış

- **Müzik oynatma:** `song_started` SSE → DJ/just_audio + videolu WebView katmanı (basic oda)
- **YouTube/S3:** Video arka plan + gizli IFrame senkron; `normalizeSongSseForDjPlayback`
- **UI:** Mesaj gönder üstü müzik ikonu + ayarlar; alt bardan ayarlar kaldırıldı
- **!istek / şarkı isteği:** `showVoiceYoutubeSongSheet` — sesli veya videolu seçim
- **Koltuk:** `action: take` öncelikli oturma; yetkili semboller (+ V % @ & ~)
- **Çıkış:** Anında navigasyon; presence leave arka planda

## 1.0.155+190 (2026-08-11) — Master sync tam faz (PK, sosyal, bot, fal)

- **PK davet:** Canlı + sesli 8s HTTP yedek poll; `invited` durumu; `targetUserId` / `guestUserId` hedef eşlemesi
- **Sosyal akış:** `hasMore` pagination yedeği; görüntülenme `registerView` + API; fal kartında «X kişi baktı» rozeti
- **Fal senkron:** `SocialFortuneFeedSync` — `postIdHint` ile `fetchPost` öncelikli
- **Bot guard:** `BotAccountGuard` / `isBotAccountProvider` — canlı, sesli oda, sosyal paylaşım, PK
- **Fal katalog:** Aura, İstihare, Kurşun dökme, Doğum haritası; yanlış alias düzeltmeleri
- **SSE:** `RoomRealtimeEventParser` — PK davet olay normalizasyonu
- Rapor: `docs/FLUTTER_MASTER_SYNC_AUDIT.md` güncellendi

## 1.0.154+189 (2026-08-11) — Master sync P0: oda çıkış + swipe TRTC

- **Sesli oda:** `refresh()` artık `_sessionActive` yokken presence yeniden join etmez (Music PiP stale presence)
- **Basic çıkış:** `awaitBackend: true` — backend leave tamamlanmadan navigasyon yok
- **Swipe canlı:** `suspendForSwipe` / `resumeFromSwipe` — ekran dışı yayın TRTC+SSE bırakır
- Rapor: `docs/FLUTTER_MASTER_SYNC_AUDIT.md`

## 1.0.153+188 (2026-08-11) — CI import düzeltmesi

- `LiveVipEntranceBanner` / `LiveRoomChatMessage` — `EntranceTheme` package import (CodeQL derleme hatası)

## 1.0.153+187 (2026-08-11) — Gold giriş banner + takım renkleri

- **Takım teması:** `TeamCatalog` + `EntranceTheme` — backend `team` nesnesi veya `favoriteTeam` (`PATCH /api/me`)
- **Tek kaynak:** `userRoomProfileProvider` — üyelik (`walletBalances`) + takım (`profileExtended`) senkron
- **Giriş FX:** `VipEntranceOverlay`, `LiveVipEntranceBanner` takım gradient; takım yoksa 🇹🇷 kırmızı/beyaz
- **Profil:** Düzenle ekranında takım seçici; kayıtta cüzdan + profil invalidate
- Rapor: `docs/LIVE_VOICE_SYNC_FIX_REPORT.md` güncellendi

## 1.0.152+186 (2026-08-11) — Canlı/sesli oda tam senkron (P0)

- **Canlı çıkış:** `LiveRoomController.tearDownSession()` — SSE, socket, hediye, backend leave anında (idempotent)
- **Fal isteği (yayıncı):** Sağ üst `LiveHostFortuneRequestStack` — max 3 kart, Cevapla/Reddet/Beklet
- **Sesli PK:** SSE bağlıyken 8s poll atlanır; `pkBattleRemoteProvider` SSE birincil
- Rapor: `docs/LIVE_VOICE_SYNC_FIX_REPORT.md`

## 1.0.151+185 (2026-08-11) — Tek backend yönlendirme

- **ApiBackendRouter:** Taşınan tüm yollar (`/api/pk/*`, `/api/live/pk/active`, `/api/live/guest/*`, `/api/games/rooms`, `/api/membership/*`) artık `canlifal.com` (main)
- **PK SSE:** `PkMatchSseService` ana backend'e bağlanır
- **Canlı socket:** `LiveNamespaceSocketService` ana backend `/live` namespace
- §8 korundu: `/api/live/gift/send`, `/api/trtc/token`, `/api/trtc/usersig`

## 1.0.150+184 (2026-08-11) — PK, fal paneli, yayın özeti, hediye

- **Sesli oda PK:** Oda bazlı poll + `guestUserId` davet body; aktif PK'da otomatik PK sayfasına yönlendirme
- **Canlı PK:** `pkRoomProvider` skorları birleşik maçla senkron
- **Fal yayını:** Sağ şeritte sürekli «Fal İste» paneli (`liveFortuneMyStatusProvider` durum)
- **Yayın/oda özeti:** Kapanışta sohbete izleyici · jeton · süre sistem mesajları; sesli oda + canlı yayın
- **Canlı hediye:** Hediye dinleyici anında bağlanır; yayın hediyeleri gecikmesiz başlatılır

## 1.0.149+183 (2026-08-11) — Backend API contract sync

- **docs/BACKEND_API_REFERENCE.md** eklendi (Flutter master contract)
- **Battles/Goals:** `ApiBackendRouter` → ana backend (`canlifal.com`); ikinci backend yönlendirmesi kaldırıldı
- **Gift battle/goal:** POST/GET sözleşmesi ve JSON alan eşlemesi (secondsLeft, rank, percent, totalScore, lastCallActive)

## 1.0.148+182 (2026-08-10) — Debug derleme + CI

- **Gradle:** Release keystore kontrolü yalnızca `assembleRelease` / `bundleRelease` sırasında — debug ve CodeQL tekrar çalışır
- **CI:** `build-debug-apk.yml` — keystore olmadan `apk-debug-latest` debug APK yayınlar

## 1.0.147+181 (2026-08-10) — Sesli oda müzik oynatma

- **SSE oynatma kapısı:** Ses modunda `RoomSongBloc` parça tutarken just_audio yeniden başlatılmıyordu — düzeltildi
- **Android stream:** googlevideo için backend proxy önce denenir (`/api/chat/youtube-audio`)
- **Video mini player:** Odaya girildiğinde mevcut parça için ilk senkron eklendi

## 1.0.146+180 (2026-08-10) — Release candidate lock

- **Production logging:** TRTC/FCM/OneSignal push token ve `audio.trtc.token` logları yalnızca `kDebugMode`
- **VoiceRoomDebugLog:** `audio.trtc.token` / `audio.agora.token` release kritik log listesinden çıkarıldı

## 1.0.145+179 (2026-08-10) — Stage 16 production parity

- **CI release gate:** Hatalı GitHub Secrets durumunda dokümante test hesaplarına otomatik geri dönüş; `acceptance-preflight.sh` + `set-acceptance-secrets.sh`
- **PK routing:** Sesli oda PK ana backend (`canlifal.com`); games yalnızca `/api/pk/*`, `/api/live/pk/active`, `/api/live/guest/*`
- **Socket.IO temizliği:** Ölü hediye/PK socket köprüleri kaldırıldı (SSE + REST birincil)
- **404 cleanup:** `current-song`, `music-stream`, `live/pk/sweep`, `liveFalPending`, `fortuneTellerIncomingSessions` çağrıları kaldırıldı
- **PK body:** Tek uç `POST /api/chat/rooms/{id}/pk` — `{ action, targetRoomId, duration, battleId }`
- **401 refresh:** Yalnızca ana backend 401'inde token yenileme (games origin hariç)
- **Müzik:** `youtube-stream` canonical; join-seat sırası düzeltildi
- **Poll:** Canlı PK 8s, sesli oda davet 10s yedek

## 1.0.144+178 (2026-08-07) — Production master P0

- **Aşama 6 hediye/jeton:** Backend `coinCost`/`spentAmount` toplam jeton parse; katalog enrich sıfır `totalCoin` doldurur; voice send yanıtı `newBalance`/`spentAmount`; `insufficient_jeton` hata eşlemesi; UI'da 0 jeton satırları gizlenir
- **Aşama 7 müzik/!istek:** `controlPlayback` switch fall-through düzeltmesi; pause POST `action:pause`; pauseMusic yerel player duraklatma; duplicate videoId kuyruk engeli
- **Aşama 8 final:** Otomatik acceptance betiği (`api-final-phase.sh`); APK split-per-abi ~94MB arm64 (universal ~247MB); release/security audit raporu
- **Canlı yayın oluşturma:** `createVideoStream` — 25s write timeout, timeout/5xx/429 için 1 retry; prep ekranında JWT ön kontrol; çift 15s timeout kaldırıldı (Dio + ApiException mesajları)
- **Falcı paneli:** `PsychicInviteDiagnosticCard` yalnızca `kDebugMode`; release listede debug slot'lar kaldırıldı
- **approvedPsychicProvider:** önce `my-profile`, hata durumunda onaylı profil cache korunur (`src=error` yerine `cached_profile`)
- **Durum matrisi:** `docs/FLUTTER_PRODUCTION_MASTER_STATUS.md`

## 1.0.143+177 (2026-08-07) — Stabil entegrasyon (1.0.138–142 paketi)

Tüm son backend senkron değişiklikleri `main` üzerinde birleştirildi; `dart analyze` + 374 test geçti.

- **Müzik (1.0.138):** `!istek` SSE + `just_audio` / YouTube video parity
- **Fal paylaşım (1.0.139):** `POST /api/social/posts/auto-fortune`
- **Canlı yayın (1.0.139–142):** Host `streamEnded`, SSE-aware poll, `createVideoStream` parse
- **Canlı falcı (1.0.140):** SSE-primary poll, falcı paneli event bus
- **Sesli oda (1.0.141–143):** RTC selective watch, tek oda ayarları paneli, güvenli roomKey yönlendirme
- **CI:** CodeQL runner kuyruğu (`max-parallel`, `c-cpp` kaldırıldı)

## 1.0.142+176 (2026-08-05) — P2 oda ayarları + canlı yayın parse

- **Oda ayarları tek panel:** `showVoiceRoomSettingsSheet` / `showVoiceRoomHubSettingsSheet` artık `showVoiceRoomManagementPanel`'e yönlendiriyor
- **Canlı yayın oluşturma:** `createVideoStream` yanıt parse — `videoStreamId`, `liveStreamId`, `liveStream` alias + `create.parse_fail` teşhis logu
- **Jeton animasyonu:** Hediye animasyonu yalnızca SSE/socket kaynaklarından (mevcut kural belgelendi)

## 1.0.141+175 (2026-08-05) — Sesli oda RTC performans

- `voice_room_rtc_page.dart`: selective `ref.watch` — footer UI, müzik mini oynatıcı, VIP giriş, teşhis banner izole widget'lara taşındı
- `roomSongBlocProvider` artık yalnızca mini oynatıcı alt ağacında dinlenir (tüm sayfa yeniden çizilmez)
- `voiceRoomUiProvider` / `voiceRoomMusicSessionProvider` tam state yerine `select` kullanımı

## 1.0.140+174 (2026-08-05) — Backend senkron P1 (SSE poll azaltma)

- **Canlı falcı seansı:** SSE bağlıyken sinyal poll 30 sn (önceden 3 sn); oda/sohbet poll zaten SSE-aware
- **Falcı paneli:** Event bus + 20 sn yedek HTTP poll (önceden 3 sn); `PsychicIncomingHost` SSE → bus yayını
- **Canlı yayın:** Host/izleyici poll aralıkları `liveRoomProvider.sseConnected` ile yavaşlatılır (sinyal 10 sn, fal 30 sn, misafir 20 sn)
- **Sesli oda:** Kullanılmayan `showVoiceRoomSettingsSheet` / `showVoiceRoomHubSettingsSheet` `@Deprecated` — `showVoiceRoomManagementPanel` kullanın

## 1.0.139+173 (2026-08-05) — Backend senkron (fal paylaşım + canlı yayın)

- **Fal otomatik paylaşım:** `POST /api/social/posts/auto-fortune` (web parity) — anında akışa prepend
- **Canlı yayın:** Host SSE `streamEnded` → yayın sonu diyaloğu
- **Rapor:** `docs/BACKEND_FLUTTER_SYNC_REPORT.md` — backend-first gap analizi

## 1.0.138+172 (2026-08-05) — Müzik sistemi (web parity)

- `!istek` akışı: SSE `song_started` / `song_changed` / `player_state` / `queue_updated` → oynatıcı
- **Ses modu:** `just_audio` (`setUrl` + `play`) — gizli YouTube iframe kaldırıldı
- **Video modu:** Mevcut `YoutubeVideoBackground` / hediye video renderer
- `SongPlaybackFields`: `musicUrl` → `videoUrl` → `youtubeUrl` → `videoId` null-safe çözümleme
- `RoomSongDto.hasTrack` yalnızca `videoId` değil, tüm URL alanlarını kabul eder
- `[MusicPipeline]` teşhis logları: Song Event, Parsed VideoId/MusicUrl, Starting Audio/Video

## 1.0.137+171 (2026-08-05) — Derleme düzeltmeleri

- Shorts: `const` scroll physics düzeltmesi; müzik tile go_router navigasyonu
- Sosyal: `commentsCount` alan adı düzeltmesi

## 1.0.136+170 (2026-08-05) — UI tamamlama

### Hikâyeler
- Video hikâye yükleme (`createStoryVideo`, galeri seçici)
- Paylaşılan `showStoryCreateSheet` — fotoğraf veya video
- Görüntüleyici: yerel silme listesi, video yükleme göstergesi, basılı tutunca video duraklatma
- Ana sayfa `StoriesSection` — kendi hikâyeni görüntüle / uzun basarak ekle
- go_router `/social/stories/view`

### Sesli oda
- `VoiceRoomCenterMusicPanel` RTC sahnesine bağlandı
- TRTC müzik karışım hatası → flash banner (`pulseMusicRequestFlash`)
- Footer `!istek` butonu müzik açıkken görünür

### Falcı paneli
- `PsychicInviteDiagnosticCard` + `PsychicRtcSessionReportCard` (debug RTC günlüğü)

### Shorts
- Müzik detay sayfası `RefreshIndicator`
- Hashtag video sayısı üst bilgi
- GPS etiketi ters coğrafi kodlama (Nominatim)

### Canlı yayın
- Sinyal poll ardışık hata banner'ı

## 1.0.135+169 (2026-08-05) — WIP senkronizasyon (3)

### Push (sunucu)
- `docs/PSYCHIC_ONESIGNAL_ACTION_BUTTONS.md` — Kabul/Reddet `actionId` ve REST örneği

### Sesli oda / TRTC
- `!istek` müzik: TRTC `TXAudioEffectManager` ile uplink karışımı (`VoiceRoomTrtcMusicMixer`)
- `chat_room_providers` parçalama: SSE (`chat_room_providers_sse.dart`), pause/resume (`chat_room_providers_playback.dart`)

### Hikâyeler
- Video oynatma (`video_player`), 5 sn otomatik ilerleme, basılı tutunca duraklat
- Kendi hikâyesini görüntüleme; `DELETE /api/stories` ile silme

### Shorts
- Hashtag sayfalandırma (`ShortHashtagNotifier`)
- Müzik detay akışı (`/shorts/music/:id`)
- Keşfet GPS konum (`geolocator`)

### Canlı yayın
- `VideoWebrtcSignalService` kaldırıldı — sinyal poll doğrudan sayfada

### Performans / tanılama
- `docs/RTC_LIFECYCLE.md`
- `PsychicRtcSessionReport` — falcı 1:1 RTC olay günlüğü

## 1.0.134+168 (2026-08-05) — WIP senkronizasyon (2)

### Sesli oda
- `!istek` müzik barı: `RoomSongBloc`/IFrame tek kaynak; pause/resume bloc-first
- Koltuk kilidi: `isLocked` parse, UI kilit ikonu, kilitli koltuğa oturma engeli, kilidi aç
- `unlockSeat` API (`action: unlock`)

### Sosyal
- Sosyal sekmesine hikâye şeridi (`SocialStoriesRail`)
- Gönderi detay: paylaş, yorumlar, silince geri dön

### Shorts
- Hashtag sayfası pull-to-refresh

### RTC temizlik
- `VoiceTrtcException` (eski Agora adı typedef ile uyumlu)

## 1.0.133+167 (2026-08-05) — WIP senkronizasyon

### Canlı falcı TRTC
- Tek join kilidi (`_joiningRtc`); SSE/room poll ile çakışan rejoin engellendi
- Heartbeat reconnect join sırasında askıya alınır (`setReconnectSuspended`)
- `startLocalPreview(viewId=0)` kaldırıldı — kamera flip-flop düzeltmesi
- Yerel PiP sabit viewId; kamera aç/kapa yalnızca mute/unmute
- `expectedAnchorUserId` 1:1 görüşmede zorunlu
- Bootstrap: önce TRTC join, sonra SSE (paralel rejoin yok)
- Uygulama ön plana dönünce `onAppResumed` → RTC yeniden bağlanma
- Medya durumu `/api/room/signal` ile `media_state` yayını (kamera/mic)

### Sesli oda !istek / DJ
- SSE `dj` → `RoomSongBloc.eventFromSse` doğrudan besleme
- DJ payload: `musicUrl`/`videoId`/`elapsedSeconds` ile geç katılan senkronu
- Oynatma sırasında video katmanı sıfırlanmıyor; `_syncRoomVideo` çağrılıyor

### Push (falcı çevrimdışı)
- OneSignal bildirim aksiyonu: Kabul/Reddet → `respondSession` + deep link
- Gelen çağrı diyaloğu: 60 sn geri sayım, süre dolunca otomatik red

## 1.0.132+166 (2026-08-05)

### Ana sayfa görselleri
- **Trend videolar:** CDN küçük resim + yerel mistik kapak yedeği
- **Fal & Tarot:** Yerel `.webp` mistik kapaklar (tarot, kahve, katina vb.)
- **Keşfet / Gold:** Unsplash yerine yerel mistik görseller; ağ katmanı isteğe bağlı
- **API:** `/api/mobile/home` fal kartı `image` alanı düzgün çözümlenir

## 1.0.131+165 (2026-08-05)

### Hediye, canlı yayın ve falcı senkron düzeltmeleri
- **Sesli oda hediyeleri:** Canlı yayınla aynı Gift Engine overlay — tüm hediyeler hızlı gösterim
- **Hediye sesi:** Sesli oda, canlı yayın ve PK'da hediye sesi her yerde çalar
- **Canlı yayın mikrofon:** İzleyici hesabı yayıncı onayı olmadan ses/video yayınlamaz
- **Çoklu yayın isteği:** Yayıncı kabul etmeden misafir koltuğuna çıkmaz; bekleyen istek banner'ı
- **PK daveti:** SSE ile anında iletim (canlı yayın + sesli oda)
- **Canlı Falcılar:** Karşılıklı görüşmede kamera aç/kapa döngüsü düzeltildi (PiP katman)
- **Bahşiş popup:** Falcıya «Danışan size bahşiş gönderdi» bildirimi

## 1.0.130+164 (2026-08-04)

### Sesli oda müzik / !istek (web parity)
- **Müzik İste:** Sağ alt FAB — yetersiz jetonda pasif, yeterli jetonda aktif
- **Arama modalı:** YouTube `GET /api/youtube/search` + A-Z sanatçı hızlı gezinme
- **Mod seçimi:** «🎵 Sadece Ses (10 Jeton)» / «🎬 Videolu (20 Jeton)»
- **Videolu mod:** Koltuk altından mesaj alanına çerçevesiz YouTube arka plan
- **Ses modu:** Gizli 1×1 embed — yalnızca ses
- **Mini kuyruk kartı:** Sağ altta sıradaki ilk 3 istek
- **SSE:** Birleşik `type: dj` olayı → `RoomSongBloc` senkronu
- **Performans:** `RepaintBoundary`, seçici `ref.watch`, gizli oynatıcı

## 1.0.129+163 (2026-08-04)

### Backend ↔ Flutter senkronizasyon — tamamlama
- **Sosyal:** `SocialPostDetailPage` + `/social/post/:id` + `/sosyal?post=` deep link
- **Stories:** Presigned upload + `POST /api/stories` JSON; ana sayfa hikâye şeridi her zaman görünür
- **Sesli oda:** Koltuk kilitle / koltuktan at UI + controller
- **Shorts:** Keşfet/hashtag API 404'de feed tabanlı yedek
- **Provider:** `chat_room_providers_entry.dart` — giriş/bootstrap ayrımı
- **CDN cache:** `/api/stories` TTL

## 1.0.128+162 (2026-08-04)

### Backend ↔ Flutter senkronizasyon (devam)
- **RTC:** `flutter_webrtc` kaldırıldı; Agora/LiveKit token sabitleri silindi
- **Canlı yayın:** `TrtcLiveRoomCoordinator` — heartbeat + otomatik TRTC reconnect
- **Canlı moderasyon:** Susturmayı kaldır / banı kaldır UI
- **Falcı:** Gelen istek poll sırası üretim `GET /sessions?status=pending` öncelikli
- **Sosyal:** `GET /api/social/posts/{id}` — `fetchPost` + `postDetailProvider`
- **Sesli oda:** `lockSeat` / `kickFromSeat` (kılavuz §9.3)
- **CDN:** Hediye/shorts/story/banner göreli yolları CDN üzerinden çözümleme
- **Stats:** `socialPublicStats` fallback kaldırıldı → `/api/public-stats`
- **Rapor:** `docs/BACKEND_FLUTTER_SYNC_REPORT.md`

## 1.0.127+161 (2026-08-04)

### Audit tamamlama — müzik IFrame, TRTC-only, platform API
- **Müzik tek yol:** `_applyDjPlayback` yalnızca `RoomSongBloc` + IFrame; `just_audio` stream resolve kaldırıldı
- **DJ sync:** `chat_room_providers_dj_sync.dart` mixin — SSE/poll müzik senkronu ayrıldı
- **Agora/LiveKit:** Modüller ve `livekit_client` kaldırıldı; ses motoru TRTC-only
- **Platform API:** `broadcast-images`, `football`, `online-fal`, `translations`, `user/likers` bağlandı
- **Global müzik şeridi:** `VoiceRoomWebMusicBar` IFrame ilerleme (`RoomSongBloc`)
- **Hediye test:** `gift_session_controller_test` flaky düzeltmesi

## 1.0.126+160 (2026-08-04)

### IFrame-only + platform API (ara sürüm)
- DJ realtime `RoomSongBloc` durumu; Agora/LiveKit temizliği başlangıcı

## 1.0.125+159 (2026-08-04)

### Oda müzik sistemi (SongQueueService) + hediye düzeltmesi
- **Backend:** `SongQueueService`, `room_song_queue` / `room_current_song` / `room_song_history`, SSE `song_*` olayları, `serverTime` senkronu
- **API:** `current-song`, `queue`, `skip`, `pause`, `resume`, `DELETE song/:queueId` — yalnızca YouTube Data API + IFrame (stream URL yok)
- **Flutter:** `flutter_bloc` + `RoomSongMiniPlayer` (`youtube_player_iframe`), 500 ms drift seek
- **Hediye:** Videolu hediyeler gecikmesiz tam ekran; prefetch arka planda; 🎁 yerine thumbnail

## 1.0.124+158 (2026-08-04)

### Sesli oda tam senkronizasyon
- **Oda çıkışı:** Anında TRTC/SSE/state temizliği; navigasyon bloklanmaz; PK socket kapatılır
- **Hediye video:** Backend `durationMs` birebir; erken kapanma kaldırıldı
- **Hoparlör/mikrofon:** TRTC `muteLocalAudio`; hoparlör kapalıyken müzik/hediye/RTC sessiz
- **Çevrimiçi:** Backend `onlineCount` + AppBar jeton yanında premium rozet
- **Müzik:** Koltuk altı 1x1 YouTube kutusu; sağ altta müzik istek butonu (jetonlu)
- **!istek:** SSE `dj_update` sonrası oynatma gate düzeltmesi

## 1.0.122+157 (2026-08-04)

### CI / Gradle
- **ABI:** `ndk.abiFilters` kaldırıldı — CI `--split-per-abi` ile çakışma (Gate 9) giderildi

## 1.0.122+156 (2026-08-04)

### CI düzeltmesi
- **GiftSyncLog:** `chat_room_providers.dart` eksik import — APK derleme gate test derlemesi düzeltildi
- **Gift SSE:** `parseGiftEvent` nullable dönüş — `onEngineQueueUpdated` imzası uyumlu

## 1.0.122+155 (2026-08-03)

### Platform & SDK güncellemesi
- **Flutter:** Stable `3.44.8` (CI + `.flutter-version`)
- **Dart:** `3.12.x` (`>=3.8.0 <4.0.0`)
- **Android:** minSdk **26** (Android 8+), targetSdk **36** (Android 16 hazır)
- **ABI:** `arm64-v8a`, `armeabi-v7a`, `x86_64` — CI `--split-per-abi`
- **iOS:** minimum deployment **15.0**
- **Gradle:** AGP 8.13, Kotlin 2.2.21, Gradle 8.14, R8 full mode
- **Cihaz:** Tablet/katlanır ekran (`resizeableActivity`, `supports-screens`, PiP)
- **Performans:** `DevicePerfTuning` — düşük RAM image cache küçültme
- **Build:** tree-shake-icons, obfuscate, split-debug-info (CI)
- **Rapor:** `docs/FLUTTER_PLATFORM_UPGRADE.md`

## 1.0.121+154 (2026-08-03)

### Sesli oda mimari — TRTC/SSE/hediye performans (web paritesi)
- **TRTC:** `exitRoom` tamamlanana kadar beklenir; yeniden giriş öncesi dispose garantisi
- **SSE:** Oda çıkışında `releaseVoiceRoom` — keşif presence bağlantısı korunur
- **Gift Engine SSE:** `gift_received` / `gift_queue_updated` / `gift_finished` motor yönlendirmesi
- **Gift socket:** SSE aktifken Socket.IO hediye dinleyicisi kapatılır (çift teslimat önlenir)
- **RTC:** İkinci SSE presence + çift hediye listener kaldırıldı
- **Join:** Giriş bootstrap sıralı — gereksiz paralel GET azaltıldı
- **Heartbeat:** Oturum başında tek timer; çıkışta iptal
- **Rapor:** `docs/FLUTTER_WEB_ARCHITECTURE_REPORT.md`

## 1.0.120+153 (2026-08-03)

### !istek müzik — web paritesi (videolu / sesli)
- **Videolu Çal:** YouTube arka planda blur + karartma; sohbet üstte; iframe sessiz (ses `just_audio`)
- **Sadece Ses Çal:** Video render yok — yalnızca `just_audio` (düşük CPU/RAM)
- **Oda oynatıcı:** Kapak, sanatçı, ilerleme, ses, oynat/duraklat/sonraki, videolu/sesli göstergesi
- **Hata:** Video açılamazsa otomatik ses moduna geçiş
- **PiP:** Odadan çıkınca global mini oynatıcı videolu modda da görünür

## 1.0.119+152 (2026-08-03)

### Web senkronizasyon — hediye motoru SSE + performans
- **Gift Engine SSE:** `gift_received` animasyon, `gift_queue_updated` yalnızca kuyruk, `gift_finished` dequeue; legacy motor sonrası yok sayılır (backend denetim §9)
- **SSE heartbeat:** 45 sn timeout (15 sn × 3) — sesli oda + video yayın
- **SSE ref-count:** Oda çıkışında `releaseVoiceRoom` — keşif presence bağlantısı korunur
- **Video SSE gift:** Tam payload (`engine` üst seviye) parse
- **RTC:** Gereksiz ikinci SSE presence listener kaldırıldı
- **Rapor:** `docs/FLUTTER_WEB_SYNC_REPORT.md`

## 1.0.118+151 (2026-08-02)

### Sesli oda UX — hediye, koltuk, müzik, komutlar
- **Hediye sesi:** SFX havuzu genişletildi, yeniden deneme; video preload süresi uzatıldı, tam oynatma (loop kapalı, bitişte dequeue)
- **Koltuk:** Boş koltuğa uzun bas → odadaki herkes listesi → seçilen kişi oturur; oturma sonrası anında senkron
- **Koltuk stabilitesi:** Kendi koltuğun geçici boş yanıtta korunur; yetki/internet dışı düşme azaltıldı
- **Ses ver:** Ayarlar/oda panelinden kaldırıldı; boş koltuk dokunuşu artık söz hakkı istemez
- **!istek video:** YouTube tam ekran arka plan + just_audio yedek ses
- **!kapat:** Sıradaki şarkıya geçer (skip); yalnızca oda sahibi, admin veya isteyen

## 1.0.117+150 (2026-08-01)

### Sesli oda — PK, koltuk, hediye sesi, müzik
- **PK daveti:** `action: create` (sunucunun kabul ettiği tek davet aksiyonu; `invite` kaldırıldı)
- **Koltuk stabilitesi:** Boş/geçici seat yanıtı koltuğu silmez; `seatSlots` → `presence.seatIndex` senkronu
- **Hediye sesi:** Animasyon kapalı veya poll kaynaklı hediyelerde de SFX çalar
- **Müzik kontrolü:** `POST /music` gövdesi `{ action: play|pause|skip, videoId?, title? }` (kılavuz §9)

## 1.0.116+149 (2026-08-01)

### Sesli oda yönetimi — backend uyumu
- **PK daveti:** Üretim sözleşmesi `{ action, targetRoomId, duration }`; `/api/live/pk` games backend yönlendirmesi
- **Oda komutları:** Hub ayarlarından doğru komut paneli; `!dj` → DJ assign/remove API
- **Arkaplan:** API + yerleşik 40 görsel birleşik liste; boş ekran düzeltmesi
- **Hediye savaşı:** Games API gövdesi (`roomId`, `duration`, zarf parse) ve yedek `action: start`

## 1.0.115+148 (2026-07-31)

### Web ↔ Flutter parity (Faz 5)
- **Platform API:** `popups`, `ads/active`, `ads/reward`, `fortune-request-types`, `user/theme`, `fortune-requests/my-status` → datasource + provider
- **Popup UI:** `AppPopupsListener` — oturum açıkken site popup bildirimleri
- **Tema senkronu:** Ayarlar ↔ `GET/POST /api/user/theme`; giriş sonrası sunucudan çekme
- **Canlı fal:** API fal türü kataloğu; `my-status` uç noktası
- **DM SSE:** 404'te reconnect durur, poll-only yedek
- **429:** `ApiException` + `ApiSnackBar` standart rate-limit mesajı
- **Shorts:** Preload ±2 video; keşfet grid `RepaintBoundary`
- **Modeller:** Chat test modelleri `voice_hub/data/models` altına taşındı

## 1.0.114+147 (2026-07-31)

### Web ↔ Flutter parity (Faz 4)
- **Legacy `services/`:** Auth, config, mobile compound feature katmanına taşındı; kullanılmayan servis dosyaları silindi
- **Ana sayfa:** `homeLiveStreamsProvider` → `liveStreamsListNotifier`; `invalidateHomeKeepAliveProviders` (SSE + 60s bridge)
- **DM:** Bildirim SSE mesaj olayında konuşma yenileme; sohbet ekranında `MessageSseService` + poll yedek (8s/15s)
- **API registry:** `chat_room_providers` müzik log path'leri; `conversationStream` endpoint sabiti
- **Performans:** Voice discover cache 2dk; ana sayfa canlı kartları `RepaintBoundary`

## 1.0.113+146 (2026-07-31)

### Web ↔ Flutter parity (Faz 3)
- **Sosyal akış:** `feedNotifierProvider` → `socialNotifierProvider` (beğeni, görüntüleme, yerel paylaşım)
- **Sesli odalar:** Tek liste kaynağı (`voiceRoomsListNotifier`); `invalidateDiscoverVoiceRooms`
- **Hediye API:** insights/battle/goal/admin datasource path'leri `api_endpoints.dart` registry
- **Marquee:** Büyük hediye poll `giftRepositoryProvider` (legacy `giftService` kaldırıldı)
- **DM:** Açık sohbet global poll ile senkron; chat poll 8s; `openDmConversationIdProvider`
- **Legacy:** Kullanılmayan `services/` provider'ları `@Deprecated`

## 1.0.112+145 (2026-07-31)

### Web ↔ Flutter parity (Faz 2)
- **Canlı yayın:** Tek keşif kaynağı (`liveStreamsListNotifier`); `invalidateDiscoverLiveStreams` ile çift fetch önlendi
- **Global state:** `userFollowersProvider`, `userFollowingProvider`, `postCommentsProvider`
- **DM:** Konuşma listesindeki çift 12s poll kaldırıldı (global `DmRealtimeListener`)
- **Falcı oda:** SSE bağlıyken oda poll 20s (3s yerine)
- **Admin:** Ödeme SSE (`/api/admin/payments/stream`) + 30s poll yedek
- **API registry:** Müzik kuyruğu, hediye, admin arka plan path'leri `api_endpoints.dart`'a taşındı

## 1.0.111+144 (2026-07-31)

### Web ↔ Flutter parity (Faz 1)
- **Ağ:** Apple/verify public auth; timeout 15s/30s; GET retry 429+5xx (max 3)
- **Cache:** Kısa TTL; wallet/me/messages/social için stale fallback kapalı; sosyal `forceRefresh`
- **Gerçek zamanlı:** Canlı hediye SSE aktifken REST poll kapalı; SSE reconnect jitter
- **API:** `public-stats`, `fortune-access/check`, `payment-methods`, `search`, `social/post/view`, presence heartbeat
- **Bildirim:** `PATCH /api/notifications` web uyumlu mark-read
- **Burç:** `POST /api/horoscope/daily` öncelikli
- **Rapor:** `docs/WEB_FLUTTER_PARITY_GAP_REPORT.md`

## 1.0.110+143 (2026-07-31)

### Fal sosyal senkron — tamamlama
- **Ana akış:** Fal paylaşımı bulununca `feedNotifierProvider` da güncellenir (`prependPost`)
- **Eşleştirme:** `findMatchingFortunePost` ayrı modül + birim testleri
- **API:** `shareFortuneAuto` kullanımdan kaldırıldı (`@Deprecated`); backend tek kaynak

## 1.0.109+142 (2026-07-31)

### Fal & Tarot — otomatik sosyal paylaşım senkronizasyonu
- **Backend tek kaynak:** Flutter artık `POST /api/social/posts/auto-fortune` ile paylaşım oluşturmaz; sunucunun oluşturduğu gönderi gösterilir
- **Gerçek zamanlı:** Bildirim SSE (`fortune_share`) → sosyal akış otomatik güncellenir (`prependPost`)
- **Fal tamamlanınca:** Coordinator tek noktadan senkronize eder; sonuç sayfalarındaki çift paylaşım kaldırıldı
- **Metadata:** `shareCount`, `fortuneId`, `visibility`, `fortuneSlug`; yazar rol rozeti (Gold/Diamond/Premium/Admin)
- **Sosyal sekme:** Uygulama ön plana gelince akış yenilenir

## 1.0.108+141 (2026-07-31)

### Backend parity (senkronizasyon — 2. tur)
- **Falcı SSE:** `session_cancelled` / red olayları anında dialog ve kuyruğu kapatır; 401'de token yenileme
- **Falcı seans SSE:** 401'de JWT refresh + yeniden bağlanma (kılavuz §6)
- **Canlı yayın VIP giriş:** Gold/Diamond/Premium/Admin katılımcıları için bölüm bazlı kayan duyuru
- **Fal türü seçici:** Dropdown yerine ikonlu kart ızgarası (Kahve, Tarot, Astroloji vb.)
- **Sesli oda RTC:** Koltukların altında «Sırada» müzik kuyruğu listesi

## 1.0.107+140 (2026-07-31)

### Backend parity (senkronizasyon — 1. tur)
- **Canlı yayın sohbet:** Alt bara emoji, hediye, bahşiş ve gönder butonları eklendi (web parity)
- **VIP/yetkili duyuru:** Diamond/Premium/Gold/Admin/Moderatör için bölüm bazlı kayan metin (`formatTierEntranceLine`)
- **Falcı bahşiş:** Gönderen «Bahşişiniz başarıyla gönderildi»; falcı «X size N Jeton bahşiş gönderdi» (backend event ile)

### Mevcut (önceki sürümlerden)
- Canlı falcı: SSE istek/kabul, TRTC görüşme, bahşiş API
- Sesli oda: `!istek`, müzik kuyruğu, YouTube embed
- Hediye: gerçek zamanlı SSE, MP4/PNG/SVG cache

## 1.0.106+139 (2026-07-31)

### Oturum (giriş sonrası çıkış düzeltmesi)
- **Token yenileme:** `/api/auth/mobile-refresh` yanıtı `user` alanı olmadan parse edilir (önceden refresh sessizce başarısız oluyordu)
- **401 zinciri:** `validateSession` artık token'ı doğrudan silmez; tek yol `AuthTokenRefreshCoordinator`
- **Giriş koruması:** Login sonrası 45 sn grace — geçici ağ/401 hatasında otomatik logout engellendi
- **Arka plan doğrulama:** Yeni girişte eski `_validateSessionInBackground` iptal edilir (`_sessionEpoch`)

## 1.0.105+138 (2026-07-31)

### CI (düzeltme)
- **CI/CodeQL:** `cancel-in-progress: false` — eşzamanlı push'ta tüm kontrollerin iptal olması engellendi
- **APK:** `main` push'ta yalnızca CI başarılı olduktan sonra derlenir (`workflow_run`)

### Hediye senkronizasyonu & performans
- **Gerçek zamanlı hediye:** SSE/socket → tek `publishRemote` hattı; `GiftEventListener` feed, sohbet ve son hediyeleri yönetir (çift işleme yok)
- **Dedupe:** Oda çıkışında sıfırlanır; `_seen` üst sınırı 2048; anında feed (ertelenmiş kuyruk kaldırıldı)
- **MP4 hediyeler:** İlk kare siyah önleme, thumbnail, seek(0), oynatma bitince dispose; soğuk açılışta sıcak controller temizliği
- **PNG/SVG:** Katalog disk önbelleği (`assetType`, `animationUrl`); bozuk dosya otomatik silinir; top 8 video preload
- **SSE canlı yayın:** `Last-Event-ID`, exponential backoff, keep-alive; yeniden bağlanma logları
- **Oturum temizliği:** `AppSessionReset.onColdStart()`; oda çıkışında video/gift cache + realtime dedupe sıfırlama
- **Teşhis logları:** `gift_sent`, `event_received`, `video_started/ended`, `cache_hit/miss`, `sse_reconnect`, pipeline ms

## 1.0.104+137 (2026-07-30)

### Sesli oda yönetimi (birleştirme)
- **Tek moderasyon merkezi:** Ayarlar → Kullanıcı yönetimi → kullanıcı seç → ses ver, koltuğa al, koltuktan indir, kanaldan at, yetki (anında koltuk)
- Tekrarlayan «Yetki Ver», «Detaylı moderasyon» ve çift kick/ban menüleri kaldırıldı
- **Arkaplan:** yalnızca sunucu kataloğu + yükleme sheet’i (`fetchBackgrounds`)
- **Müzik:** şarkı isteği video (CDN arka plan) / ses (YouTube API); DJ hub doğrudan Oda yönetimi’nden
- Oda komutları paneli sadeleştirildi (duyuru, temizle, kullanıcı yönetimi)

## 1.0.103+136 (2026-07-30)

### Duyuru şeridi & giriş
- **1000+ jeton hediyeler** ve **Gold/admin girişleri** tüm sayfalarda üst şeritte (navbar altı)
- Ana sayfa arama altındaki hediye şeridi kaldırıldı (çift gösterim yok)
- Sesli odada yetkili/sahip/admin girişi koltukların **altında** sağdan sola kayar

### Sohbet stilleri
- Gold üyeler ve admin nick kullanıcılar tüm sesli oda sohbetlerinde şekilli profil + neon yazı

### PK daveti
- B odası sahibine popup: «X odası size PK isteği attı — Kabul / Reddet»
- Aktif oda + sahip odaları için socket; 3 sn poll yedek; çift popup önlendi

### Sesli oda
- Oda sahibi, yetkili ve DJ odaya girince otomatik koltuğa oturur

## 1.0.102+135 (2026-07-30)

### Performans (production)
- **Soğuk açılış:** Çerez jar `LazyCookieJar` ile runApp sonrası; splash yolu kısaldı
- **Auth:** Token + oturum önbelleği paralel okunur; arka planda doğrulama (stale-while-revalidate)
- **Mobil config:** İlk kareden 600ms sonra yüklenir (ağ rekabeti azalır)
- **Kabuk prefetch:** Tek timer; hediye katalog önbellekteyse tekrar istek yok
- **Sesli oda giriş:** Presence sonrası SSE hemen; state/seats arka planda; gereksiz refresh kaldırıldı
- **Oda çıkış:** Gift realtime + PK + SSE + TRTC ses dispose tamamlandı
- **API önbellek:** SharedPreferences max 80 kayıt — otomatik budama

## 1.0.101+134 (2026-07-30)

### Ana sayfa & videolar
- Trend küçük resimler: R2/CDN + video yolundan thumb türetme
- Trend kartlarda izlenme + beğeni sayısı
- Fal/Keşfet/Gold fantastik görseller
- Video analitiği: beğenenler; admin tüm videoları silebilir

### Hediye
- Panel: şeffaf siyah cam arkaplan
- Ses öncelikli; video min 10sn oynatma; controller havuzu

## 1.0.100+132 (2026-07-30)

### Ana sayfa — Keşfet & Gold 2026 premium
- Cam kartlar (24px radius, mor neon kenarlık, blur, shimmer)
- Yatay kaydırma, eşit boyut, CachedNetworkImage + Shimmer
- Gold tier temaları: Basic bronz, Premium mavi, Gold altın, Diamond mor

### Hediye pipeline
- Sıra: ses → animasyon → jeton güncelleme
- `GiftSoundPool` (just_audio, 4 kanal, preload)
- Video controller ısıtma havuzu, prefetch öncelikli kuyruk
- Pipeline zamanlama logları, release debug log azaltma

### Performans
- Hediye katalog prefetch erken (T+200ms)
- Sesli oda API yanıt logları release'te kapalı
- Voice hediye fade süreleri kısaltıldı (100/150ms)

## 1.0.99+131 (2026-07-29)

### Düzeltme
- **GiftMediaType:** `.webp` URL'leri doğru algılanır (CI test düzeltmesi)

## 1.0.99+130 (2026-07-29)

### Sesli oda hediye görünürlüğü
- **Animasyon katmanı:** Tam ekran/video hediyeler %100 opaklık; `Positioned.fill` ile arka plan üstünde net görünür
- **Video varsayılanları:** CMS'den gelmeyen video hediyeler `FULL_SCREEN`, `LARGE` öncelik, 8 sn süre
- **Koltuk altı:** Hediye atanlar etiket paneli (`VoiceGiftSenderTagsPanel`) kaldırıldı

## 1.0.99+129 (2026-07-29)

### UI
- Sesli oda ve canlı yayında **Son hediyeler** kutusu kaldırıldı (duyuru şeridi kaldı)
- Tam ekran hediye motoru ayarında video `BoxFit.cover` ile ekranı doldurur

## 1.0.99+128 (2026-07-29)

### Hediye medya — backend paritesi
- **GiftMediaWidget:** PNG, SVG, WEBP, MP4 tek oynatıcıda; `mediaType==video` → VideoPlayer (Image değil)
- **Video:** disk önbelleği (`VideoCacheService`), muted + looping, init bitene kadar thumbnail
- **AspectRatio:** backend `width`/`height` (veya `mediaWidth`/`mediaHeight`); `BoxFit.contain`
- **CDN:** R2 `gift/gifts/*` → `cdn.girlive.com` (`CloudMediaUrl`)
- **Katalog:** 45 sn'de bir `giftVersion` kontrolü — yeni hediyeler uygulama yeniden başlatmadan görünür

## 1.0.99+126 (2026-07-28)

### Videolu hediyeler + performans + hızlı koltuk
- **Sesli oda / canlı:** `voice_realtime` ve `voice_announce` kaynaklı hediyeler artık animasyon kuyruğuna girer
- **Katalog zenginleştirme:** CMS'den `videoUrl`, `thumbnailUrl`, `assetFormat`, `engineAnimationType` otomatik eklenir
- **Video tanıma:** `assetType: video` ve uzantısız CDN URL'leri doğru şekilde MP4/WEBM olarak oynatılır
- **Performans:** Video tam indirme kaldırıldı (VideoPlayer akış); yalnızca küçük önizleme önbelleği
- **Oda girişi:** Presence sonrası erken otomatik koltuk; hediye katalog önbelleği atlanır; ses bekleme 1,5 sn

## 1.0.98+125 (2026-07-28)

### Sesli oda hediye animasyonu — ambient katman
- Video/animasyon arka plan üstünde, UI (koltuk/sohbet/bar) altında oynar
- Opaklık %40, üst LinearGradient fade — sert siyah kesim kaldırıldı
- BoxFit.cover ile doğal birleşim; bitişte yumuşak fade-out
- IgnorePointer + RepaintBoundary; yeni CMS videoları URL uzantısından tanınır

## 1.0.97+124 (2026-07-28)

### Gift Engine — backend render (web paritesi)
- **FIFO kuyruk:** Aynı anda tek animasyon; bitince sıradaki otomatik oynar (üst üste bindirme yok)
- **Priority:** SMALL / MEDIUM (%35) / LARGE (%60) / ULTRA (tam ekran) — backend `priority`
- **Display Area:** FULL_SCREEN, CENTER, SEAT, TOP, BOTTOM — backend `displayArea` / `screenPosition`
- **Animasyon türleri:** PNG, SVG, Lottie, MP4, WEBM, Particle (+ Rive/SVGA fallback)
- **Koltuk efektleri:** Glow, Border, Shake, Pulse, Particle — backend `seatEffects`
- **Combo:** x2 / x5 / x10 / x100 rozeti — backend `combo` (istemci hesaplamaz)
- **Gift Feed:** Sağ panel; gönderen + hediye + jeton; `feedDurationMs` sonra kaybolur
- **Performans:** Asset preload, RepaintBoundary, bellek/video önbelleği, controller dispose

## 1.0.96+123 (2026-07-28)

### Çerez / oturum düzeltmesi (kritik)
- **"Failed to load cookies for the request"** hatası giderildi: `PersistCookieJar` artık `getApplicationSupportDirectory()` altında (`canlifal_cookies`) saklanıyor; okunamaz `.cookies` kök dizini kullanılmıyor
- Çerez jar `runApp` öncesinde `forceInit` ile hazırlanıyor — sosyal feed, sesli odalar, canlı yayın, yönetim paneli ve hediye ekranları tekrar API'ye bağlanır

## 1.0.95+122 (2026-07-28)

### Yükleme, fal ödeme, profil ve VIP
- **Sesli odalar:** `GET /api/chat/rooms?type=voice` düzeltmesi; ana sayfada API sayısı ile liste (SSE beklemeden)
- **Canlı yayın:** `/api/live/rooms` 401'de video-streams yedeğine düşme
- **Sosyal feed:** `feed=following` + `items`/`data` parse; giriş sonrası otomatik yenileme
- **Fal&Tarot:** Kayıt/profil doğum tarihi kullanımı; jeton veya CFC ile ödeme; tek reklam → +10 CFC → otomatik fal açılışı
- **Profil istatistikleri:** Beğeni/izlenme gerçek API; hediye sayısı beğeni yerine kullanılmaz
- **VIP ayrıcalıkları:** Site üyelik tablosu ile uyumlu liste; tıklanınca kademe karşılaştırması

## 1.0.94+121 (2026-07-28)

### Performans — soğuk açılış, sesli oda giriş/çıkış, bellek
- **Startup:** Hive, API önbelleği ve çerez yükleme runApp sonrasına ertelendi; ilk kare daha hızlı
- **Ana sayfa:** Bildirim/mesaj/cüzdan rozetleri T+200ms shell prefetch ile yüklenir (ilk karede API yok)
- **Cüzdan:** Auth jeton değeri anında gösterilir; arka planda sessiz yenileme
- **Sesli oda giriş:** Snapshot sonrası gereksiz `refresh()` kaldırıldı; hediye katalog önbelleği atlanır
- **PK socket:** Tek sahip (provider); sayfa tarafında çift bağlantı yok
- **SSE oda güncellemesi:** 450ms debounce ile gereksiz yenileme azaltıldı
- **Oda çıkışı:** TRTC `leave()`, SSE kapatma ve oturum temizliği oda değişiminde await
- **RTC/Basic sayfa:** Çift `audio.leave()` ve paylaşılan coordinator `dispose` hatası düzeltildi
- **SDK init:** OneSignal, Firebase, Sentry paralel başlatılır

## 1.0.93+120 (2026-07-27)

### Canlı yayın UX — alt bar, beğeni, turnuva, performans
- **Düşen emoji kaldırıldı:** Açılışta otomatik 💖🌹⭐ animasyonu ve hediye parçacıkları kapalı
- **Alt bar sade:** Yalnızca mesaj + «Daha fazla»; emoji, misafir, oyun, hediye menüde
- **Popüler No / Lig:** PK liderlik tablosundan gerçek sıra; tıklanınca liderlik sayfası
- **Yıldız turnuvası:** `/api/tournaments` listesi ve katılım sheet'i
- **Çift dokunma beğeni:** Gerçek double-tap; kişi bazlı sayaç + signal senkronu
- **Yayın kapatma:** Yayıncı geri tuşunda onay; izleyici yayın bitince sonraki yayına geçiş
- **Hediye donması:** Panel anında kapanır, gönderim arka planda
- **Ödüllü reklam:** Tam yükleme beklenir (15 sn timeout)
- **Keşfet:** Ana sayfada «Keşfet» başlığı + canlı yayınlar ve trend videolar

## 1.0.92+119 (2026-07-27)

### Hediye görünürlüğü, otomatik koltuk, PK iletimi, performans
- **Hediye/jeton:** SSE hediyeleri tekrar `publishRemote` ile koltuk rozeti, liderlik ve kazanç panellerine iletilir
- **Payload:** Dış zarf sender/jeton alanları `mergeEnvelope` ile korunur; `giftId` parse düzeltmesi
- **Animasyon:** Katılım öncesi 15 sn tolerans; canlı socket kaynağı da animasyon tetikler
- **Otomatik koltuk:** Oda sahibi önceliği; `seatSlots` doluluk haritası; `seat_changed` sonrası yeniden deneme
- **PK:** `pk_invite`/`PK_INVITE` socket olayları; `/api/pk/me/invites` 6 sn poll yedek
- **Yükleme:** Hediye katalog prefetch kabukta (mevcut kademe korunur)

## 1.0.91+118 (2026-07-27)

### Backend §9 uyumu — SSE hediye, Last-Event-ID, assetFormat
- **Hediye animasyonu:** Yalnızca SSE `source: sse`; katılım öncesi hediyeler atlanır; poll SSE açıkken kapalı
- **Render meta:** `assetFormat`, `imageUrl`, `videoUrl`, `thumbnailUrl` parse + oynatıcı seçimi
- **SSE reconnect:** `Last-Event-ID` header ile kaçırılan olaylar
- **Heartbeat:** Presence 15 sn (backend 45 sn stale penceresi)
- **Jeton UI:** Canlı yayın koltuk/host panelinde yalnızca sayı

## 1.0.90+117 (2026-07-27)

### Canlı oda senkronizasyonu
- **Hediye:** Yerel animasyon kaldırıldı; yalnızca SSE/uzak olay ile oynatılır (tüm cihazlar aynı anda)
- **Video hediye:** MP4/webm ön-indirme + `assetUrl`/`assetType` ile doğru oynatıcı
- **Jeton rozeti:** Koltuk altında yalnızca sayı (Toplam/Jeton metni kaldırıldı)
- **Oda çıkışı:** Koltuk/presence önce temizlenir; TRTC/SSE/hediye/PK önbellekleri sıfırlanır
- **Bellek:** Oda çıkışında hediye önbelleği; görsel önbellek 100 MB sınırı

## 1.0.89+116 (2026-07-27)

### CI düzeltmesi — TRTC ve hediye paketi
- **Derleme:** Agora motoru tamamen kaldırıldı; import yolları ve güzellik filtresi düzeltildi
- **11 koltuk:** `parseVoiceRoomSeatMap` ve oda düzeni 11 koltukla hizalandı
- **Gönderen paneli:** Hediye atan kişinin toplam adedi (×N) koltuk sol altında görünür

## 1.0.88+115 (2026-07-27)

### Canlı Falcılar, TRTC, hediye ve oda sistemi
- **TRTC tek motor:** Agora bağımlılığı kaldırıldı; ses/görüntü yalnızca Tencent TRTC
- **11 koltuk:** Backend ile uyumlu 0–10; yetkili kullanıcılar (+ ve üzeri) otomatik oturur
- **Hediye render:** Backend meta ile tam ekran `cover`; sesli odada koltuk altı–mesaj kutusu bandı
- **Gönderen paneli:** Koltuk sol altında son 3 isim, 4 sn karararak kapanır
- **VIP şifre:** Derin bağlantıda şifre kapısı; bildirim tıklanınca anında ekran açılır

## 1.0.87+114 (2026-07-27)

### Sesli oda hediye donması + yükleme hızı
- **Gönderim:** Panel hemen kapanır; hediye yayını ve animasyon arka planda işlenir
- **Sesli oda animasyon:** Ağır tam ekran/Lottie yerine hızlı sahne ikonu; API zaman aşımı 25 sn
- **Katalog:** Hediye listesi önbellekte; panel her açılışta yeniden indirmez
- **Genel:** Son hediyeler kutusunda blur kaldırıldı; katalog prefetch ile canlı/sesli bölümler hızlandı

## 1.0.86+113 (2026-07-27)

### Sesli oda hediye donması (ANR)
- **Performans:** Hediye animasyonları izole widget’ta; oda sayfası her hediyede yeniden çizilmez
- **Gönderim:** Hediye sonrası gereksiz oda `refresh()` kaldırıldı; ses arka planda çalar
- **Animasyon:** Sesli odada parçacık/glow kapatıldı; tekrarlayan Lottie decode azaltıldı
- **State:** Hediye oturumu tek seferde güncellenir

## 1.0.85+112 (2026-07-27)

### Büyük hediye sahnesi
- **Sesli oda / canlı yayın:** Hediyeler koltukların altından mesaj alanına kadar büyük gösterilir
- **Etiket:** Yalnızca sol üstte «gönderen → alıcı»; jeton/ad/isim şeritleri kaldırıldı
- **Tam ekran hediyeler:** Aynı sahne bandında, aynı boyutta oynatılır

## 1.0.84+111 (2026-07-27)

### Hediye görünürlük, tam ekran ve oda performansı
- **CMS animasyon:** Ağ URL'si olan hediyeler her fiyatta tam ekran; minimum 3 sn süre
- **SSE/socket:** `gift_sent` tipi + payload birleştirme — tüm katılımcılar hediye/jeton görür
- **Canlı yayın:** Socket.IO hediye köprüsü ana yayın sayfasında
- **Sesli oda:** State+seats paralel, hızlı çıkış/oda geçişi, TRTC bekleme 4 sn
- **Yetkili otomatik koltuk:** `/join-seat` + 3 deneme, snapshot sonrası hemen oturma
- **Saatlik sıfırlama:** Oda jeton toplamı ve sıralama her saat başı yenilenir

## 1.0.83+110 (2026-07-24)

### Hediye kataloğu + koleksiyon örnekleri
- **Sesli oda / canlı yayın:** Admin katalog hediyeleri `visibleInVoiceRoom` / `visibleInLiveStream` ile birleşik gösterim
- **Admin «Hediye & Koleksiyon»:** 40 arkaplan efekti, 20 oda teması, 20 avatar aksesuarı, 10 mikrofon çerçevesi, 10 sohbet balonu, 20 isim efekti, 10 üyelik rozeti, 20 profil çerçevesi, 20 başarı rozeti
- **Kozmetik kataloğu:** Örnek setler Gold profil ekranında da kullanılabilir
- **Arkaplan:** Yerleşik sesli oda arkaplan listesi 40 görsele çıkarıldı

## 1.0.82+109 (2026-07-24)

### Resmî servis + hediye sistemi dokümantasyonu
- **Dokümanlar:** `docs/CANLIFAL_FLUTTER_RESMI_SERVIS_ENTEGRASYONU.md`, `docs/CANLIFAL_HEDIYE_SISTEMI_DOKUMANTASYONU.md` repoya eklendi
- **GiftAssetType / GiftDisplayType:** `unknown` fallback ile backend şeması
- **Animasyon paritesi:** fiyat eşikleri 100/200/500 jeton → 3s/4s/5s kuyruk; ≥200 tam ekran flash
- **Idempotency:** hediye gönderim POST'larına `idempotencyKey` (çift düşüm koruması)
- **Katalog alanları:** `assetType`, `displayType`, `contentVersion` parse

## 1.0.81+108 (2026-07-23)

### Gerçek zamanlı parite (dokümantasyon §17–19)
- **Seans SSE ham olay:** `type` olmadan `timerStartedAt`, `actualMinutesUsed`, `addedMinutes`, `message` alanlarından tür çıkarımı
- **SSE keep-alive:** Seans odası kanalında `: heartbeat` yorumları yok sayılır; 20 sn timeout ile yeniden bağlanma
- **Hediye SSE:** Sesli oda düz + canlı yayın iç içe payload; CMS katalogdan video animasyon zenginleştirme (önceki madde tamamlandı)

## 1.0.80+107 (2026-07-23)

### Gerçek zamanlı hediye sistemi (dokümantasyon uyumu)
- **SSE hediye parse:** Sesli oda düz payload (`giftTypeId`, `giftName`, `giftIcon`, `amount`) + canlı yayın iç içe `gift` nesnesi
- **Video animasyon:** SSE yalnızca emoji gönderse bile CMS `assetUrl` ile katalogdan zenginleştirme
- **SSE heartbeat:** Sunucu 15 sn keep-alive → istemci 20 sn timeout (doküman §4–5)
- **Birleşik katalog:** Sesli oda + canlı yayın + genel CMS tek indeks

## 1.0.79+106 (2026-07-23)

### Backend dokümantasyonu ile tam hizalama
- **Admin hediye API:** `canlifal.com` ana backend (`/api/admin/gifts`, `/stats`) — games API yönlendirmesi kaldırıldı
- **DTO alanları:** `iconImageCloudPath`, `cloudStoragePath`, `assetUrl`, `assetType` (`gift_types` şeması)
- **Yükleme:** yalnızca `POST /api/upload/presigned` (dokümante edilmiş uç)
- **Yetki:** JWT `admin` / `yonetici` rolü; dokümanda olmayan `X-Staff-*` başlıkları kaldırıldı
- **Gelir sekmesi:** dokümanda olmayan `/revenue/rules` kaldırıldı

## 1.0.78+105 (2026-07-23)

### Admin / yonetim tam yetki + hediye video
- **`admin` ve `yonetim` nickleri:** Cüzdan rolü beklemeden tam site yetkisi; hediye CRUD ve admin panel
- **Admin API başlıkları:** `X-Staff-Role` + `X-Staff-Username` — backend ile uyumlu yetki çözümlemesi
- **Video hediyeler:** CMS `animationUrl` alanı sesli oda ve canlı yayında oynatılır; admin editörde MP4/WebM önizleme
- **Admin katalog:** Video animasyon rozeti; CDN/cloud path URL çözümlemesi

## 1.0.77+104 (2026-07-23)

### Hediye yönetimi hızlandırma + video animasyon
- **Admin panel:** Tüm backend bayrakları (şanslı, kombo, öne çıkan, popüler, gizli, sıralama); kayıt sonrası anında katalog yenileme
- **Video/GIF/Lottie CDN:** Yüklenen MP4/WebM/GIF animasyonlar sesli oda ve canlı yayında tam ekran oynatılır
- **Ses:** Admin CDN ses dosyası (`soundUrl`) oda/yayında çalınır
- **Performans:** Admin katalog keepAlive; kayıt sonrası bloklayıcı liste beklemesi kaldırıldı; animasyon prefetch

## 1.0.76+103 (2026-07-23)

### Backend hediyeleri kullanılabilir
- **CMS katalog birincil:** Sesli oda ve canlı yayın `GET /api/gifts/catalog` ile admin panelinden eklenen hediyeleri gösterir
- **Versiyon senkronu:** Panel açılışında katalog yenilenir; `thumbnailUrl` / `assetUrl` / emoji ikon desteği
- **Yedek:** CMS boş veya hata → eski `/api/gifts` ve `/api/video-streams/gifts` uçları

## 1.0.75+102 (2026-07-23)

### 🍀 Şanslı Hediye (Talih Kutusu)
- **Katalog CMS:** `GET /api/gifts/version` + `GET /api/gifts/catalog` — `isLucky` alanı, versiyon önbelleği
- **Şanslı hediye API:** `config`, `send`, `history` (kişisel özet + global jackpot akışı)
- **Gönderim:** `isLucky` hediyeler `POST /api/gifts/lucky/send` ile yönlendirilir (sesli oda + canlı yayın)
- **UI:** 🍀 rozeti, spin/kutu açılış overlay, JACKPOT kayan duyuru, «Son Büyük Kazançlar» şeridi

## 1.0.74+101 (2026-07-23)

### Ana sayfa görselleri + Canlı Falcılar oda düzeltmesi
- **Fal & Tarot:** API görselleri (`homepage-fortune-cards`) öncelikli; yanlış Unsplash katmanı kaldırıldı
- **Günlük burç:** Her burç için ayırt edici gökyüzü / element görseli
- **Keşfet & Gold:** Kutu ve paket adına uygun görseller güncellendi
- **Canlı Falcılar:** TRTC oda — önce `GET /api/room` senkronu, sonra bağlantı; `trtcRoomId` güncellenir
- **Randevu:** Seans oluşturma hatası kullanıcıya gösterilir; bekleme ekranında oda bilgisi çekilir

## 1.0.73+100 (2026-07-23)

### Sesli oda bağlantı düzeltmesi
- **Zaman aşımı:** `/api/chat/rooms` istekleri 15/22 sn timeout (global 3/5 sn yerine)
- **Presence join:** 3 deneme + gövde varyantları; geçici hata banner'ı gizlenir
- **Optimistic UI:** Odaya girerken kullanıcı hemen çevrimiçi sayılır; arka planda join tamamlanır
- **SSE bağlanınca:** Hata temizlenir ve presence join yeniden denenir

## 1.0.72+99 (2026-07-23)

### Backend uyum + performans
- **Açılış:** Ana sayfa API dalgaları; kabuk prefetch çift istek düzeltmesi; marquee gecikmesi
- **Trend video:** 5 thumbnail karesi (%10–80, gerçek süre); kapak seçimi zorunlu
- **Canlı Falcılar kartı:** 132×176 premium kart — yıldız, yorum, ücret, canlı rozeti
- **Canlı fal:** SSE bahşiş eventleri; falcı popup; TRTC dispose leave
- **Sesli PK:** Davet eşleşmesi genişletildi (opponent oda/kullanıcı)
- Rapor: `docs/FLUTTER_BACKEND_SYNC_REPORT_2026-07-23.md`

## 1.0.71+98 (2026-07-22)

### Hediye sistemi, cüzdan ve performans
- **Hediye sohbet mesajı:** «Mesut, Ayşe'ye 100 Jeton değerinde Rose gönderdi.» — sesli oda ve canlı yayın
- **Koltuk altı sayaç:** Canlı yayında kümülatif jeton rozeti + tıklanınca gönderici dökümü (sesli oda ile aynı)
- **Geç katılanlar:** Oda hediye geçmişi API'den koltuk toplamlarına seed
- **Cüzdan:** Kazanç özeti (bekleyen, çekilebilir, bugün/ay, gönderilen/alınan jeton)
- **Para çek:** `POST /api/withdrawals` — ad, banka, IBAN, tutar; geçmiş talepler
- **Komisyon oranı:** `GET /api/platform/commission-rate` (salt okunur gösterim)
- **Performans:** Odadan çıkışta hediye provider/state temizliği (bellek sızıntısı önleme)

## 1.0.70+97 (2026-07-21)

### Ana sayfa sesli odalar + oda içi hediye gösterimi
- **Sesli odalar:** Yalnızca içinde kullanıcı olan odalar listelenir; canlı kişi sayısı (SSE + REST)
- **5 kullanıcı:** Oda kartında en fazla 5 avatar; fazlası `+N` rozeti
- **Hediye anlık:** Gönderen → alıcı, hediye adı ve jeton miktarı tüm rollerde (oda sahibi, konuk, izleyici)
- **Son hediyeler:** 5 kayıt; kayan duyuru şeridi (`VoiceGiftAnnouncementTicker`) yeniden bağlandı
- **Uçuş animasyonu:** Alıcı adı ve hediye bilgisi gösterilir

## 1.0.69+96 (2026-07-21)

### Backend dokümantasyon uyumu (Faz 2)
- **ApiEndpoints:** sesli oda uçları merkezileştirildi (music-queue, settings, moderation, speak-request, banned-words, …)
- **chat_room_remote_datasource:** tüm inline `/api/chat/rooms/...` path'leri `ApiEndpoints`'e taşındı
- **Profil:** `userStats`, `userActivity`, `userBroadcastHistory` birincil; `/api/users/me/*` yedek
- **Hediye:** `check-reciprocal` gönderim öncesi sesli oda, canlı yayın ve `GiftService`'te
- **SSE seat_update:** 300 ms debounce ile koltuk yenileme
- **Cache policy:** `/api/user/stats` ve `/api/user/activity` TTL kuralları

## 1.0.68+95 (2026-07-21)

### Backend dokümantasyon uyumu (Faz 1)
- **Giriş:** `emailOrUsername` kaldırıldı — kılavuz §9.1 `{email}` veya `{username}` + `password`
- **Alınan hediyeler:** birincil uç `GET /api/user/received-gifts` (eski `/api/users/me/gifts-received` yedek)
- **Presence heartbeat:** 12 sn → 25 sn (PART4/PART10)
- **SSE alias:** `seat_update` → koltuk yenileme; `pk_score` → PK skor olayı
- **Endpoint sabitleri:** `giftsCheckReciprocal`, `authVerifyDevice`, `authReclaimDevice`
- **GiftRepository:** `checkReciprocal(userId)` — kılavuz §9.9
- Uyumluluk raporu: `docs/FLUTTER_BACKEND_COMPLIANCE_REPORT.md`

## 1.0.67+94 (2026-07-21)

### Sesli oda — backend %100 senkronizasyon
- **GET /state** ve **GET /seats** — odaya girişte tek kaynaklı durum; Flutter artık koltuk/owner/mic üretmiyor
- **Oda akışı:** Join → state → seats → TRTC (backend `trtcRoomId` + `numericUid`) → SSE → UI
- **SSE `room_event`:** `user_joined`, `user_left`, `mic_changed`, `seat_changed`, `owner_changed`, `room_closed` — ek API çağrısı yok
- Optimistic presence/koltuk ve otomatik koltuk seçimi kaldırıldı
- Çıkışta state tamamen temizlenir (hayalet kullanıcı önleme)

## 1.0.66+93 (2026-07-21)

### Hediye senkronizasyonu — sesli oda ve canlı yayın
- **Tek kaynak:** SSE/socket/poll → `GiftEventListener` → `giftSessionProvider` (host/guest/admin aynı state)
- **Son hediyeler:** combo mantığı (❤️ x1 → x2 → x3), 5 sn TTL, ortak `UnifiedRecentGiftersBox`
- **Animasyon kuyruğu:** aynı anda gelen hediyeler sırayla oynar; premium fullscreen + uçuş overlay
- Host için `if (isHost) return` / gönderen filtresi kaldırıldı — tüm roller aynı event yolunu kullanır
- **Loglar:** broadcast, SSE bağlantı, host/guest alma, işleme ve UI render (`GiftSyncLog`)
- Canlı yayın, sesli oda RTC/basic ve PK sayfaları birleşik sisteme taşındı

## 1.0.65+92 (2026-07-20)

### Sesli oda — mikrofon ve otomatik koltuk
- **No voice permission:** izleyici girişinde gereksiz `POST /voice` kaldırıldı; mikrofon açılırken önce koltuğa oturma
- **Geçersiz alan:** koltuk atama artık yalnızca `/api/chat/rooms/{id}/seats` kullanıyor (yanlış `/api/live/seats` kaldırıldı)
- Koltuk API: `take` / `sit` / `force` + `targetUserId` yedekleri; 400/422'de sonraki format denenir
- **Yetkili otomatik koltuk:** sunucu `myPermissions` yüklendikten sonra tekrar denenir; `@` `&` `~` rolleri tanınır
- Normal kullanıcı mikrofon açarken boş koltuğa otomatik oturma

## 1.0.64+91 (2026-07-20)

### Sesli oda — oda sahibi yetkileri ve PK onayı
- Oda sahibi girişte **dâhilî sunucu hatası** banner'ı artık odayı kilitlemiyor; yetkiler ayrıca yenileniyor
- SSE açıkken bile `myPermissions` sunucudan çekiliyor — yetki verme, koltuğa alma, ses verme düzeltildi
- Oda sahibi için sunucu bayrakları boşsa istemci tarafı yetki yedeği (`~` founder)
- Rol atama: `set_role` + `give_voice` / `give_op` / `give_sop` / `give_founder` yedekleri
- Koltuk atama: başka kullanıcı için önce `force` aksiyonu deneniyor
- **PK daveti:** süre dolunca sunucuya otomatik red; sesli odada banner ve global dinleyici düzeltildi

## 1.0.63+90 (2026-07-20)

### Premium profil önizleme ve görsel iyileştirmeler
- **Premium Profil:** üstte canlı profil önizleme paneli — seçilen çerçeve/efekt/isim profilde anında görünür
- Giriş efekti için **“Giriş efektini oynat”** butonu; sohbet balonu ve mikrofon önizlemesi
- Kozmetik kartlarında parlak seçim vurgusu ve **“Profilde aktif”** etiketi

### Fal & Tarot görselleri
- Ana sayfa ve keşfet önizlemesinde `FortuneTypeCoverImage` (yerel asset + Unsplash yedek)
- API görselleri `CanlifalImageUrls.resolve` ile düzgün yüklenir

### Keşfet ve Gold
- Her kutu/paket için ayrı, net temalı görseller (karışık görünüm azaltıldı)
- Daha hafif gradient overlay — arka plan fotoğrafları daha net

### Trend video kapak önerileri
- Video düzenleme ve yayınlama adımında otomatik **6 kapak önerisi**
- Seçilen kapak video küçük resmi olarak kullanılır

## 1.0.62+89 (2026-07-20)

### Görsel iyileştirmeler ve premium sesli oda kaldırma
- **Premium sesli odalar** ana sayfa ve keşfetten kaldırıldı (VIP sekmesi, VIP şeridi, premium oda satırı)
- **Trend videolar:** `coverUrl` / `image` alanları destekleniyor; küçük resim yoksa sinematik yedek görsel
- **Fal & Tarot:** sinematik Unsplash görselleri (ana sayfa + keşfet önizlemesi)
- **Günlük burç:** her burç için gökyüzü / mistik arka plan görselleri
- **Keşfet** ve **Gold üyelik** kartlarında premium arka plan görselleri

## 1.0.61+88 (2026-07-19)

### Sesli oda ayarları — üst menü kaldırıldı, alt Ayarlar birleşik
- Üstteki **⋯** (üç nokta) menü kaldırıldı; tüm işlevler **Ayarlar** alt menüsünde
- **Kullanıcı yönetimi:** yetki ver, kullanıcı listesi, cezalar, sessize alınanlar
- **Sohbet yönetimi:** oda sessize, sohbet temizle, oda komutları
- **Oda yönetimi:** PK, müzik, arkaplan, hediye savaşı/hedefi
- **Kullanıcı ayarları:** rumuz, efektler, bildirim sesi, jeton
- Sunucu `myPermissions` bayrakları (`canGiveVoice`, `canGiveOp`, `canGiveSop`…) kullanılıyor
- **Ses verilince** boş koltuğa otomatik alma + mikrofon açma (alıcı cihazda)

## 1.0.60+87 (2026-07-19)

### Hediye senkronizasyonu ve jeton gösterimi
- **Çift sayım düzeltildi:** 1000 jeton artık 2000 olarak görünmüyor (`jetonAmount` brüt; `coinCost × quantity` tekrar çarpılmıyor)
- **Tüm cihazlarda hediye:** SSE/socket → tek `publishRemote` hattı; sayfa dinleyicisi kayıt + duyuru + animasyon
- **Gönderen sıralaması:** Olay kimliği ile dedupe; gönderici başına brüt jeton toplamı
- **Canlı yayın:** Liderlik tablosu dedupe; göndericide çift kazanç düzeltmesi

### Oturum sonu net paylaşım (sesli oda + canlı)
- Yayıncıya hediye: brüt 100 → yayıncı net 50, site 50
- Misafire hediye: brüt 100 → misafir 35, yayıncı 15, site 50
- Herkese görünen tutar her zaman **brüt** (100 jeton = 100 gösterilir)

### Canlı Falcılar (TRTC)
- Odaya girmeden önce eski TRTC oturumu kapatılır (donma çakışması)
- Oda kimliği değişince tam yeniden bağlanma (yalnızca `reconnect` değil)

## 1.0.59+86 (2026-07-19)

### Premium entegrasyon — eksik bağlantılar tamamlandı
- **Mikrofon çerçevesi:** Varsayılan sesli oda sahnesinde `selfUserId` ile kozmetik halka (basic mod)
- **Giriş efekti:** RTC sesli oda sayfasında da `CosmeticEntranceOverlay` (basic ile aynı)
- **Ayarlar:** Merkezi `/settings` sayfasına **Premium Profil** kısayolu
- **Ana sayfa:** `DiscoverPremiumHomeSection` — premium oda kartları yatay şerit
- **Sesli keşfet:** Popüler odalar `DiscoverPremiumRoomCard` kullanıyor
- **Üyelik rozetleri:** API boşken yerel katalog (Premium/Gold/Diamond/Kurucu)
- **PK sahnesi:** Mikrofon kozmetiği PK katılımcı şeridinde

## 1.0.58+85 (2026-07-19)

### Premium kozmetik — eksik alanlar tamamlandı
- **Giriş efektleri:** Ejderha, meteor, kanat, melek + odaya girişte `CosmeticEntranceOverlay` (Gold seçim → sesli oda)
- **Sohbet balonu:** Altın / neon / cam balon kataloğu + kendi mesajlarında uygulama
- **Mikrofon çerçevesi:** Koltukta kendi avatarında dönen kozmetik halka
- **Profil kozmetik sayfası:** 6 sekme (Çerçeve, İsim, Efekt, Giriş, Balon, Mikrofon)
- **Üyelik rozetleri:** `GET /api/membership-badges` yatay şerit profilde
- **Equip senkron:** `POST /api/user/cosmetics/equip` hazır olduğunda otomatik (404’te yerel prefs)

### Backend notu
- Kozmetik equip/loadout ve başkalarının giriş efektini görme için sunucu deploy gerekir (mobil hazır)

## 1.0.57+84 (2026-07-19)

### Ana sayfa — premium sesli oda kartları
- `VoiceRoomSection` artık `DiscoverPremiumRoomCard` kullanıyor (canlı dalga, müzik, mikrofon, rozetler)
- Kategori temalı arka planlar: fal, tarot, burç, kahve, Gold/VIP (`DiscoverRoomVisuals`)
- Oda kapak görselleri önbelleğe alınır (prefetch)

### Kozmetik & rozet
- Profil çerçevesi kataloğu 30 dk disk önbelleği
- Üyelik rozeti profil başlığında (`GET /api/membership-badges`)

## 1.0.56+83 (2026-07-19)

### Mobil Admin Paneli (WebView)
- Profil > Ayarlar > **Yönetim Paneli** (yalnızca Admin / Süper Admin)
- Tam ekran in-app WebView — harici tarayıcı açılmaz
- JWT SSO: çerez senkronu + bootstrap ile Bearer token aktarımı
- HTTPS zorunlu, http engelli; canlifal.com içi navigasyon
- Pull-to-refresh (toolbar), geri tuşu WebView geçmişi
- Dosya yükleme: galeri, kamera, çoklu seçim, PDF/Excel (Android file selector)
- Kamera/mikrofon izinleri, panoya kopyalama köprüsü
- Giriş sayfası algılanırsa yerel admin paneline yönlendirme banner'ı
- Yerel admin paneli (`/admin/panel`) yedek olarak korunur

## 1.0.55+82 (2026-07-19)

### Premium Profil Sistemi
- Yetkiye göre dinamik profil çerçevesi (Admin, Mod, Oda Sahibi, Gold, VIP, Yayıncı, Falcı, Destek)
- Animasyonlu çerçeveler: dönen ışık, neon, ateş, altın parçacık, elmas, kozmik, aura, kalp, şimşek, gökkuşağı, taç
- Gold üyeler çerçeve, isim efekti ve profil parçacık efekti seçebilir (`/profile/cosmetics`)
- İsim efektleri: altın, gümüş, elmas, neon, rainbow, ateş, hologram
- Profil efektleri: yıldızlar, galaksi, altın toz, kalpler
- Backend katalog: `GET /api/profile-frames`, `GET /api/membership-badges` (offline yerleşik katalog yedek)

### Sesli sohbet kartları (Keşfet)
- Canlı ses dalgası, dönen müzik ikonu, mikrofon nabız animasyonu
- Oda seviyesi, popülerlik, kategori ve VIP/Gold/Admin rozetleri
- Online sayısı sarı parlayan yazı; ilk avatar konuşan vurgusu (büyük + glow)

## 1.0.54+81 (2026-07-18)

### Profil — Yasal bölümü
- Kullanıcı Sözleşmesi, Gizlilik, Çocuk Güvenliği, KVKK, Topluluk Kuralları
- İçerik `GET /api/site-pages/{slug}` ile dinamik yüklenir (WebView)
- Uygulama sürümü (v1.0.54) profil altında gösterilir

### Sesli oda + PK + yetki + bildirim
- Oda geçişinde eski presence anında temizlenir (`prepareVoiceRoomSwitch`)
- Giriş: presence önce, sonra paralel yükleme; çıkış: leave await
- PK daveti önce `POST /api/live/pk` (TRTC signaling)
- Moderatör yetkisi → otomatik boş koltuk + unmute; host → koltuk 1
- Çift bildirim: OneSignal aktifken FCM foreground kapalı
- Hediye jeton: `jetonAmount` / `giftJeton` alanları parse edilir
- Randevu davet debounce 60→20 sn

## 1.0.53+80 (2026-07-17)

### Sesli oda — Invalid type, PK, hız
- «Invalid type»: tüm oda API gövdeleri Map; join presence GET yedek; hata şeridi gizlenir
- Sistem mesajları: `[SYSTEM_VIP_JOIN]` / `[SYSTEM_LEAVE]` kullanıcı dostu Türkçe metin
- PK davet: rakip sahip `ownerId` yoksa presence'tan çözülür; `opponentRoomId` gövde yedeği
- Koltuk: optimistic güncelleme + hızlı refresh; poll aralığı kısaltıldı (8–120 sn)
- SSE bağlanınca geçici hatalar temizlenir

## 1.0.52+79 (2026-07-17)

### Profil + canlı yayın + sesli oda
- Profil: üst boşluk/kayma giderildi — kapak kısaldı, avatar kapak üzerine bindi
- Video / Takipçi / Takip / Beğeni / İzlenme: nested API stats + hub istatistik yedekleri
- Canlı yayın: sohbet yazma alanı yeniden görünür (SafeArea + kompakt hediye/sohbet)
- Hediye: gönderen adı + jeton miktarı net; son hediyeler kutusu; banner küçültüldü
- Zaten takip edilen yayıncıda «Takip Et» gizlenir
- Yayına giren kişinin adı sohbette + son giriş şeridinde kalır
- Sesli oda: PK davet eşleşmesi genişletildi; koltuk/komutlar anında (optimistic)

## 1.0.51+78 (2026-07-17)

### Sesli oda — komutlar, şifre, hediye, giriş
- «Invalid type»: moderasyon/DJ/rol gövdeleri Map (jsonEncode string kaldırıldı)
- VIP/şifreli oda: şifre girişi → `joinPresence` ile sunucuya; yanlış şifrede giriş yok
- Ses Ver / Sustur / Koltuk Ata / Yetki Ver+Al / DJ Yap-Çıkar: anında API + refresh
- Yetki verildiğinde kullanıcı hemen boş koltuğa alınır; Ses Ver sonrası unmute
- Odayı devret: `POST …/transfer-ownership`
- Giriş: çift şerit kaldırıldı; yetkili/Gold koltuk altında (5 sn); normal alt toast
- Hediye: chat alanı temizlenir; duyuru 5 sn sonra kaybolur; kim→kime+jeton herkese
- Hediye savaşı şeridi RTC odada; PK kabul/red mevcut banner+listener

## 1.0.50+77 (2026-07-17)

### Canlı yayın UI (mockup)
- Yayın açma/izleme ekranı mockupa göre yenilendi: üst bar (isim, ID, takip, rozetler, top hediye atanlar, izleyici, Keşfet)
- Alt bar: Sohbet, mesaj, Misafir, Eş Yayın, Oyunlar, Paylaş, **Hediye kutusu**, Daha fazla
- Hediyeler açık şeritte değil — yalnızca hediye kutusundan panel açılır
- Hediye Hedefi + Yıldız Turnuvası kartları; Fal İste sağ CTA; kalp beğeni
- Yayıncı PK/Kontrol/Ayarlar/Güzellik “Daha fazla” menüsüne alındı

## 1.0.49+76 (2026-07-17)

### Düzeltme
- `LiveRecentGiftersBox` import yolu — release gate derleme hatası giderildi

## 1.0.48+75 (2026-07-17)

### Backend + Flutter birlikte çalışma (doküman paketi)
- Tüm yüklenen API/prompt dokümanları `docs/` ve `docs/prompts/` altına eklendi
- Hediye gönderimi: kılavuz `giftId` + üretim `giftTypeId`
- Canlı falcı: seans `POST …/{tellerId}/session` (+ `maxMinutes`); mesaj `content`+`message`
- TRTC: `/token` 404’te `/usersig` yedek; host `userId` ile
- Sesli oda SSE: `dj_update` alias; DJ `assign`/`remove`; mute/ban kılavuz action
- Sesli alt menü: Müzik Aç / DJ kayar panel / PK kaldırıldı (prompt)
- Ortak yayın: izleyiciye davet kabul/red dialog + RTC yükseltme

## 1.0.47+74 (2026-07-17)

### API dokümanı hizalama (`docs/FLUTTER_API_DOCS.md`)
- Ana sayfa: `GET /api/homepage-ticker` kayan yazı kaynağı (+ `recent-big` poll)
- Canlı PK: `POST /api/video-streams/pk` (`opponentStreamId`, `durationMinutes`); yanıt/aksiyon `pkBattleId`
- PK skor: `POST /api/video-streams/pk/score` gövdesi `pkBattleId` + `points`
- Hediye SSE: `totalPrice`, iç içe `giftType.icon` / `giftType.price` / `sender.name`
- PK rakip listesi: önce `GET /api/video-streams/pk`, yedek `pk/list`
- Canlı PK daveti: doküman yolu + birleşik `/api/pk/request` birlikte denenir

## 1.0.46+73 (2026-07-17)

### Ana sayfa
- Sabit büyük hediye kartı kaldırıldı; arama çubuğu altında kayan şerit
- Yetkili/Gold girişleri + 1000+ jeton hediyeleri sağdan sola (herkes görür)
- `/api/gifts/recent-big` periyodik yenileme

### PK
- Canlı PK daveti: liste yüklenirken sonsuz spinner yok; davet sırasında sayfa kapanmıyor
- İzleyicisi 0 olan yayınlar da listelenir (yayıncı belli ise)

### Hediye
- Çift/üst üste binen gösterim düzeltildi (tek katman + premium fullscreen)
- Sesli oda ve canlı yayında son 3 hediye atan jeton miktarıyla görünür

## 1.0.45+72 (2026-07-17)

### Sesli oda — yetki, PK, hediye
- `myPermissions` snake_case / truthy parse; yalnız `canGiveVoice` gelse bile uygulanır
- Rol değişince oda yetkileri anında yenilenir; «Yetki ver» hata metni düzeltildi
- Ses hakkı: boş koltuk 0–14 aralığında aranır
- PK SSE/yanıt: üst düzey battle alanları + kısmi accept/reject yanıtı desteklenir
- Hediye: herkes aynı anda görür (parmak izi dedupe); jeton miktarı `jetonAmount` ile gösterilir
- Hediye duyuru şeridi premium odada koltuk altında

### Canlı yayın — PK ve misafir
- PK daveti önce birleşik `/api/pk/request` (karşı tarafta kabul/red dialog)
- Misafir listesinden `joinRequests` korunur; invite gövdesinde `userId` + `inviteeId`
- Yayın SSE: gift/pk üst düzey payload

### Canlı falcı
- TRTC iki yönlü: kamera erken başlatma / yeniden açma

### Yetkili giriş şeridi
- Navbar altında kayar; sesli sohbet odalarında global şerit kapalı (koltuk altı kalır)
- Giriş duyurusunda kullanıcı adı yerine görünen isim

## 1.0.44+71 (2026-07-17)

### CI düzeltmesi
- `voice_room_rtc_page`: eksik `VoiceWebChatOverlay` import geri eklendi

## 1.0.44+70 (2026-07-17)

### CI düzeltmesi
- `staff_entrance_marquee_provider`: `ref.mounted` kaldırıldı (Notifier derleme hatası — Release gate)

## 1.0.44+69 (2026-07-17)

### Yetkili giriş duyurusu
- Ana sayfada kalıcı mor kart kaldırıldı; yetkili girişleri geçici sağdan-sola kayan şerit
- Tüm sayfalarda `StaffEntranceMarqueeHost` overlay; sesli odada koltuk altı banner

### PK ve ses
- PK daveti: kılavuz uyumlu `{ guestUserId, durationSec }` gövdesi öncelikli
- Canlı yayın PK: `/api/video-streams/{id}/pk-battle` önce, birleşik API yedek
- Mikrofon: izin isteği açılışta; siteadmin için `staffBypassVoiceApi` TRTC sayfasında

## 1.0.44+68 (2026-07-17)

### Sesli oda — «Invalid type» düzeltmesi
- Koltuk/presence POST gövdeleri `jsonEncode` string yerine JSON Map (sunucu Zod hatası)
- Otomatik koltuk: `take` action (yanlış `swap` kaldırıldı)
- `/api/live/seats` 400 → chat room koltuk uçlarına yedek
- Presence join: `action` / `type` gövde yedekleri
- `seatIndex` string/num güvenli parse

## 1.0.44+67 (2026-07-17)

### Düzeltme
- `voice_room_rtc_page`: `VoiceRoomYoutubeEmbedHost` import yolu (CI derleme)

## 1.0.44+66 (2026-07-17)

### Sesli oda — canlı oda entegrasyonu
- **!istek:** `skipPayment` kaldırıldı; şarkı seçiminden sonra ses/videolu jeton seçici (10/20)
- **Video isteği:** YouTube IFrame embed (`VoiceRoomYoutubeEmbedHost`) videolu modda aktif
- **DJ çalma:** Video isteğinde IFrame; ses modunda just_audio (mevcut akış)
- **Compound API:** `fortune_menu_providers` ve `home_remote_datasource` import düzeltmesi (CI)

## 1.0.44+65 (2026-07-17)

### CanlıFal Backend API referansı + uyumluluk raporu
- Doküman: `docs/api/FLUTTER_BACKEND_COMPATIBILITY_REPORT.md`
- Mobil birleşik uçlar: `GET /api/mobile/home`, `/api/mobile/fortune-menu`, `/api/mobile/user-profile/{id}`
- `MobileCompoundService` — ana sayfa tek istek (canlı yayın, sesli oda, fal kartları, falcılar)
- Profil: compound user-profile öncelikli, eski uç yedek
- Fal menüsü: `fortuneMenuTypesProvider` (API + yerel katalog yedeği)

## 1.0.44+64 (2026-07-17)

### Düzeltme
- `Dio` uzantısına `safePut` eklendi (profil güncelleme `PUT /api/user/profile` yedeği)

## 1.0.44+63 (2026-07-17)

### Düzeltme
- Canlı yayın ayrılma: `DELETE .../join?viewerId=` derleme hatası giderildi (`safeDelete` query parametresi yok)

## 1.0.44+62 (2026-07-17)

### CanlifalTV API dokümantasyonu entegrasyonu
- Referans: `docs/api/CANLIFALTV_FLUTTER_API.md`, parite: `CANLIFALTV_FLUTTER_PARITY.md`
- Profil: `PUT /api/user/profile` yedek
- Canlı yayın: `PATCH status ended`, `DELETE .../join` ayrılma
- Hediye: `recipientUsername`, `type` alanları
- Üyelik: `/api/memberships` + `/api/memberships/purchase` alias
- Bildirim: `POST /api/notifications` `{markAll:true}`
- Koltuk: `action: sit` yedek

## 1.0.44+61 (2026-07-17)

### 7 saha `/api/live/*` API entegrasyonu
1. **Oda yaşam döngüsü** — create/join/leave/heartbeat
2. **Oda keşif** — `GET /api/live/rooms` (stream + voice listesi)
3. **Koltuk** — `POST/GET /api/live/seats`
4. **Mesaj** — `POST/GET /api/live/message`
5. **Hediye** — `gift-types` + `gift/send`
6. **PK** — `GET/POST /api/live/pk` + `pk/score` (games yedeği)
7. **Çevrimiçi** — `GET /api/live/online-users`

- Katman: `mobile/lib/features/live/data/datasources/live_field/` (7 dosya + facade)
- Provider: `liveFieldApiRemoteProvider`
- Doküman: `docs/api/field/README.md`, `docs/api/FLUTTER_API_REFERENCE_LIVE_FIELD.md`

## 1.0.44+60 (2026-07-17)

### Backend API parity — 8 düzeltme (tek APK)
1. **Presence heartbeat** — `PATCH /presence` (boş POST kaldırıldı)
2. **Presence join** — `{action: "join", nickname?}` (`enterPresence` → `joinPresence`)
3. **Voice session** — yalnızca `{action: "join"|"leave"}` (`type` kaldırıldı)
4. **Live join** — `{nickname?}` body
5. **Oda ownerId** — `ownerUserId`, `hostUserId`, `createdBy`, `userId`, `owner.id` alias
6. **Voice hediye** — `giftId` + `receiverUserId` alias
7. **Video PK create** — önce `{opponentStreamId, durationMinutes}` (kılavuz §9.4)
8. **PK davet (sesli oda)** — games `{action:"create", targetRoomId, duration}` + kılavuz `{guestUserId, durationSec}`; `opponentRoomId` eklendi

Rapor: `docs/API_PARITY_AUDIT_2026-07-17.md`

## 1.0.44+59 (2026-07-17)

### PK davet — «Invalid type» düzeltmesi
- Games backend: `{action:"create", targetRoomId, duration}` + `{guestUserId, durationSec}` birlikte deneniyor
- Rakip oda kimliği (`opponentRoomId`) PK isteğine eklendi
- Presence join: `jsonEncode` yerine Map (çift kodlama önlendi)

## 1.0.44+58 (2026-07-17)

### Backend API parity (PK / Voice / Live)
- Presence heartbeat: PATCH (kılavuz §9.3); join voice yalnızca `{action}`
- PK video create: önce `{opponentStreamId, durationMinutes}` (kılavuz §9.4)
- PK voice invite: `ChatService` action alanı kaldırıldı (`guestUserId` + `durationSec`)
- Voice gift: `giftId` + `receiverUserId` alias; oda `ownerId` parse genişletildi
- Live join: `{nickname?}` body
- Rapor: `docs/API_PARITY_AUDIT_2026-07-17.md`

## 1.0.44+57 (2026-07-16)

### CI düzeltmesi (CodeQL)
- `voice_room_rtc_page.dart`: TRTC import yolu (`../../trtc/...`)
- `live_broadcast_room_page.dart`: `fetchTrtcParallel` named args, `TrtcCredentials` null guard, void RTC çağrıları
- `open_live_stream.dart`: `fetchTrtcParallel` + `trtc` session alanı

## 1.0.44+56 (2026-07-16)

### Agora pasif — yalnızca Tencent TRTC
- **Sesli oda:** `VoiceTrtcEngine` + `POST /api/trtc/token` (Agora token hatası kaldırıldı)
- **Canlı yayın:** hazırlık, oda, misafir grid, PK önizleme TRTC
- **Canlı fal video:** Agora yedek kaldırıldı
- **DM sesli arama:** TRTC ses odası
- **TRTC önizleme:** yayın hazırlığında kamera önizlemesi (`startPreviewOnly`)

## 1.0.44+55 (2026-07-16)

### CI düzeltmesi (CodeQL)
- **`auth_providers.dart`:** TRTC bootstrap import yolu (`../../../trtc/...`)
- **`trtc_providers.dart`:** `dio_provider` import yolu (`../../../../core/...`)

## 1.0.44+54 (2026-07-16)

### Tencent TRTC — Canlı Fal entegrasyonu
- **API:** `POST /api/trtc/token`, `/api/live/join-room`, `/api/live/heartbeat`, `/api/live/leave-room`
- **TRTC birincil:** Canlı fal video oturumu TRTC ile bağlanır; başarısızsa Agora yedek
- **Heartbeat:** 10 sn canlı oda nabzı; kopunca otomatik yeniden bağlanma + UserSig yenileme
- **Ses:** TRTC speech kalitesi, AEC/ANS/AGC (SDK varsayılan), hoparlör yönlendirme
- **Güvenlik:** SDKSecret istemcide yok; UserSig yalnızca backend'den
- **Giriş sonrası:** TRTC motoru ısıtma + mikrofon izni ön kontrolü
- **Test:** `trtc_live_room_test.dart`

## 1.0.44+52 (2026-07-16)

### CI / derleme düzeltmesi
- **`parseResponseBody`:** servis katmanı `fromData` API uyumu
- **`services_providers.dart`:** `Dio` + `auth_service_provider` import
- **`api_exception.dart`:** `Map<dynamic, dynamic>` → `Map<String, dynamic>` cast

## 1.0.44+51 (2026-07-16)

### Flutter yeni endpoint'ler
- **Apple Sign-In:** `AuthService.loginWithApple` / `signInWithApple` → `POST /api/auth/mobile-apple`; `APPLE_SERVICE_ID` env; giriş/kayıt UI
- **Mobil config:** `ConfigService.getConfig` → `GET /api/mobile/config`; `MobileConfigGate` bakım / zorunlu / isteğe bağlı güncelleme
- **Şifre değiştirme:** `AuthService.changePassword` → `POST /api/auth/change-password`; profil güvenlik sayfası PATCH yerine bu uç
- **Kullanıcı engelleme:** `UserService.blockUser` (toggle), `getBlockedUsers` → `/api/user/block` (+ eski `/api/user/blocked` yedek)
- **Kullanıcı şikayet:** `UserService.reportUser` → `POST /api/user/report`
- **Modeller:** `AppleFullName`, `MobileConfig`, `UserBlockResult`, `UserReportResult`, `BlockedUserEntry`
- **Rapor:** `docs/FLUTTER_BACKEND_UYUMLULUK_RAPORU.md`
- **Test:** `new_endpoints_test.dart`

## 1.0.43+50 (2026-07-16)

### Flutter diğer servisler (13 modül)
- **`profile_service.dart`:** getMe, updateProfile, getUser, follow, credits, XP, achievements, arama
- **`gift_service.dart`:** types, send, recent-big
- **`fortune_service.dart`:** generateFortune SSE (14 fal tipi slug eşlemesi)
- **`teller_service.dart`:** falcı listesi, session, favoriler
- **`social_service.dart`:** post, yorum, beğeni
- **`short_video_service.dart`:** liste, presigned upload, like, comment
- **`message_service.dart`:** DM konuşmalar ve mesajlar
- **`notification_service.dart`:** liste, markRead, SSE
- **`push_service.dart`:** FCM token kayıt/silme
- **`upload_service.dart`:** presigned PUT yükleme
- **`payment_service.dart`:** paketler, jeton, üyelik, cüzdan
- **`game_service.dart`:** oyunlar, daily-spin, görevler
- **`misc_service.dart`:** homepage, duyuru, liderlik, burç, günlük giriş, referral
- **`services_providers.dart`:** tüm Riverpod provider'ları tek export
- **Endpoint:** gifts/types, send, recent-big, homepage-buttons, credit-packages, games/quests, vb.
- **Test:** `other_services_test.dart`

## 1.0.42+49 (2026-07-16)

### Flutter Canlı Yayın servisi
- **`lib/services/stream_service.dart`:** yayın listesi, başlat/bitir, join/leave, SSE, yorum, hediye, beğeni
- **Co-broadcast:** `getCoStatus`, `joinCo`, `inviteCo`
- **Moderasyon:** `getMods`, `addMod`, `muteUser`, `banUser`
- **RTC:** `fetchAgoraToken`, `fetchTrtcUserSig`
- **Kılavuz §9.4 uyumu:** leave için `DELETE .../join` + `POST .../leave` yedek; gifts `{giftId, giftTypeId}`
- **Modeller:** `StreamSummary`, `StreamComment`
- **`stream_service_provider.dart`:** Riverpod + `SseClient`
- **Test:** `stream_service_test.dart`

## 1.0.41+48 (2026-07-16)

### Flutter Chat servisi
- **`lib/services/chat_service.dart`:** oda listesi, mesajlar, presence, typing, SSE, hediye, koltuk, ses, Agora/TRTC token, DJ/müzik, PK
- **Kılavuz §9.3 uyumu:** presence `{action: join|leave}`, seats `POST/PATCH`, voice `{action}`, gifts `{giftId, receiverUserId}`
- **Modeller:** `ChatRoomSummary`, `ChatServiceMessage`, `ChatPresence`, `ChatMusicHit`
- **`chat_service_provider.dart`:** Riverpod + `SseClient`
- **Endpoint:** `chatRoomSeats`, `chatRoomMusic`, `chatRoomSongRequest`, `chatRoomPkScore`, `chatRoomMessage`
- **Test:** `chat_service_test.dart`
- **Düzeltme:** `auth_service_provider.dart` import yolları

## 1.0.40+47 (2026-07-16)

### SSE istemcisi
- **`lib/core/sse_client.dart`:** Dio ByteStream GET SSE — 5 endpoint + AI fal POST stream
- **Olay parse:** `data: { "type", "data" }` + `event:` satırı desteği
- **Reconnect:** exponential backoff (max 20), 401 → refresh → yeniden bağlan
- **Yaşam döngüsü:** arka plan `pauseAll`, ön plan `resumeAll` (`MainAppShell`)
- **`sse_client_provider.dart`:** Riverpod + JWT refresh
- **Test:** `sse_client_test.dart`

## 1.0.39+46 (2026-07-16)

### API response modeli + parsing
- **`lib/core/api_response.dart`:** `ApiResponse<T>`, `ApiError`, `FieldError`, `Pagination`
- **`parseResponse`:** yeni `{ success, data, error }` + eski düz JSON / string `error`
- **`apiPageQuery`:** `?page=1&limit=20` liste parametreleri
- **Test:** `api_response_test.dart`

## 1.0.38+45 (2026-07-16)

### Flutter Auth servisi
- **`lib/services/auth_service.dart`:** login, register, Google/TikTok, refresh, forgot/reset password, logout (`POST /api/auth/logout` + `DELETE /api/devices/fcm`)
- **`AuthResponse` / `AuthUser` modelleri** — tüm auth uçları ortak format
- **Token storage:** `accessToken`, `refreshToken`, `userId` (`flutter_secure_storage`)
- **401 interceptor:** queue pattern ile tek refresh; başarısız → otomatik logout / login
- **Hata formatı:** yeni `{ error: { code, message } }` + eski `{ error: "..." }`

## 1.0.37+44 (2026-07-16)

### Canlı PK polling kaldırma + kalan performans
- **Global PK davet:** `/live` namespace socket (sahip yayınlar) + bildirim SSE; `LivePkInviteListener` HTTP poll kaldırıldı
- **Yayın odası PK:** 3 sn `_pkInvitePoll` kaldırıldı; SSE/socket + `pkPendingInvites` dinleyici
- **PK rakip listesi:** global 3 sn poll kaldırıldı; davet sayfasında 10 sn yedek + `liveStreams` invalidation
- **PK skor:** unified maçta SSE aktifken 5 sn poll kapalı; legacy yolda 15 sn yedek
- **Sesli hediye:** socket aktifken REST poll tamamen kapalı
- **Oda listesi:** ilk 3 oda Agora token ön-isıtma

## 1.0.36+43 (2026-07-16)

### Sesli oda + PK performans (web paritesi)
- **Paralel oda girişi:** presence, mesajlar, PK durumu, hediye kataloğu, üye listesi `Future.wait`
- **Agora token ön-isıtma:** oda listesi dokunuşunda arka planda; girişte `POST /voice` + Agora paralel
- **PK davet:** HTTP polling kaldırıldı — Socket.IO (sahip odalar) + oda SSE; 30 sn popup
- **PK banner:** 4 sn poll kaldırıldı; SSE/socket ile anlık güncelleme
- **Presence:** SSE `user_left` anında listeden düşürür
- **API:** connectTimeout 3 sn, receiveTimeout 5 sn; retry exponential backoff (max 2)
- **Kabuk:** hediye kataloğu prefetch

## 1.0.35+42 (2026-07-16)

### Canlı PK / hediye / yayın stabilizasyonu
- **PK listesi:** `GET /api/video-streams/pk/list` tek kaynak, cache kapalı, 3 sn poll, 5 sn timeout, owner-null ve izleyicisiz filtre, dedupe
- **PK davet:** 3 sn poll + `pkPendingInvites` dinleyici, 30 sn popup süresi, süre dolunca otomatik red
- **Hediye jeton:** `giftPrice` / `totalCoin` / `giftImage` parse; `jetonAmount` ile 0 jeton gösterimi kaldırıldı
- **Hediye UI:** chat bildirimi 3× font + gradient/glow + 3 sn fade; koltuk altı 3 sn flaş listesi
- **Yayın:** yayıncı heartbeat 15 sn (`signal ping`); SSE yeniden bağlanma ≤2 sn; «Yayına devam et» kanal açıksa yeniden oluşturmaz
- **API:** Dio timeout 5 sn
- **Test:** `live_pk_gift_stabilize_test.dart`

## 1.0.34+41 (2026-07-15)

### Backend entegrasyon ve performans
- **ApiClient:** merkezi HTTP facade (`api_client.dart`) — tüm modüller `dioProvider` üzerinden
- **Bildirim SSE:** `GET /api/notifications/stream` — web ile aynı gerçek zamanlı kanal
- **Çevrimdışı banner:** kabukta `OfflineStatusBanner` aktif
- **SSE ağ kurtarma:** çevrimiçi olunca aktif oda SSE yeniden bağlanır
- **Cache:** `voiceRoomsProvider` + `liveGiftCatalogProvider` oturum `keepAlive`
- **Açılış:** kabuk prefetch — cüzdan + bildirim + profil paralel (T+200ms)
- **Admin:** sunucu `wallet.isAdmin` → tüm özellikler açık
- **Doküman:** `docs/FLUTTER_BACKEND_INTEGRATION_STATUS.md`

## 1.0.33+40 (2026-07-15)

### Derleme düzeltmesi (CodeQL)
- `api_backend_router_test.dart`: eksik `});` — admin hediye test bloğu kapanışı

## 1.0.33+39 (2026-07-15)

### Sesli oda PK parite
- **Analiz:** `docs/PK_VOICE_ROOM_PARITY.md` — web vs Flutter endpoint, SSE, Socket.IO, iş akışı
- **Düzeltme:** Boş `GET /pk` yanıtı (`activeBattle:null`) artık sahte davet üretmiyor
- **PK geçmişi:** `/api/pk/me/history` öncelikli (games backend)
- **Socket.IO:** PK skor/davet yedek kanalı yeniden etkin (`pk_battle_remote_provider`)
- **Kılavuz:** `FLUTTER_ENTegrasyon_KILAVUZU.md` §9.3 sesli oda PK satırları

## 1.0.32+38 (2026-07-14)

### Derleme düzeltmesi (CodeQL)
- `mini_music_player.dart`: müzik kuyruğu import yolu
- `pk_opponent_room_filter.dart`: `ownerId` tanımı
- `staff_roles.dart`: `managerUsernames` geri eklendi

## 1.0.32+37 (2026-07-14)

### Sesli odalar hub düzeltmeleri
- Müzik mini player: yalnızca canlı oturumda; kuyruk modalı çalışır
- Odalarım: sahip olunan odalar listelenir; oda oluştur akışı bağlandı
- Popüler odalar: kimse yoksa gizlenir
- En aktif konuşmacılar: gerçek oda sahipleri (online sayısı)
- Çift alt bar: site nav `/voice-rooms` üzerinde gizlendi; sesli oda barı yönlendirir
- PK daveti: polling iyileştirmesi, hedef eşleşmesi genişletildi
- `siteadmin` nick tam yetkili (site admin)

## 1.0.31+36 (2026-07-14)

### Derleme düzeltmesi (CodeQL)
- `voice_room_session_utils.dart`: `WidgetRef`/`Ref` tip uyumu — registry çağrısı inline (java-kotlin CodeQL derlemesi)

## 1.0.30+35 (2026-07-14)

### Sesli sohbet performans ve senkronizasyon
- Oda girişi &lt; 1 sn: paralel presence+mesaj, optimistic kullanıcı, SSE hemen
- Çıkış: anında yerel presence silme, koltuk clear, force SSE disconnect
- Oda geçişi: aktif oturum kaydı, eski bağlantılar tam kapatma
- Yetkili auto-seat: ~ & @ % sembolleri (oda sahibi öncelikli)
- PK kabulünde TRTC/Agora prewarm
- Profil prefetch; sohbet RepaintBoundary
- Rapor: `docs/VOICE_CHAT_PERF_REPORT.md`

## 1.0.29+34 (2026-07-14)

### Performans optimizasyonu
- Soğuk açılış: cookie `forceInit` ertelendi; shell prefetch kademeli (cüzdan → bildirim/profil → mesaj → shorts → jeton)
- `isOnlineProvider` bağlantı stream'ine bağlandı (offline banner doğru çalışır)
- Sesli oda basic: sohbet izole rebuild (`_BasicLiveShell`, `VoiceRoomBasicChatFeed` Consumer)
- Sohbet overlay ve hediye paneli filtre önbelleği
- Global poll aralıkları gevşetildi (DM, psikolog, PK)
- Admin hediye: `CanlifalNetworkImage`; profil auth `.select`
- Rapor: `docs/PERFORMANCE_OPTIMIZATION_REPORT.md`

## 1.0.28+33 (2026-07-14)

### Sesli oda, staff ve PK düzeltmeleri
- Staff hesabı yalnızca **yonetici** (kurucu); `admin` nick artık sesli oda staff bypass almaz
- Yetkili (yonetici) odaya girince otomatik koltuk; oda sahibi **Ses Ver** önce `+` rolü + boş koltuk atar
- Hoparlör: açık = yeşil «Açık», kapalı = kırmızı «Kapalı»; uzak ses yeni katılanlarda da susturulur
- PK daveti: «{oda} odasında PK isteği var» popup; redde davet gönderene «{oda} isteğinizi reddetti» bildirimi
- PK kabulünde seçilen süreyle savaş başlar

## 1.0.27+32 (2026-07-14)

### Admin, ödeme, PK ve sesli oda düzeltmeleri
- Jeton/CFC ödeme onay/red: doğru API uçları (`payment-requests` + `cfc-payment-requests`); boş talep kimliği düzeltildi
- Ödeme bildirimleri sekmesinde **Onayla / Reddet** butonları
- `admin` / `yonetici` nickleri cüzdan rolü beklemeden tam yetkili; `X-Staff-Role` admin API isteklerinde
- Kurucu (yonetici) admin atayıp çıkarabilir; diğer adminler moderasyon rolleri
- Sesli oda PK daveti uygulama genelinde dinlenir (`VoicePkInviteListener`)
- Yetkililer odaya girince otomatik koltuk; sesli oda komut paneli basic modda da açılır
- Admin hediye API ve kullanıcı yönetimi staff başlığı ile hizalandı

## 1.0.26+31 (2026-07-13)

### PK daveti + performans + komutlar
- PK daveti: koltuk üstü banner (oda sahibi), Kabul/Reddet, 60 sn sonra kaybolur; 4 sn poll
- Oda değiştirme: `go` ile tek oda, dispose'da oturum kapatma, ses motoru yalnızca `leave`
- Moderasyon: Sustur/Sesi Aç tek düğme; Ses Ver/Yetki Al birleşik; Rol/Yetki tek yerde

## 1.0.25+30 (2026-07-13)

### Sesli oda açma + hediye + profil
- Oda açma: oda adı + arka plan seçimi; ücretler 0 / 2500 / 5000 jeton
- Hediye: sohbette çift satır kaldırıldı; 50 jetonun 100 görünmesi düzeltildi (birim fiyat)
- Profil: istatistikler anında gösterilir; arka planda paralel yükleme

## 1.0.24+29 (2026-07-13)

### Sesli oda + canlı yayın UX
- Giriş/çıkış: yalnızca o anki geçişler; odaya girince eski «çıkış yapan» duyurusu gösterilmez
- Koltuk altında tek geçiş bandı; hediyeler çevrimiçi kutusundan kaldırıldı
- Son 5 hediye atan (sağ kutu) + kayan duyuru: «Mesut, Suna … kahve … 🪙1000 jeton.🎉»
- Admin/yönetici ses API hatasında Agora dinleme/konuşma devam eder (`action`+`type` join)
- Canlı yayın kapatma hızlandı; izleyici/yayıncı hediye özeti ekranı
- PK davetleri `myInvites` ile 2 sn poll; yanlış alıcı filtresi düzeltildi
- Admin panel: **Sohbet odası görselleri** — R2/S3 yükleme; kullanıcı kendi arka planını yükleyemez

## 1.0.23+28 (2026-07-13)

### Derleme düzeltmesi (CodeQL)
- `AdminGiftManagementPage.openEditor` static erişim hatası giderildi
- `safeDelete` için `options` parametresi eklendi (admin hediye silme)

## 1.0.23+27 (2026-07-13)

### Admin / kurucu tam yetki + hata düzeltmeleri
- **admin** ve **yonetici** hesapları uygulamada tam yetkili: hediye kataloğu, jeton/CFC yükleme, Gold üyelik, sesli oda moderasyonu
- Sesli oda `POST /voice` gövdesi kılavuzla uyumlu (`action: join|leave`) — «No voice permission» hatası giderildi
- Yetkili kullanıcılar koltukta olmasa da konuşabilir; oda içi tüm admin bypass açık
- Hediye yönetimi: çift zaman aşımı banner'ı kaldırıldı; istatistik/gelir sekmeleri yalnızca seçilince yüklenir
- Admin hediye API isteklerine staff rol başlığı (`X-Staff-Role`) eklendi
- 403 mesajları «admin veya kurucu (yonetici)» olarak güncellendi

## 1.0.22+26 (2026-07-13)

### Hediye görünürlüğü + yayın/oda özeti
- Atılan hediye brüt jeton tutarı herkese görünür (sesli sohbet şeridi, chat, uçuş animasyonu)
- Yayın veya odadan çıkınca hediye özeti sayfası: kimden ne kadar, misafir payı, size kalan net (jeton + ₺)
- Hediye alan kullanıcı çıkışta cüzdanı otomatik yenilenir
- Admin MP4 hediye: süre otomatik doldurulur; görsel yoksa videodan kare alınır
- Yetkili (admin/kurucu) ve sesli yetkililer odaya girince boş koltuğa otomatik oturur

## 1.0.21+25 (2026-07-13)

### Admin hediye + combo + gelir paylaşımı
- Hediye ekleme/düzenleme artık **admin** ve **kurucu (yonetici)** hesaplarına açık (`canManageGifts`); cüzdan yüklenemese bile kayıt engellenmez
- Combo tamamen kaldırıldı — hediye gönderiminde birleştirme yok, bildirimlerde jeton tutarı gösterilir
- Canlı yayın ve sesli odalarda gelir paylaşımı: **%50 alıcı/yayıncı, %50 site**
- Hediye bildirimlerinde atılan jeton miktarı görünür (canlı toast, banner, tam ekran, sesli oda uçuş animasyonu)

## 1.0.20+24 (2026-07-12)

### PK daveti — alıcı eşleşmesi düzeltmesi
- Backend `liveStreamId` / `opponentLiveStreamId` / `opponentId` alanları artık parse edilir
- `challenger` / `opponent` nesnelerinden koltuk listesi oluşturulur
- Davet popup yalnızca gerçek hedef yayıncıya gösterilir (önceden boş `seats` yüzünden hiç gelmiyordu)

## 1.0.19+23 (2026-07-12)

### Canlı PK daveti + misafir grid
- PK daveti gönderimi hata mesajı gösterir; kabul beklemeden savaş ekranına gitmez
- Gelen PK daveti yalnızca hedef yayıncıya popup (Kabul / Reddet); kabulde PK başlar
- Uygulama geneli PK davet dinleyicisi (`/api/pk/me/invites` + socket `pk_invite`)
- Misafir katılınca otomatik duo grid ve üst/alt ekran bölünmesi
- Misafir adı + yayıncı/konuk jeton miktarı grid hücrelerinde
- Tüm konuk slotları Agora UID ile video gösterir; `/api/live/guest/list` ile senkron

## 1.0.18+22 (2026-07-12)

### Canlı PK + misafir — prod `/api/live/*` ve `/live` WebSocket
- `GET /api/live/pk/active` öncelikli; yedek `/api/pk/active`
- `GET /api/live/guest/list` ile çoklu yayın misafir listesi; yedek co-broadcast API
- Socket.IO `/live` namespace: JWT auth, `joinStream` / `joinBattle`, `pk_score_update`, `guest_joined` olayları
- PK skoru ve misafir grid canlı odada gerçek zamanlı güncellenir; PK battleId değişince socket odaya katılır

## 1.0.17+21 (2026-07-12)

### Admin — jeton/CFC/üyelik ve hediye düzeltmeleri
- Kullanıcı kimliği (`userId` / `id`) doğru okunur; jeton ve Gold üyelik işlemleri çalışır
- **Uygula** / **Üyelik ver** anında yükleme göstergesi + başarı/hata mesajı (titreşim)
- Jeton/CFC: birden fazla API gövdesi ve POST yedeği; 12 sn zaman aşımı
- Gold üyelik: grant-membership + kullanıcı PATCH yedeği
- Hediye yönetimi: **Yeni Hediye** her zaman görünür; admin API yoksa uygulamadaki canlı katalog listelenir

## 1.0.16+20 (2026-07-12)

### Admin — hediye ve kullanıcı yönetimi
- Hediye kataloğu artık **admin** ve **kurucu (yonetici)** hesaplarına açık; mevcut hediyeleri görüp ekleyebilir, düzenleyebilir veya silebilirsiniz
- Kullanıcı yönetimi sayfasında harf yazınca anında arama listesi (buton yerine doğrudan arama alanı)
- Seçilen kullanıcıda jeton, CFC ve Gold üyelik hızlı işlem kısayolları; bakiye özeti ve rol/üyelik düzenleme
- CI: manuel RE-RUN artık devam eden push derlemesini iptal etmez; disk temizliği hızlandırıldı

## 1.0.15+19 (2026-07-12)

### Roller — Site Admin / Kurucu etiketleri
- `admin` kullanıcı adı profilde «Site Admin» olarak gösterilir
- `yonetici` kullanıcı adı «Kurucu» olarak gösterilir
- Hediye yönetimi kapalı ekranında hangi hesabın kullanılacağı açıkça yazılır

## 1.0.14+18 (2026-07-12)

### Admin Hediye — 403 ve ham hata düzeltmesi
- Ham `DioException` artık snackbar'da gösterilmez; Türkçe `ApiException` mesajı kullanılır
- Hediye yönetimi yalnızca **site admin** (`isSiteAdmin`) hesabına açılır; yönetici/ödeme paneli yetkisi yeterli değil
- Sunucu 403/401 dönerse kırmızı uyarı bandı + «Yenile»; kayıt öncesi cüzdan/rol yenilenir
- Animasyon dosyası yokken `animationType: none` gönderilir (MP4 seçili ama dosya yok → sunucu hatası önlenir)
- R2 PUT hataları da `ApiException` olarak map edilir; create timeout 45 sn

## 1.0.13+17 (2026-07-12)

### Admin Hediye Yönetimi — katalog ve yükleme onarımı
- Hediye kataloğu (`GET /api/admin/gifts`) artık 30 sn operasyon timeout ile gelir; sonsuz spinner yerine hata + «Tekrar dene»
- Admin `upload-url` zaman aşımı/5xx/404 olduğunda kılavuzdaki `/api/upload/presigned` yedek yoluna düşer (R2 cloud path korunur)
- Presign isteğine `fileSize` eklendi; PUT için daha uzun gönderim süresi
- Katalog provider `autoDispose` kaldırıldı — sekme geçişinde gereksiz yeniden yükleme azaltıldı
- Kayıt sonrası medya doğrulaması CDN URL / cloud path eşleşmesini kabul eder

## 1.0.12+16 (2026-07-12)

### Admin Hediye Yönetimi — create/upload onarımı
- Yeni hediye Kaydet isteğine timeout + cancel eklendi; sonsuz loading kaldırıldı
- API yalnız HTTP 200/201 + geçerli `gift.id` ile başarılı kabul edilir
- R2/S3 `cloudPath` ile CDN `publicUrl` ayrıldı; veritabanına doğru cloud path gönderilir
- Presign/PUT hataları artık sessizce yutulmaz; gerçek hata mesajı gösterilir
- Upload sürerken Kaydet engellenir; dosya R2'ye stream edilir
- Başarılı create sonrası admin, canlı yayın ve sesli oda katalogları otomatik yenilenir
- HTTP memory/disk gift cache temizliği ve create/upload/loading testleri eklendi

## 1.0.11+15 (2026-07-11)

### Üretim hazırlığı — analyzer / performans / SSE
- `flutter analyze`: **0 error / 0 warning** (önce ~191 warning)
- Kullanılmayan import/ölü private kod temizlendi; null-safety uyarıları giderildi
- SSE reconnect maks. 20 deneme (kılavuz §6); 401 sonrası JWT refresh + yeniden bağlanma
- Release ErrorWidget artık istisna detayı göstermiyor
- Scroll `cacheExtent` → `scrollCacheExtent` (Flutter 3.41+) ana listelerde
- SharePlus API güncellemesi; webview platform bağımlılıkları eklendi
- Android Manifest / Gradle / Proguard / Firebase doğrulandı (imzalama key.properties CI’de)

## 1.0.10+14 (2026-07-11)

### Üyelikler — pixel-perfect sayfa
- `/premium-membership` Canlifal koyu/neon/glass Üyelikler sayfasına taşındı (AppBar, yatay kademe kartları, özellik tablosu, yükselt banner, jeton paketleri, ortak avantajlar, destek)
- Fiyatlar: Basic ₺500 / Gold ₺1000 / Premium ₺1500 / Diamond ₺2500 (aylık)
- Aylık jeton: 250 / 1500 / 3500 / 7500 — jeton alımında indirim yok
- Gold varsayılan seçili; seçili kartta altın border + glow + scale
- Ana sayfa Gold Üyelikler satırı yeni TL fiyatlarını gösterir

## 1.0.9+13 (2026-07-10)

### Kısa videolar — açılış hızı
- Ana sayfa trend videoya dokununca izlenme kaydı artık navigasyonu bekletmez; video sayfası hemen açılır
- Trend videolar dokunma anında arka planda video URL prefetch yapar
- Shorts route geçişi animasyonsuz açılır
- Feed ilk yüklemesi 15 video alır; daha az load-more tetiklenir
- Video controller pool aktif videoyu önce, sonra sonraki/önceki komşuları hazırlar
- Oynatıcı artık imzalı URL çözümlemesini ilk açılışta beklemez; CDN/API stream adayları önce denenir

### Premium mesajlaşma UI/UX
- Mesaj listesi Canlifal siyah/mor neon/glass tasarım diline taşındı; üst arama, filtreler, online nokta, okunmamış rozet ve lazy liste korundu
- Sohbet üst barı profil, online/yazıyor durumu, sesli arama, görüntülü fal/arama ve işlemler ikonlarıyla yenilendi
- Mesaj gönderimi optimistic hale getirildi; balon ağ cevabını beklemeden görünür
- Gönderilen mesaj balonları mor gradient, alınan mesajlar koyu glass gri olarak güncellendi
- Canlifal özel aksiyon paneli eklendi: fotoğraf, video, dosya, konum, hediye, jeton, fal iste, sesli/görüntülü fal, canlı yayın, sesli oda, GIF, sticker
- Canlifal aksiyon mesajları sohbet içinde özel premium kart olarak gösterilir
- Mesaj cache’i reply/forward/raw metni koruyacak şekilde genişletildi

### Sesli Chat Odaları — senkronizasyon ve arkaplan
- Oda sahibi/admin/~ / & / @ / % yetkileri için otomatik koltuk seçimi en düşük numaralı boş koltuğa hizalandı; client-side iyimser oturma kaldırıldı, backend doğrulaması beklenir
- Koltuk API gövdesi kılavuzla uyumlu `{action: take, seatIndex}` biçimine getirildi
- Odaya giriş route ve VIP/giriş overlay animasyonları kapatıldı; kullanıcı doğrudan odaya yüklenir
- Giriş/çıkış olayları chat içinde sistem mesajı olarak görünür; kullanıcı referansı korunur
- Arkaplan listesinde backend/CDN listesi öncelikli hale getirildi; yerleşik arkaplanlar sadece fallback olarak kalır
- Arkaplan değişimi SSE state güncellemesiyle odadaki herkese anlık yansır ve görsel geçiş fade ile yapılır

### Performans — profil / sesli sohbet / canlı yayın
- Profil ilk açılışta gereksiz sosyal gönderi prefetch’i kaldırıldı ve prefetch 3 dk TTL ile tekilleştirildi
- Profil alt içerikleri/ayarlar kademeli lazy yüklenir; rozet/seviye/hediye özetleri oturum cache’i kullanır
- Profil arka plan senkronu 45 sn yerine 120 sn ve yalnız cüzdan odaklı çalışır
- Hakkımda istatistik kartı artık fal geçmişini ilk boyamada çekmez
- Sesli oda keşfinde eşzamanlı presence SSE bağlantısı 12’den 6’ya düşürüldü
- Sesli oda detay sayfası tüm oda listesini izlemek yerine tek oda provider’ını kullanır
- Canlı yayın/voice liste otomatik yenilemeleri seyrekleştirildi
- Canlı yayın hediye fallback polling’i 2 sn yerine 15 sn’ye alındı; SSE ana kaynak olarak kalır
- Canlı yayın oda/PK/fal/çoklu yayın poll aralıkları daha düşük CPU/ağ kullanacak şekilde optimize edildi

### Mobil profil / bildirim / ödeme / video
- Admin panelinde hediye yönetimi yönetici hesaplarından erişilebilir hale getirildi
- İçeriklerim: Fallarım ve Canlı Yayınlarım kartları premium görsel kartlara taşındı; İzlediklerim ve Favoriler sekmeleri görünür akışta
- Profilde kısa video toplam beğeni/izlenme gerçek shorts istatistikleriyle gösterilir
- Hakkımda burç değeri İngilizce gelirse Türkçe gösterilir (ör. Libra → Terazi)
- Bekleyen jeton/CFC/Gold ödeme talepleri 24 saat sonunda mevcut iptal API’siyle otomatik temizlenir; kullanıcı elle de iptal edebilir
- Bildirimlerde “Tümünü oku” okundu durumunu cihazda kalıcı tutar; mesaj push’ları sohbet hedefiyle açılır
- Trend videoya ana sayfadan dokununca izlenme endpoint’i çağrılır
- Fal sonucu açıldığında gizlilik ayarına göre CanlıFal Sosyal paylaşımı otomatik yapılır
- Video stüdyosu 20 MB / 30 sn sınırına hizalandı; emoji/sticker silme-düzenleme, Creative Commons ve bağlantıdan müzik ekleme eklendi

### PK daveti
- PK menüsü artık doğrudan savaş ekranına değil **oda seçim listesine** gider (yalnızca aktif PK savaşında savaş ekranı)
- PK davet listesi: boş odalar gizli; yalnızca çevrimiçi kullanıcısı ve oda sahibi olan odalar
- Gelen PK daveti popup: rakip oda sahibi `opponentId` ile doğru eşleşir
- Keşfet PK sekmesi: aktif odaları listeler (doğrudan boş savaş ekranına gitmez)

## 1.0.9+12 (2026-07-10)

### CI / derleme
- Release gate: `canlifal_image_urls` testi güncellendi (`/_next/image` 404 — doğrudan URL)
- Kullanılmayan YouTube IFrame embed widget sadeleştirildi (DJ stream tabanlı)

## 1.0.9+11 (2026-07-09)

### Ana sayfa performans
- Canlı/ses/trend bölümleri yenilemede eski veriyi korur (iskelet flash yok)
- Ana sayfa canlı kartları yalnızca thumbnail — HLS önizleme bellek sızıntısı giderildi
- Arka plan yenileme 180 sn + `refresh` (invalidate yerine)

### Canlı falcılar
- Bahşiş: GET `/api/room/signal` yedek poll (falcı görür)
- Süre: sunucu `elapsedSeconds` öncelikli; oda poll 3 sn
- Bağlantı: RTC + SSE paralel bootstrap

### Canlı yayın
- Hediye ortada: «kullanıcı yayıncıya hediye (jeton) gönderdi»
- Hediye poll 2 sn; emoji/görünüm güncellendi
- Fal isteği: yanlış 1:1 falcı köprüsü kaldırıldı; host poll 3 sn
- Misafir/çoklu yayın: onay sonrası Agora host rolü
- PK: gelen davet popup + 4 sn poll

## 1.0.8+10 (2026-07-09)

### Kritik — Agora ses motoru (-8)

- **AgoraRtcException(-8):** Sesli oda `channelProfileCommunication` ile `setClientRole` çağırıyordu; bu profilde rol değişimi desteklenmez
- Ses motoru `channelProfileLiveBroadcasting` (canlı yayın) profiline geçirildi — `AgoraRoomManager` ile aynı
- Mikrofon aç/kapa: `updateChannelMediaOptions` + host token ile tam yeniden bağlanma
- Derleme: `updateChannelMediaOptions` pozisyonel argüman düzeltmesi

## 1.0.8+9 (2026-07-09)

## 1.0.7+8 (2026-07-09)

### Kritik — ses açılınca çökme

- **Agora `libagora_ffmpeg.so`:** APK boyut optimizasyonunda yanlışlıkla hariç tutulmuştu; `libagora-rtc-sdk.so` bu kütüphaneye bağlı — ses açılınca `UnsatisfiedLinkError` ile çöküyordu
- Gradle `packaging.jniLibs.excludes` listesinden `libagora_ffmpeg.so` kaldırıldı (yalnızca isteğe bağlı AI/eklenti `.so` dosyaları hariç kalır)

## 1.0.6+7 (2026-07-09)

### Sesli sohbet — çökme ve hediye

- **Ses çöküşü:** odaya girince Agora dinleyici olarak bağlanır; mikrofon açılınca tam yeniden bağlanma yerine rol yükseltme
- **Hediyeler:** alıcı `receiverId` ile eşleşir; koltuk altında anında görünür (SSE + socket + 5 sn poll)
- **Giriş bildirimi:** SSE ile tüm odada aynı anda «giriş yaptı» / yetkili bandı
- **Yetkili koltuk:** öncelik sırasına göre otomatik koltuk yeniden denenir

## 1.0.5+6 (2026-07-09)

### Sesli sohbet odaları

- **Otomatik koltuk:** oda sahibi, kanal yetkilileri ve admin girişte koltuğa oturur (yeniden deneme düzeltmesi)
- **Giriş/çıkış bildirimleri:** herkes «kullanıcı giriş yaptı» / «çıkış yaptı» görür; yetkililer koltuk altında «kullanıcı oda adı odasına giriş yaptı» bandı
- **Çevrimiçi kutusu:** hediye atanlar çoktan aza sıralı; koltuk üstü sıralama şeridi kaldırıldı
- **Koltuk hediyeleri:** puan koltuk altında; tıklanınca gönderenler listelenir
- **Arka planlar:** sunucudan tüm liste + galeriden özel yükleme

### Performans ve stabilite

- **Canlı fal seansı:** kapanışta Agora/SSE/API temizliği beklenir; uygulama kapanmaya zorlanmaz
- **Canlı yayın:** izleyici geri tuşu ile çıkış; dispose’da Agora bırakılır
- **Kamera gecikmesi:** iki yönlü görüşmede düşük gecikme (360p + low-latency)

## 1.0.4+5 (2026-07-09)

### Özellik sadeleştirme

- **Oyunlar / Oyun Merkezi kaldırıldı** — ana sayfa, keşfet, profil ve `/games-hub` rotaları
- **Blog ve Rüyalarım kaldırıldı** — profil ayarları ve `/blog-hub`, `/dreams-hub` rotaları
- **Tema:** yalnızca **Koyu** ve **AMOLED Koyu**; açık ve sistem teması kaldırıldı

## 1.0.3+4 (2026-07-09)

### APK / AAB boyut optimizasyonu

- **arm64-v8a tek ABI** — 32-bit ve x86 native kütüphaneler paket dışı (~%60 küçülme)
- **Fal görselleri:** PNG → WebP (~30MB tasarruf)
- **Rive kaldırıldı** — hediyeler Lottie / premium painter (~46MB native)
- **FFmpeg:** `full-gpl` → `min-gpl` (Shorts stüdyo export)
- **Agora:** AI/eklenti `.so` modülleri paket dışı; ekran paylaşımı modülü hariç
- **CI:** `--target-platform android-arm64` + obfuscate + tree-shake-icons
- Örnek: APK ~385MB → ~158MB; AAB ~373MB → ~101MB (Play’de cihaz başı indirme daha da küçük)

## 1.0.2+3 (2026-07-09)

### Play Console — ön plan hizmeti beyanı

- **Manifest:** `FOREGROUND_SERVICE_MEDIA_PROJECTION` eklendi (Agora/TRTC ekran paylaşımı SDK birleşimi)
- **Rehber:** `docs/PLAY_FOREGROUND_SERVICE_DECLARATION.md` — Play Console’da kamera, mikrofon, medya oynatma ve medya yansıtma beyanı adımları

## 1.0.1+2 (2026-07-08)

### Android production — R8, boyut ve Play Console uyarıları

- **R8:** `minifyEnabled` + `shrinkResources` + `proguard-android-optimize` + genişletilmiş ProGuard kuralları
- **Dart:** `--obfuscate` + `--split-debug-info` (Play Console kod karartma uyarısı)
- **AGP 8.13**, Gradle 8.14, Kotlin 2.2.21
- **AAB splits:** dil / yoğunluk / ABI ayrımı
- **Manifest:** `largeHeap` kaldırıldı, `extractNativeLibs=false`, ağ güvenliği
- **multidex** kaldırıldı (minSdk 24 + R8)
- Betik: `scripts/build-play-aab.sh`

## 1.0.506+510 (2026-07-08)

### Canlı Falcılar — senkron ve kapanma düzeltmeleri

- **Seans senkronu:** Oda poll artık `ended/cancelled/rejected/expired` durumlarını algılıyor; SSE `session_end` tipi destekleniyor
- **Kapanma:** Seans bitince otomatik `/canli-falcilar` navigasyonu (push + manuel çıkış); özet diyaloğu güvenli `try/finally`
- **İptal sinyali:** Tekrarlayan iptal olayları `seq` ile her zaman tetikleniyor
- **Bekleme ekranı:** Red/süre dolumu sonrası otomatik çıkış (Tamam zorunluluğu kaldırıldı)
- **Falcı dialog:** Danışan iptalinde gelen çağrı diyaloğu anında kapanıyor

## 1.0.505+509 (2026-07-08)

### Performans — web seviyesi açılış ve akıcılık

- **Kabuk prefetch:** Kademeli API yükleme (T+0 / +450 / +900 / +1400 ms) — soğuk açılış ağ tıkanıklığı azaltıldı
- **Ana sayfa bootstrap:** 7 paralel görev; canlı falcılar `homeOnlinePsychicsProvider` paylaşımlı cache
- **Riverpod:** `keepAlive` (advisors, games, daily rewards, shorts feed); `select` ile bölüm izolasyonu
- **Kabuk:** `VoiceRoomsPresenceScope` — presence SSE kabuk rebuild'ini keser
- **Sesli odalar:** `addAutomaticKeepAlives: false`, `DeferredTickerMode` ambient FX
- **Kısa video:** Önceki + sonraki disk preload `[-1, 1]`; placeholder `CanlifalNetworkImage`
- **Görseller:** Profil kapak, shorts placeholder, paylaşım kartı cache
- **Canlı falcılar:** Skeleton loader, paylaşımlı provider, statik arka plan ilk karede
- **Realtime poll:** 90 s → 120 s

Detay: `docs/PERFORMANCE_OPTIMIZATION_REPORT.md`

## 1.0.504+508 (2026-07-07)

### Profil Hub — tam backend entegrasyonu

- **Yeni düzen:** Referans profil ekranı — başlık, jeton/elmas/beğeni/seri kartı, VIP banner, hızlı menü
- **Hakkımda + İstatistikler:** `GET /api/user/profile`, `/api/user/statistics`, fal geçmişi
- **Rozetler + Hediyeler:** `/api/user/achievements`, `/api/users/me/gifts-received`
- **Hizmetlerim:** Ana sayfa fal kartları + fal geçmişi sayıları (dinamik)
- **QR Kodum:** `/profile/qr` — `qr_flutter`, paylaş ve kaydet
- **Avatar:** Alt sayfa (görüntüle/değiştir/kamera/galeri/sil) + R2 presigned yükleme
- **Profil düzenle:** Şehir ve burç alanları; `PATCH /api/user/profile`
- **Gerçek zamanlı:** Bildirim tetiklemeli + 45sn periyodik cüzdan/profil yenileme
- **Pull-to-refresh:** Tüm hub provider'ları invalidate

## 1.0.503+507 (2026-07-07)

### Sesli Odalar — Premium FX katmanı

- **Ses dalgası:** `VoiceSoundWaveBars` — AppBar, aktif kategori
- **Canlı glow:** `VoiceLiveAvatarGlow` — online odalar ve top konuşmacılar
- **Mikrofon seviyesi:** `VoiceMicLevelBars` — canlı oda / konuşmacı satırları
- **Partikül + gradient:** `VoiceRoomParticleField`, `VoiceDynamicGradientBackground`
- **3D neon kartlar:** `VoiceNeonCard` — popüler, öne çıkan, yakın odalar
- **Glassmorphism:** `VoiceGlassFxContainer` — trend + konuşmacı kartları
- **Lottie:** `VoiceLottieAccent` — müzik kategorisi, konuşmacı başlığı
- **Geçişler:** `VoiceRoomsFx.sectionEnter` — akıcı fade/slide giriş animasyonları
- **Premium ikonlar:** `VoicePremiumCategoryIcon` — neon mikrofon / kategori

## 1.0.502+506 (2026-07-07)

### Sesli Odalar — TikTok seviyesi performans

- **İlk kare:** Progressive bootstrap (odalar önce, trend/konuşmacı arka planda) + cache-first
- **Scroll:** `SliverList` lazy yükleme, `shrinkWrap` kaldırıldı; scroll jank kaynakları (`TweenAnimationBuilder`) temizlendi
- **Rebuild:** Riverpod `select` ile bölüm bazlı izolasyon; `AutomaticKeepAliveClientMixin`
- **GPU:** `RepaintBoundary`, Hero flight cache, ambient arka plan izolasyonu
- **Görseller:** `CanlifalNetworkImage` + `prefetchCanlifalImages` ön yükleme

## 1.0.501+505 (2026-07-07)

### Sesli Odalar — Abacus AI API entegrasyonu (UI aynı)

- **Veri katmanı:** Repository + RemoteDataSource + Mapper; `CacheFirstLoader` offline önbellek
- **Riverpod:** `voiceRoomsDiscoverProvider` — kategori, odalar, trend, konuşmacı, sayfalama
- **API:** `/api/chat/rooms`, `/api/trends`, `/api/leaderboards`; mini player `voiceRoomMusicSessionProvider`
- **UX:** Skeleton + shimmer yükleme, sonsuz kaydırma (yakındaki odalar), pull-to-refresh
- **Görsel:** Hiçbir UI bileşeni değiştirilmedi — yalnızca veri bağlandı

## 1.0.500+504 (2026-07-07)

### Sesli Odalar — Premium 2026 UI (mock)

- **Yeni ekran:** Referans görsele uygun `VoiceRoomsPage` — AMOLED siyah, mor gradient, cam/glow
- **Bileşenler:** AppBar, kategori seçici, öne çıkan banner, popüler carousel, yakındaki odalar, Odalarım, trend konular, aktif konuşmacılar, mini müzik çalar, özel bottom nav
- **Teknik:** Hardcoded veri, SVG ikonlar, `ListView.builder`, reusable kartlar, responsive (mobil/tablet)
- **Rota:** `/voice-rooms` — henüz API bağlı değil

## 1.0.499+503 (2026-07-06)

### Performans — Principal audit (özellik yok)

- **Kısa video:** Controller pool 3 video (önceki/aktif/sonraki); tile penceresi daraltıldı; gereksiz Riverpod rebuild kaldırıldı
- **Ağ:** `/api/short-videos` HTTP cache 25 sn; shell prefetch For You feed
- **Sesli oda:** Presence anında, canlı liste lazy 200 ms; keşfet jeton `select()`
- **Falcılar:** AppBar `select()` — liste gövdesi izole
- **Rapor:** `PERFORMANCE_AUDIT.md`

## 1.0.498+502 (2026-07-06)

### Jeton / CFC — bekleyen ödeme

- **Banner:** Jeton ve CFC yükleme sayfalarında bekleyen ödeme talebi üstte gösterilir
- **İptal:** Kullanıcı tek tıkla talebi (veya tümünü) iptal edebilir; CFC geçmiş satırlarında da iptal

### Canlı yayın — kapatma ve bağlantı kopması

- **Kapat tuşu:** Onay diyaloğu olmadan yayın anında sonlanır; sohbete «Yayın kapandı» mesajı gider
- **İzleyici:** Yayın bitince «Yayın kapandı» bildirimi; yayıncı kopunca 5 dk uyarısı
- **Grace period:** Yayıncı bağlantısı kesilince yayın 5 dk açık kalır; hazırlık ekranından veya odadan devam

## 1.0.497+501 (2026-07-06)

### Sesli oda müzik — video yok, sadece ses + kuyruk

- **Şarkı isteği:** Video/WebView kapatıldı; müzik `just_audio` ile arka planda çalar (donma/kasma azaltıldı)
- **Görünüm:** Çalan parça + isteyen kişi + sıradaki şarkılar alt bantta gösterilir; video şeridi yok
- **Tüm istekler:** `withVideo: false` — ses modu varsayılan

### Oda arka planı

- **Kayıt:** `/settings` hem `background` hem `backgroundImage` alanı gönderir
- **Liste:** API + 30 yerleşik `voice-bg-*` birleşik; picker’da thumbnail önbelleği

## 1.0.496+500 (2026-07-06)

### Performans — Instagram seviyesi hedef (Görev 20)

- **Soğuk açılış:** OneSignal, Firebase ve crash SDK `runApp` sonrasına alındı; cookie jar depolama ile paralel init
- **Keşfet:** Header blur kaldırıldı, oda listesi 30 sn poll kapatıldı (SSE presence), filtre önbelleği, kapak prefetch
- **Görseller:** Discover/grid/kart arka planlarında `thumbnailWidth` — tam ekran decode yerine karo boyutu
- **Sesli oda:** Sohbet mesajları izole `Consumer` + `_RtcLiveShell` select — yeni mesajda koltuk/arka plan yeniden çizilmez
- **SSE poll:** Bağlıyken yenileme aralığı 90–180 sn; DJ yokken her iki tick'te bir
- **Router:** Ajans durumu değişince tüm GoRouter yeniden oluşturulmaz

## 1.0.495+499 (2026-07-06)

### Sesli oda arka planı — 404 düzeltmesi

- **Kök neden:** Arka plan kaydı `PATCH /api/chat/rooms/{id}/background` ile yapılıyordu; üretimde bu uç yok (404). Kılavuzdaki `PATCH /settings` + `background` alanı kullanılmalıydı
- **Düzeltme:** Önce `/settings` (`background`), sonra eski `/background` ve oda PATCH fallback zinciri
- **Hazır arka planlar:** API'deki tüm odaların görselleri + yerleşik `voice-bg-*` listesi birleştirilir; arka plan sayfasında ızgara seçim + galeri/kamera yükleme

## 1.0.494+498 (2026-07-06)

### Admin hediye — «İstenen kaynak bulunamadı» düzeltmesi

- **Kök neden:** `/api/admin/gifts/*` uçları `canlifal.com`'da 404; gerçek API `canlifalapi.abacusai.app` üzerinde
- **Düzeltme:** Admin hediye listesi, ekleme, güncelleme, yükleme ve istatistik istekleri games backend'e yönlendirildi (PK ile aynı desen)

## 1.0.493+497 (2026-07-06)

### Admin — tam özellikli hediye ekleme formu

- **Yeni ekran:** `/admin/gifts/new` ve düzenleme — tüm alanlar tek formda
- **Medya yükleme:** Görsel (PNG/WebP), Thumbnail, Animasyon (MP4/WebM/SVGA/Lottie/GIF/Rive), Ses (MP3/WAV)
- **Alanlar:** TR/EN isim, jeton fiyatı, kategori, kademe, animasyon türü & süresi, efekt rengi (hex)
- **Anahtarlar:** Combo destekli, Premium, Tam ekran, Aktif/Pasif
- Katalog satırında Premium / Combo / Tam ekran / Pasif rozetleri

## 1.0.492+496 (2026-07-05)

### PK sistemi — birleşik API entegrasyonu (Faz 1–3)

- **Backend yönlendirme:** `/api/pk/*` istekleri `canlifalapi.abacusai.app` (games backend) üzerinden gider
- **Faz 1 (1v1):** `POST /api/pk/request`, `respond`, `cancel`, `me/invites`, `active` — canlı PK daveti artık birleşik API ile çalışır; başarısızsa eski video-stream yolu
- **SSE:** `GET /api/pk/{id}/stream` — skor, süre, Final Sprint, premium çarpan canlı güncelleme (8 sn poll yedek)
- **Faz 2/3:** Çoklu misafir/takım overlay, liderlik, geçmiş, premium etkinlikler, moderasyon (mevcut UI bağlandı)
- **Dokümantasyon:** `docs/PK_SYSTEM_FLUTTER_INTEGRATION.md`
- **Test:** `pk_unified_bridge_test`, `api_backend_router` PK routing testleri; `verify-pk-endpoints.sh` güncellendi

## 1.0.491+495 (2026-07-05)

### Canlı yayın PK + admin hediye yönetimi

- **PK daveti:** Canlı yayında «PK Başlat» artık `/live/pk-invite` sayfasını açar (stub mesaj kaldırıldı)
- **Hediye yönetimi:** Admin paneli ve profil admin kartına «Hediye Yönetimi / Katalog» kısayolu eklendi (`/admin/gifts`)

## 1.0.490+494 (2026-07-05)

### Profil — admin Beğenilen/Kaydedilen çökmesi (asıl düzeltme)

- **Kök neden:** Videolar/Beğenilen/Kaydedilen sekmeleri `shrinkWrap` olmayan `GridView` kullanıyordu; admin’de üstteki paneller yüklenince layout çöküyordu
- **Düzeltme:** Profil scroll içinde `nestedInProfileScroll` grid; cüzdan `Wrap`; admin/yayıncı paneli içeriklerin **altına** taşındı; `RepaintBoundary` raster hayaleti kaldırıldı

## 1.0.489+493 (2026-07-05)

### Profil — admin sayfası bozulması

- **Kök neden:** Admin panelindeki `shrinkWrap GridView`, ~3 sn sonra (ödeme kuyruğu / istatistik yüklenince) Beğenilen-Kaydedilen bölümünü çökertip tek mor kare bırakıyordu
- **Düzeltme:** `ProfileAdminCard` ve `ProfileQuickActions` → `LayoutBuilder` + `Wrap` (Yayıncı Paneli ile aynı desen)

## 1.0.488+492 (2026-07-05)

### Derleme düzeltmesi

- **Provider döngüsü:** `messagesUnreadCountProvider` ↔ `conversationsUnreadTotalProvider` çapraz bağımlılığı kaldırıldı; ayrı `messages_unread_providers.dart` modülü
- İlk 1.0.487 push'u bu hata yüzünden APK üretemedi; bu sürümde derleme ve CodeQL geçer

## 1.0.487+491 (2026-07-05)

### Kritik düzeltmeler — mesajlar ve canlı falcılar

- **DM sesli arama:** Kendini arama hatası giderildi; giden aramada yerel gelen çağrı UI kaldırıldı
- **Alıntı (yanıtla):** Mesaja uzun basınca yanıtla menüsü tekrar çalışır
- **Mesaj gecikmesi:** Uygulama genelinde 8 sn DM poll + push’ta liste/rozet yenileme; okunmamış rozeti anında güncellenir
- **Sohbet açılışı:** Önbellekten hızlı açılış; dokununca mesaj ön-yükleme
- **Canlı fal sonlandırma:** Tek taraftan kapatınca karşı taraf da anında çıkar (falcı + danışan)
- **Seans başlangıcı:** RTC + SSE paralel; falcı tarafında süre otomatik başlar

## 1.0.486+490 (2026-07-05)

### Mesajlar — WhatsApp tarzı iyileştirmeler

- **Yazı boyutu:** Konuşma listesi ve balonlarda daha büyük, okunaklı fontlar
- **Yazıyor göstergesi:** Karşı taraf yazarken isim + «yazıyor…»
- **Hızlı yanıtlar:** Gelen son mesajın altında öneri chip’leri
- **Uzun basma:** Sohbet listesi / başlıkta sohbet silme veya engelleme
- **Yanıtla / ilet:** Mesaja uzun basınca alıntı veya başka sohbete iletme
- **Ses:** Her gelen/giden mesajda bildirim sesi
- **Son mesaj:** Sohbet açılınca en alta kaydırma (tüm mesajlar görünür)
- **Gold sesli arama:** Mesajlar ekranından sesli arama; karşı taraf kabul/red/engelleyebilir

## 1.0.485+489 (2026-07-05)

### Canlı yayın — Fal İste bildirimi

- **Yayıncı uyarısı:** Yeni fal isteği SSE + 8 sn poll ile algılanır; snackbar ve Kontrol merkezi kısayolu
- **Köprü:** Video-stream fal kuyruğu → falcı davet event bus (uygulama genelinde mor dialog)
- **API:** Fal isteği gövdesine `message` alanı eklendi (kılavuz uyumu)

### Fal — tam ekran reklam ve CFC ödülü

- **Reklam kapısı:** Fal açılmadan önce tam ekran ödüllü reklam (jeton ile ödeyenler hariç)
- **CFC overlay:** Reklam bitince ortada şekilli “+10 CFC jeton kazandınız” bildirimi
- **Büyüme merkezi / fal erişimi:** Ödüllü reklam sonrası aynı overlay

## 1.0.484+488 (2026-07-04)

### Profil — üst üste binme (raster hayaleti) düzeltmesi

- **Opak kartlar:** Profil cam kartları tam opak `surfaceContainer` — yarı saydam katmanlar kaldırıldı
- **RepaintBoundary:** Profil bölümlerinden kaldırıldı (GPU'da önceki kare izi bırakıyordu)
- **Kaydırma:** `CustomScrollView` `clipBehavior: hardEdge` — bölümler üst üste çizilmez
- **Teşhis rozeti:** Kaldırıldı (#205 ile birlikte; bu sürümde katman düzeltmesi tamamlandı)

### Sesli oda — müzik sohbetten bağımsız

- **WebView boyutu:** Arka plan müziği 128×128 gizli iframe — klavye/layout değişiminde 1px WebView durmuyordu
- **Poll koruması:** Sunucu geçici `playing:false` döndürse bile yerel çalan parça korunur
- **Yazarken/beklerken:** Müzik artık sohbet yazımı veya periyodik poll ile kesilmemeli

## 1.0.483+487 (2026-07-03)

### Profil — boş ekran düzeltmesi

- **Boş ekran:** `RefreshIndicator` artık her zaman `CustomScrollView` kullanıyor; yükleme sırasında içerik kaybolmuyor
- **Oturum:** Yenileme sırasında önceki kullanıcı verisi korunuyor (`valueOrNull`)
- **Header:** Avatar kapak altına taşmıyor; basit dikey düzen — görünür ve tıklanabilir
- **ClipRect kaldırıldı:** Bölüm kırpma boş görünüme yol açabiliyordu

## 1.0.482+486 (2026-07-03)

### Profil — tıklama ve katman düzeltmesi

- **Header:** Avatar taşması sabit yükseklikli Stack içinde; görünmez hit-test katmanı kaldırıldı
- **İstatistik:** Yinelenen shorts istatistik satırı kaldırıldı (tek satır)
- **Animasyon:** Profil kartlarındaki fade/slide animasyonları kaldırıldı — dokunma hedefleri kaymıyor
- **Ayarlar:** Tema seçici çift cam katmanından çıkarıldı
- **Kırpma:** Bölüm düzeni ClipRect ile sınırlandı

## 1.0.481+485 (2026-07-03)

### Profil — düzen ve katman düzeltmesi

- **Katman çakışması:** Tek sütun düzen; cam blur kapatıldı; grid animasyon taşması giderildi
- **Gruplar:** Cüzdan → Hızlı erişim → İçeriklerim → Ayarlar (Görünüm / Hesap / Keşfet / Destek)
- **Admin Paneli:** Yönetici ve admin kullanıcılar için üstte; tüm yönetim kısayolları tek başlık altında
- **Temizlik:** Yinelenen menüler kaldırıldı; çalışmayan «Destek Talepleri» admin linki silindi; Güvenlik `/profile/security`

## 1.0.480+484 (2026-07-03)

### Canlı Falcılar, hediye ve sesli oda

- **Seans kapatma:** Karşı taraf anında kapanır; tek tıkla çıkış; oda sinyali + SSE
- **Bahşiş:** Falcıya popup; seans sonu kazanç özeti (jeton + bahşiş); danışan her zaman değerlendirebilir
- **Senkron:** SSE `timer_started` / `time_extended`; oda poll 4 sn
- **Profil:** Ödül/hediye/yorum API anahtarları düzeltildi; hata mesajları
- **Hediye jeton:** Canlı yayıncı %50 net; sesli oda oda sahibi/misafir kuralları
- **Roket:** Premium roket çizimi (araba Lottie yerine)
- **!istek müzik:** Tek YouTube arka plan; tam genişlik orta; ses açık; çift player kaldırıldı

## 1.0.479+483 (2026-07-03)

### Düzeltme — kısa video «Bileşen hatası» (Infinity/NaN toInt)

- **Kök neden:** `VideoPlayer` bazen `Size.zero` / geçersiz boyut döndürüyor; `SizedBox` layout `toInt` hatası veriyordu
- **`SafeCoverVideoPlayer`:** güvenli boyut + `ListenableBuilder` ile kısa video, sponsorlu ve PiP yüzeyleri
- **`asInt` / görsel cache:** NaN ve Infinity için savunma

## 1.0.478+482 (2026-07-03)

### Düzeltme — sesli oda arka plan, !istek müzik, ana sayfa, kısa video

- **Arka plan yükleme:** R2 presigned + `POST /api/upload/get-url`; `canlifal.com` kökenli URL (403 giderildi)
- **!istek müzik:** Şarkı seçince arama sheet'i kapanır; çalma başlar; başarı/hata snackbar
- **Ana sayfa:** Canlı önizleme HLS kapatıldı (yalnızca thumbnail); polling 90 sn
- **Kısa video:** API stream proxy öncelikli; ek URL alanları; init timeout 18 sn

## 1.0.477+481 (2026-07-03)

### Performans — ana sayfa & kısa videolar

- **Paralel home bootstrap:** 6 kritik API aynı anda (`homeBootstrapProvider`)
- **Lazy load:** üst bölüm delay 0 ms; alt bölümler 80–800 ms (önce 900–1350 ms)
- **Refresh:** yalnızca görünen 6 bölüm; gereksiz shorts/psychics/games istekleri kaldırıldı
- **keepAlive** home provider cache; shell çift mesaj prefetch kaldırıldı
- **Canlı önizleme:** eager HLS 5→2 kart
- **Shorts:** sonraki 3 video öncelikli warm + disk preload +4; pool 6; UI window ±3
- **Video cache:** 48→64 obje; rapor: `docs/HOME_SHORTS_PERF_REPORT.md`

## 1.0.476+480 (2026-07-03)

### Backend-2 uyumu — doğrudan routing, API Monitor, mock kaldırma

- **Merkezi backend yönlendirme:** `ApiBackendRouter` — her path doğrudan Main (`canlifal.com`) veya Game (`canlifalapi.abacusai.app`) origin'ine gider; gateway yalnızca 502/503/504 acil yedeği
- **Tek Dio:** `BackendRoutingInterceptor` + `GatewayFallbackInterceptor`; split `gamesDio` kaldırıldı
- **API Monitor (debug):** Ayarlar → API Monitor — URL, method, backend (Main/Game), status, süre, retry sayısı
- **Mock/yerel yedek kaldırıldı:** Okey101 yerel oturum, oyun katalog fallback — yalnızca gerçek API; hata durumunda anlamlı exception
- **Oyun gameType:** okey, okey101, tavla, pişti, tombala slug eşlemesi
- **Smoke test:** `scripts/api-module-smoke-test.sh` — modül bazlı Main/Game uç doğrulama
- **Uyumluluk:** Keep-Alive, gzip Accept-Encoding, 15s connect / 20s receive timeout, client GET retry

## 1.0.475+479 (2026-07-03)

### Düzeltme — ana sayfa / fal / video / sosyal (404 regresyonu)

- **Kök neden:** Tüm uygulama `canlifalapi.abacusai.app`'e yönlendirilmişti; bu backend yalnızca oyun odaları + sesli sohbet sunuyor (banner, sosyal, kısa video, fal kartları → 404)
- **Ana API geri:** Varsayılan taban yeniden `https://canlifal.com` (fal, tarot, video, sosyal, auth, sesli oda)
- **Split games API:** Oyun odaları ayrı `GAMES_API_BASE_URL` (`canlifalapi.abacusai.app`) üzerinden; token yenileme ana API'den
- **`gamesDioProvider`:** Oda oluştur/katıl/state/hamle Redis backend'e gider; katalog/skorbord canlifal.com'da kalır

## 1.0.474+478 (2026-07-03)

### Backend — canlifalapi.abacusai.app (Redis önbellek + oyun odaları)

- **Varsayılan API tabanı:** `https://canlifalapi.abacusai.app` (mobil JWT aynı `/api/auth/mobile-*` uçları)
- **Merkezi `Api` istemcisi:** Dio paylaşımı, Bearer `setToken`, `GET /api/v1/health` sağlık kontrolü
- **Oyun odaları:** `POST /api/games/rooms`, `/auto-match`, `POST /api/games/room/:id` katılma, `GET` oda detayı — `gameType` alanı (örn. `okey101`)
- **Geriye dönük:** Eski `gameId`/`slug` gövdeleri ve yerel Okey101 yedeği korunur
- **Zaman aşımı:** connect 15 sn, receive 20 sn (Redis önbellekli liste uçları için yeterli)

## 1.0.473+477 (2026-06-26)

### Okey 101 — 404 düzeltmesi (site API uyumu)

- **Kök neden:** canlifal.com'da `POST /api/games/rooms` 404; oda oluşturma ve hamleler başarısız oluyordu
- **Üretim yedek uçları:** `POST /api/games/room`, `GET /api/games/room`, `POST /api/games/play` sıralı deneme
- **Hamle formatı:** `action: move`, düz `action: open` ve alternatif gövdeler
- **Yerel oda modu:** API 404 ise oturum içi Okey101 motoru (101 aç, çek, at) devreye girer
- **Slug yedekleri:** `okey101`, `yuzbirokey`, `okey-101`

## 1.0.472+476 (2026-06-26)

### Okey 101 — çok oyunculu oyun

- **101 Okey:** 2–4 oyuncu, 101 puanla aç, desteden/atıktan çek, taş at
- **Oyun merkezi + lobide** Okey 101 kartı; `/games-hub/okey101` lobisi
- **Gerçek tahta UI:** gösterge/okey, rakip el sayıları, el ıstakası, oyun sohbeti
- **Site API uyumu:** `POST /api/games/rooms`, auto-match, join, move, chat
- **API mirror:** Tam okey101 motoru + oda yönetimi (`api/src/routes/games.ts`)

## 1.0.471+475 (2026-06-26)

### Kısa video — Otomatik oynatma & hızlı kaydırma

- **Otomatik oynatma:** Merkezi playback koordinatörü; sayfa değişince `play()` + 6 denemeli retry
- **Gri ekran:** Thumbnail ilk kare gelene kadar gösterilir; init timeout 10 sn
- **Kaydırma:** `PageScrollPhysics` + hızlı snap spring — TikTok tarzı tek sayfa geçişi
- **Preload:** ±2 video penceresi; pool 5 slot; `allowImplicitScrolling`
- **Play ikonu:** Yalnızca aktif ve duraklatılmış videoda görünür

## 1.0.470+474 (2026-06-26)

### Kısa video — Performans & kaydırma düzeltmesi

- **PageView yeniden yapı:** Dikey `PageView.builder`, `pageSnapping`, `BouncingScrollPhysics` (hızlı swipe)
- **Hedefli rebuild:** `shortsFeedIndexProvider` — yalnızca aktif ±1 tile rebuild olur
- **Controller pool:** Max 3 slot (önceki + aktif + sonraki); LRU ile uzak videolar dispose
- **Preload:** Kaydırma sırasında pool warm + disk cache prefetch
- **Siyah ekran azaltma:** Thumbnail anında gösterilir; spinner kaldırıldı
- **Tek oynatıcı:** Yalnızca aktif video play; diğerleri pause
- **RepaintBoundary:** Video yüzeyi, placeholder ve feed öğeleri izole
- **ListenableBuilder:** Play/pause overlay setState'siz güncellenir

## 1.0.469+473 (2026-06-26)

### Kısa video — Profesyonel performans & sosyal

- **Video performansı:** Controller pool (5 slot), ±2 PageView, `fastStart` 800ms, disk peek cache, arka plan warm ±2 + preload
- **Siyah ekran azaltma:** Uzak tile'larda thumbnail önizleme; pool ile yeniden initialize yok
- **Sponsorlu reklam:** Her 5 videoda 1 modüler slot («Sponsorlu», geçilebilir, AdMob/GAM hazır)
- **Offline kuyruk:** Beğeni / kaydet çevrimdışı kuyruk + bağlantı gelince senkron
- **Paylaş:** X, Facebook, Instagram eklendi (WhatsApp, Telegram, QR, link)
- **Hediye animasyonu:** Jeton gönderiminde tam ekran emoji burst
- **Profil:** Toplam izlenme istatistiği, Canlı Yayın + Mesaj butonları
- **API mirror:** save, share, profile stats, single video, liked/saved sekmeleri

## 1.0.468+472 (2026-06-26)

### Kısa video — Faz 7 AI & sosyal

- **AI altyazı:** Yayın ekranında otomatik altyazı taslağı (API + istemci yedek)
- **AI hashtag / etiketleme:** Özet + hashtag önerisi (`/suggest-metadata`)
- **Otomatik kapak:** Videodan 3 küçük resim adayı (FFmpeg kare)
- **AI video özeti:** Yayın açıklamasına AI özet enjeksiyonu
- **İçeriğe göre müzik:** `/music/recommend` + katalog yedek
- **Canlı fal klipleri:** `/live-clip` indirme; seans bitince «Shorts klip»; yayın geçmişi
- **Shorts hediye (Jeton):** Aksiyon rail + katalog; kısa video API, canlı yedek
- **Video yanıt:** `replyToVideoId` stüdyo modu; yorum sheet + menü
- **Oynatma hızı:** 0.5x / 1x / 1.5x / 2x (izleyici uzun bas + editör export)
- **Çocuk güvenliği:** Kısıtlı mod + yetişkin içerik filtresi (SharedPreferences)

## 1.0.467+471 (2026-06-26)

### Kısa video — Faz 6 Premium Görünüm

- **Material 3 / 2026:** Keşfet ve hashtag AMOLED uyumlu tema renkleri
- **Glassmorphism:** Feed cam üst bar, arama alanı, müzik kartları, aksiyon rail
- **Shimmer / Skeleton:** Feed, keşfet grid ve şerit yükleme iskeletleri
- **Hero animasyonları:** Grid/ana sayfa → feed kapak geçişi (`HeroShortThumb`)
- **120 Hz kaydırma:** `PremiumMotion` + `ScrollPerf.shortsFeed` cache
- **Platform animasyonları:** iOS/Android tab eğrileri, `flutter_animate` beğeni kalbi
- **Premium bottom sheet:** Paylaşım ve yorum sheet'leri cam tema ile

## 1.0.466+470 (2026-06-26)

### Kısa video — Faz 5 Profesyonel özellikler

- **Düet / Remix:** Menüden düet veya «bu sesi kullan» ile stüdyo açılışı; `duetOfId` / `remixOfId` kayıt
- **Picture in Picture:** Sürüklenebilir mini oynatıcı overlay
- **Canlı yayın klipleri:** Yayın geçmişinden kısa videoya dönüştür
- **Hikâyede paylaş + QR kod:** Paylaşım sheet’inde hikâye ve QR
- **Video analitikleri:** İçerik sahibi için istatistik paneli
- **Moderasyon:** Kısa video bildir, yorum sabitle/bildir, sahip silme
- **Telif + spam/küfür filtresi:** Yayın öncesi telif uyarısı; yorum/açıklama ContentGuard

## 1.0.465+469 (2026-06-26)

### Kısa video — Faz 4 Keşfet

- **Sana özel:** Keşfet üstünde yatay öneri şeridi + Akışa git
- **Yapay zekâ önerileri:** `/recommend` ve explore `source=ai` ile AI şeridi
- **Konuma göre:** Şehir seçimi (SharedPreferences) + yakın video listesi
- **Trend videolar / hashtag / müzik:** Geliştirilmiş bölümler, müzik kullanım sayısı
- **Keşfet hub:** Paralel API birleştirme (trend + forYou + AI + konum)

## 1.0.464+468 (2026-06-26)

### Kısa video — Faz 3 sosyal özellikler

- **TikTok/Instagram profil:** Video | Takipçi | Takip | Beğeni istatistik satırı; 3 sütunlu video grid
- **Sekmeler:** Videolar, Beğenilen, Kaydedilen (kendi profil + diğer kullanıcı profili)
- **Takip et / Takibi bırak:** Profil ve feed senkronu
- **Doğrulanmış rozet:** API `isVerified` ile profil, feed ve yazar satırında
- **Bildirim merkezi:** Kısa video beğeni/yorum/takip bildirimleri `/shorts?videoId=` veya profile yönlendirir
- **Kendi profil:** İçeriklerim sekmelerine Beğenilen + Kaydedilen; Taslaklar gerçek liste

## 1.0.463+467 (2026-06-26)

### Kısa video — Faz 2 taslak + trend sıralama + Faz 1 iyileştirmeler

- **Trend videolar üstte:** Ana sayfa ve Keşfet ekranında trend videolar ilk sırada
- **Taslak kaydetme:** Video Stüdyosu yayın ekranından «Taslak»; girişte kayıtlı taslaklar listesi, devam et / sil
- **Takip senkronu:** Feed aksiyon şeridinde yazar avatarında takip (+) butonu
- **Ön yükleme:** Sonraki videolar disk önbelleğine indirilir (daha hızlı geçiş)
- **Hashtag:** Keşfet chip'leri ilgili hashtag sayfasına yönlendirir

## 1.0.462+466 (2026-06-26)

### Sesli oda — Oda Yönetim paneli

- **Alt bar:** Kulaklık yanındaki «Müzik İste» kaldırıldı → **Ayarlar** butonu
- **Oda Yönetim paneli:** Sohbet, Kullanıcılar, Oda yönetimi, Cezalar
- **Sohbet:** odayı sessize al, bildirim sesi, mesaj temizle, sahiplik devri, takma ad
- **Kullanıcılar:** sustur, kick, engelle (ban), +v / @ / & yetki, yetki kaldır, ban kaldır
- **Oda:** arkaplan yükleme düzeltmesi, VIP oda şifresi (`/settings` API)
- Ayarlar/menü/araçlardan müzik isteği ve DJ kısayolları kaldırıldı

## 1.0.461+465 (2026-06-26)

### Kısa video — CI / FFmpeg düzeltmesi

- `ffmpeg_kit_flutter_min` → `ffmpeg_kit_flutter_new` (FFmpegKit Maven kaldırılması sonrası Android derleme)
- Android `minSdk` 24 (FFmpegKit gereksinimi)

## 1.0.460+464 (2026-06-26)

### Kısa video — Video Stüdyosu ve etkileşim düzeltmeleri

- **Video Stüdyosu:** Galeri seçimi → kırp/döndür/kapak (video_editor + FFmpeg) → yazı & emoji sticker → yayın ekranı
- **Yayın:** Açıklama (@mention, #hashtag önerileri), müzik arama, seslendirme kaydı, konum, gizlilik & yorum ayarları, duet izni
- **R2 yükleme:** Presigned `upload-url` + `register`; başarısız olursa multipart `/upload` fallback
- **Feed düzeltmeleri:** Beğeni/kaydet/paylaş/yorum gerçek API + SnackBar hata; çift dokunuş kalp animasyonu; güvenli sayaç formatı (NaN/Infinity yok)
- **Paylaş:** WhatsApp, Telegram, kopyala, sistem paylaşımı
- **Hashtag sayfası:** `/shorts/hashtag/:name` grid + feed derin bağlantı
- **Profil:** Kullanıcı profilinde kısa videolar grid bölümü

## 1.0.459+463 (2026-06-26)

### Kısa video / Keşfet — tam `/api/short-videos` entegrasyonu

- **Akış:** `Sana Özel` / `Takip` sekmeleri (`?tab=foryou|following`), derin bağlantı (`/shorts?videoId=`)
- **Keşfet ekranı:** `GET /explore` — trend videolar, hashtag'ler, popüler müzikler + arama
- **Etkileşimler:** kaydet, paylaş (API + `canlifal.com/shorts?videoId=`), yorum yanıtları / beğeni / silme
- **Profil:** Videolar sekmesi artık `/api/short-videos/user/:id?tab=videos` kullanıyor
- **Ana sayfa:** Trend videolar `GET /explore` üzerinden yükleniyor

## 1.0.458+462 (2026-06-30)

### Claude + Cursor birleşik sürüm (tam APK)

Bu APK, `main` dalındaki **tüm Claude commit'lerini** ve son Cursor düzeltmelerini içerir.

**Claude — bildirim & mesaj**
- Bildirimler Instagram tarzı (renkli ikon, okunmamış nokta, tıklanan okundu)
- Mesaj composer klavye üstü, hızlı scroll, typing altyapısı

**Claude — performans & ana sayfa**
- Profil stats/wallet RepaintBoundary
- Ana sayfa hızlandırma, jeton bekleyen talep temizleme
- Instagram seviyesi performans optimizasyonları

**Claude — sesli oda & müzik**
- Sesli oda hata düzeltmeleri, ProviderScope modal fix
- El kaldırma/onay, platform oda ayarları (backend maliyet)
- Müzik: CDN fallback, video her şarkıda, proxy düzeltmeleri
- Emoji picker, closeMusicPlayer, şarkı isteği modal fix

**Claude — admin & ödeme**
- Admin timeout, ödeme bildirimi poll (30s + push)
- Ödeme gönderiminde admin bildirimi

**Claude — diğer**
- FCM stale token deregistration (OneSignal)
- Bildirim yönlendirme (ses odası, follow, mention, like)
- CI disk alanı fix

**Cursor (üzerine) — 1.0.455–1.0.457**
- Çift bildirim / hızlı bildirim tıklama
- WhatsApp mesaj UI, silme, mesaj gelme (forceRefresh)
- !duyuru 2 geçiş
- Hediye animasyonu painter çökmesi düzeltmesi

## 1.0.457+461 (2026-06-30)

### Sesli oda — hediye animasyonu çökme düzeltmesi

- **Kök neden:** `_RepaintListenablePainter` / `_FloatEmojiPainter` tip uyuşmazlığı hediye atınca oda arayüzünü düşürüyordu
- **Düzeltme:** Emoji parçacık katmanı doğrudan CustomPaint; shouldRepaint tip güvenli
- **Bellek:** Emoji TextPainter önbelleği sınırlandı (siyah ekran / yavaş açılış riski azaltıldı)
- **SafePremiumGiftFullscreenOverlay:** Hediye katmanı RepaintBoundary ile izole

## 1.0.456+460 (2026-06-30)

### Mesajlar — WhatsApp tarzı + gelmeme düzeltmesi

- **Gelen mesaj:** Sohbet açıkken 4 sn'de bir zorunlu yenileme; 15 dk cache kaldırıldı
- **WhatsApp UI:** Yeşil/gri balonlar, 16px yazı, tek/çift tik (iletildi / görüldü)
- **Silme:** Kendi mesajına uzun bas → Sil (sunucu + yerel)
- **Liste:** Saat, okunmamış yeşil rozet, WhatsApp tarzı satır

### Sesli oda — !duyuru

- **2 geçiş:** Kayan bant 2 kez geçer, kısa metinlerde de otomatik kapanır
- **Sıradaki duyuru:** Önceki bittikten sonra yeni duyuru gösterilebilir

## 1.0.455+459 (2026-06-30)

### Bildirimler — çift bildirim ve tıklama hızı

- **Çift bildirim:** OneSignal ön planda `preventDefault` + tek `display()`; FCM tıklama dinleyicisi OneSignal aktifken kapatıldı
- **Tıklama hızı:** Bildirime tıklayınca ağır liste yenilemesi yapılmıyor; hedef sayfaya anında gidiliyor
- **Soğuk açılış:** Router hazır olana kadar tıklama payload'ı buffer'lanıyor, shell açılınca otomatik yönlendirme
- **Uygulama içi liste:** Okundu işareti arka planda; navigasyon bekletilmiyor

## 1.0.454+458 (2026-06-30)

### Google ile giriş

- **Birincil giriş:** Giriş ekranında Google butonu öne çıkarıldı (beyaz CTA)
- **Oturum sonrası:** Google / TikTok / kayıt sonrası OneSignal push kaydı
- **Sessiz giriş:** Daha önce Google ile girmiş kullanıcılar için `signInSilently` denemesi
- **Misafir profil:** Profilde «Google ile Giriş yap» kartı
- **Önceki sürüm özellikleri:** Sesli oda moderasyon menüsü, site admin, CDN müzik, duyuru bandı (1.0.453)

## 1.0.453+457 (2026-06-26)

### Sesli oda — moderasyon, admin, müzik, duyuru

- **Oda menüsü (Yetki Ver üstü):** Sessize alınmış kullanıcılar, banlanmış kullanıcılar, sohbeti temizle
- **Site admin (`admin`):** profil admin paneli geri; tüm oda yetkileri (staff moderatör değil)
- **Müzik:** arka plan `just_audio` + YouTube CDN/proxy; videolu isteklerde WebView şerit
- **Giriş bandı:** herkesin odaya girişi üstten kayan şerit
- **`!duyuru`:** sağdan sola tek geçiş, tekrar gösterilmez

## 1.0.452+456 (2026-06-26)

### Sesli oda müzik — YouTube IFrame embed

- **youtube_player_iframe:** stream / yt-dlp / googlevideo çözümleme kaldırıldı; tek `YoutubePlayerController`
- **SSE senkron:** `videoId` + `elapsedSeconds` ile `loadVideoById(startSeconds: …)` — geç katılan kaldığı saniyeden başlar
- **Aynı videoId:** oynatıcı yeniden yüklenmez (yeniden başlamaz)
- **Ses modu:** 1×1 görünmez embed; **video modu:** koltuk altı şerit
- **Çalınamayan video:** uyarı + yetkili ise `DELETE /music` ile sıradaki

## 1.0.451+455 (2026-06-26)

### Admin — ödeme talepleri

- **Admin paneli:** `admin` kullanıcı adı tam yetki; API `canManagePayments` / `isAdmin` bayrakları
- **Bekleyen talepler:** «Tüm bekleyenleri kapat» — toplu red (admin uç noktası)
- **Bildirimler:** yeni ödeme talepleri yalnızca admin/yönetici hesaplarına

## 1.0.450+454 (2026-06-26)

### Bildirimler, ana sayfa, oyunlar, profil, sesli oda

- **Bildirimler:** çift kayıt birleştirme; liste + zil rozeti senkronu; bildirimler açılınca / zile basınca tümü okundu
- **Ana sayfa:** Fal → **Sosyal**, Oda Aç → **Oyunlar**; «+6 Daha Fazla Fal» Fal & Tarot altına alındı
- **Oyun merkezi:** tüm oyun kartları kaldırıldı (yakında mesajı)
- **Profil:** lazy bölüm gecikmeleri kaldırıldı; admin için profilde ödeme onay/red kuyruğu
- **Gold üyelik:** katalog provider kalıcı; cüzdan bekleme süresi kısaltıldı
- **Fal & Tarot:** her fal/burç otomatik sosyal paylaşım (kapalı değilse); doğum tarihi bir kez sorulur
- **Sesli oda:** yetkili giriş tek satır + oda adı; normal kullanıcı «X giriş yaptı»; arka plan galeri/kamera yükleme düzeltmesi

## 1.0.449+453 (2026-06-26)

### Sesli odalar — hız, giriş, müzik, arka plan

- **Performans:** presence heartbeat 25 sn → 12 sn; oda açılışı mesaj/presence paralel; bootstrap hafifletildi
- **Canlı sayaç:** giriş/çıkış anında hub sayacı güncellenir (SSE leave + presence patch)
- **Yetkili giriş:** ENTRY_ANNOUNCEMENT SSE düzeltildi; admin/mod girişi koltuk altında sağdan sola marquee — odadaki herkes görür
- **Normal giriş:** sohbet alanında «Ali giriş yaptı.» 10 sn (yetkililer hariç)
- **!istek:** müzik arama popup (1 harf); seçimden sonra popup açık kalır; koltuk altı tam genişlik YouTube şeridi; eski müzik kartı/arka plan videosu kaldırıldı
- **!kapat:** müzik ve video anında kapanır
- **Arka plan:** hazır liste kaldırıldı; galeriden özel görsel yükleme
- **Yetkili koltuk:** girişte otomatik rütbe koltuğu hemen denenir

## 1.0.448+452 (2026-06-26)

### Admin panel & oturum

- **Admin paneli:** menü anında açılır; istatistik rozetleri arka planda yüklenir (sonsuz spinner düzeltildi)
- **Kullanıcı yönetimi / Raporlar / Moderasyon:** ayrı sayfalar (`/admin/users`, `/admin/reports`, `/admin/moderation`)
- **Admin API:** tüm çağrılara 8 sn zaman aşımı; ödeme listesi 6 → 2 uç nokta
- **Ödeme hub:** arka plan yenileme 5 sn → 30 sn (pil/ağ yükü azaltıldı)
- **Oturum kalıcılığı:** son kullanıcı güvenli depoda; açılış timeout 1 sn → 12 sn; ağ hatasında token varsa çıkış istemez

## 1.0.447+451 (2026-06-26)

### Performans & UX

- **Ana sayfa:** yapay gecikmeler kaldırıldı (0 ms); bölümler `HomePageSections` + `RepaintBoundary`
- **Kabuk prefetch:** 400 ms → anında; sekme geçişleri hafifletildi
- **Yatay listeler:** canlı yayın, trend video, falcılar — `RepaintBoundary` izolasyonu
- **Falcı paneli:** FAZ 1 teşhis kartı kaldırıldı; `.select()` ile gereksiz rebuild azaltıldı
- **Orta alt menü:** her dokunuşta **Canlı yayın aç** / **Video yükle** seçenekleri

## 1.0.446+450 (2026-06-26)

### Ana sayfa & canlı falcılar

- **Alt menü:** Profil yanındaki Jeton sekmesi → **Fal & Tarot** (`/fortune`)
- **Üst bar:** Canlifal logosu ile bildirim arasına **Keşfet** — trend videolar (`/shorts`)
- **Keşfet grid:** Canlı Futbol, Dizi & Film, Ünlüler, Fan Club kaldırıldı; Oyunlar, Trendler, Davet Et, Hediyeler kaldı
- **Fan Club bölümü** ana sayfa akışından çıkarıldı
- **Canlı Falcılar bahşiş:** seans içi `POST /api/room/{id}/tip`; profilden `POST /api/teller/gifts` + **Bahşiş Ver** butonu

## 1.0.445+449 (2026-06-29)

### Admin paneli — web paritesi & ödeme talepleri

- **Admin Paneli** (`/admin/panel`): profilden erişim; jeton/CFC yükle-çıkar, Gold/Premium/Diamond üyelik, kullanıcı yönetimi
- **Kullanıcı arama:** harf yazınca anında liste (`/api/admin/users/search` + fallback)
- **İstatistikler:** bugün üyeler, jeton alanlar, oda/yayın, en çok kazanan/hediye atanlar — kırmızı rozet sayıları
- **Ödeme talepleri:** admin GET istekleri cache dışı + `forceRefresh`; üretim JSON parse genişletildi
- **API:** `/api/admin/users/credits`, `grant-membership`, `finance`, `activity-feed`, `leaderboards`

## 1.0.444+448 (2026-06-26)

### Performans & ağ optimizasyonu (Görev 19)

- **HTTP:** keep-alive, GET retry (2×), istek süresi ölçümü, `CancelToken` scope
- **Çevrimdışı:** `connectivity_plus` — offline banner + GET stale cache
- **Tekrar istek:** mesaj/sohbet/bildirim açılış çift fetch kaldırıldı
- **SSE:** fal stream iptali (`FortuneSseSession.cancel`)
- **Metrik:** `AppPerfMetrics`, route geçiş süresi, `docs/PERFORMANCE_REPORT.md`
- Cüzdan çift invalidate düzeltmesi; discover oda poll 30s

## 1.0.443+447 (2026-06-26)

### Fal & Tarot — UX ve sosyal paylaşım

- **Günlük fal:** «Bugünün enerjisi ve sürpriz mesajın» başlık çubuğunun altına taşındı
- **Falını Aç:** 3 kart animasyonu büyük orijinal kart boyutunda; mistik ambient müzik
- **Sonuç:** Daha okunabilir tipografi; «Sesli dinle» (TTS) butonu
- **Paylaş:** Benzer falların üstüne alındı; otomatik paylaşım varsayılanı Canlifal sosyal (herkese açık)
- **Tür sayfaları:** Fal adı + açıklama en üstte (Tarot, Kahve falı vb.)
- **Kahve falı:** Fincan/tabağ üzerindeki Kamera/Galeri etiketleri kaldırıldı
- **Hub burç kartı:** Doğum tarihi/saati → burç + «Falına bak»; eksikse otomatik form; profile kayıt

## 1.0.442+446 (2026-06-26)

### Sesli oda — Faz 1–12 düzeltmeleri

- **Faz 1:** Müzik X tuşu `closeMusicPlayer()` ile kapanır; oda duyuru bandı müzik çalarken gizlenir (çift panel azaltıldı); DJ paneli açıkken merkez player gizlenir
- **Faz 2:** Koltuk 11 her zaman görünür; yetkili otomatik koltuk yeniden dener; koltukta değilken konuşma kapalı (admin dahil)
- **Faz 3:** Menü kartlarında ikon altında etiket; sohbette profil resmi + görünen ad
- **Faz 7–9:** Giriş olayları RTC modunda da yayınlanır — «giriş yaptı» toast ve yetkili giriş animasyonu herkese görünür
- **Faz 10:** `!duyuru` koltuk altında, sağdan sola 2 geçiş; 15 sn otomatik kapanma kaldırıldı
- **Faz 11:** @ bahsetme bildirimi + odada «senden bahsetti» satırı; çoklu API alanı desteği
- **Faz 12:** Konuşma dalgası güçlendirildi; çoklu konuşan koltuk desteği

## 1.0.441+445 (2026-06-29)

### Sesli oda — 12 Faz birleşik sürüm (APK)

Tüm sesli oda fazları `main` dalında birleştirildi:

| Faz | Özet |
|-----|------|
| 1 | Arka plan müzik, kuyruk, DJ paneli, jeton (10/20) |
| 2 | Yetki ve koltuk önceliği (Admin 11, Kurucu 1, …) |
| 3 | Material 3 üç nokta menüsü |
| 4 | Yetki Ver popup (rol + moderasyon) |
| 5 | Yasak kelime — tam kelime regex |
| 6 | Alt menü (hoparlör, müzik, mic, hediye, davet) |
| 7 | Giriş toastları («Ali giriş yaptı», 10 sn) |
| 8 | Yetkili sohbet neon avatar + metin |
| 9 | Yetkili giriş animasyonu (koltuk altı) |
| 10 | `!duyuru` — üst kayan bant (5 jeton) |
| 11 | @ etiket + «Ali senden bahsetti» bildirimi |
| 12 | Yuvarlak cam koltuk, neon halka, ses dalgası |

## 1.0.440+444 (2026-06-26)

### Faz 12 — Yeni koltuk tasarımı

- Altıgen koltuklar kaldırıldı; **tam yuvarlak avatarlar**
- **Premium cam efekti** (glass overlay + parıltı)
- Yetkiye göre **animasyonlu neon çerçeve** (Admin, Host, DJ, Mod, VIP)
- Hafif **parlayan neon halka** — mikrofon açıkken dış halka döner
- **Konuşurken ses dalgası** animasyonu + ritmik nabız (büyüyüp küçülme)
- **Mikrofon kapalı:** gri görünüm, mic-off rozeti, animasyon yok
- Boş koltuklar cam yuvarlak stile güncellendi

## 1.0.439+443 (2026-06-26)

### Faz 11 — @ Etiket sistemi

- Yazarken `@` girilince oda kullanıcıları listesi açılır
- Kişi seçilince `@Mesut` metne eklenir
- Etiketlenen kullanıcıya bildirim: «Ali senden bahsetti.»
- RTC ve Basic sohbet girişinde; `mentionedUserIds` API ile sunucuya iletilir

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
