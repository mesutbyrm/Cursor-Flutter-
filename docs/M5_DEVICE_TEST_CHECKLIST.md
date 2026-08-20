# M5 — Cihaz test kontrol listesi (!istek / müzik)

**Tarih:** 2026-08-20  
**APK:** `1.0.291+327` veya üzeri (`apk-latest`)  
**Hazırlık:** `bash scripts/faz0-handoff.sh` veya `bash scripts/m5-device-prep.sh`

---

## Otomatik ön kontrol (önerilir)

```bash
bash scripts/m5-api-smoke.sh      # Test 1–4 API karşılığı (cihaz yok)
bash scripts/m5-device-prep.sh
# veya
bash scripts/m5-preflight.sh
```

Geçerse: API müzik 6/6, API voice seat, jeton ≥10, voice_hub testleri OK.  
`m5-api-smoke` → `docs/M5_API_SMOKE_REPORT.md` (Test 5–10 hâlâ cihaz).

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

## Test 7 — Koltuk ↔ ses (P0)

**Hesaplar:** Normal dinleyici + `+V` yetkili (admin değil) + moderatör

1. Normal dinleyici boş koltuğa tıkla → otur
2. Mikrofonu aç → konuşabilmeli
3. Koltuktan in (veya moderatör indirsin)
4. **Beklenen:**
   - [ ] `+V` yetkili koltuksuz **yayıncı değil** (dinleyici modu, ses gitmez)
   - [ ] Normal dinleyici koltuksuz mikrofon açamaz
   - [ ] Moderatör / oda sahibi koltuksuz da konuşabilir

---

## Test 8 — Moderasyon popup (P1)

**Hesap:** `canMuteUsers` veya `canGiveVoice` olan, tam moderatör olmayan yetkili

1. Chat mesajındaki kullanıcıya tıkla
2. Koltuktaki kullanıcıya tıkla
3. Katılımcı listesinden kullanıcıya tıkla
4. **Beklenen:**
   - [ ] Üç yerden de **moderasyon paneli** açılır (profil değil)
   - [ ] Kendi profiline tıklayınca profil sheet (tam mod hariç)

---

## Test 9 — Dinleyici self-seat (P1)

1. Jetonlu normal dinleyici hesabıyla odaya gir
2. Boş (kilitli olmayan) koltuğa tıkla
3. **Beklenen:**
   - [ ] Koltuğa oturur (`seatIndex` güncellenir)
   - [ ] Mikrofon açılabilir

---

## Test 10 — Giriş bildirimi (P1/P2)

1. Gold / Diamond / yetkili hesapla odaya gir (veya başka cihazdan izle)
2. **Beklenen:**
   - [ ] Koltuk altında giriş şeridi: rol etiketi + emoji (ör. `💎 Diamond Üye …`)
   - [ ] VIP giriş SSE ile de tetiklenir

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
| Koltuk ↔ ses | | |
| Moderasyon popup | | |
| Self-seat | | |
| Giriş bildirimi | | |

**M5 PASS** → `docs/FAZ0_CLOSURE_CHECKLIST.md` · `docs/REMAINING_WORK.md` A9

Otomatik API probe (M7 yedeği): `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`
