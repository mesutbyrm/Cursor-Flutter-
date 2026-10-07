# CANLIFAL — TRTC & SSE Raporu

**Gerçek cihaz oturumu:** `DIAG-20261007-032621-E0BF` (Telefon A)  
**Cloud VM TRTC/SSE canlı test:** **BLOCKED**

---

## 1. TRTC mimarisi (kod)

| Bileşen | Dosya | Not |
|---------|--------|-----|
| Sesli oda engine | `voice_trtc_engine.dart` | `VoiceTrtcEngine` + `TrtcRoomManager` |
| Koordinatör | `voice_room_audio_coordinator.dart` | join / leave / reconnect / `releaseSeatVoice` |
| Canlı fal | `psychic_video_controller.dart` | Ayrı `TrtcRoomManager` örneği |
| Token | `trtc_remote_datasource.dart` | `POST /api/trtc/token` (kılavuz) |

**Kritik:** İki ayrı TRTC yığını (voice hub vs psychic) — birinden çıkış diğerini **otomatik kapatmaz**. Telefon A logunda yalnızca psychic kanalı `trtc-130` join/leave açıkça kayıtlı.

---

## 2. TRTC olayları (Telefon A log — gerçek)

| Zaman (UTC) | Olay | Detay |
|-------------|------|--------|
| Oturum içi | `TRTC_JOIN_START` | — |
| Oturum içi | `TRTC_CREATE` | `trtc-130`, room: `voice_room_room_cmuxda2n200d6t7094sxa8i2w_…` |
| Oturum içi | `TRTC_JOIN_SUCCESS` | Canlı fal seans TRTC |
| Oturum içi | `TRTC_REMOTE_ENTER` / `TRTC_USER_VIDEO` | Karşı taraf medya |
| Oturum içi | `TRTC_LEAVE` | — |
| Oturum içi | `TRTC_DISPOSE` | trtc-130 dispose |

**Kullanıcı şikâyeti:** Sesli **sohbet** odasında ses sürüyor — log sesli oda TRTC create satırı içermiyor (yalnızca chat API + SSE). Olasılıklar:

1. TRTC diagnostic hook sesli oda join’den önce/sonra kaçırdı  
2. DJ / müzik oynatıcı (`voice_room_dj_player.dart`)  
3. Çıkış pipeline erken timeout (731 öncesi 400 ms) — **kod düzeltildi, retest BLOCKED**

---

## 3. TRTC leave pipeline (sesli oda)

**Dosya:** `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`  
**Fonksiyon:** `leaveRoomSession`  
**Adım 1 (~1211–1225):** `setReconnectSuspended(true)` → `leave()` **await 4s** (731+)  
**Adım 3:** İkinci `leave()` + `_leaveVoiceSession()`  

**Koltuk:**

**Dosya:** `chat_room_providers_seat.dart` ~656–672  
**Akış:** `releaseSeatVoice()` → audience `join(enableMic: false)` (731+)

**Reconnect riski:**

**Dosya:** `voice_room_audio_coordinator.dart` — `_reconnectVoice`, `ensureConnected`  
**Dosya:** `chat_room_providers_presence.dart` ~685–697 — ağ geri gelince `ensureConnected()`  

**Retest:** Wi‑Fi ↔ mobil veri geçişi sesli odada; log `audio.trtc.network_recovery`.

---

## 4. SSE envanteri

### Sesli oda

- **Endpoint:** `GET /api/chat/rooms/{roomId}/stream` (`api_endpoints.dart` ~486)  
- **Hub:** `sse_connection_hub.dart` — lease / ref-count  
- **Release:** `forceReleaseVoiceRoom` (~80) — leave step ~1284  

### Telefon A — DUPLICATE / LEAK

| Olay | Kanıt |
|------|--------|
| `SSE_CREATE` | `voice_sse:cmuvuazea024po2086221dlss` |
| `SSE_CREATE` | `voice_sse:cmuvu9e2n023go208epjsnjec` |
| `SSE_CREATE` | `voice_sse:cmuviw5ug000jo208mb0fwaes` |
| Diagnostic | `DUPLICATE_SSE`, `LEAK_SUSPECTED after SCREEN EXIT` |
| Snapshot | `sse: 3` (summary.json) |

**Muhtemel neden:** Keşif (`voice_rooms_presence_provider.dart`) + aktif oda eşzamanlı; çıkışta yanlış release key (leave pipeline yorumu ~1193–1198 — key yakalama mevcut).

### Canlı fal SSE

- `psychic_room_sse_service.dart` — 401 refresh (kılavuz §6)  
- Log: `room_sse` + `live_fortune` timer yükü birlikte

### Falcı incoming SSE

- `psychic_incoming_sse_service.dart` — `/api/fortune-tellers/sessions/stream`  
- Log: parallel **HTTP** pending poll — SSE ile çift yük riski

---

## 5. SSE kontrol listesi (retest)

| # | Kontrol | Durum |
|---|---------|--------|
| 1 | Authorization Bearer SSE isteğinde | BLOCKED |
| 2 | Odadan çıkınca stream kapanır | FAIL (log leak suspect) |
| 3 | Token refresh sonrası tek bağlantı | BLOCKED |
| 4 | Background → foreground duplicate | BLOCKED |
| 5 | Reconnect max 20 + backoff | Kod var — BLOCKED cihaz |

---

## 6. TRTC kontrol listesi (retest)

| # | Kontrol | Durum |
|---|---------|--------|
| 1 | Enter room token geçerli | Kısmi (JOIN_SUCCESS log) |
| 2 | Exit room tam kapanır | FAIL (kullanıcı) / fix 731 retest |
| 3 | Koltuk yokken mic publish kapalı | BLOCKED |
| 4 | Başka odaya geçince eski room sessiz | BLOCKED |
| 5 | Psychic + voice aynı anda — çift ses | BLOCKED |

---

## 7. Önerilen düzeltme sırası (kod değişikliği öncesi rapor)

1. 731+ APK ile sesli oda çıkış / koltuk retest + ZIP  
2. SSE duplicate — keşif limiti + leave `forceReleaseVoiceRoom` metrik  
3. Psychic TRTC dispose — seans bitince `psychic_video_controller.leave` zorunlu  
4. İki cihaz PK SSE — ayrı test planı

**Detay hatalar:** `CANLIFAL_CRITICAL_ERRORS.md`
