# FAZ 0 — Kapanış kontrol listesi

**Durum:** Jeton + M7 + preflight ✅ — yalnızca M5 cihaz bekliyor  
**APK:** `1.0.291+327` (`apk-latest`)  
**Otomatik:** `bash scripts/faz0-sequential.sh` (sıralı ilerleme) · `bash scripts/faz0-verify.sh` (özet)

---

## Otomatik kapılar (tamamlandı)

- [x] M1–M12 — !istek / ANR / SSE oda anahtarı (`1.0.266+302`)
- [x] API müzik fazı 6/6 — `API_MUSIC_PHASE_REPORT.md`
- [x] API voice seat — presence/koltuk/SSE — `API_VOICE_SEAT_PHASE_REPORT.md`
- [x] voice_hub unit + 15 faz test
- [x] MCP selftest v1.2.0
- [x] Jeton UX — `showInsufficientJetonDialog` + `showJetonAwareError`
- [x] Push/bildirim → sesli oda `prepareVoiceRoomSwitch` (`1.0.286+322`)
- [x] PK popup kabul teardown (`1.0.287+323`)
- [x] Sesli oda koltuk-ses P0 (`1.0.289+325`)
- [x] Moderasyon popup / self-seat / giriş SSE P1 (`1.0.290+326`)
- [x] Birleşik kullanıcı sheet + VIP giriş P2 (`1.0.291+327`)

---

## Manuel kapılar (bekleyen)

### 1. Jeton (M5 + M7 önkoşul)

- [x] Test hesabına ≥50 jeton — jeton=9920 (2026-08-20)
- [x] `m5-preflight` ✅

### 2. M7 — song-request HTTP 200

- [x] `bash scripts/m7-on-jeton.sh` — HTTP **200** (`cmoohrbrx00a4nt08zlkdjyil`)
- [x] `M7_MUSIC_SSE_CAPTURE.md` içinde HTTP **200** JSON

### 3. M5 — Android cihaz E2E

- [ ] APK `1.0.291+327` yüklü
- [ ] Oda `cmoohrbr` — `!istek Tarkan - Şımarık` ANR yok, müzik gelir
- [ ] `docs/M5_DEVICE_TEST_CHECKLIST.md` (Test 1–10; 7–10 sesli oda P0–P2)

### 4. A9 — FAZ 0 kapat

- [ ] M5 PASS → FAZ 1

---

## Hızlı komutlar

```bash
bash scripts/faz0-sequential.sh     # sıralı eksikler (önerilen)
bash scripts/faz0-next.sh
bash scripts/faz0-verify.sh
bash scripts/wait-for-jeton.sh 10 3600
bash scripts/m5-ready.sh
bash scripts/faz0-handoff.sh       # kullanıcı devir özeti
```
