import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_discover_shortcut_labels.dart';

void main() {
  test('socialDiscoverShortcutLabels has five entries', () {
    expect(socialDiscoverShortcutLabels, hasLength(5));
    expect(socialDiscoverShortcutLabels.first, 'Tümü');
    expect(socialDiscoverShortcutLabels, contains('Ünlüler'));
    expect(socialDiscoverShortcutLabels.last, 'Fan Club');
  });

  test('socialDiscoverShortcutRoutes align with labels', () {
    expect(socialDiscoverShortcutRoutes, hasLength(socialDiscoverShortcutLabels.length));
    expect(socialDiscoverShortcutRoutes, contains('/celebrities-hub'));
    expect(socialDiscoverShortcutRoutes.first, isEmpty);
    expect(socialDiscoverShortcutRoutes, contains('/canli-falcilar'));
  });
}
