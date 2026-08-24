import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/domain/entities/payment_method_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';

void main() {
  group('PaymentMethodEntity', () {
    test('fromJson id ve label çözümler', () {
      final m = PaymentMethodEntity.fromJson({
        'key': 'papara',
        'name': 'Papara',
        'recommended': true,
      });
      expect(m.id, 'papara');
      expect(m.label, 'Papara');
      expect(m.recommended, isTrue);
      expect(m.enabled, isTrue);
    });

    test('disabled method filtrelenir', () {
      final m = PaymentMethodEntity.fromJson({
        'id': 'bank_transfer',
        'label': 'Havale',
        'enabled': false,
      });
      expect(m.enabled, isFalse);
    });

    test('parseList boş listede defaults döner', () {
      expect(PaymentMethodEntity.parseList([]), PaymentMethodEntity.defaults);
      expect(PaymentMethodEntity.parseList(null), PaymentMethodEntity.defaults);
    });

    test('parseList API listesini ayrıştırır', () {
      final list = PaymentMethodEntity.parseList([
        {'id': 'whatsapp', 'label': 'WhatsApp'},
        {'method': 'papara', 'title': 'Papara'},
      ]);
      expect(list.length, 2);
      expect(list.first.id, 'whatsapp');
      expect(list.last.id, 'papara');
    });

    test('checkoutMethods bilinmeyen kanalları filtreler', () {
      final list = PaymentMethodEntity.checkoutMethods([
        const PaymentMethodEntity(id: 'crypto', label: 'Kripto', enabled: true),
        const PaymentMethodEntity(id: 'papara', label: 'Papara', enabled: true),
      ]);
      expect(list.length, 1);
      expect(list.first.id, 'papara');
    });

    test('checkoutMethods yalnızca bilinmeyen varsa defaults', () {
      final list = PaymentMethodEntity.checkoutMethods([
        const PaymentMethodEntity(id: 'crypto', label: 'Kripto', enabled: true),
      ]);
      expect(list, PaymentMethodEntity.defaults);
    });
  });

  group('shouldShowSocialMembershipBadge', () {
    test('ücretli tier gösterilir', () {
      expect(shouldShowSocialMembershipBadge('gold'), isTrue);
      expect(shouldShowSocialMembershipBadge('svip'), isTrue);
      expect(shouldShowSocialMembershipBadge('premium'), isTrue);
    });

    test('free ve özel roller gösterilmez', () {
      expect(shouldShowSocialMembershipBadge('free'), isFalse);
      expect(shouldShowSocialMembershipBadge('fortune_teller'), isFalse);
      expect(shouldShowSocialMembershipBadge('agency'), isFalse);
      expect(shouldShowSocialMembershipBadge(null), isFalse);
    });
  });
}
