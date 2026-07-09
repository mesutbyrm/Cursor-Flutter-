# APK / AAB boyut — neden büyük, ne yaptık?

## Play Store’da gördüğünüz boyut

Play Console **indirme boyutu** (65–85MB hedef) ile GitHub’daki **APK dosya boyutu** farklıdır:

| Dosya | Eski | Yeni (1.0.3+4) |
|-------|------|----------------|
| GitHub APK (arm64) | ~385MB | ~158MB |
| Yükleme AAB | ~373MB | ~101MB |
| Play’de telefona inen | — | AAB split ile genelde **daha küçük** |

AAB yüklediğinizde Google her cihaza yalnızca **arm64** + gerekli dil/yoğunluk paketini verir.

## Boyutu şişiren ana bileşenler

| Bileşen | Neden |
|---------|--------|
| Agora RTC | Sesli odalar + canlı yayın |
| Tencent TRTC | Canlı falcı / yayın |
| LiveKit / WebRTC | Sesli oda alternatifi |
| FFmpeg (min) | Shorts video export |
| Firebase + reklam SDK | Auth, push, AdMob |

Üç ayrı RTC yığını üretim API parity için gerekli; tamamen kaldırmak özellik kaybıdır.

## Uygulanan optimizasyonlar

1. Yalnızca **arm64-v8a** (minSdk 24)
2. Fal asset **WebP** (~30MB)
3. **Rive** kaldırıldı
4. **FFmpeg min-gpl** (full yerine)
5. Agora **isteğe bağlı AI .so** dosyaları hariç
6. Agora **ekran paylaşımı** modülü hariç

## Daha da küçültmek için (gelecek)

- Shorts export’u sunucuya taşımak → FFmpeg mobilde kaldırılabilir (~15–25MB)
- Tek RTC motoru (backend + mobil refactor)
- Play Feature Delivery ile nadir modüller

## Derleme

```bash
# Play AAB
bash scripts/build-play-aab.sh

# GitHub APK (arm64)
cd mobile && flutter build apk --release --target-platform android-arm64 \
  --tree-shake-icons --obfuscate --split-debug-info=build/app/outputs/symbols
```
