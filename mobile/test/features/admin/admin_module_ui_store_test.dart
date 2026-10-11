import 'package:canlifal_social/features/admin/presentation/providers/admin_module_ui_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save and load scroll + filter', () async {
    SharedPreferences.setMockInitialValues({});
    await AdminModuleUiStore.saveScroll('admin.users', 120.5);
    await AdminModuleUiStore.saveFilter('admin.complaints', 'pending');
    final all = await AdminModuleUiStore.loadAll();
    expect(AdminModuleUiStore.scrollFor(all, 'admin.users'), 120.5);
    expect(AdminModuleUiStore.filterFor(all, 'admin.complaints'), 'pending');
  });
}
