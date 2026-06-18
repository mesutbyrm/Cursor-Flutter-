# Canlifal Flutter — Web Özellik Paritesi Test Raporu

**Tarih:** 2026-06-18  
**Uygulama sürümü:** `1.0.263+266` (`mobile/pubspec.yaml`)  
**Üretim API:** `https://canlifal.com`  
**Kapsam:** !istek müzik, SSE, DJ, oda müziği, fal talebi, jeton düşümü, görüntülü görüşme, canlı sohbet

---

## 1. Özet

| Kategori | Kod paritesi | Üretim uç doğrulama | Birim test |
|----------|--------------|---------------------|------------|
| !istek müzik sistemi | ✅ (komut) / ⚠️ (picker) | Kısmi (anonim probe) | ✅ Parser |
| SSE (sesli oda) | ✅ | ✅ Uç mevcut | — |
| DJ sistemi | ✅ | ✅ | — |
| Oda içi müzik oynatma | ✅ | Kısmi | ✅ Sync |
| Fal talebi oluşturma | ✅ | ✅ (401 = auth gerekli) | — |
| Jeton düşümü | ⚠️ | Auth gerekli | — |
| Görüntülü görüşme (TRTC) | ✅ | ✅ (POST uç mevcut) | — |
| Canlı sohbet | ✅ (oda) / ⚠️ (fal seansı) | Kısmi | — |

**Genel sonuç:** Flutter istemcisi web ile aynı üretim uçlarını büyük ölçüde kullanıyor; kod incelemesi ve anonim endpoint probu **tam E2E kanıtı sağlamaz**. Oturumlu JWT ile canlı ortamda manuel veya entegrasyon testi önerilir.

**Doğrulama yöntemleri:**
1. Statik kod analizi (`api_endpoints.dart`, feature modülleri)
2. Birim test dosyaları (`mobile/test/`) — CI yalnızca `dart analyze` çalıştırır, `flutter test` çalıştırmaz
3. Anonim `curl` probu (`canlifal.com`, Bearer olmadan)
4. Gerçek oda kimliği: `cmokyb9o9007iod09gi6pb1tb` (public `/api/chat/rooms` listesinden)

---

## 2. Endpoint Bazlı Test Matrisi

### 2.1 !istek Müzik Sistemi

| Endpoint | Metot | Mobil dosya | Probe (anonim) | Durum | Not |
|----------|-------|-------------|----------------|-------|-----|
| `/api/chat/rooms/{id}/music-request-by-query` | POST | `chat_room_remote_datasource.dart` | 404 (sahte oda) | ✅ Kod | `!istek` komutu bu uca gider (`skipPayment: false`) |
| `/api/chat/rooms/{id}/song-request` | POST | `chat_room_remote_datasource.dart` | 200 (sahte oda) | ⚠️ | Fallback + picker yolu `skipPayment: true` |
| `/api/music/search` | GET | `chat_room_remote_datasource.dart` | 401 | ✅ | Bearer gerekli — beklenen |
| `VoiceMusicSync.parseIstekSongTitle` | — | `voice_music_sync.dart` | — | ✅ | `voice_music_sync_test.dart` |

**Akış:**
- Sohbet satırı `!istek Sanatçı - Şarkı` → `chat_room_providers.dart` `sendMessage()` → `_submitMusicRequestByTitle(song, priority: false)` → `requestMusicByQuery` (ücretli)
- YouTube arama picker → `submitSelectedSong()` → `skipPayment: true` → `song-request` (ücretsiz bypass)

### 2.2 SSE Bağlantıları

| Endpoint | Metot | Mobil dosya | Probe | Durum | Not |
|----------|-------|-------------|-------|-------|-----|
| `/api/chat/rooms/{id}/stream` | GET (SSE) | `voice_room_sse_service.dart` | 200 (gerçek oda, auth yok) | ✅ | Mesaj, presence, DJ, fal_request olayları |
| `/api/video-streams/{id}/stream` | GET (SSE) | `video_stream_sse_service.dart` | — | ✅ | Canlı yayın izleyici/sohbet/hediye |
| `/api/chat/rooms/{id}/stream` (falcı fal) | GET (SSE) | `live_fortune_request_sse_service.dart` | — | ⚠️ | Yalnızca falcının aktif yayın/sesli odası varsa bağlanır |

**SSE olay işleme (`voice_room_sse_service.dart`):**

| Olay | İşleniyor | Not |
|------|-----------|-----|
| `messages` | ✅ | Sohbet anlık |
| `presence` | ✅ | Koltuk/liste |
| `dj` / `music` | ✅ | DJ state + oynatıcı |
| `fortune_request` | ✅ | Falcı davet SSE |
| `gift` | ❌ (noop) | Hediye Socket.IO köprüsüne bırakılmış |

### 2.3 DJ Sistemi

| Endpoint | Metot | Mobil dosya | Probe | Durum |
|----------|-------|-------------|-------|-------|
| `/api/chat/rooms/{id}/dj` | GET/POST | `chat_room_remote_datasource.dart`, `room_music_remote_datasource.dart` | 200 (gerçek oda) | ✅ |
| `/api/chat/rooms/{id}/music-queue` | GET | `room_music_remote_datasource.dart` | 401 | ✅ (auth gerekli) |
| SSE `dj` olayı | — | `voice_room_sse_service.dart` | — | ✅ |
| Socket.IO `gift`/`dj` | — | `voice_room_gift_socket.dart` | — | ✅ (yedek kanal) |

### 2.4 Oda İçi Müzik Oynatma

| Endpoint / bileşen | Mobil dosya | Durum | Not |
|--------------------|-------------|-------|-----|
| `/api/chat/rooms/{id}/music-stream` | `chat_room_remote_datasource.dart` | ✅ | Stream URL çözümleme |
| `/api/chat/youtube-stream` | `youtube_stream_resolver` | ✅ | googlevideo URL süresi dolabilir |
| `VoiceRoomDjPlayer` | `voice_room_dj_player.dart` | ✅ | just_audio + sync |
| `RoomPlaybackSync` | `room_playback_sync.dart` | ✅ | `room_playback_sync_test.dart` geçer |

### 2.5 Fal Talebi Oluşturma

| Endpoint | Metot | Mobil dosya | Probe | Durum |
|----------|-------|-------------|-------|-------|
| `/api/fortune-tellers/session` | POST | `home_remote_datasource.dart`, `live_fortune_flow.dart` | 401 | ✅ |
| `/api/fortune-tellers/sessions?status=pending` | GET | `home_remote_datasource.dart` | 401 | ✅ |
| `/api/live-fal/pending` | GET | `home_remote_datasource.dart` | 404 (anonim) | ⚠️ | Falcı rolü / auth gerekebilir |
| `/api/live-fal/request/{id}/accept` | POST | `home_remote_datasource.dart` | — | ✅ |
| `/api/live-fal/request/{id}/reject` | POST | `home_remote_datasource.dart` | — | ✅ |
| `/api/fortune-tellers/session/{id}/respond` | PATCH | `home_remote_datasource.dart` | — | ✅ |
| `/api/user/active-sessions` | GET | `home_remote_datasource.dart` | — | ✅ |

**Falcı bildirim kanalları:** SSE (`fortune_incoming_invite_host.dart`) + 3 sn poll + push (`fortune_incoming_invite_provider.dart`).

**Eksik:** Mobil tarafta `POST /api/live-fal/request` (yeni istek oluşturma) yok; web akışı `POST /api/fortune-tellers/session` ile hizalı.

### 2.6 Jeton Düşümü

| Senaryo | Endpoint | Mobil dosya | Durum |
|---------|----------|-------------|-------|
| Canlı fal randevu | `POST /api/fortune-tellers/session` | `live_fortune_flow.dart` | ✅ Ön kontrol + sunucu `creditsCharged` |
| Bekleme iptali / iade | `PATCH /api/room/{id}` (`end`) | `live_fortune_flow.dart` | ✅ |
| Süre uzatma | `PATCH /api/room/{id}` (`extend`) | `home_remote_datasource.dart` | ✅ |
| Bahşiş | `POST /api/teller/gifts` | `live_fortune_session_page.dart` | ✅ |
| !istek şarkı | `music-request-by-query` | `chat_room_providers.dart` | ✅ |
| Müzik picker | `song-request` + `skipPayment: true` | `chat_room_providers.dart:1183` | ❌ Web paritesi dışı |
| Sesli oda hediye | `POST .../gifts` + Socket | `voice_room_gift_socket.dart` | ✅ |
| Bakiye okuma | `GET /api/user/credits` | `profile_providers.dart` | ✅ (401 anonim) |

### 2.7 Görüntülü Görüşme

| Senaryo | Endpoint | Mobil dosya | Probe | Durum |
|---------|----------|-------------|-------|-------|
| Canlı fal TRTC | `POST /api/trtc/usersig` | `trtc_room_manager.dart`, `live_fortune_session_page.dart` | 400 (boş body) | ✅ |
| Oda bilgisi / timer | `GET/PATCH /api/room/{sessionId}` | `home_remote_datasource.dart` | 401 | ✅ |
| Canlı yayın (Agora) | `POST /api/agora/token` | `live_broadcast_room_page.dart` | 405 GET | ✅ (farklı ürün) |

### 2.8 Canlı Sohbet

| Senaryo | Endpoint | Mobil dosya | Gerçek zamanlı | Durum |
|---------|----------|-------------|----------------|-------|
| Sesli oda metin | `POST/GET .../messages` + SSE | `chat_room_providers.dart` | SSE + 20s presence | ✅ |
| Canlı yayın sohbet | `.../messages` + SSE | `live_broadcast_room_page.dart` | SSE | ✅ |
| Fal seansı sohbet | `GET/POST /api/room/{id}/messages` | `live_fortune_session_page.dart` | **3 sn poll** | ⚠️ |
| Fal seansı fallback | `GET/POST /api/teller-chat/{id}` | `home_remote_datasource.dart` | Poll | ⚠️ |

---

## 3. Birim Test Sonuçları

| Dosya | Kapsam | Yerel çalıştırma | CI |
|-------|--------|------------------|-----|
| `voice_music_sync_test.dart` | !istek parser, kuyruk mesajı | ⚠️ Flutter SDK yok | ❌ Çalıştırılmıyor |
| `room_playback_sync_test.dart` | DJ pozisyon senkronu | ⚠️ | ❌ |
| `youtube_stream_resolver_test.dart` | YouTube stream | ⚠️ | ❌ |
| `voice_music_pipeline_log_test.dart` | Pipeline log | ⚠️ | ❌ |
| `voice_room_background_catalog_test.dart` | Arka plan kataloğu | ⚠️ | ❌ |
| `premium_fortune/pf_home_page_test.dart` | Premium fal UI | ⚠️ | ❌ |
| `widget_test.dart` | Smoke | ⚠️ | ❌ |

CI (`.github/workflows/ci.yml`): yalnızca `dart analyze lib` — **entegrasyon veya üretim E2E testi yok**.

---

## 4. Çalışmayan / Kısmi Özellikler ve Çözüm Planları

### 4.1 Müzik picker jeton bypass (`skipPayment: true`)

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` (~1183, ~1597) |
| **Hata sebebi** | `submitSelectedSong()` ve picker fallback yolu `skipPayment: true` gönderiyor; web’de ücretli `music-request-by-query` veya bakiye kontrolü var |
| **Etki** | Kullanıcı `!istek` yerine arama picker’ından şarkı seçerse jeton düşmeyebilir |
| **Çözüm planı** | 1) `skipPayment: false` yap 2) `VoiceMusicAccess.canRequestSongs` kontrolünü picker’a da uygula 3) Başarıda `walletBalancesProvider` invalidate 4) Entegrasyon testi: picker → bakiye azalması |

### 4.2 SSE hediye olayı yok sayılıyor

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/lib/features/voice_hub/data/services/voice_room_sse_service.dart` (265–266) |
| **Hata sebebi** | `VoiceRoomSseKind.gift` için `return` (noop); hediyeler yalnızca `VoiceRoomGiftSocket` üzerinden |
| **Etki** | Socket bağlantısı koparsa SSE hediye olayları görünmez; web tek kanaldan alıyor olabilir |
| **Çözüm planı** | 1) SSE `gift` payload’ını `LiveGiftsRemoteDataSource.parseGiftEvent` ile işle 2) Socket ile çift işlemeyi `giftId` dedupe ile önle 3) Bağlantı teşhisinde SSE gift sayacı ekle |

### 4.3 Falcı fal SSE — aktif oda şartı

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/lib/features/home/presentation/widgets/fortune_incoming_invite_host.dart` (`_resolveTellerSseRoomId`, ~136–158) |
| **Hata sebebi** | SSE yalnızca falcının canlı video yayını veya sahip olduğu sesli oda varsa `chat/rooms/{id}/stream`’e bağlanıyor |
| **Etki** | Yayın/oda açmadan çevrimiçi falcı daveti yalnızca 3 sn poll + push ile gelir (gecikme) |
| **Çözüm planı** | 1) Üretimde falcıya özel SSE ucu var mı envanterden doğrula 2) Yoksa poll aralığını 3→1 sn düşür veya FCM önceliğini artır 3) Varsa doğrudan falcı SSE URL’sine geç |

### 4.4 Fal seansı sohbeti — poll, SSE değil

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/lib/features/home/presentation/pages/live_fortune_session_page.dart` (~171–174) |
| **Hata sebebi** | `_chatPoll` 3 sn; `VoiceRoomSseService` veya `room/signal` kullanılmıyor |
| **Etki** | Mesaj gecikmesi ~3 sn; web anlık olabilir |
| **Çözüm planı** | 1) `GET /api/room/{sessionId}/stream` veya mevcut signal ucu varlığını doğrula 2) `LiveFortuneSessionPage`’e hafif SSE katmanı ekle 3) Poll’u yedek olarak 15–30 sn’ye çek |

### 4.5 `/api/live-fal/pending` anonim 404

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart` (`fetchLiveFalPending`) |
| **Hata sebebi** | Uç falcı JWT veya farklı path gerektirebilir; mobil 404’te sessizce boş liste döner |
| **Etki** | Legacy `live-fal` istekleri yalnızca falcı oturumunda görünür; anonim prob kanıtlayamaz |
| **Çözüm planı** | 1) Üretim envanterinde `/api/live-fal/pending` sözleşmesini doğrula 2) Falcı test hesabıyla oturumlu integration test 3) 404 vs boş liste loglama |

### 4.6 Entegrasyon / E2E test eksikliği

| Alan | Değer |
|------|-------|
| **Dosya** | `mobile/test/` (yalnızca birim), `.github/workflows/ci.yml` |
| **Hata sebebi** | Üretim API’ye JWT ile smoke test yok; `flutter test` CI’da yok |
| **Etki** | Bu rapor kod + anonim probe düzeyinde; regresyon riski |
| **Çözüm planı** | 1) `integration_test/` veya `scripts/api-smoke.sh` (test JWT) 2) CI’a `flutter test` ekle 3) Kritik akışlar: session create, !istek, SSE connect, TRTC usersig |

---

## 5. Web Paritesi — Özellik Bazlı Sonuç

| Özellik | Sonuç | Güven |
|---------|-------|-------|
| !istek (sohbet komutu) | ✅ Uygulandı | Yüksek (kod + parser test) |
| !istek (picker) | ⚠️ Jeton bypass | Yüksek (kod) |
| SSE sesli oda | ✅ | Orta (probe 200) |
| DJ kuyruk/çalma | ✅ | Orta |
| Oda müzik oynatma | ✅ | Orta |
| Fal talebi oluşturma | ✅ | Orta (401 = uç var) |
| Falcı davet (kabul/red) | ✅ | Orta |
| Jeton (fal/bahşiş/!istek) | ⚠️ Picker hariç | Orta |
| TRTC görüntülü fal | ✅ | Orta |
| Sesli oda canlı sohbet | ✅ | Orta |
| Fal seansı sohbet | ⚠️ Poll | Yüksek (kod) |

---

## 6. Önerilen Sonraki Adımlar

1. Test JWT ile `scripts/canlifal-api-smoke.sh` — kritik 8 endpoint PASS/FAIL JSON çıktısı  
2. `skipPayment: true` picker düzeltmesi → `main` + APK  
3. Fal seansı sohbetine SSE veya WebSocket  
4. CI: `flutter test` job’u  
5. Falcı hesabıyla manuel test checklist (randevu → kabul → TRTC → bahşiş → iptal iadesi)

---

*Rapor: statik analiz + anonim üretim probu. Oturumlu E2E kanıtı için test hesabı gerekir.*
