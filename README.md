# Canlifal Mobile

Canlifal Mobile, Canlifal için Flutter ile hazırlanmış native mobil uygulama önizlemesidir. Bu sürüm WebView yerine Flutter bileşenleriyle çizilen ana sayfa, videolar, canlı yayınlar, falcılar ve fal gönderme ekranlarını içerir.

## Özellikler

- Ana Sayfa, Videolar, Canlı, Falcılar ve Fal bölümleri için native alt navigasyon sunar.
- Mor/pembe vurgulu Material 3 kart tasarımı kullanır.
- Popüler falcılar, video kartları, canlı yayın kartı ve fal seçenekleri gösterir.
- Yenile akışı için kısa yükleme göstergesi ve bilgilendirme mesajı sunar.
- Material 3 tema kullanır.

## Kurulum

Bu repoda Flutter kaynakları ve proje yapılandırması bulunur. Yeni bir makinede ilk kez çalıştırırken eksik platform klasörlerini Flutter CLI ile üretin:

```bash
flutter create --platforms=android,ios --project-name canlifal_mobile .
flutter pub get
flutter run
```

## Gereksinimler

- Flutter SDK
- Dart SDK `>=3.8.0 <4.0.0`
- Android SDK
- iOS için iOS 13.0 veya üzeri

## Geliştirme komutları

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

> Not: APK üretmek için platform klasörleri `flutter create --platforms=android` komutuyla oluşturulabilir.
