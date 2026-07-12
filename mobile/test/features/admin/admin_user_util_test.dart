import 'package:canlifal_social/features/admin/domain/admin_user_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAdminUserId', () {
    test('reads userId when id missing', () {
      expect(
        resolveAdminUserId({'username': 'test', 'userId': 'cuid_abc'}),
        'cuid_abc',
      );
    });

    test('prefers id over userId', () {
      expect(
        resolveAdminUserId({'id': 'id1', 'userId': 'id2'}),
        'id1',
      );
    });

    test('normalize fills id', () {
      final m = normalizeAdminUserMap({'userId': 'x', 'userName': 'ali'});
      expect(m['id'], 'x');
      expect(m['username'], 'ali');
    });
  });
}
