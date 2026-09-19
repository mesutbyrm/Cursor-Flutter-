import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hediye katalogları animasyon dosyalarına sabit yollarla işaret ediyor.
/// Yanlış yazılmış ya da silinmiş bir yol çalışma zamanında sessizce
/// yedeğe düşüyor; kimse fark etmiyor. Bu test referansların diskteki
/// gerçek dosyalarla eşleştiğini doğrular.
///
/// Not: Bu test yalnızca **dosyanın var olduğunu** doğrular, doğru animasyon
/// olduğunu değil. Örneğin `yacht` bugün `star.json`'a işaret ediyor — dosya
/// var, ama yat hediyesi yıldız oynatıyor. Bunun için gerçek bir `yacht.json`
/// tasarım varlığı gerekiyor.
void main() {
  final catalogFiles = <String>[
    'lib/features/gifts/data/gift_catalog_maps.dart',
    'lib/features/live/domain/entities/live_gift_catalog.dart',
  ];

  // Yalnızca lottie yolları taranıyor: `_LottiePlayer` bu dosyayı gerçekten
  // açıyor, dolayısıyla eksik olması görünür bir arızadır.
  //
  // SVGA yolları bilinçli olarak kapsam dışı: `_SvgaFallback` dosyayı hiç
  // okumuyor, CMS thumbnail'i + emoji çiziyor. `svgaAssetByKey` girişi yalnızca
  // "bu hediye svga türü" yönlendirme işareti olarak kullanılıyor
  // (`resolvedKind`), bu yüzden `assets/gifts/svga/galaxy.svga` diskte
  // bulunmasa da kullanıcıya yansıyan bir hata oluşmuyor.
  final assetRefPattern = RegExp(r"'(assets/gifts/lottie/[^']+)'");

  test('kataloglarda referans verilen her hediye varlığı diskte var', () {
    final missing = <String>[];
    final seen = <String>{};

    for (final path in catalogFiles) {
      final source = File(path);
      expect(
        source.existsSync(),
        isTrue,
        reason: '$path bulunamadı — test yolu güncellenmeli',
      );

      for (final m in assetRefPattern.allMatches(source.readAsStringSync())) {
        final assetPath = m.group(1)!;
        if (!seen.add(assetPath)) continue;
        // Dizin kaydı (pubspec asset klasörü) değil, dosya bekleniyor.
        if (assetPath.endsWith('/')) continue;
        if (!File(assetPath).existsSync()) {
          missing.add('$assetPath  ($path)');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Katalog var olmayan dosyalara işaret ediyor:\n${missing.join('\n')}',
    );
  });

  test('en az bir varlık taranmış olmalı (regex çürümesine karşı)', () {
    var count = 0;
    for (final path in catalogFiles) {
      count += assetRefPattern
          .allMatches(File(path).readAsStringSync())
          .length;
    }
    expect(
      count,
      greaterThan(0),
      reason: 'hiç varlık yolu bulunamadıysa test sessizce anlamsızlaşır',
    );
  });
}
