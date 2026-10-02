import 'package:canlifal_social/features/live_psychics/presentation/data/psychic_teller_features_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('katalog yalnızca gerçek veriye bağlı ekranları listeler', () {
    final routes = psychicTellerFeaturesCatalog(profileId: 'test-id')
        .expand((s) => s.items)
        .map((i) => i.routePath)
        .toSet();
    expect(routes, contains('/canli-falcilar/dashboard'));
    expect(routes, contains('/canli-falcilar/test-id'));
    expect(routes, contains('/canli-falcilar/sessions'));
    expect(routes, contains('/canli-falcilar/dashboard/reviews'));
    expect(routes, contains('/wallet'));
    // Sahte veriyle çalışan ekranlar geri gelmesin.
    expect(routes, isNot(contains('/canli-falcilar/earnings')));
    expect(routes, isNot(contains('/canli-falcilar/withdrawal-management')));
    expect(routes, isNot(contains('/canli-falcilar/dashboard/profile-edit')));
  });
}
