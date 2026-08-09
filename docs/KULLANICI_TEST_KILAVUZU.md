# Canlifal — Sizin İçin Basit Test Kılavuzu

**Teknik bilgi gerekmez.** Aşağıdaki 3 adımı yapmanız yeterli; geri kalanını sistem otomatik test eder.

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

## Adım 3 — Telefon testi (sonraki iş — bilgisayar gerekir)

Ses, mikrofon ve kamera testleri için **bilgisayar + USB kablo + Android telefon** gerekir. Şimdilik atlanabilir; API tarafı hazır.

---

## Test hesapları

| Rol | E-posta | Şifre |
|-----|---------|-------|
| Kullanıcı A | `cursor.test.1786235468@mailinator.com` | `CursorTest!1786235468` |
| Host (yayıncı) | `cursor.host.1786235468@mailinator.com` | `CursorTest!1786235468` |

Jeton: her hesapta **~5000** (hediye ve müzik testleri için).

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
| Falcı isteği kabul | ❌ Bekliyor | Falcı hesabı secret (isteğe bağlı) |
| Ses / kamera / TRTC oda | ⏳ Sonraki iş | Bilgisayar + telefon (şimdilik atlandı) |

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
