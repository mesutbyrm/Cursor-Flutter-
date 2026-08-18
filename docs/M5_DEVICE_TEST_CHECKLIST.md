# M5 — Cihaz test kontrol listesi (!istek / müzik)

**Tarih:** 2026-08-18  
**APK:** `1.0.262+298` veya üzeri (`apk-latest`)  
**Oda:** `cmoohrbr`

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
3. **Beklenen:** Önceki oda müziği durur; yeni oda temiz

---

## Sonuç

| Test | PASS / FAIL | Not |
|------|-------------|-----|
| !istek | | |
| Müzik paneli | | |
| Video isteği | | |
| Oda çıkışı | | |

**M5 PASS** → `docs/REMAINING_WORK.md` A9 + FAZ 0 kapatılabilir.

Otomatik API probe (M7 yedeği): `MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh`
