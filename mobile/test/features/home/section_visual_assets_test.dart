import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/home/presentation/data/section_visual_catalog.dart';
import 'package:canlifal_social/features/home/presentation/widgets/approved/home_horoscope_section.dart';

void main() {
  test('12 burcun yerel arka planı var ve dosyası mevcut', () {
    for (final (name, _, _, _) in HomeHoroscopeSection.signs) {
      final path = SectionVisualCatalog.horoscopeAsset(name);
      expect(path, isNotNull, reason: name);
      expect(File(path!).existsSync(), isTrue, reason: name);
    }
    expect(SectionVisualCatalog.horoscopeAsset('yok'), isNull);
  });
}
