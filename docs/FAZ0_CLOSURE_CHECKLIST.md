# FAZ 0 — Kapanış kontrol listesi

**Durum:** INCOMPLETE — M5 cihaz bekliyor  
**APK:** `1.0.266+302`  
**Otomatik:** `bash scripts/faz0-status.sh` (hızlı) · `bash scripts/faz0-verify.sh` (tam)

---

## Otomatik kapılar (tamamlandı)

- [x] M1–M12 — !istek / ANR / SSE oda anahtarı (`1.0.257–266`)
- [x] API müzik fazı 6/6 — `API_MUSIC_PHASE_REPORT.md`
- [x] voice_hub 93 unit test
- [x] MCP selftest v1.2.0
- [x] SSE üretim `connected` + `dj` — `M7_MUSIC_SSE_CAPTURE.md`
- [x] CI `faz0-music` job

---

## Manuel kapılar (bekleyen)

### 1. Jeton (M5 + M7 önkoşul)

- [ ] Test hesabına ≥10 jeton (`cursor.test.*` veya `cursor.host.*`)
- [ ] `bash scripts/m5-preflight.sh` → ✅

Rehber: `docs/M5_M7_JETON_BLOCKER.md`

### 2. M7 — song-request HTTP 200

- [ ] `bash scripts/m7-on-jeton.sh` (jeton ≥10 sonrası otomatik probe)
- [ ] `M7_MUSIC_SSE_CAPTURE.md` içinde HTTP **200** JSON
- [ ] `REMAINING_WORK.md` M7 → `[x]`

### 3. M5 — Android cihaz E2E

- [ ] APK `1.0.266+302` yüklü
- [ ] Oda `cmoohrbr` — `!istek Tarkan - Şımarık` ANR yok, müzik gelir
- [ ] Müzik paneli testi PASS
- [ ] Sonuç tablosu dolduruldu — `M5_DEVICE_TEST_CHECKLIST.md`

### 4. A9 — FAZ 0 kapat

- [ ] M5 PASS
- [ ] `REMAINING_WORK.md` A9 → `[x]`
- [ ] `PHASE_PLAN.md` FAZ 0 → PASS
- [ ] **FAZ 1** başlayabilir

---

## Hızlı komutlar

```bash
bash scripts/faz0-status.sh       # durum (hızlı)
bash scripts/faz0-verify.sh     # tam otomatik kapılar
bash scripts/m7-on-jeton.sh       # jeton sonrası M7 probe
bash scripts/m5-preflight.sh      # M5 öncesi
bash scripts/run-music-acceptance.sh
```
