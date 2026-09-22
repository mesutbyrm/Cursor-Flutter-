import 'package:canlifal_social/features/live_psychics/presentation/data/psychic_teller_features_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('psychic teller catalog lists all major tool routes', () {
    final sections = psychicTellerFeaturesCatalog(profileId: 'test-id');
    final routes = sections
        .expand((s) => s.items)
        .map((i) => i.routePath)
        .toSet();
    expect(routes.length, greaterThan(40));
    expect(routes, contains('/canli-falcilar/gamification'));
    expect(routes, contains('/canli-falcilar/ai-chatbot'));
    expect(routes, contains('/canli-falcilar/test-id'));
  });
}
