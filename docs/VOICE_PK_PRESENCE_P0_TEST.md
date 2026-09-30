# Sesli oda — PK + presence P0 (2 telefon)

> **APK:** `1.0.656+707` ve üzeri önerilir  
> **Amaç:** PK davet modalı, çapraz oda PK, aktif PK ekranı ve presence “hayalet” regresyonunu iki cihazda doğrulamak.  
> **Psychic P0’dan bağımsız** — canlı falcı TRTC testine ek olarak veya ayrı oturumda yapılabilir.

---

## 0. Hazırlık (5 dk)

```bash
bash scripts/psychic-p0-prereqs.sh   # APK + giriş + jeton (isteğe bağlı)
bash scripts/print-build-status.sh   # sürüm / CI
```

| Telefon | Rol | Önerilen hesap | Not |
|---------|-----|----------------|-----|
| **A** | Oda sahibi / PK başlatan | Kendi hesabın veya test hesabı | En az bir **sesli oda** sahibi ol |
| **B** | Rakip oda sahibi / davetli | **Farklı** kullanıcı | A ile aynı hesap **olmasın** |

**APK:** https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk

Her iki telefonda:

1. APK kur, uygulamayı aç.
2. İlgili hesapla giriş yap.
3. Bildirim izni ver (PK push testi için B’de özellikle).
4. Uygulama içi banner’ların engellenmediğinden emin ol.

**İki sesli oda:** A kendi odasında, B kendi odasında (farklı oda ID’leri). İkisi de odada **içeride** (RTC/sesli oda ekranı açık) olsun.

---

## 1. Çapraz oda PK daveti — modal (kritik)

| Adım | Telefon A | Telefon B | Beklenen |
|------|-----------|-----------|----------|
| 1.1 | Kendi odanda → PK / düello → **B’nin odasını** hedef seç → davet gönder | Odada kal (arka planda olabilir) | — |
| 1.2 | “Bekleniyor” / pending UI | **Kabul/Reddet** modalı (SSE veya birkaç sn içinde poll) | Modal **root** seviyede; odaya zorla gitmeden |
| 1.3 | — | **Reddet** | A’da red mesajı; PK pending bitmeli |
| 1.4 | Tekrar davet gönder | **Kabul** | B: oda/PK akışı; kısa sürede **tam ekran PK** |

**FAIL işaretleri:** B’de bildirim gelip modal yok; yalnızca odaya yönlendirme; çift modal; A yanlış PK endpoint / 404.

---

## 2. Push / banner → aynı modal

| Adım | Telefon B | Beklenen |
|------|-----------|----------|
| 2.1 | Uygulama **açık**, farklı sekmede (feed vb.) | — |
| 2.2 | A tekrar PK daveti gönder | Üst **in-app banner** |
| 2.3 | Banner’a dokun | **Odaya gitmeden** modal; veya doğrudan modal (bump + poll) |
| 2.4 | (Opsiyonel) Uygulama arka planda | Push tıkla | Yine modal öncelikli; kör `/voice-room/...` atlama |

---

## 3. Aktif PK — iki taraf tam ekran

| Adım | Telefon A | Telefon B | Beklenen |
|------|-----------|-----------|----------|
| 3.1 | Kabul sonrası PK ekranında | Kabul sonrası PK ekranı | İkisi de **aktif** skor / süre |
| 3.2 | Süreyi izle (~30 sn yeter) | Aynı | Tek sayaç mantığı (`endsAt`); bar/header tutarlı, “çift geri sayım” yok |
| 3.3 | Skor etiketleri | Aynı | A (başlatan): **Biz / Onlar**; B: **1. Takım / 2. Takım** (1v1 HUD üst etiket) |
| 3.4 | PK bitene kadar bekle veya moderasyonla bitir | — | Sonuç / çıkış mantıklı; takılı kalmama |

---

## 4. Presence — hayalet (kritik)

| Adım | Telefon A | Beklenen |
|------|-----------|----------|
| 4.1 | Odadan **çık** (geri / leave) | Kendi avatarın listeden **hemen** düşmeli |
| 4.2 | Ana sayfa / oda listesi | Kendini “hâlâ odada” **görme** |
| 4.3 | Uygulamayı arka plan → 10 sn → geri | Hayalet yok |
| 4.4 | Tekrar odaya gir | Tek presence; çift “giriş” banner’ı yok (SSE reconnect spam yok) |

Telefon B ile A’nın odasına bak: A çıktıktan sonra A listede **görünmemeli**.

---

## 5. Kısa regresyon (isteğe bağlı, 3 dk)

- **Hediye hedefi:** Hedef tamamlanınca ~4 sn kutlama, sonra banner kaybolur.
- **PK pending:** Davetli olmayan kullanıcı PK tam ekranda **Kabul/Reddet kartı görmez**.
- **Jeton / hediye:** PK sırasında hediye gönderimi skoru günceller (SSE).

---

## 6. Sonuç kaydı

Başarılı oturum (tüm kritik maddeler PASS):

```bash
bash scripts/record-user-test-result.sh p0 PASS
# veya sadece sesli PK için agent’a yaz:
# Voice PK P0 PASS
```

Herhangi bir kritik FAIL:

```bash
bash scripts/on-p0-fail.sh "Voice PK: <kısa açıklama>"
```

Agent’a örnek mesajlar:

- `Voice PK P0 PASS` — presence + çapraz PK modal tamam  
- `Voice PK P0 FAIL modal gelmiyor`  
- `Voice PK P0 FAIL presence hayalet`

---

## 7. Psychic P0 ile birleştirme

Tam release kapısı için hâlâ **Canlı falcı TRTC** P0 gerekir:

```bash
bash scripts/user-test-start.sh p0
bash scripts/psychic-p0-checklist.sh
```

Bu dosya yalnızca **sesli oda PK + presence** dilimini kapsar. İkisi PASS olunca:

`Psychic P0 PASS` + `Voice PK P0 PASS` → P1’e geçiş rehberi: [`PSYCHIC_P0_START.md`](PSYCHIC_P0_START.md)

---

## Hızlı kontrol listesi (yazdır)

- [ ] B: davet modalı (SSE)
- [ ] B: red / kabul
- [ ] A + B: aktif PK ekranı
- [ ] Sayaç tek kaynak (endsAt)
- [ ] Etiketler (Biz/Onlar vs 1./2.)
- [ ] Banner/push → modal
- [ ] Çıkış sonrası presence hayalet yok
- [ ] Yeniden giriş temiz
