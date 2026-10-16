import 'package:canlifal_social/features/admin_web/domain/admin_web_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yalnız /admin altındaki web sayfaları açılır', () {
    expect(AdminWebConfig.safeAdminPath('/admin/withdrawals'), '/admin/withdrawals');
    expect(AdminWebConfig.safeAdminPath('/admin'), '/admin');
    expect(AdminWebConfig.safeAdminPath(null), '/admin');
    expect(AdminWebConfig.safeAdminPath('/profil'), '/admin');
    expect(AdminWebConfig.safeAdminPath('/admin/../giris'), '/admin');
    expect(AdminWebConfig.safeAdminPath('https://evil.example/admin'), '/admin');
    expect(AdminWebConfig.safeAdminPath('/adminx'), '/admin');
  });

  test('giriş adresi seçilen sayfayı ve mobil bayrağı taşır', () {
    final uri = AdminWebConfig.adminEntryUri(path: '/admin/blog');
    expect(uri.path, '/admin/blog');
    expect(uri.queryParameters['canlifal_mobile'], '1');
  });
}
