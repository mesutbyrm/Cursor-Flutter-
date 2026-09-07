# Canlifal — Sizin İçin Basit Test Kılavuzu


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Sürüm:** `1.0.371+409` · **Son release gate:** [FINAL PASS](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509)

**Teknik bilgi gerekmez.** Önce jeton, sonra Psychic TRTC (2 telefon). Hızlı rehber: [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md)

---

## Adım 1 — APK'yı telefona yükleyin

1. Bu linki telefonda açın ve indirin:  
   **https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk**
2. İndirilen dosyaya dokunun → **Yükle** deyin.
3. İlk seferde “Bilinmeyen kaynak” izni istenirse **İzin ver** deyin.

---

## Adım 2 — Host hesabı onayı ✅ (tamamlandı)

`cursor.host.1786235468@mailinator.com` hesabı **onaylandı** — canlı yayın API testi geçti.

---

## Adım 3 — Psychic TRTC (öncelik — 2 telefon)

Canlı falcı görüntülü görüşme — **T+5 saniyede donma olmamalı**.

1. APK'yı **iki telefona** yükleyin (danışan + falcı hesapları).
2. Terminalde checklist: `bash scripts/psychic-p0-checklist.sh`
3. Detay: [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md)

Sonuç: **Psychic P0 PASS** veya **FAIL** yazın.

---

## Adım 4 — Diğer telefon testleri (sonra)

Sesli oda, müzik, PK vb. — [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) P1 bölümü.

---

## Test hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Kullanıcı A | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Host (yayıncı) | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Jeton: danışan hesabında **Psychic seans için yeterli jeton** gerekir (probe: `bash scripts/psychic-p0-prereqs.sh`). Jeton 0 ise admin panel — `bash scripts/admin-jeton-cheatsheet.sh`

---

## Şu an ne geçiyor, ne bekliyor?

| Test | Durum | Kim yapar? |
|------|-------|------------|
| Giriş, profil, sohbet | ✅ Otomatik geçti | — |
| Hediye 500 jeton düşümü | ✅ Otomatik geçti | — |
| Müzik ücreti (10 jeton) | ✅ Otomatik geçti | — |
| Falcı isteği oluşturma | ✅ Otomatik geçti | — |
| PK iki kullanıcı (oluştur→kabul→bitir) | ✅ Otomatik geçti | — |
| TRTC token (sunucu) | ✅ Otomatik geçti | — |
| Gift SSE olayı | ✅ Otomatik geçti | — |
| **Canlı yayın açma** | ✅ Otomatik geçti | Host onaylandı |
| **Psychic TRTC 1:1 (T+5s)** | ⏳ **Sizin testiniz** | 2 telefon — `psychic-p0-checklist.sh` |
| Ses / kamera / sesli oda | ⏳ Sonra | [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md) |

---

## İsteğe bağlı: GitHub Secrets

Otomatik falcı kabul testi için repo → **Settings → Secrets**:

- `ACCEPTANCE_TELLER_EMAIL` — onaylı falcı e-postası
- `ACCEPTANCE_TELLER_PASSWORD` — şifre

Admin ile otomatik host onayı için:

- `ACCEPTANCE_ADMIN_EMAIL` / `ACCEPTANCE_ADMIN_PASSWORD`

---

## Sorular

Detaylı teknik rapor: `docs/STAGE5_REAL_E2E_ACCEPTANCE_REPORT.md`

**Özet:** API testleri (giriş, jeton, hediye, müzik, canlı yayın oluşturma, PK, TRTC token) **geçti**. Telefon/ses testi bilgisayarınız olduğunda yapılır.
