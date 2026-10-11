import 'package:canlifal_social/features/admin/presentation/providers/admin_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminPreferences toJson/fromJson roundtrip', () {
    const prefs = AdminPreferences(
      theme: AdminThemeMode.dark,
      layout: AdminLayoutMode.compact,
      compactSidebar: true,
      notificationFilters: {'error', 'warning'},
    );
    final restored = AdminPreferences.fromJson(prefs.toJson());
    expect(restored.theme, AdminThemeMode.dark);
    expect(restored.layout, AdminLayoutMode.compact);
    expect(restored.compactSidebar, isTrue);
    expect(restored.notificationFilters, {'error', 'warning'});
  });
}
