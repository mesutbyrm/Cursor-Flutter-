# Canlifal — Sizin İçin Basit Test Kılavuzu

**Teknik bilgi gerekmez.** Aşağıdaki 3 adımı yapmanız yeterli; geri kalanını sistem otomatik test eder.

---

## Adım 1 — APK'yı telefona yükleyin

1. Bu linki telefonda açın ve indirin:  
   **https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk**
2. İndirilen dosyaya dokunun → **Yükle** deyin.
3. İlk seferde “Bilinmeyen kaynak” izni istenirse **İzin ver** deyin.

---

## Adım 2 — Host hesabını onaylatın (önemli)

`cursor.host.1786235468@mailinator.com` hesabı **canlı yayıncı başvurusu bekliyor**. Bu onay olmadan canlı yayın testi yapılamaz.

**Siz ne yapacaksınız:** Canlifal **admin paneline** girin → bu hesabın **falcı / canlı yayıncı başvurusunu onaylayın**.

> Onayladıktan sonra bize “onayladım” yazmanız yeterli; geri kalan testleri biz tekrar çalıştırırız.

---

## Adım 3 — (İsteğe bağlı) Telefonu bilgisayara bağlayın

Sadece **ses, mikrofon ve kamera** testleri için gerekli. API testleri telefon olmadan da çalışır.

1. Telefonda: **Ayarlar → Telefon hakkında** → Yapı numarasına **7 kez** dokunun (geliştirici modu açılır).
2. **Ayarlar → Geliştirici seçenekleri → USB hata ayıklama** → AÇIK.
3. USB kabloyla bilgisayara bağlayın.
4. Bilgisayarda şu komutu çalıştırın (veya bize “telefon bağlı” deyin):

```bash
bash scripts/run-tests-for-user.sh
```

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
| **Canlı yayın açma** | ❌ Bekliyor | **Siz — admin onayı** |
| Falcı isteği kabul | ❌ Bekliyor | Falcı hesabı secret veya sizin onaylı hesap |
| Ses / kamera / TRTC oda | ❌ Bekliyor | **Telefon + USB** (Cloud sunucuda emülatör yok) |

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

**Özet:** Jeton ve API testleri hazır. Sizden tek zorunlu iş: **host hesabını admin panelden onaylamak**. Ses/kamera için telefon bağlamak isteğe bağlı.
