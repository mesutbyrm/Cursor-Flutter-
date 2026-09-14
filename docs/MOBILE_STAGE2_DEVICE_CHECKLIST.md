# Mobil Aşama 2 — cihaz doğrulama (1.0.483+521+)

APK: [apk-latest](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) · Sürüm `mobile/pubspec.yaml`

İki hesap / iki cihaz veya iki yayıncı odası önerilir. Her madde için **PASS** / **FAIL** not edin; FAIL’de ekran kaydı + yaklaşık saat yeterli.

## 1. Canlı yayın PK (donma)

| Adım | Beklenen |
|------|----------|
| A ve B canlı yayın açar | Liste ve davet ekranı yanıt verir |
| A, B’ye PK daveti gönderir | Snackbar; uygulama donmaz |
| B daveti görür, Kabul | PK başlar; uygulama yeniden başlatma gerekmez |
| B Reddet veya 30 sn bekle | Diyalog kapanır; A takılı kalmaz |

## 2. Sesli oda PK (rakibe ulaşma)

| Adım | Beklenen |
|------|----------|
| İki aktif sesli oda (sahipleri farklı) | PK davet listesinde görünür |
| A rakip odaya davet | A’da onay |
| B (odada veya uygulama açık) | Davet popup veya poll ile gelir (~4–8 sn) |
| B kabul | PK ekranı / oda akışı |

## 3. Canlı fal — seans isteği

| Adım | Beklenen |
|------|----------|
| Danışan falcı seçer, süre onaylar | Bekleme ekranı &lt; ~5 sn içinde açılır (ağ koşuluna bağlı) |
| Falcı uygulama açık | Gelen çağrı ~2–5 sn içinde (SSE/poll) |

## 4. Bahşiş (falcı görür)

| Adım | Beklenen |
|------|----------|
| Aktif video seans, danışan bahşiş | Danışanda teşekkür snackbar |
| Falcı ekranı | Jeton popup / banner (SSE veya sinyal poll) |

---

Sonuçları `bash scripts/record-user-test-result.sh` ile kaydedebilirsiniz. Tümü PASS → **Psychic P0** akışına devam (`docs/PSYCHIC_P0_START.md`).
