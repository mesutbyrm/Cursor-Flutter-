# Sürüm notları — canlifal_social

## 1.0.7+8 (2026-05-20)

### Sesli sohbet

- Odalar tamamen **native Flutter + TRTC** (WebView yok)
- **Benim odam** bölümü; popüler odalar responsive grid (1–2 sütun)
- Koltuk 1 yalnızca **oda sahibi** için (yoksa rezerve boş koltuk)
- Üst bar: genel ADMIN yerine sahip bilgisi / “Benim odam”
- Hediye ve jeton yükleme native (`/api/chat/rooms/.../gifts`, jeton mağazası)
- Oda sahibi TRTC’de `isHost: true`

## 1.0.6+7 (2026-05-20)

### Ana sayfa (Keşfet)

- Üst bar: **jeton** dokununca jeton mağazası; **profil** (avatar/isim) dokununca profil sekmesi
- **3** canlı yayın kartı
- **5** hızlı işlem tek satırda (hepsi görünür)
- **Tüm** sohbet odaları listelenir; native sesli oda açılışı
- **Fal & Tarot:** 14 kart, satırda 5
- Daha hızlı pull-to-refresh (paralel yenileme, kısa animasyon)

### Önceki sürümlerden (1.0.5)

- Sesli sohbet neon UI + canlifal.com chat API
- TRTC canlı yayın, hediye sistemi
- Shell hızlı işlemler, jeton mağazası, davet arkadaş

## 1.0.5+6

- Sesli oda, TRTC, hediye, shell entegrasyonu

## 1.0.4+5

- İlk neon sesli oda + API entegrasyonu
