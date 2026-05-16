# Canlifal Mobile

Canlifal Mobile, [canlifal.com](https://canlifal.com) için Flutter ile hazırlanmış mobil uygulama kabuğudur. Uygulama siteyi WebView içinde açar ve ana bölümlere yerel alt navigasyonla hızlı erişim sağlar.

## Özellikler

- Canlifal ana sayfasını güvenli `https` WebView içinde açar.
- Ana Sayfa, Videolar, Canlı, Falcılar ve Fal bölümleri için alt navigasyon sunar.
- Sayfa yükleme ilerlemesini gösterir.
- Geri, yenile ve bağlantı hatasında tekrar dene akışlarını destekler.
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
- Android WebView için Android SDK 24 veya üzeri
- iOS için iOS 13.0 veya üzeri

## Geliştirme komutları

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

> Not: Bu cloud ortamında Flutter SDK kurulu olmadığı için `flutter analyze` ve `flutter test` komutları burada çalıştırılamadı.
