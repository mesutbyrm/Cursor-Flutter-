# Google Play — Ön Plan Hizmeti (Foreground Service) Beyanı

Play Console şu uyarıyı veriyorsa:

> *Uygulamanızda aşağıdaki beyan edilmemiş ön plan hizmeti izinleri kullanılıyor*

Bu, **AndroidManifest** içinde izinlerin olmasından ayrı olarak Play Console’da **manuel beyan** gerektiği anlamına gelir.

## Canlifal’da hangi izinler neden var?

| İzin | Kaynak | Kullanım |
|------|--------|----------|
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | `audio_service` | Sesli odalarda DJ / arka plan müzik çalma bildirimi |
| `FOREGROUND_SERVICE_CAMERA` | Uygulama manifest | Canlı falcı görüntülü görüşme (TRTC / Agora) |
| `FOREGROUND_SERVICE_MICROPHONE` | Uygulama manifest | Sesli sohbet odaları, canlı görüşme mikrofonu |
| `FOREGROUND_SERVICE_MEDIA_PROJECTION` | Agora + Tencent TRTC SDK | Ekran paylaşımı altyapısı (SDK birleşik manifest) |

Manifest dosyası: `mobile/android/app/src/main/AndroidManifest.xml`

## Adım adım: Play Console beyanı

1. [Google Play Console](https://play.google.com/console) → **Canlifal** uygulamasını açın.
2. Sol menü: **Politika ve programlar** → **Uygulama içeriği** (*App content*).
3. **Ön plan hizmeti izinleri** (*Foreground service permissions*) satırına tıklayın → **Yönet** / **Başlat**.
4. Listelenen her izin için aşağıdaki gibi doldurun ve **kaydedin**.

### 1. Kamera (`FOREGROUND_SERVICE_CAMERA`)

- **Kullanım amacı:** Canlı görüntülü fal / video görüşme
- **Kullanıcıya görünür mü?** Evet — görüntülü görüşme sırasında kamera açık
- **Açıklama (Türkçe örnek):**
  > Canlifal’da kullanıcılar canlı falcılarla görüntülü görüşme yapabilir. Görüşme sırasında kamera erişimi gereklidir.

### 2. Mikrofon (`FOREGROUND_SERVICE_MICROPHONE`)

- **Kullanım amacı:** Sesli sohbet odaları ve canlı sesli/görüntülü görüşme
- **Kullanıcıya görünür mü?** Evet — oda veya görüşme aktifken mikrofon kullanılır
- **Açıklama (Türkçe örnek):**
  > Sesli sohbet odalarında ve canlı falcı görüşmelerinde mikrofon kullanılır. Kullanıcı odaya katıldığında veya görüşmeyi başlattığında bu izin devreye girer.

### 3. Medya oynatma (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`)

- **Kullanım amacı:** Sesli odalarda arka planda müzik / DJ yayını
- **Kullanıcıya görünür mü?** Evet — bildirim çubuğunda oynatma kontrolü görünür
- **Açıklama (Türkçe örnek):**
  > Sesli sohbet odalarında DJ müziği çalınırken arka planda ses devam eder; kullanıcı bildirimden oynatmayı kontrol edebilir.

### 4. Medya yansıtma (`FOREGROUND_SERVICE_MEDIA_PROJECTION`)

- **Kullanım amacı:** Video SDK ekran paylaşımı altyapısı (Agora / Tencent TRTC)
- **Kullanıcıya görünür mü?** Yalnızca ekran paylaşımı başlatılırsa (sistem izin diyaloğu)
- **Açıklama (Türkçe örnek):**
  > Görüntülü görüşme SDK’ları ekran paylaşımı özelliği için sistem düzeyinde medya yansıtma iznine ihtiyaç duyar. Kullanıcı bu özelliği açmadıkça izin kullanılmaz.

5. Formu tamamladıktan sonra **Gönder** / **Kaydet**.
6. Yeni bir sürüm yükleyin veya mevcut inceleme sürümünü tekrar gönderin; uyarı genelde beyan tamamlanınca kaybolur.

## Video kanıtı (gerekirse)

Google bazen kısa bir ekran kaydı ister. Her izin için şunları gösterin:

| İzin | Videoda gösterilecek |
|------|----------------------|
| Kamera | Canlı falcı → görüntülü görüşme başlat |
| Mikrofon | Sesli oda → odaya katıl → konuş |
| Medya oynatma | Sesli oda → DJ müziği → uygulamayı arka plana al → bildirim |
| Medya yansıtma | (Varsa) görüntülü görüşmede ekran paylaşımı; yoksa SDK’nın paketlendiğini ve kullanıcı tetiklemeden çalışmadığını açıklayın |

Telefon ekran kaydı yeterlidir; 30–60 saniye.

## Manifest kontrolü (geliştirici)

Birleşik release manifest’i görmek için:

```bash
cd mobile/android
./gradlew :app:processReleaseManifest
# Çıktı: mobile/build/app/intermediates/merged_manifests/release/.../AndroidManifest.xml
```

Şunların listede olduğundan emin olun:

- `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- `FOREGROUND_SERVICE_MEDIA_PROJECTION`
- `FOREGROUND_SERVICE_CAMERA`
- `FOREGROUND_SERVICE_MICROPHONE`

## Sık sorulanlar

**Manifest’te zaten var, neden Play uyarı veriyor?**  
Android izinleri APK’da olur; Play Console ayrıca **politika beyanı** ister. İkisi birlikte gerekli.

**Ekran paylaşımı kullanmıyoruz, MEDIA_PROJECTION kaldırılabilir mi?**  
Agora ve Tencent SDK’ları bu izni otomatik ekler. Kaldırmak için SDK bağımlılıklarını değiştirmek gerekir; pratikte Play Console’da beyan etmek daha kolaydır.

**Beyan sonrası hâlâ uyarı var mı?**  
Yeni AAB yükleyin (`scripts/build-play-aab.sh`). Birka saat içinde Play durumu güncellenir.
