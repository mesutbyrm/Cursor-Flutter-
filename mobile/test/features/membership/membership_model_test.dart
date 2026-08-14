import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';

void main() {
  group('MembershipCatalogData', () {
    test('SVIP tier katalogda yer alır', () {
      final svip = MembershipCatalogData.tiers
          .firstWhere((t) => t.id == MembershipTierId.svip);
      expect(svip.title, 'SVIP');
      expect(svip.wireId, 'svip');
      expect(svip.monthlyTokens, greaterThan(7500));
    });

    test('özellik tablosu 5 sütun', () {
      for (final row in MembershipCatalogData.featureRows) {
        expect(row.values.length, 5);
      }
    });

    test('token paketleri SVIP içerir', () {
      expect(
        MembershipCatalogData.tokenPackages
            .any((p) => p.tierId == MembershipTierId.svip),
        isTrue,
      );
    });
  });

  group('MembershipPackageEntity', () {
    test('isSvip super_vip alias', () {
      const pkg = MembershipPackageEntity(
        id: 'super_vip',
        planId: 'plan-1',
        title: 'SVIP',
        durationDays: 30,
        priceJeton: 7000,
        bonusJeton: 10000,
        falDiscountPercent: 0,
      );
      expect(pkg.isSvip, isTrue);
    });

    test('popular recommended alias', () {
      final pkg = MembershipPackageEntity.fromJson({
        'id': 'gold',
        'recommended': true,
      });
      expect(pkg.popular, isTrue);
    });
  });
}
