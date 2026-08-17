import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/presentation/utils/social_discover_shortcut_labels.dart';

void main() {
  test('socialDiscoverShortcutLabels has four entries', () {
    expect(socialDiscoverShortcutLabels, hasLength(4));
    expect(socialDiscoverShortcutLabels, contains('Ünlüler'));
    expect(socialDiscoverShortcutLabels, contains('Sesli'));
  });

  test('socialDiscoverShortcutRoutes align with labels', () {
    expect(socialDiscoverShortcutRoutes, hasLength(socialDiscoverShortcutLabels.length));
    expect(socialDiscoverShortcutRoutes, contains('/celebrities-hub'));
    expect(socialDiscoverShortcutRoutes, contains('/voice-rooms'));
  });
}
