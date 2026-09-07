# Canlifal — Sizin İçin Basit Test Kılavuzu


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

**Sürüm:** `1.0.371+409` · **Son release gate:** [FINAL PASS](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34146919509)

**Teknik bilgi gerekmez.** Özet: [`USER_TEST_QUICK_REF.md`](USER_TEST_QUICK_REF.md) · **`bash scripts/kalan-isler.sh`**

---

## Adım 1 — APK'yı telefona yükleyin

1. Bu linki telefonda açın ve indirin:  
   **https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk**
2. İndirilen dosyaya dokunun → **Yükle** deyin.
3. İlk seferde “Bilinmeyen kaynak” izni istenirse **İzin ver** deyin.

---

## Adım 2 — Hesaplar ve falcı uyarısı

| Rol | E-posta | Şifre | Not |
|-----|---------|-------|-----|
| Danışan | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` | Jeton ~100k ✅ |
| Falcı | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` | Onaylı falcı ✅ (`Cursor Host Test`) |

Psychic P0: **danışan + falcı** yukarıdaki iki hesap — aynı şifre.

```bash
bash scripts/probe-psychic-teller.sh    # falcı listede mi?
```

Detay: [`PSYCHIC_TELLER_STATUS.md`](PSYCHIC_TELLER_STATUS.md)

## Adım 3 — Psychic TRTC (öncelik — 2 telefon)

Canlı falcı görüntülü görüşme — **T+5 saniyede donma olmamalı**.

```bash
bash scripts/p0-go.sh                         # GO ekranı
bash scripts/validate-pre-device-handoff.sh   # önce API doğrulama
bash scripts/user-test-start.sh p0              # P0 akışı + checklist
bash scripts/on-p0-pass.sh                    # PASS kaydı → P1
```

1. APK'yı **iki telefona** yükleyin (danışan + **falcı** — `cursor.host.*`).
2. Kritik: **T+5s** donma olmamalı.

FAIL: `bash scripts/on-p0-fail.sh "hangi adım"`

Detay: [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md) · [`LIVE_PSYCHICS_REMAINING.md`](LIVE_PSYCHICS_REMAINING.md)

---

## Adım 4 — Platform testleri (P0 PASS sonrası)

```bash
bash scripts/on-p1-pass.sh                      # P1 PASS kaydı
bash scripts/on-release-ready-candidate.sh      # RELEASE adayı
```

Sesli oda, müzik, PK vb. — [`P1_DEVICE_START.md`](P1_DEVICE_START.md) · [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md)

---

## Test hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Kullanıcı A | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Host (yayıncı) | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Jeton: danışan **~100k** ✅ (`bash scripts/psychic-p0-prereqs.sh`)

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
| **Psychic TRTC 1:1 (T+5s)** | ⏳ **Sizin testiniz** | `user-test-start.sh p0` |
| Ses / kamera / sesli oda (P1) | ⏳ P0 sonrası | `on-p0-pass.sh` → P1 |

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

**Özet:** API testleri geçti. Agent **kapalı** — sırada 2 telefon Psychic P0 → P1. [`AGENT_CLOSED.md`](AGENT_CLOSED.md)
