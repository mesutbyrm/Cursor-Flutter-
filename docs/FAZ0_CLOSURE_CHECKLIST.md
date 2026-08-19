# FAZ 0 — Kapanış kontrol listesi

**Durum:** INCOMPLETE — M5 cihaz + jeton bekliyor  
**APK:** `1.0.283+319` (`apk-latest`)  
**Otomatik:** `bash scripts/faz0-next.sh` (önerilen) · `bash scripts/faz0-verify.sh` (tam)

---

## Otomatik kapılar (tamamlandı)

- [x] M1–M12 — !istek / ANR / SSE oda anahtarı (`1.0.266+302`)
- [x] API müzik fazı 6/6 — `API_MUSIC_PHASE_REPORT.md`
- [x] voice_hub 93 unit + 15 faz test
- [x] MCP selftest v1.2.0
- [x] Jeton UX — `showInsufficientJetonDialog` + `showJetonAwareError` (oda + müzik + hediye + fal + oyun + üyelik + canlı panel, `1.0.277–283`)
- [x] Günlük görevler — Growth Hub API eşlemesi (`1.0.269–273`)
- [x] CI `faz0-music` + FAZ12 otomatik 4/4

---

## Manuel kapılar (bekleyen)

### 1. Jeton (M5 + M7 önkoşul)

- [ ] Test hesabına ≥50 jeton — `bash scripts/admin-jeton-cheatsheet.sh`
- [ ] `bash scripts/wait-for-jeton.sh` veya jeton ≥10 sonrası `m5-preflight` ✅

Rehber: `docs/M5_M7_JETON_BLOCKER.md`

### 2. M7 — song-request HTTP 200

- [ ] `bash scripts/m7-on-jeton.sh` (jeton ≥10)
- [ ] `M7_MUSIC_SSE_CAPTURE.md` içinde HTTP **200** JSON

### 3. M5 — Android cihaz E2E

- [ ] APK `1.0.283+319` yüklü
- [ ] Oda `cmoohrbr` — `!istek Tarkan - Şımarık` ANR yok, müzik gelir
- [ ] `docs/M5_DEVICE_TEST_CHECKLIST.md`

### 4. A9 — FAZ 0 kapat

- [ ] M5 PASS → FAZ 1

---

## Hızlı komutlar

```bash
bash scripts/faz0-next.sh          # durum + cheatsheet + probe (+ M7 jeton varsa)
bash scripts/faz0-verify.sh
bash scripts/wait-for-jeton.sh 10 3600
bash scripts/m5-ready.sh
```
