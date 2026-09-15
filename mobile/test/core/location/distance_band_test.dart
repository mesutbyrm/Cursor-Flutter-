import 'package:canlifal_social/core/location/distance_band.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistanceBand', () {
    test('bands km into Turkish labels', () {
      expect(DistanceBand.labelFromKm(0.5), '0–1 km');
      expect(DistanceBand.labelFromKm(2.5), '1–5 km');
      expect(DistanceBand.labelFromKm(8), '5–10 km');
      expect(DistanceBand.labelFromKm(120), '50+ km');
    });

    test('displayLabel respects hidden flag', () {
      expect(DistanceBand.displayLabel(12, hidden: true),
          'Mesafe bilgisi gizli');
      expect(DistanceBand.displayLabel(12), 'Yaklaşık 10–25 km uzakta');
    });
  });
}
