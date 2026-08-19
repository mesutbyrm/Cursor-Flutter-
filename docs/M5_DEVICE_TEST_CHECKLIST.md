# M5 — Cihaz test kontrol listesi (!istek / müzik)

**Tarih:** 2026-08-19  
**APK:** `1.0.287+323` veya üzeri (`apk-latest`)  
**Hazırlık:** `bash scripts/faz0-handoff.sh` veya `bash scripts/m5-device-prep.sh`

---

## Otomatik ön kontrol (önerilir)

```bash
bash scripts/m5-device-prep.sh
# veya
bash scripts/m5-preflight.sh
```

Geçerse: API müzik 6/6, jeton ≥10, voice_hub testleri OK.

Jeton yoksa: `docs/M5_M7_JETON_BLOCKER.md` · Durum: `bash scripts/faz0-status.sh`

---

## Hazırlık

- [ ] APK indir: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk
- [ ] Test hesabı: `docs/TEST_ACCOUNTS.md` (`ACCEPTANCE_USER_*`)
- [ ] Odada yeterli jeton (müzik isteği ~10 jeton)
- [ ] İnternet stabil (Wi‑Fi veya mobil veri)

---

## Test 1 — `!istek` komutu

1. Sesli oda `cmoohrbr` aç
2. Sohbete yaz: `!istek Tarkan - Şımarık`
3. **Beklenen:**
   - [ ] Uygulama donmuyor (ANR yok)
   - [ ] "Şarkı kuyruğa eklendi" veya benzeri geri bildirim
   - [ ] 5–15 sn içinde müzik sesi (IFrame veya stream)
4. **Başarısızsa not:** ekran görüntüsü + logcat `VoiceRoom` / `MusicPipeline`

---

## Test 2 — Müzik paneli

1. Oda içi müzik panelini aç
2. Arama yap → şarkı seç → iste
3. **Beklenen:** Test 1 ile aynı (ANR yok, ses gelir)

---

## Test 3 — Video isteği (varsa)

1. Video modunda şarkı iste
2. **Beklenen:** Mini player veya arka plan video; ANR yok

---

## Test 4 — Oda değiştirme

1. Müzik çalarken odadan çık
2. Başka odaya gir
3. **Beklenen:** Önceki oda müziği durur; yeni oda temiz; eski odada koltukta görünmezsin

---

## Test 5 — Sesli oda PK daveti

1. İki farklı sesli odada (A ve B) iki hesap veya iki cihaz
2. Oda A'dan PK daveti gönder → Oda B'yi seç
3. **Beklenen:**
   - [ ] Gönderen ekran donmuyor
   - [ ] Karşı tarafta PK popup veya bildirim gelir
   - [ ] Kabul sonrası PK başlar; kabul eden eski odada koltukta kalmaz
4. **Bildirim testi:** PK bildirimine tıkla → `GoException` yok, oda açılır; önceki odada presence temiz

---

## Test 6 — Canlı yayın PK daveti

1. İki canlı yayıncı
2. PK daveti gönder / kabul et
3. **Beklenen:** Donma yok; karşı taraf daveti görür

---

## Sonuç

| Test | PASS / FAIL | Not |
|------|-------------|-----|
| !istek | | |
| Müzik paneli | | |
| Video isteği | | |
| Oda çıkışı | | |
| Sesli PK | | |
| Canlı PK | | |

**M5 PASS** → `docs/FAZ0_CLOSURE_CHECKLIST.md` · `docs/REMAINING_WORK.md` A9

Otomatik API probe (M7 yedeği): `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`
